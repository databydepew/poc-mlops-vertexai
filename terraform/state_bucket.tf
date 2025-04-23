resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-state"
  location      = var.region
  force_destroy = false

  # Use Standard storage class for state files
  storage_class = "STANDARD"

  # Enable versioning to keep history of state files
  versioning {
    enabled = true
  }

  # Lifecycle rules for state management
  lifecycle_rule {
    condition {
      age = 30  # Days
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Move older versions to coldline storage
  lifecycle_rule {
    condition {
      age = 90  # Days
      with_state = "ARCHIVED"
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Delete versions older than 1 year
  lifecycle_rule {
    condition {
      age = 365  # Days
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  # Ensure uniform bucket-level access
  uniform_bucket_level_access = true
}
