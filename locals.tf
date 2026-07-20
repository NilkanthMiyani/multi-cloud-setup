locals {
  # Cloud selection flags. Each resource file gates its resources on the
  # matching flag via count, so only the selected cloud's resources are created.
  is_aws   = var.cloud == "aws" ? 1 : 0
  is_azure = var.cloud == "azure" ? 1 : 0
  is_gcp   = var.cloud == "gcp" ? 1 : 0

  # GCP resource labels must be lowercase, so var.tags is normalized here before
  # being applied to GKE resources.
  gcp_labels = { for k, v in var.tags : lower(k) => lower(v) }
}
