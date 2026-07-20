locals {
  # GCP resource labels must be lowercase, so var.tags is normalized here before
  # being applied to GKE resources.
  gcp_labels = { for k, v in var.tags : lower(k) => lower(v) }
}
