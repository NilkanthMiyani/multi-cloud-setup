cloud        = "az"
cluster_name = "prod-azure"
k8s_version  = "1.36"

azure_subscription_id = ""
azure_tenant_id       = ""
azure_client_id       = ""
azure_client_secret   = ""

location       = "eastus"
project        = "prod-proj"
node_size      = "Standard_D2s_v3"
node_count     = 2
node_disk_size = 40

tags = {
  "Project" = "prod-proj"
}
