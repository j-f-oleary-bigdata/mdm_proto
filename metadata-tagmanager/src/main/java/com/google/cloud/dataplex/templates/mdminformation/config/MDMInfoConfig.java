/*
 * Copyright (C) 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

 package com.google.cloud.dataplex.templates.mdminformation.config;

 import com.fasterxml.jackson.annotation.JsonAutoDetect;
 
 @JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
 public class MDMInfoConfig {
 
     
     private String mdm_field_id_name;
     
     private String mdm_rows;
     
     private String mdm_fields;
     
     private String mdm_last_updated_date;
     
     private String mdm_project_name;
     
     public String getMDMFieldIdName() {
         return mdm_field_id_name;
     }
 
     public void setMDMFieldIdName(String mdm_field_id_name) {
         this.mdm_field_id_name = mdm_field_id_name;
     }
 
     public String getMDMRows() {
         return mdm_rows;
     }
 
     public void setMDMRows(String mdm_rows) {
         this.mdm_rows = mdm_rows;
     }
 
     public String getMDMFields() {
         return mdm_fields;
     }
 
     public void setMDMFields(String mdm_fields) {
         this.mdm_fields = mdm_fields;
     }
 
     public String getMDMLastUpdatedDate() {
         return mdm_last_updated_date;
     }
 
     public void setMDMLastUpdatedDate(String mdm_last_updated_date) {
         this.mdm_last_updated_date = mdm_last_updated_date;
     }
 
     public String getMDMProjectName() {
         return mdm_project_name;
     }
 
     public void setMDMProjectName(String mdm_project_name) {
         this.mdm_project_name = mdm_project_name;
     }
 
 
 }