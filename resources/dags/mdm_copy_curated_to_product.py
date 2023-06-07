from airflow import DAG 
from airflow.contrib.operators.bigquery_to_bigquery import BigQueryToBigQueryOperator
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



#IMPERSONATION_CHAIN = models.Variable.get('mdm_sa_acct')
MDM_CURATED_TABLE = models.Variable.get('mdm_curated_table')
MDM_DATAPRODUCT_TABLE = models.Variable.get('mdm_dataproduct_table')
LOCATION = models.Variable.get('gcp_mdm_region')

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
    dag_id = 'mdm_copy_curated_to_product',
    schedule_interval = None,
    default_args = default_args
) as dag:


    ##
    ## As of 5/31/2023 
    ## The BigQueryToBigQueryOperator fails with NotFound exception if BigQuery dataset's location:
    ##  is not in the us or the eu multi-regional location
    ##  is in a single region (for example, us-central1)
    ##  BUT: the copy does succeed
    ##
    t1 = BigQueryToBigQueryOperator(
        task_id = 'BQ_CP_V2',
        location = LOCATION,
        source_project_dataset_tables=MDM_CURATED_TABLE,
        destination_project_dataset_table=MDM_DATAPRODUCT_TABLE
    )


    t1