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



 
locals {
  _prefix = var.project_id
  _bucket_prefix = var.project_id
  _useradmin_fqn                  = format("%s", var.ldap)
  _dataplex_process_bucket_name   = format("%s_dataplex_process", local._prefix) 
  _dataplex_bqtemp_bucket_name    = format("%s_dataplex_temp", local._prefix) 
}



data "google_project" "project" {}

locals {
  _project_number = data.google_project.project.number
}


provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   =  format("admin-%s-sa", local._project_number)
  display_name = "Demo Service Account"
}
 
resource "google_project_iam_member" "service_account_owner" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/bigquery.dataEditor",
"roles/bigquery.admin",
"roles/metastore.admin",
"roles/metastore.editor",
"roles/metastore.serviceAgent",
"roles/storage.admin",
"roles/dataplex.editor",
"roles/dataproc.admin",
"roles/dataproc.worker",
"roles/serviceusage.serviceUsageConsumer",
"roles/dataplex.admin",
"roles/datacatalog.tagEditor",
"roles/datacatalog.tagTemplateUser"
  ])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.service_account.email}"
  depends_on = [
    google_service_account.service_account
  ]
}
 
resource "google_project_iam_member" "user_account_owner" {
  for_each = toset([
"roles/iam.serviceAccountUser",
"roles/iam.serviceAccountTokenCreator",
"roles/bigquery.user",
"roles/bigquery.dataEditor",
"roles/bigquery.jobUser",
"roles/bigquery.admin",
"roles/storage.admin",
"roles/dataplex.admin",
"roles/dataplex.editor"
  ])
  project  = var.project_id
  role     = each.key
  member   = "user:${local._useradmin_fqn}"
}

resource "google_service_account_iam_binding" "admin_account_iam" {
  role               = "roles/iam.serviceAccountTokenCreator"

  service_account_id = google_service_account.service_account.name
  members = [
    "user:${local._useradmin_fqn}"
  ]

    depends_on = [
    google_service_account.service_account
  ]

}

####################################################################################
# Resource for Network Creation                                                    #
# The project was not created with the default network.                            #
# This creates just the network/subnets we need.                                   #
####################################################################################
resource "google_compute_network" "default_network" {
  project                 = var.project_id
  name                    = "default"
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

####################################################################################
# Resource for Subnet                                                              #
#This creates just the subnets we need                                             #
####################################################################################

resource "google_compute_subnetwork" "main_subnet" {
  project       = var.project_id
  name          = "default"    #format("%s-misc-subnet", local._prefix)
  ip_cidr_range = var.ip_range
  region        = var.location
  network       = google_compute_network.default_network.id
  private_ip_google_access = true
  depends_on = [
    google_compute_network.default_network,
  ]
}

####################################################################################
# Resource for Firewall rule                                                       #
####################################################################################

resource "google_compute_firewall" "firewall_rule" {
  project  = var.project_id
  name     = "allow-intra-default"    #format("allow-intra-%s-misc-subnet", local._prefix)
  network  = google_compute_network.default_network.id

  direction = "INGRESS"

  allow {
    protocol = "all"
  }
  
  source_ranges = [ var.ip_range ]
  depends_on = [
    google_compute_subnetwork.main_subnet
  ]
}

resource "google_compute_firewall" "user_firewall_rule" {
  project  = var.project_id
  name     = "allow-ingress-from-office-default"   #format("allow-ingress-from-office-%s", local._prefix)
  network  = google_compute_network.default_network.id

  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = [ var.user_ip_range ]
  depends_on = [
    google_compute_subnetwork.main_subnet
  ]
}

#data "google_compute_network" "default_network" {
#  name = "default"
#}


/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_iam_steps" {
  create_duration = "120s"
  depends_on = [
                google_compute_firewall.user_firewall_rule,
                google_service_account_iam_binding.admin_account_iam,
                google_project_iam_member.user_account_owner,
                google_project_iam_member.service_account_owner  
              ]
}

resource "google_storage_bucket" "storage_bucket_process" {
  project                     = var.project_id
  name                        = local._dataplex_process_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "google_storage_bucket_object" "tsv_file" {
    name          = "mdm.tsv"
    source        = "./mdm.tsv"
    bucket        = google_storage_bucket.storage_bucket_process.name
    depends_on = [google_storage_bucket.storage_bucket_process]
  }
  

resource "google_storage_bucket" "storage_bucket_bqtemp" {
  project                     = var.project_id
  name                        = local._dataplex_bqtemp_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}


####################################################################################
# Create BigQuery Datasets
####################################################################################

resource "google_bigquery_dataset" "raw_dataset" {
  project                     = var.project_id
  dataset_id                  = var.raw_dataset_name
  friendly_name               = var.raw_dataset_name
  description                 = "Raw Dataset for MDM Demo"
  location                   = var.location
  delete_contents_on_destroy  = true
  
  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "google_bigquery_dataset" "curated_dataset" {
  project                     = var.project_id
  dataset_id                  = var.curated_dataset_name
  friendly_name               = var.curated_dataset_name
  description                 = "Curated Dataset for MDM Demo"
  location                   = var.location
  delete_contents_on_destroy  = true
  
  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

resource "google_bigquery_dataset" "product_dataset" {
  project                     = var.project_id
  dataset_id                  = var.product_dataset_name
  friendly_name               = var.product_dataset_name
  description                 = "Product Dataset for MDM Demo"
  location                   = var.location
  delete_contents_on_destroy  = true
  
  depends_on = [time_sleep.sleep_after_network_and_iam_steps]
}

####################################################################################
# Create BigQuery Table
####################################################################################

resource "google_bigquery_table" "raw_customer_data" {
  project                     = var.project_id
  dataset_id                  = google_bigquery_dataset.raw_dataset.dataset_id
  table_id                    = var.raw_table_name
  schema      = <<EOF
    [
            {
                "name": "country",
                "type": "STRING"
            },
            {
                "name": "source_id",
                "type": "STRING"
                },
            {
                "name": "city",
                "type": "STRING"
            },
            {
                "name": "tamr_id",
                "type": "STRING"
            },
            {
                "name": "mock_id",
                "type": "STRING"
            },
            {
                "name": "enriched_phone_national",
                "type": "STRING"
            },
            {
                "name": "full_address",
                "type": "STRING"
            },
            {
                "name": "entity_id",
                "type": "STRING"
            },
            {
                "name": "alternative_name",
                "type": "STRING"
            },
            {
                "name": "enriched_phone_carrier",
                "type": "STRING"
            },
            {
                "name": "enriched_full_address",
                "type": "STRING"
            },
            {
                "name": "enriched_phone",
                "type": "STRING"
            },
            {
                "name": "phone",
                "type": "STRING"
            },
            {
                "name": "google_lookup_url",
                "type": "STRING"
            },
            {
                "name": "company_name",
                "type": "STRING"
            },
            {
                "name": "address_line1",
                "type": "STRING"
            },
            {
                "name": "enriched_phone_flag",
                "type": "STRING"
            },
            {
                "name": "address_line2",
                "type": "STRING"
            },
            {
                "name": "region",
                "type": "STRING"
            },
            {
                "name": "postal_code",
                "type": "STRING"
            }
    ]
    EOF
    external_data_configuration {
        autodetect = false
        source_format = "CSV"

        csv_options {
            quote                 = "\""
            field_delimiter       = "\t"
            allow_quoted_newlines = "false"
            allow_jagged_rows     = "false"
            skip_leading_rows     = 1
        }

        source_uris = [
            "gs://${local._dataplex_process_bucket_name}/mdm.tsv"
        ]
    }
  depends_on = [google_bigquery_dataset.raw_dataset,
  google_storage_bucket_object.tsv_file]
}

####################################################################################
# Create Custom Lineage
####################################################################################

resource "null_resource" "custom_lineage" {
  provisioner "local-exec" {
    command = <<-EOT

      rm -f lineage_processes_listing.json
      rm -f custom_lineage_run.json

      curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application.json" \
        https://us-datalineage.googleapis.com/v1/projects/${var.project_id}/locations/${var.api_location}/processes \
          -d "{\
            \"displayName\": \"Load MDM Dataset from TAMR\" \
        }"

      curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application.json" \
        https://us-datalineage.googleapis.com/v1/projects/${var.project_id}/locations/${var.api_location}/processes >> ./lineage_processes_listing.json

      CUSTOM_LINEAGE_PROCESS_ID=`cat lineage_processes_listing.json | grep -C 1 Public | grep name | cut -d'/' -f6 | tr -d \" | tr -d ,`

      DATE_START=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
      DATE_END=`date -u +"%Y-%m-%dT%H:%M:%SZ"`     

      curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application.json" \
      https://us-datalineage.googleapis.com/v1/projects/${var.project_id}/locations/${var.api_location}/processes/$CUSTOM_LINEAGE_PROCESS_ID/runs -d "{\
        \"displayName\": \"One time load\", \
        \"startTime\": \"$DATE_START\", \
        \"endTime\": \"$DATE_END\", \
        \"state\": \"COMPLETED\" \
      }"

      curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application.json" \
      https://us-datalineage.googleapis.com/v1/projects/${var.project_id}/locations/${var.api_location}/processes/$CUSTOM_LINEAGE_PROCESS_ID/runs >> ./custom_lineage_run.json

      CUSTOM_LINEAGE_PROCESS_RUN_ID=`cat custom_lineage_run.json | grep name | grep / | cut -d'/' -f8 | tr -d \" | tr -d ,`


      curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application.json" \
      https://us-datalineage.googleapis.com/v1/projects/${var.project_id}/locations/${var.api_location}/processes/$CUSTOM_LINEAGE_PROCESS_ID/runs/$CUSTOM_LINEAGE_PROCESS_RUN_ID/lineageEvents -d "{\
        \"links\": [ \
          { \
            \"source\": { \
              \"fullyQualifiedName\":\"internet:${var.project_id}.mdm_datasets.raw_dataset\" \
            }, \
            \"target\": { \
              \"fullyQualifiedName\":\"gs//:${var.project_id}_dataplex_process\/mdm.tsv\" \
            }, \
          } \
        ], \
        \"startTime\": \"$DATE_START\", \
      }"

    EOT
    }
    depends_on = [ google_bigquery_dataset.raw_dataset ]
  }

resource "null_resource" "gsutil_resources" {
  provisioner "local-exec" {
    command = <<-EOT
      cd ../resources/
      gsutil -u ${var.project_id} cp gs://dataplex-dataproc-templates-artifacts/* ./common/.
      java -cp common/mdm-tagmanager-1.0-SNAPSHOT.jar  com.google.cloud.dataplex.setup.CreateTagTemplates ${var.project_id} ${var.location} mdm_information
      gsutil -m cp -r * gs://${local._dataplex_process_bucket_name}
    EOT
    }
    depends_on = [
                  google_bigquery_dataset.raw_dataset,
                  google_storage_bucket.storage_bucket_process,
                  google_storage_bucket.storage_bucket_bqtemp]

  }

/*
####################################################################################
# Organize the Data
####################################################################################
*/

module "organize_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                 = "./modules/organize_data"
  #metastore_service_name = local._metastore_service_name
  project_id             = var.project_id
  location               = var.location
  lake_name              = var.lake_name
  project_number         = local._project_number
   
  #depends_on = [null_resource.dataproc_metastore]
  depends_on = [google_bigquery_table.raw_customer_data]

}


####################################################################################
# Register the Data Assets in Dataplex
####################################################################################

module "register_assets" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                                = "./modules/register_assets"
  project_id                            = var.project_id
  project_number                        = local._project_number
  location                              = var.location
  lake_name                             = var.lake_name
  raw_dataset_name                      = var.raw_dataset_name
  curated_dataset_name                  = var.curated_dataset_name
  product_dataset_name                  = var.product_dataset_name
  
  depends_on = [module.organize_data]

}


####################################################################################
# Reuseable Modules
####################################################################################

module "composer" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source                        = "./modules/composer"
  location                      = var.location
  network_id                    = google_compute_network.default_network.id
  project_id                    = var.project_id
  project_number                = local._project_number
  dataplex_process_bucket_name  = local._dataplex_process_bucket_name
  raw_dataset_name              = var.raw_dataset_name
  raw_table_name                = var.raw_table_name
  curated_dataset_name          = var.curated_dataset_name
  product_dataset_name          = var.product_dataset_name
  mdm_table_name                = var.mdm_table_name

  depends_on = [module.register_assets]
} 

/*
Data pipelines will be done in composer for initial enablement
####################################################################################
# Run the Data Pipelines
####################################################################################
module "process_data" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  source          = "./modules/process_data"
  project_id                            = var.project_id
  location                              = var.location
  dataplex_process_bucket_name          = local._dataplex_process_bucket_name
  dataplex_bqtemp_bucket_name           = local._dataplex_bqtemp_bucket_name

  depends_on = [module.register_assets]

}
*/

########################################################################################
#NULL RESOURCE FOR DELAY/TIMER/SLEEP                                                   #
#TO GIVE TIME TO RESOURCE TO COMPLETE ITS CREATION THEN DEPENDANT RESOURCE WILL CREATE #
########################################################################################
/*
resource "time_sleep" "wait_X_seconds" {
  depends_on = [google_resource.resource_name]

  create_duration = "Xs"
}
*/


