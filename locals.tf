locals {
  # The target cloud is the current Terraform workspace name. This also gives
  # each cloud its own state file automatically (terraform.tfstate.d/<cloud>/),
  # so there is no -state flag to remember. The tobool() fails the run fast in
  # the default workspace (or any typo'd name) instead of silently creating
  # zero resources; local.cloud is reachable from the resource counts below, so
  # this always evaluates.
  cloud = contains(["aws", "az", "gcp"], terraform.workspace) ? terraform.workspace : tobool(
  "Select a cloud workspace first: terraform workspace select <aws|az|gcp>")

  # Cloud selection flags. Each resource file gates its resources on the
  # matching flag via count, so only the selected cloud's resources are created.
  is_aws   = local.cloud == "aws" ? 1 : 0
  is_azure = local.cloud == "az" ? 1 : 0
  is_gcp   = local.cloud == "gcp" ? 1 : 0

  # GCP resource labels must be lowercase, so var.tags is normalized here before
  # being applied to GKE resources.
  gcp_labels = { for k, v in var.tags : lower(k) => lower(v) }
}
