output "cluster_name" {
  description = "Name of the provisioned cluster."
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint (FQDN) of the provisioned cluster."
  value       = azurerm_kubernetes_cluster.this.fqdn
}
