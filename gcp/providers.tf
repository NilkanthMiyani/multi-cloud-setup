terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.gcp_project != "" ? var.gcp_project : null
  region  = var.gcp_region

  # Blank credentials fall back to Application Default Credentials.
  credentials = var.gcp_credentials != "" ? file(var.gcp_credentials) : null
}
