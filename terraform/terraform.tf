terraform {
  backend "gcs" {
    bucket = "mdepew-assets-terraform-state"
    prefix = "terraform/state"
  }


  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.default_region
}
