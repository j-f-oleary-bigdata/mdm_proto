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
variable "lake_name" {}
variable "raw_dataset_name" {}
variable "curated_dataset_name" {}
variable "product_dataset_name" {}


resource "google_dataplex_asset" "register_bq_assets1" {
 for_each = {
    "mdm-info-raw/MDM Raw Data/mdm-raw-zone/prod-mdm-domain" : var.raw_dataset_name,
    "mdm-info-curated/MDM Curated Data/mdm-curated-zone/prod-mdm-domain" : var.curated_dataset_name,
    "mdm-info-product/MDM Product Data/mdm-data-product-zone/prod-mdm-domain" : var.product_dataset_name,
  }
  name          = element(split("/", each.key), 0)
  display_name  = element(split("/", each.key), 1)
  location      = var.location

  lake = element(split("/", each.key), 3)
  dataplex_zone = element(split("/", each.key), 2)

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name = "projects/${var.project_id}/datasets/${each.value}"
    type = "BIGQUERY_DATASET"
  }

  project = var.project_id
}

