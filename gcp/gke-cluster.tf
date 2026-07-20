###############################################################################
# GCP / GKE
###############################################################################

resource "google_container_cluster" "this" {
  name                     = var.cluster_name
  location                 = var.gcp_zone
  min_master_version       = var.k8s_version
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  resource_labels = local.gcp_labels
}

resource "google_container_node_pool" "this" {
  name       = "${var.project}-default"
  location   = var.gcp_zone
  cluster    = google_container_cluster.this.name
  node_count = var.node_count

  node_config {
    machine_type = var.node_size
    labels       = local.gcp_labels
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
