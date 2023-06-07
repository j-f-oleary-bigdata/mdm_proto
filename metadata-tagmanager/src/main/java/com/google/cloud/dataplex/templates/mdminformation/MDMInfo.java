
/*
 * Copyright (C) 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */

 package com.google.cloud.dataplex.templates.mdminformation;

 import static com.google.cloud.dataplex.utils.Constants.API_URI_BQ;
 import static com.google.cloud.dataplex.utils.Constants.DOC_URL_PREFIX;
 import static com.google.cloud.dataplex.utils.Constants.DOMAIN_ORG;
 import static com.google.cloud.dataplex.utils.Constants.ENTITY_ID_OPT;
 import static com.google.cloud.dataplex.utils.Constants.ICON_URL_PREFIX;
 import static com.google.cloud.dataplex.utils.Constants.INPUT_FILE_OPT;
 import static com.google.cloud.dataplex.utils.Constants.LAKE_ID_OPT;
 import static com.google.cloud.dataplex.utils.Constants.LOCATION_OPT;
 import static com.google.cloud.dataplex.utils.Constants.PROJECT_NAME_OPT;
 import static com.google.cloud.dataplex.utils.Constants.TAG_TEMPLATE_ID_OPT;
 import static com.google.cloud.dataplex.utils.Constants.ZONE_ID_OPT;
 import static com.google.cloud.dataplex.utils.Constants.DERIVE_INDICATOR;
 
 import java.io.File;
 import java.io.IOException;
 import java.text.ParseException;
 import java.util.HashMap;
 import java.util.Map;
 import java.util.regex.Matcher;
 import java.util.regex.Pattern;
 
 import com.fasterxml.jackson.databind.ObjectMapper;
 import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
 import com.google.cloud.datacatalog.v1.DataCatalogClient;
 import com.google.cloud.datacatalog.v1.Entry;
 import com.google.cloud.datacatalog.v1.LookupEntryRequest;
 import com.google.cloud.datacatalog.v1.TagField;
 import com.google.cloud.dataplex.templates.mdminformation.config.MDMInfoConfig;
 import com.google.cloud.dataplex.utils.InputArgsParse;
 import com.google.cloud.dataplex.utils.TagOperations;
 import com.google.cloud.dataplex.v1.DataplexServiceClient;
 import com.google.cloud.dataplex.v1.Entity;
 import com.google.cloud.dataplex.v1.Lake;
 import com.google.cloud.dataplex.v1.MetadataServiceClient;
 import com.google.cloud.dataplex.v1.Zone;
 import com.google.protobuf.util.Timestamps;
 
 import org.apache.commons.cli.CommandLine;
 import org.slf4j.Logger;
 import org.slf4j.LoggerFactory;
 
 // Move versioning info to a new tag
 // copy restruction move it to data governance tag
 public class MDMInfo {
         private static final Logger LOGGER = LoggerFactory.getLogger(MDMInfo.class);
 
         public static void main(String[] args) throws IOException {
 
                 LOGGER.info("Started the Data Product information  metadata tagging process...");
                 Entry entry;
                 CommandLine cmd = InputArgsParse.parseArguments(args);
 
                 File file = new File(cmd.getOptionValue(INPUT_FILE_OPT));
                 ObjectMapper objectMapper = new ObjectMapper(new YAMLFactory());
                 MDMInfoConfig config =
                                 objectMapper.readValue(file, MDMInfoConfig.class);
 
                 try (MetadataServiceClient mdplx = MetadataServiceClient.create()) {
 
                         try (DataplexServiceClient sdplx = DataplexServiceClient.create()) {
 
                                 Entity entity = mdplx.getEntity(String.format(
                                                 "projects/%s/locations/%s/lakes/%s/zones/%s/entities/%s",
                                                 cmd.getOptionValue(PROJECT_NAME_OPT),
                                                 cmd.getOptionValue(LOCATION_OPT),
                                                 cmd.getOptionValue(LAKE_ID_OPT),
                                                 cmd.getOptionValue(ZONE_ID_OPT),
                                                 cmd.getOptionValue(ENTITY_ID_OPT)));
                                 Lake lake = sdplx.getLake(
                                                 String.format("projects/%s/locations/%s/lakes/%s",
                                                                 cmd.getOptionValue(
                                                                                 PROJECT_NAME_OPT),
                                                                 cmd.getOptionValue(LOCATION_OPT),
                                                                 cmd.getOptionValue(LAKE_ID_OPT)));
                                 Zone zone = sdplx.getZone(String.format(
                                                 "projects/%s/locations/%s/lakes/%s/zones/%s",
                                                 cmd.getOptionValue(PROJECT_NAME_OPT),
                                                 cmd.getOptionValue(LOCATION_OPT),
                                                 cmd.getOptionValue(LAKE_ID_OPT),
                                                 cmd.getOptionValue(ZONE_ID_OPT)));
 
                                 String dataplex_entity_name_fqdn = String.format("%s.%s.%s.%s.%s",
                                                 cmd.getOptionValue(PROJECT_NAME_OPT),
                                                 cmd.getOptionValue(LOCATION_OPT),
                                                 cmd.getOptionValue(LAKE_ID_OPT),
                                                 cmd.getOptionValue(ZONE_ID_OPT),
                                                 cmd.getOptionValue(ENTITY_ID_OPT));
 
                                 try (DataCatalogClient dataCatalogClient =
                                                 DataCatalogClient.create()) {
                                         // extending support to GCS Storage
                                         // if ("BIGQUERY".equals(entity.getSystem().name())) {
                                         if (1 == 1) {
 
                                                 /* 
                                                  * Use this if tagging needs to be created at the
                                                  * actualy data object level */
 
                                                   entry =
                                                   dataCatalogClient.lookupEntry(
                                                   LookupEntryRequest.newBuilder()
                                                   .setLinkedResource( String.format("%s/%s",
                                                   API_URI_BQ, entity.getDataPath())) .build()); 
                                                  /* 
 
                                                  entry = dataCatalogClient.lookupEntry(
                                                                 LookupEntryRequest.newBuilder()
                                                                                 .setFullyQualifiedName(
                                                                                                 "dataplex:" + dataplex_entity_name_fqdn)
                                                                                 .build()); */
 
 
 
                                                 if (config.getMDMLastUpdatedDate()
                                                                 .equalsIgnoreCase(DERIVE_INDICATOR)
                                                                 || config.getMDMLastUpdatedDate()
                                                                         .isEmpty()) {
                                                         config.setMDMLastUpdatedDate(Timestamps
                                                                 .toString(Timestamps
                                                                         .fromMillis(System
                                                                                 .currentTimeMillis())));
 
                                                 }
                 
 
                                                 Map<String, TagField> values = new HashMap<>();
                                                 values.put("mdm_id_field_name", TagField.newBuilder()
                                                                 .setStringValue(config
                                                                                 .getMDMFieldIdName())
                                                                 .build());
                                                 
                                                 values.put("mdm_rows", TagField.newBuilder()
                                                                 .setStringValue(config
                                                                                 .getMDMRows())
                                                                 .build());
 
                                                 values.put("mdm_fields", TagField.newBuilder()
                                                                 .setStringValue(config
                                                                                 .getMDMFields())
                                                                 .build());
 
 
                                                 values.put("mdm_last_updated_date", TagField.newBuilder()
                                                                 .setStringValue(config
                                                                                 .getMDMLastUpdatedDate())
                                                                 .build());
 
                                                 values.put("mdm_project_name", TagField.newBuilder()
                                                                 .setStringValue(config
                                                                                 .getMDMProjectName())
                                                                 .build());
 
 
                                                 TagOperations.publishTag(entry, dataCatalogClient,
                                                                 cmd.getOptionValue(
                                                                                 TAG_TEMPLATE_ID_OPT),
                                                                 values, "MDM Information");
 
                                                 LOGGER.info("Tag was successfully created for entry {} using tag template {}",
                                                                 entry.getFullyQualifiedName(),
                                                                 cmd.getOptionValue(
                                                                                 TAG_TEMPLATE_ID_OPT));
 
                                         }
 
                                 } catch (Exception e) {
                                         e.printStackTrace();
                                 }
                         }
                 }
 
                 // spark.stop();
 
         }
 
 }
 