#!/bin/bash

# Variables
PROJECT_ID="mdepew-assets"
POOL_ID="github-pool"
PROVIDER_ID="github-provider"
GITHUB_SA="github-actions-sa"
PIPELINE_SA="vertex-pipelines"
PREDICT_SA="vertex-predict"

# Import Workload Identity Pool
echo "Importing Workload Identity Pool..."
terraform import -var="project_id=${PROJECT_ID}" -var="github_repo=egen/egen-mlops-accelerator-dev" google_iam_workload_identity_pool.github_pool "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_ID}"

# Import Workload Identity Provider
echo "Importing Workload Identity Provider..."
terraform import -var="project_id=${PROJECT_ID}" -var="github_repo=egen/egen-mlops-accelerator-dev" google_iam_workload_identity_pool_provider.github_provider "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"

# Import Service Accounts
echo "Importing GitHub Service Account..."
terraform import google_service_account.github_sa "projects/${PROJECT_ID}/serviceAccounts/${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Importing Pipeline Runner Service Account..."
terraform import google_service_account.pipeline_runner "projects/${PROJECT_ID}/serviceAccounts/${PIPELINE_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Importing Predict Service Account..."
terraform import google_service_account.predict "projects/${PROJECT_ID}/serviceAccounts/${PREDICT_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Import complete. You can now run terraform plan/apply to manage these resources."
