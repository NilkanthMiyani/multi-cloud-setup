###############################################################################
# Networking (per cloud)
# All networking resources for every cloud live here, gated by the same
# local.is_<cloud> flags used elsewhere. Only the selected cloud's network is
# created; the others produce zero resources.
###############################################################################

# =============================================================================
# AWS / EKS networking
# =============================================================================

data "aws_availability_zones" "available" {
  count = local.is_aws
  state = "available"
}

resource "aws_vpc" "this" {
  count = local.is_aws

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  count = local.is_aws

  vpc_id = aws_vpc.this[0].id

  tags = merge(var.tags, {
    Name = "${var.project}-igw"
  })
}

# One public subnet per AZ, up to var.availability_zones_count.
resource "aws_subnet" "public" {
  count = local.is_aws == 1 ? var.availability_zones_count : 0

  vpc_id                  = aws_vpc.this[0].id
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.project}-public-${count.index}"
    "kubernetes.io/role/elb" = "1"
    # Subnet discovery tag must match the cluster name.
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# One private subnet per AZ. Node groups live here; egress is via NAT.
# CIDRs are offset by availability_zones_count so they don't overlap the public
# subnets.
resource "aws_subnet" "private" {
  count = local.is_aws == 1 ? var.availability_zones_count : 0

  vpc_id            = aws_vpc.this[0].id
  availability_zone = data.aws_availability_zones.available[0].names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, count.index + var.availability_zones_count)

  tags = merge(var.tags, {
    Name                                        = "${var.project}-private-${count.index}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# --- NAT for private-subnet egress ------------------------------------------

resource "aws_eip" "nat" {
  count = local.is_aws

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project}-nat-eip"
  })

  depends_on = [aws_internet_gateway.this]
}

# Single NAT gateway (in the first public subnet) shared by all private subnets.
resource "aws_nat_gateway" "this" {
  count = local.is_aws

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.project}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

# --- Route tables -----------------------------------------------------------

resource "aws_route_table" "public" {
  count = local.is_aws

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = local.is_aws == 1 ? var.availability_zones_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = local.is_aws

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = local.is_aws == 1 ? var.availability_zones_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# --- Security groups --------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  count = local.is_aws

  name        = "${var.project}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.this[0].id

  tags = merge(var.tags, {
    Name = "${var.project}-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_inbound" {
  count = local.is_aws

  description              = "Allow worker nodes to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
}

resource "aws_security_group_rule" "cluster_outbound" {
  count = local.is_aws

  description              = "Allow cluster API Server to communicate with the worker nodes"
  type                     = "egress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
}

resource "aws_security_group" "eks_nodes" {
  count = local.is_aws

  name        = "${var.project}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.this[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name                                        = "${var.project}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "nodes_internal" {
  count = local.is_aws

  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
}

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  count = local.is_aws

  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes[0].id
  source_security_group_id = aws_security_group.eks_cluster[0].id
}

# =============================================================================
# Azure / AKS networking
# AKS currently uses provider-managed default networking (a vnet/subnet is
# created automatically for the node pool). To manage it explicitly, add an
# azurerm_virtual_network + azurerm_subnet here (gated on local.is_azure) and
# wire the subnet id into default_node_pool.vnet_subnet_id in aks-cluster.tf.
# =============================================================================

# =============================================================================
# GCP / GKE networking
# GKE currently uses the project's default VPC. To manage it explicitly, add a
# google_compute_network + google_compute_subnetwork here (gated on
# local.is_gcp) and set network/subnetwork on google_container_cluster in
# gke-cluster.tf.
# =============================================================================
