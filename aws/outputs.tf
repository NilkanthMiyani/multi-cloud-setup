output "cluster_name" {
  description = "Name of the provisioned cluster."
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the provisioned cluster."
  value       = aws_eks_cluster.this.endpoint
}
