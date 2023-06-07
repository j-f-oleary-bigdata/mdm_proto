/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

####################################################################################
# Variables
####################################################################################
variable "project_id" {}
variable "project_number" {}
variable "location" {}
variable "network_id" {}
variable "dataplex_process_bucket_name" {}
variable "raw_dataset_name" {}
variable "raw_table_name" {}
variable "curated_dataset_name" {}
variable "product_dataset_name" {}
variable "mdm_table_name" {}


locals {
_dataplex_process_bucket_name   = format("%s_dataplex_process",var.project_id) 
}


####################################################################################
# Composer 2
####################################################################################
# Cloud Composer v2 API Service Agent Extension
# The below does not overwrite at the Org level like GCP docs: https://cloud.google.com/composer/docs/composer-2/create-environments#terraform
resource "google_project_iam_member" "cloudcomposer_account_service_agent_v2_ext" {
  project  = var.project_id
  role     = "roles/composer.ServiceAgentV2Ext"
  member   = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# Cloud Composer API Service Agent
resource "google_project_iam_member" "cloudcomposer_account_service_agent" {
  project  = var.project_id
  role     = "roles/composer.serviceAgent"
  member   = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_iam_member.cloudcomposer_account_service_agent_v2_ext
  ]
}

resource "google_project_iam_member" "composer_service_account_worker_role" {
  project  = var.project_id
  role     = "roles/composer.worker"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_service_account.composer_service_account
  ]
}


resource "google_compute_subnetwork" "composer_subnet" {
  project       = var.project_id
  name          = "composer-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.location
  network       = var.network_id

}

resource "google_service_account" "composer_service_account" {
  project      = var.project_id
  account_id   = "composer-service-account"
  display_name = "Service Account for Composer Environment"
}


# Let composer impersonation the service account that can change org policies (for demo purposes)
resource "google_service_account_iam_member" "cloudcomposer_service_account_impersonation" {
  service_account_id ="projects/${var.project_id}/serviceAccounts/admin-${var.project_number}-sa@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.composer_service_account.email}"
  depends_on         = [ google_service_account.composer_service_account ]
}

# ActAs role
resource "google_project_iam_member" "cloudcomposer_act_as" {
  project  = var.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_service_account_iam_member.cloudcomposer_service_account_impersonation
  ]
}




# ActAs role
resource "google_project_iam_member" "cloudcomposer_admin" {
  project  = var.project_id
  role     = "roles/composer.admin"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_act_as
  ]
}


resource "google_project_iam_member" "cloudcomposer_editorrole" {
  project  = var.project_id
  role     = "roles/editor"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_admin
  ]
}

resource "google_project_iam_member" "cloudcomposer_tokencreator" {
  project  = var.project_id
  role     = "roles/iam.serviceAccountTokenCreator"
  member   = "serviceAccount:${google_service_account.composer_service_account.email}"

  depends_on = [
    google_project_iam_member.cloudcomposer_editorrole
  ]
}



resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = format("%s-composer", var.project_id) 
  region   = var.location

  config {

    software_config {
      image_version = "composer-2-airflow-2"
      #"composer-2.0.7-airflow-2.2.3"

      pypi_packages = {
        #google-cloud-dataplex = ">=0.1.0"
        requests_oauth2 = ""
       # scipy = "==1.1.0"
      }

      env_variables = {
        #account_id   =  format("admin-%s-sa", local._project_number)
        AIRFLOW_VAR_DPLX_API_END_POINT = "https://dataplex.googleapis.com",
        AIRFLOW_VAR_MDM_ENTITY_LIST_PATH = "/home/airflow/gcs/data/entities.txt",
        AIRFLOW_VAR_MDM_SA_ACCT = "admin-${var.project_number}-sa@${var.project_id}.iam.gserviceaccount.com",
        AIRFLOW_VAR_MDM_RAW_TABLE = "${var.project_id}.${var.raw_dataset_name}.${var.raw_table_name}"
        AIRFLOW_VAR_MDM_CURATED_TABLE = "${var.project_id}.${var.curated_dataset_name}.${var.mdm_table_name}"
        AIRFLOW_VAR_MDM_CURATED_DATASET = "${var.curated_dataset_name}"
        AIRFLOW_VAR_MDM_DATAPRODUCT_TABLE = "${var.project_id}.${var.product_dataset_name}.${var.mdm_table_name}"
        AIRFLOW_VAR_MDM_DPLX_LAKE_ID = "prod-mdm-domain",
        AIRFLOW_VAR_MDM_DPLX_RAW_ZONE_ID = "mdm-raw-zone",
        AIRFLOW_VAR_MDM_DPLX_CURATED_ZONE_ID = "mdm-curated-zone",
        AIRFLOW_VAR_MDM_DPLX_DATA_PRODUCT_ZONE_ID = "mdm-data-product-zone",
        AIRFLOW_VAR_MDM_DPLX_TABLE_NAME = "${var.mdm_table_name}",
        AIRFLOW_VAR_MDM_DPLX_REGION = "US",
        AIRFLOW_VAR_GCP_MDM_PROJECT = "${var.project_id}",
        AIRFLOW_VAR_GCP_MDM_REGION = "${var.location}",
        AIRFLOW_VAR_TAG_TEMPLATE_MDM_INFORMATION = "projects/${var.project_id}/locations/${var.location}/tagTemplates/mdm_information",
        AIRFLOW_VAR_TAG_TEMPLATE_INPUT_FILE="mdm_info.yaml",
        AIRFLOW_VAR_TAG_TEMPLATE_INPUT_PATH = "gs://${var.dataplex_process_bucket_name}/mdm_configs",
        AIRFLOW_VAR_GCP_SUB_NET = "projects/${var.project_id}/regions/${var.location}/subnetworks/default",
        AIRFLOW_VAR_GDC_TAG_JAR = "gs://${var.dataplex_process_bucket_name}/common/mdm-tagmanager-1.0-SNAPSHOT.jar",
        AIRFLOW_VAR_MDM_INFORMATION_MAIN_CLASS = "com.google.cloud.dataplex.templates.mdminformation.MDMInfo",
        AIRFLOW_VAR_MDM_TAG_PREFIX="mdm-tag"
      }
    }

    # this is designed to be the smallest cheapest Composer for demo purposes
    workloads_config {
      scheduler {
        cpu        = 4
        memory_gb  = 10
        storage_gb = 10
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1
        storage_gb = 1
      }
      worker {
        cpu        = 2
        memory_gb  = 10
        storage_gb = 10
        min_count  = 1
        max_count  = 4
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      network         = var.network_id
      subnetwork      = google_compute_subnetwork.composer_subnet.id
      service_account = google_service_account.composer_service_account.name
    }
  }

  depends_on = [
    google_project_iam_member.cloudcomposer_account_service_agent_v2_ext,
    google_project_iam_member.cloudcomposer_account_service_agent,
    google_compute_subnetwork.composer_subnet,
    google_service_account.composer_service_account,
    google_project_iam_member.composer_service_account_worker_role,
 ##   google_project_iam_member.composer_service_account_bq_admin_role
  ]

  timeouts {
    create = "90m"
  }
}


resource "null_resource" "dag_setup" {
  provisioner "local-exec" {
    command = <<-EOT
    export airflow_dag_folder=$(gcloud composer environments describe ${var.project_id}-composer --location="us-central1" | grep dagGcsPrefix | awk  '{print $2}')
    export airflow_data_folder=$(gcloud composer environments describe ${var.project_id}-composer --location="us-central1" | grep dagGcsPrefix | awk  '{print $2}' | sed -e 's/dags/data/')
    gsutil mv gs://${local._dataplex_process_bucket_name}/dags/* $airflow_dag_folder
    gsutil mv gs://${local._dataplex_process_bucket_name}/airflow_data/* $airflow_data_folder/
    EOT
    }
    depends_on = [
               google_composer_environment.composer_env]

  }
