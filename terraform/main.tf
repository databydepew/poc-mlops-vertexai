resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com", 
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  
  project = var.project_id
  service = each.key
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

#------- Workload Identity -------#

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Federates GitHub Actions with GCP"
  
  lifecycle {
    ignore_changes = [
      description,
      display_name
    ]
  }
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub Provider"
  description                        = "GitHub as identity provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "attribute.repository == '${var.github_repo}'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

#------- SA -------#

# GitHub Service Account
resource "google_service_account" "github_sa" {
  account_id   = var.service_account_id
  display_name = "GitHub Actions SA"
  
  lifecycle {
    ignore_changes = [
      display_name,
      description
    ]
  }
}

# Pipeline Runner Service Account
# Create Pipeline Job Runner Service Account
resource "google_service_account" "pipeline_runner" {
  account_id   = "vertex-pipelines"
  display_name = "Pipeline Runner Service Account"
  description  = "For submitting PipelineJobs"
  
  depends_on = [google_project_service.required_apis]
  
  lifecycle {
    ignore_changes = [
      display_name,
      description
    ]
  }
}
#predict service account
resource "google_service_account" "predict" {
  account_id   = var.predict_service_account_id
  display_name = "Predict Service Account"
  description  = "For submitting PredictJobs"
  
  depends_on = [google_project_service.required_apis]
  
  lifecycle {
    ignore_changes = [
      display_name,
      description
    ]
  }
}


#---- bindings ----# 
# IAM role bindings for Pipeline Job Runner Service Account
resource "google_project_iam_member" "pipeline_runner_roles" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/artifactregistry.reader",
    "roles/cloudfunctions.admin",
    "roles/bigquery.user",
    "roles/bigquery.dataEditor",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.pipeline_runner.email}"
  
  depends_on = [google_service_account.pipeline_runner]
}

# IAM role bindings for Predict Service Account
resource "google_project_iam_member" "predict_roles" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/artifactregistry.reader",
    "roles/cloudfunctions.admin",
    "roles/bigquery.user",
    "roles/bigquery.dataEditor",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.predict.email}"
  
  depends_on = [google_service_account.predict]
}


# IAM role bindings for GitHub Service Account
resource "google_service_account_iam_member" "github_sa_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# IAM role bindings for GitHub Service Account
resource "google_project_iam_member" "github_sa_roles" {
  for_each = toset([
    # Core Vertex AI permissions
    "roles/aiplatform.user",
    "roles/aiplatform.serviceAgent",
    
    # Storage permissions for pipeline artifacts
    "roles/storage.objectViewer",
    "roles/storage.objectCreator",
    
    # BigQuery permissions for data operations
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    
    # Dataflow permissions
    "roles/dataflow.worker",
    
    # Logging and monitoring permissions
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    
    # Artifact Registry permissions
    "roles/artifactregistry.reader",
    
    # IAM Viewer role to allow viewing IAM policies
    "roles/iam.securityReviewer",
    
    # Cloud Build permissions
    "roles/cloudbuild.builds.editor",
    "roles/cloudbuild.serviceAgent"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

# Service Account Impersonation
# This allows the GitHub service account to impersonate the pipeline runner service account
resource "google_service_account_iam_binding" "pipeline_impersonation" {
  service_account_id = google_service_account.pipeline_runner.name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.github_sa.email}"]
}

# This allows the GitHub service account to impersonate the predict service account
resource "google_service_account_iam_binding" "predict_impersonation" {
  service_account_id = google_service_account.predict.name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.github_sa.email}"]
}



# Create Artifact Registry repository
resource "google_artifact_registry_repository" "vertex_registry" {
  provider = google
  
  location      = var.default_region
  repository_id = var.registry_name
  description   = "Artifact Registry ${var.registry_name} in ${var.default_region}."
  format        = "DOCKER"
  
  depends_on = [google_project_service.required_apis]
}

# Create Cloud Storage bucket
resource "google_storage_bucket" "vertex_bucket" {
  name          = "${var.project_id}-vertex-bucket"
  location      = var.default_region
  force_destroy = false
  
  depends_on = [google_project_service.required_apis]
}





# Outputs
output "artifact_registry_name" {
  value = google_artifact_registry_repository.vertex_registry.repository_id
}

output "storage_bucket_name" {
  value = google_storage_bucket.vertex_bucket.name
}

output "pipeline_runner_service_account" {
  value = google_service_account.pipeline_runner.email
}