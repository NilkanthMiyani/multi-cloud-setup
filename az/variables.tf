# --- Common ----------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the managed Kubernetes cluster."
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes control plane version (e.g. 1.30)."
  type        = string
}

variable "project" {
  description = "Name to be used on all the resources as identifier. e.g. Project name, Application name"
  type        = string
  default     = "prod-proj"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    "Project" = "prod-proj"
  }
}

variable "node_size" {
  description = "VM size for the default node pool (e.g. Standard_D2s_v3)."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "OS disk size (GiB) for each node (os_disk_size_gb)."
  type        = number
  default     = 40
}

# --- Azure / AKS -----------------------------------------------------------

variable "location" {
  description = "Azure location/region. e.g. eastus."
  type        = string
  default     = "eastus"
}

variable "azure_subscription_id" {
  description = "Azure subscription id. Leave blank to use ARM_SUBSCRIPTION_ID / az login context."
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "Azure tenant id (service-principal auth). Leave blank to use az login / env vars."
  type        = string
  default     = ""
}

variable "azure_client_id" {
  description = "Azure client (app) id (service-principal auth). Leave blank to use az login / env vars."
  type        = string
  default     = ""
}

variable "azure_client_secret" {
  description = "Azure client secret (service-principal auth). Leave blank to use az login / env vars."
  type        = string
  default     = ""
  sensitive   = true
}
