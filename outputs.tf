# Only the selected cloud creates resources, so one() returns that cloud's value
# and null for the other two; coalesce() then picks the live one. try() guards
# the all-null case (e.g. `terraform output` against fresh, pre-apply state),
# where coalesce() would otherwise error.

output "cluster_name" {
  description = "Name of the provisioned cluster."
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the provisioned cluster."
  value = try(coalesce(
    one(aws_eks_cluster.this[*].endpoint),
    one(azurerm_kubernetes_cluster.this[*].fqdn),
    one(google_container_cluster.this[*].endpoint),
  ), null)
}
