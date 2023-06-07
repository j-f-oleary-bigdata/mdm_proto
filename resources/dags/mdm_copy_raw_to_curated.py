from airflow import DAG 
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow import models

"""
This DAG Requires Run time parameters to determine FROM and TO Dataset names. 

Use the following JSON format when Triggering DAG. 

{
"from_period":"2020_P10",
"to_period":"2020_P11"
}
"""

from datetime import datetime, timedelta

#LOCATION = models.Variable.get('gcp_mdm_region')
#IMPERSONATION_CHAIN = models.Variable.get('mdm_sa_acct')
PROJECT_ID = models.Variable.get('gcp_mdm_project')
DATASET_ID = models.Variable.get('mdm_curated_dataset')
TABLE_NAME = models.Variable.get('mdm_dplx_table_name')
MDM_RAW_TABLE = models.Variable.get('mdm_raw_table')

default_args = {
    'owner':'Prod_Ops_Team',
    'start_date':datetime(2020,10,29),
    'end_date':None,
    'email':None, 
    'email_on_failure':False,
    'email_on_retry':False,
    'retries':0
}

with DAG(
    dag_id = 'mdm_copy_raw_to_curated',
    schedule_interval = None,
    default_args = default_args
) as dag:

    t1 = BigQueryInsertJobOperator(
    task_id="execute_copy_query",
    configuration={
        "query": {
            "query": "select * from " + MDM_RAW_TABLE,
            "useLegacySql": False,
            "writeDisposition": "WRITE_EMPTY",
            'destinationTable': {
                'projectId': PROJECT_ID,
                'datasetId': DATASET_ID,
                'tableId': TABLE_NAME
            },
        }
    },
    )


    t1