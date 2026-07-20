###############################################################################
# AWS / EKS
# Networking for this cluster lives in networking.tf. This file holds the EKS
# cluster, the node group, and the IAM roles they assume. Every resource is
# gated on local.is_aws. All cross-references use [0] indexing.
###############################################################################

# --- Cluster ----------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  count = local.is_aws

  name     = var.cluster_name
  version  = var.k8s_version
  role_arn = aws_iam_role.cluster[0].arn

  vpc_config {
    subnet_ids              = flatten([aws_subnet.public[*].id, aws_subnet.private[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

resource "aws_iam_role" "cluster" {
  count = local.is_aws

  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count = local.is_aws

  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- Node group -------------------------------------------------------------

resource "aws_eks_node_group" "this" {
  count = local.is_aws

  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = var.project
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  ami_type       = var.node_ami_type
  instance_types = [var.node_size]

  launch_template {
    id      = aws_launch_template.node[0].id
    version = aws_launch_template.node[0].latest_version
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

resource "aws_launch_template" "node" {
  count = local.is_aws

  name_prefix = "${var.project}-node-"

  vpc_security_group_ids = [
    aws_security_group.eks_nodes[0].id,
    aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.node_disk_size
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.project}-node" })
  }

  tags = var.tags
}

# --- IAM: node role ---------------------------------------------------------

resource "aws_iam_role" "node" {
  count = local.is_aws

  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  count = local.is_aws

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count = local.is_aws

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  count = local.is_aws

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
