terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# All three provider blocks are always evaluated regardless of which cloud is
# selected. AWS now uses flat variables (always defined via defaults). The Azure
# and GCP provider args are wrapped in try() so their null variable objects on
# an inactive cloud degrade to a harmless default instead of erroring at plan
# time.

provider "aws" {
  region = var.region

  # Blank keys fall back to the standard AWS credential chain (env vars, shared
  # config/credentials file, instance profile, etc.).
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null
}

provider "azurerm" {
  features {}

  # Blank values fall back to `az login` / ARM_* environment variables.
  subscription_id = var.azure_subscription_id != "" ? var.azure_subscription_id : null
  tenant_id       = var.azure_tenant_id != "" ? var.azure_tenant_id : null
  client_id       = var.azure_client_id != "" ? var.azure_client_id : null
  client_secret   = var.azure_client_secret != "" ? var.azure_client_secret : null
}

provider "google" {
  project = var.gcp_project != "" ? var.gcp_project : null
  region  = var.region

  # Blank credentials fall back to Application Default Credentials.
  credentials = var.gcp_credentials != "" ? file(var.gcp_credentials) : null
}
