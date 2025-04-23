# GitHub Actions Workload Identity Federation with GCP

This document explains how Workload Identity Federation is configured in our GitHub Actions workflows to securely authenticate with Google Cloud Platform (GCP) without using static service account keys.

## Overview

Workload Identity Federation allows external identities (like GitHub Actions) to act as GCP service accounts. This provides a more secure authentication method compared to using long-lived service account keys.

## Architecture

![Workload Identity Federation Architecture](https://cloud.google.com/static/iam/docs/images/workload-identity-federation-overview.svg)

Our implementation uses the following components:

1. **Workload Identity Pool**: A collection of external identities
2. **Workload Identity Provider**: Defines the trust relationship with GitHub
3. **Service Account**: The GCP identity that GitHub Actions impersonates
4. **IAM Binding**: Connects the GitHub repository to the service account

## How It Works

1. When a GitHub Actions workflow runs, it generates an OpenID Connect (OIDC) token
2. The token contains claims about the workflow (repository, branch, etc.)
3. Our Workload Identity Provider validates these claims
4. If valid, GCP issues a short-lived access token for the service account
5. GitHub Actions uses this token to authenticate with GCP services

## Implementation Details

### Terraform Configuration

Our Terraform configuration creates:

```hcl
# Workload Identity Pool for GitHub
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Federates GitHub Actions with GCP"
}

# Workload Identity Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "attribute.repository == 'egen/egen-mlops-accelerator-dev'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions
resource "google_service_account" "github_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions SA"
}

# IAM Binding between GitHub and Service Account
resource "google_service_account_iam_member" "github_sa_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/egen/egen-mlops-accelerator-dev"
}
```

### GitHub Actions Workflow

Our workflow authenticates using:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    token_format: 'access_token'
    workload_identity_provider: 'projects/194822035697/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
    service_account: 'github-actions-sa@mdepew-assets.iam.gserviceaccount.com'
```

## Security Benefits

1. **No Static Keys**: No long-lived credentials to manage or rotate
2. **Limited Scope**: Only specific GitHub repositories can authenticate
3. **Attribute Conditions**: Only actions from our repository are allowed
4. **Audit Trail**: All authentications are logged in Cloud Audit Logs
5. **Principle of Least Privilege**: Service account has only necessary permissions

## Service Account Permissions

Our service account has the following IAM roles:

- `roles/storage.objectViewer` - For reading from GCS buckets
- `roles/storage.objectCreator` - For writing to GCS buckets
- `roles/aiplatform.user` - For using Vertex AI services
- `roles/logging.logWriter` - For writing logs
- `roles/iam.securityReviewer` - For viewing IAM policies
- `roles/cloudbuild.builds.editor` - For creating and managing Cloud Build jobs
- `roles/cloudbuild.serviceAgent` - For acting as the Cloud Build service agent

## Troubleshooting

If authentication fails:

1. Verify the GitHub repository name matches the attribute condition
2. Check that the service account has necessary permissions
3. Ensure the Workload Identity Pool and Provider are properly configured
4. Review Cloud Audit Logs for authentication failures

## References

- [GCP Workload Identity Federation Documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
