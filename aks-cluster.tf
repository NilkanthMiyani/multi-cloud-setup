###############################################################################
# Azure / AKS
# Every resource is gated on local.is_azure so nothing here is created unless
# var.cloud == "azure". All cross-references use [0] indexing.
###############################################################################

resource "azurerm_resource_group" "this" {
  count = local.is_azure

  name     = "${var.project}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  count = local.is_azure

  name                = var.cluster_name
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
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
