"""
Vertex AI Pipeline for BigQuery data processing and model training.
This pipeline demonstrates a practical ML workflow with BigQuery data extraction,
preprocessing, training with TabNet, and model deployment.
"""

from kfp import dsl
from kfp import compiler
from google_cloud_pipeline_components import aiplatform as gcc_aip
from google_cloud_pipeline_components.v1.bigquery import BigqueryQueryJobOp
from google_cloud_pipeline_components.v1.bigquery import BigqueryCreateModelJobOp
from google_cloud_pipeline_components.v1.endpoint import EndpointCreateOp, ModelDeployOp


@dsl.pipeline(
    name="bq-tabnet-pipeline",
    description="BigQuery TabNet Training and Deployment Pipeline"
)
def bq_tabnet_pipeline(
    project_id: str,
    region: str,
    dataset_id: str = "ml_dataset",
    table_id: str = "training_data",
    model_display_name: str = "bq-tabnet-model",
    target_column: str = "target",
    batch_size: int = 32,
    learning_rate: float = 0.01,
    max_steps: int = 1000,
    threshold: float = 0.5
):
    """Define a practical ML pipeline using BigQuery ML and Vertex AI."""
    
    # Step 1: Extract and prepare data with BigQuery
    extract_data = BigqueryQueryJobOp(
        project=project_id,
        location=region,
        query=f"""
        CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.prepared_data` AS
        SELECT *
        FROM `{project_id}.{dataset_id}.{table_id}`
        WHERE {target_column} IS NOT NULL
        """
    )
    
    # Step 2: Create train/test split
    create_train_test = BigqueryQueryJobOp(
        project=project_id,
        location=region,
        query=f"""
        CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.train_data` AS
        SELECT * FROM `{project_id}.{dataset_id}.prepared_data`
        WHERE RAND() < 0.8;
        
        CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.test_data` AS
        SELECT * FROM `{project_id}.{dataset_id}.prepared_data`
        WHERE RAND() >= 0.8;
        """
    ).after(extract_data)
    
    # Step 3: Train a TabNet model in BigQuery ML
    train_model = BigqueryCreateModelJobOp(
        project=project_id,
        location=region,
        query=f"""
        CREATE OR REPLACE MODEL `{project_id}.{dataset_id}.tabnet_model`
        OPTIONS(
            model_type='TABNET',
            input_label_cols=['{target_column}'],
            BATCH_SIZE = {batch_size},
            LEARN_RATE = {learning_rate},
            MAX_STEPS = {max_steps},
            EARLY_STOP = TRUE
        ) AS
        SELECT * EXCEPT({target_column}), {target_column}
        FROM `{project_id}.{dataset_id}.train_data`
        """
    ).after(create_train_test)
    
    # Step 4: Evaluate the model
    evaluate_model = BigqueryQueryJobOp(
        project=project_id,
        location=region,
        query=f"""
        CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.model_evaluation` AS
        SELECT *
        FROM ML.EVALUATE(
            MODEL `{project_id}.{dataset_id}.tabnet_model`,
            (SELECT * FROM `{project_id}.{dataset_id}.test_data`)
        )
        """
    ).after(train_model)
    
    # Step 5: Export model to Vertex AI
    export_model = gcc_aip.ModelUploadOp(
        project=project_id,
        location=region,
        display_name=model_display_name,
        artifact_uri=f"bq://{project_id}.{dataset_id}.tabnet_model",
        serving_container_image_uri="us-docker.pkg.dev/vertex-ai/prediction/tf2-cpu.2-8:latest"
    ).after(evaluate_model)
    
    # Step 6: Create endpoint
    endpoint_create = EndpointCreateOp(
        project=project_id,
        location=region,
        display_name=f"{model_display_name}-endpoint"
    )
    
    # Step 7: Deploy model to endpoint
    ModelDeployOp(
        project=project_id,
        location=region,
        endpoint=endpoint_create.outputs["endpoint"],
        model=export_model.outputs["model"],
        deployed_model_display_name=model_display_name,
        dedicated_resources_machine_type="n1-standard-4",
        dedicated_resources_min_replica_count=1,
        dedicated_resources_max_replica_count=1,
        traffic_split={"0": 100}
    )


# Compile the pipeline
if __name__ == "__main__":
    compiler.Compiler().compile(
        pipeline_func=bq_tabnet_pipeline,
        package_path="pipeline.json"
    )
