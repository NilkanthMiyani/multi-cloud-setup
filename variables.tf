variable "cloud" {
  description = "Which cloud to provision the cluster on. One of: aws | az | gcp."
  type        = string

  validation {
    condition     = contains(["aws", "az", "gcp"], var.cloud)
    error_message = "var.cloud must be one of: aws, az, gcp."
  }
}

variable "cluster_name" {
  description = "Name of the managed Kubernetes cluster."
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes control plane version (e.g. 1.30)."
  type        = string
}

# --- Generic (shared across all clouds) ------------------------------------

variable "project" {
  description = "Name to be used on all the resources as identifier. e.g. Project name, Application name"
  type        = string
  default     = "punta-medica"
}

variable "region" {
  description = "Cloud region. AWS: e.g. mx-central-1. GCP: e.g. us-central1. (Azure uses var.location instead.)"
  type        = string
  default     = "mx-central-1"
}

variable "node_size" {
  description = "Machine type for the default node pool. Cloud-specific: AWS t3.medium, Azure Standard_D2s_v3, GCP e2-standard-2."
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "tags" {
  description = "A map of tags to add to all resources (applied as labels on GCP, lowercased)."
  type        = map(string)
  default = {
    "Project" = "punta-medica"
  }
}

# --- AWS / EKS -------------------------------------------------------------
# Flat variables (only consumed when var.cloud == "aws").

variable "aws_access_key" {
  description = "AWS access key. Leave blank to use the standard credential chain (env vars, shared config, instance profile)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key. Leave blank to use the standard credential chain (env vars, shared config, instance profile)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "availability_zones_count" {
  description = "The number of AZs (and public subnets) to spread the cluster across."
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr_bits" {
  description = "The number of subnet bits for the CIDR. For example, specifying a value 8 for this parameter will create a CIDR with a mask of /24."
  type        = number
  default     = 8
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_ami_type" {
  description = "AMI type for the EKS managed node group (e.g. AL2023_x86_64_STANDARD)."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_disk_size" {
  description = "OS/disk size (GiB) for each worker node (EKS disk_size / AKS os_disk_size_gb)."
  type        = number
  default     = 50
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS node group."
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS node group."
  type        = number
  default     = 5
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS node group."
  type        = number
  default     = 5
}

# --- Azure / AKS -----------------------------------------------------------
# Flat variables (only consumed when var.cloud == "az").

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

# --- GCP / GKE -------------------------------------------------------------
# Flat variables (only consumed when var.cloud == "gcp").

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
