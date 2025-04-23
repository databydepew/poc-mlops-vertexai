#!/usr/bin/env python3
"""
Script to compile the Vertex AI pipeline.
This creates the pipeline.json file that will be used by the GitHub Actions workflow.
"""

#!/usr/bin/env python3
"""
Compile the Vertex AI pipeline.
"""

import os
from kfp import compiler
from pipeline import bq_tabnet_pipeline


def main():
    """Compile the pipeline to a JSON file."""
    # Ensure we're in the pipeline directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Compile the pipeline
    compiler.Compiler().compile(
        pipeline_func=bq_tabnet_pipeline,
        package_path="pipeline.json"
    )
    print("Pipeline compiled successfully to pipeline.json")


if __name__ == "__main__":
    main()
