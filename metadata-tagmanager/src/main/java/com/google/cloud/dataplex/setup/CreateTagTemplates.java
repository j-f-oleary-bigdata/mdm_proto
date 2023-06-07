package com.google.cloud.dataplex.setup;


import com.google.api.gax.rpc.PermissionDeniedException;
import com.google.cloud.datacatalog.v1.CreateTagTemplateRequest;
import com.google.cloud.datacatalog.v1.DeleteTagTemplateRequest;
import com.google.cloud.datacatalog.v1.DataCatalogClient;
import com.google.cloud.datacatalog.v1.FieldType;
import com.google.cloud.datacatalog.v1.LocationName;
import com.google.cloud.datacatalog.v1.TagTemplate;
import com.google.cloud.datacatalog.v1.TagTemplateField;
import com.google.cloud.datacatalog.v1.FieldType.EnumType.EnumValue;
import com.google.cloud.datacatalog.v1.FieldType.EnumType.EnumValue.Builder;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.google.cloud.datacatalog.v1.GetTagTemplateRequest;

public class CreateTagTemplates {
        private static final Logger LOGGER = LoggerFactory.getLogger(CreateTagTemplates.class);

        public static void main(String[] args) throws IOException {
                String projectId = args[0];
                String location = args[1];
                String templateName = args[2];
                LocationName locationName = LocationName.of(projectId, location);

                if (templateName.equals(new String("mdm_information"))) {
                        createMDMInformationTagTemplate(locationName);
                } 
                else {
                        LOGGER.error("templateName '%s' not recognized.  Only the 'mdm_information' template name is recognized.");
                }

        }
        // Create Data Product Information Tag

        private static void createMDMInformationTagTemplate(LocationName locationName)
                        throws IOException {
                String tagTemplateId = "mdm_information";

                TagTemplateField mdm_project_name = TagTemplateField.newBuilder().setDisplayName("MDM Project Name")
                                .setIsRequired(true).setOrder(5)
                                .setDescription("Name of the MDM Project in the MDM Source System")
                                .setType(FieldType.newBuilder()
                                                .setPrimitiveType(FieldType.PrimitiveType.STRING)
                                                .build())
                                .build();

                TagTemplateField mdm_last_updated_date = TagTemplateField.newBuilder()
                                .setDisplayName("MDM Last Updated Date").setIsRequired(true).setOrder(4)
                                .setDescription("Date of Last Update")
                                .setType(FieldType.newBuilder()
                                                .setPrimitiveType(FieldType.PrimitiveType.STRING)
                                                .build())
                                .build();

                TagTemplateField mdm_fields= TagTemplateField.newBuilder()
                                .setDisplayName("MDM Fields").setIsRequired(true).setOrder(3)
                                .setDescription("Number of Fields in the MDM Golden Record")
                                .setType(FieldType.newBuilder()
                                                .setPrimitiveType(FieldType.PrimitiveType.STRING)
                                                .build())
                                .build();

                TagTemplateField mdm_rows = TagTemplateField.newBuilder()
                                .setDisplayName("MDM Rows").setIsRequired(true).setOrder(2)
                                .setDescription("Number of Rows in the MDM Golden Record")
                                .setType(FieldType.newBuilder()
                                                .setPrimitiveType(FieldType.PrimitiveType.STRING)
                                                .build())
                                .build();
                TagTemplateField mdm_id_field_name = TagTemplateField.newBuilder()
                                .setDisplayName("MDM ID Field Name").setIsRequired(true).setOrder(1)
                                .setDescription("Name of the ID Field in the Golden Record")
                                .setType(FieldType.newBuilder()
                                                .setPrimitiveType(FieldType.PrimitiveType.STRING)
                                                .build())
                                .build();
                TagTemplate tagTemplate = TagTemplate.newBuilder()
                                .setDisplayName("MDM Information")
                                .putFields("mdm_project_name", mdm_project_name)
                                .putFields("mdm_last_updated_date", mdm_last_updated_date)
                                .putFields("mdm_fields", mdm_fields)
                                .putFields("mdm_rows", mdm_rows)
                                .putFields("mdm_id_field_name", mdm_id_field_name).build();
                createTagTemplate(locationName, tagTemplateId, tagTemplate);

        }
       
        public static void createTagTemplate(LocationName name, String tagTemplateId,
                        TagTemplate template) throws IOException {
                // Initialize client that will be used to send requests. This client only needs to
                // be
                // created
                // once, and can be reused for multiple requests. After completing all of your
                // requests,
                // call
                // the "close" method on the client to safely clean up any remaining background
                // resources.
                try (DataCatalogClient client = DataCatalogClient.create()) {

                        try {
                                /*
                                 * GetTagTemplateRequest getRequest =
                                 * GetTagTemplateRequest.newBuilder().setName("projects/" +
                                 * name.getProject() + "/locations/" + name.getLocation() +
                                 * "/tagTemplates/" + tagTemplateId +"_testing").build();
                                 * 
                                 * TagTemplate tagTemplate = client.getTagTemplate(getRequest);
                                 * System.out.println(tagTemplate);
                                 */

                                DeleteTagTemplateRequest delRequest = DeleteTagTemplateRequest
                                                .newBuilder()
                                                .setName("projects/" + name.getProject()
                                                                + "/locations/" + name.getLocation()
                                                                + "/tagTemplates/" + tagTemplateId)
                                                .setForce(true).build();
                                client.deleteTagTemplate(delRequest);

                        } catch (Exception e) {
                                System.out.println("Tag was not found!");

                        }


                        CreateTagTemplateRequest request = CreateTagTemplateRequest.newBuilder()
                                        .setParent(name.toString()).setTagTemplateId(tagTemplateId)
                                        .setTagTemplate(template).build();
                        client.createTagTemplate(request);
                        System.out.println("Tag template " + template.getDisplayName()
                                        + " created successfully in location " + name);
                }
        }
}
