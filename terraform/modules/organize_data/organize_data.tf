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
variable "location" {}
variable "lake_name" {}
#variable "metastore_service_name" {}
variable "project_number" {}

resource "google_dataplex_lake" "create_lakes" {
 for_each = {
    "prod-mdm-domain/MDM Domain" : "domain_type=source",
  }
  location     = var.location
  name         = element(split("/", each.key), 0)
  description  = element(split("/", each.key), 1)
  display_name = element(split("/", each.key), 1)

  labels       = {
    element(split("=", each.value), 0) = element(split("=", each.value), 1)
  }
  
  project = var.project_id
}

resource "time_sleep" "sleep_after_dataplex_permissions" {
  create_duration = "120s"
  depends_on = [
                google_dataplex_lake.create_lakes
              ]
}

resource "google_dataplex_zone" "create_zones" {
 for_each = {
    "mdm-curated-zone/MDM Curated Zone/prod-mdm-domain/CURATED" : "",
    "mdm-raw-zone/MDM Raw Zone/prod-mdm-domain/RAW" : ""
  }

  discovery_spec {
    enabled = true
    schedule = "0 * * * *"
  }

  lake     =  element(split("/", each.key), 2)
  location = var.location
  name     = element(split("/", each.key), 0)

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = element(split("/", each.key), 3)
  description  = element(split("/", each.key), 1)
  display_name = element(split("/", each.key), 1)

  project      = var.project_id

  depends_on  = [time_sleep.sleep_after_dataplex_permissions]
}

#sometimes we get API rate limit errors for dataplex; add wait until this is resolved.
resource "time_sleep" "sleep_after_zones" {
  create_duration = "60s"

  depends_on = [google_dataplex_zone.create_zones]
}

resource "google_dataplex_zone" "create_zones_with_labels" {
 for_each = {
    "mdm-data-product-zone/MDM Data Product Zone/prod-mdm-domain/CURATED" : "data_product_category=master_data"
  }

    discovery_spec {
    enabled = true
    schedule = "0 * * * *"
  }

  lake     =  element(split("/", each.key), 2)
  location = var.location
  name     = element(split("/", each.key), 0)

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = element(split("/", each.key), 3)
  description  = element(split("/", each.key), 1)
  display_name = element(split("/", each.key), 1)
  labels       = {
    element(split("=", each.value), 0) = element(split("=", each.value), 1)
  }
  project      = var.project_id

  depends_on  = [time_sleep.sleep_after_zones]
}
