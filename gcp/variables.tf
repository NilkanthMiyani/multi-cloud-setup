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
  description = "A map of labels to add to all resources. GCP labels must be lowercase (see validation)."
  type        = map(string)
  default = {
    "project" = "prod-proj"
  }

  # GCP label keys/values allow only lowercase letters, digits, '_' and '-',
  # and keys must start with a lowercase letter. Fail early with a clear message
  # instead of an opaque API rejection at apply time.
  validation {
    condition = alltrue([
      for k, v in var.tags :
      k == lower(k) && v == lower(v) && can(regex("^[a-z]", k))
    ])
    error_message = "GCP labels must be lowercase and keys must start with a lowercase letter (e.g. \"project\", not \"Project\")."
  }
}

variable "node_size" {
  description = "Machine type for the default node pool (e.g. e2-standard-2)."
  type        = string
  default     = "e2-standard-2"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

# --- GCP / GKE -------------------------------------------------------------

variable "gcp_region" {
  description = "GCP region for the google provider (e.g. us-central1)."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP location for the GKE cluster and node pool. A zone (e.g. us-central1-a) creates a cheaper zonal cluster where node_count is the total node count. A region (e.g. us-central1) creates a regional cluster where node_count is applied PER zone (x3 by default)."
  type        = string
  default     = "us-central1-a"
}

variable "gcp_project" {
  description = "GCP project id to create the cluster in."
  type        = string
  default     = ""
}

variable "gcp_credentials" {
  description = "Path to a GCP service-account key JSON file. Leave blank to use Application Default Credentials (gcloud auth)."
  type        = string
  default     = ""
}
