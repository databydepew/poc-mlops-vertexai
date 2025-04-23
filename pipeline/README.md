# Vertex AI Pipeline Example

This directory contains an example Vertex AI pipeline that can be run using the GitHub Actions workflow.

## Pipeline Overview

The sample pipeline demonstrates a typical ML workflow with the following steps:

1. **Data Preprocessing**: Prepares the raw data for training
2. **Model Training**: Trains a machine learning model on the preprocessed data
3. **Model Evaluation**: Evaluates the model performance
4. **Model Deployment**: Deploys the trained model to Vertex AI Endpoints

## Prerequisites

- Google Cloud Project with Vertex AI API enabled
- Service account with appropriate permissions
- Storage bucket for pipeline artifacts

## Compiling the Pipeline

Before running the pipeline through GitHub Actions, you need to compile it:

```bash
# Install dependencies
pip install -r requirements.txt

# Compile the pipeline
python compile_pipeline.py
```

This will generate a `pipeline.json` file that the GitHub Actions workflow will use.

## Pipeline Parameters

The pipeline accepts the following parameters:

- `project_id`: Your GCP project ID
- `region`: GCP region to run the pipeline in (e.g., us-central1)
- `data_path`: GCS path to the input data
- `model_display_name`: Display name for the deployed model
- `serving_container_image_uri`: Container image for model serving
- `training_steps`: Number of training steps
- `evaluation_frequency`: Frequency of evaluation during training

## Running the Pipeline

The pipeline can be run manually through the GitHub Actions workflow by:

1. Going to the "Actions" tab in your GitHub repository
2. Selecting the "Run Vertex AI Pipeline" workflow
3. Clicking "Run workflow"
4. Filling in the required parameters
5. Clicking "Run workflow" again

## Monitoring

Once the pipeline is running, you can monitor its progress in the Vertex AI section of the Google Cloud Console.
