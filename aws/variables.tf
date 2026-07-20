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
  description = "EC2 instance type for the default node group (e.g. t3.medium)."
  type        = string
  default     = "t3.medium"
}

# --- AWS / EKS -------------------------------------------------------------

variable "region" {
  description = "AWS region (e.g. us-east-1)."
  type        = string
  default     = "us-east-1"
}

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
  description = "OS/disk size (GiB) for each worker node."
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
