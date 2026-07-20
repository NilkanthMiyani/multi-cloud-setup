###############################################################################
# AWS / EKS
# Networking for this cluster lives in networking.tf. This file holds the IAM
# roles, the EKS cluster, and the node group. Every resource is gated on
# local.is_aws. All cross-references use [0] indexing.
###############################################################################

# --- IAM: cluster role ------------------------------------------------------

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

# --- Cluster ----------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  count = local.is_aws

  name     = var.cluster_name
  version  = var.k8s_version
  role_arn = aws_iam_role.cluster[0].arn

  vpc_config {
    # Control plane ENIs span both tiers; nodes launch in the private subnets.
    subnet_ids              = flatten([aws_subnet.public[*].id, aws_subnet.private[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
    # security_group_ids      = [aws_security_group.eks_cluster[0].id, aws_security_group.eks_nodes[0].id]
  }

  tags = var.tags

  # The cluster policy must be attached before the cluster is created, and must
  # remain until the cluster is deleted.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

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
  disk_size      = var.node_disk_size
  instance_types = [var.node_size]

  tags = var.tags

  # Node policies must be attached before the node group's instances join, and
  # must remain until the node group is deleted.
  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}
