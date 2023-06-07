variable "project_id" {
  type        = string
  description = "project id required"
}

variable "ldap" {
  type        = string
  description = "users ldap"
}

variable "location" {
 description = "Location/region to be used"
 default = "us-central1"
}

variable "api_location" {
 description = "Location/region to be used"
 default = "us"
}


variable "raw_dataset_name" {
 description = "Name of the MDM raw bq dataset"
 default = "mdm_raw_dataset"
}

variable "raw_table_name" {
 description = "Name of the MDM raw bq table"
 default = "raw_customer_data"
}

variable "curated_dataset_name" {
 description = "Name of the MDM raw bq dataset"
 default = "mdm_curated_dataset"
}

variable "product_dataset_name" {
 description = "Name of the MDM raw bq dataset"
 default = "mdm_product_dataset"
}

variable "mdm_table_name" {
 description = "Name of the MDM customer bq table"
 default = "mdm_customer_data"
}


variable "ip_range" {
 description = "IP Range used for the network for this demo"
 default = "10.6.0.0/24"
}

variable "user_ip_range" {
 description = "IP range for the user running the demo"
 default = "10.6.0.0/24"
}


variable "lake_name" {
  description = "Default name of the Dataplex Lake"
  default = "dataplex_enablement_lake"
}

variable "date_partition" {
  description = "Date Partition to use for Data Generator Tool"
  default = "2022-05-01"
}

variable "tmpdir" {
  description = "Temporary folder to use for Data Generator Tool"
  default = "/tmp/data"
}

