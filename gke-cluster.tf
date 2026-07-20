###############################################################################
# GCP / GKE
# Every resource is gated on local.is_gcp so nothing here is created unless
# var.cloud == "gcp". All cross-references use [0] indexing.
###############################################################################

resource "google_container_cluster" "this" {
  count = local.is_gcp

  name = var.cluster_name
  # A zone (var.gcp_zone default) makes this a zonal cluster so node_count is the
  # total node count. Set gcp_zone to a region for a regional (HA) cluster, but
  # note node_count then applies per zone.
  location           = var.gcp_zone
  min_master_version = var.k8s_version

  # We manage node pools explicitly, so drop the default one the cluster is
  # created with. deletion_protection is disabled so `terraform destroy` works.
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  resource_labels = local.gcp_labels
}

resource "google_container_node_pool" "this" {
  count = local.is_gcp

  name       = "${var.project}-default"
  location   = var.gcp_zone
  cluster    = google_container_cluster.this[0].name
  node_count = var.node_count

  node_config {
    machine_type = var.node_size
    labels       = local.gcp_labels
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
