variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  default     = "github-provider"
}

variable "service_account_id" {
  description = "Service account ID (no domain)"
  default     = "github-actions-sa"
}

variable "github_repo" {
  description = "GitHub repository in format 'OWNER/REPO'"
  type        = string
}

variable "target_service_account_id" {
  description = "Service account ID to be impersonated by the GitHub service account"
  type        = string
  default     = ""
}

variable "pipeline_runner_service_account_id" {
  description = "Service account ID for Pipeline service account"
  type        = string
  default     = ""
}

variable "predict_service_account_id" {
  description = "Service account ID for Predict service account"
  type        = string
  default     = ""
}

variable "registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "mdepew-registry"
}
  
variable "default_region" {
  description = "Default region for resources"
  default     = "us-central1"
}
  