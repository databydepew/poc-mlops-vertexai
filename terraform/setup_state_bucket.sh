#!/bin/bash
set -e

# Variables
PROJECT_ID="mdepew-assets"
BUCKET_NAME="${PROJECT_ID}-state"
REGION="us-central1"

# Check if bucket exists
if gsutil ls -b gs://${BUCKET_NAME} &>/dev/null; then
  echo "State bucket gs://${BUCKET_NAME} already exists."
else
  echo "Creating Terraform state bucket gs://${BUCKET_NAME}..."
  
  # Create the bucket
  gsutil mb -p ${PROJECT_ID} -l ${REGION} -b on gs://${BUCKET_NAME}
  
  # Enable versioning
  gsutil versioning set on gs://${BUCKET_NAME}
  
  # Set lifecycle rules
  cat > /tmp/lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "NEARLINE"
        },
        "condition": {
          "age": 30,
          "matchesStorageClass": ["STANDARD"]
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 90,
          "matchesStorageClass": ["NEARLINE"],
          "isLive": false
        }
      },
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": 365,
          "isLive": false
        }
      }
    ]
  }
}
EOF

  # Apply lifecycle rules
  gsutil lifecycle set /tmp/lifecycle.json gs://${BUCKET_NAME}
  
  echo "Terraform state bucket created with lifecycle rules."
fi

# Verify bucket configuration
echo "Bucket details:"
gsutil ls -L -b gs://${BUCKET_NAME} | grep -E 'Storage class:|Versioning enabled:|Lifecycle configuration:'

echo "Terraform state bucket is ready to use."