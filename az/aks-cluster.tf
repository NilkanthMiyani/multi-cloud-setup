###############################################################################
# Azure / AKS
###############################################################################

resource "azurerm_resource_group" "this" {
  name     = "${var.project}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.k8s_version

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.node_size
    os_disk_size_gb = var.node_disk_size
  }

  # Cluster authenticates to Azure with a service principal (appId / password).
  service_principal {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }

  tags = var.tags
}
