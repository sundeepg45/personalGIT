/**
 * This is the controller for SyncPicklistValues.page. It provides actions that
 * pull data from sObjects and use it to populate picklist values using the
 * metadata API. The first use of this page/controller is to populate region
 * and subregion picklist values on the User object based on records in Region__c.
 * This is a tool that should only be used by IT.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2014-03-05
 * 2014-03-05 - Created
 */
public class SyncPicklistValuesController {

    public final String LOG_PREFIX_REGION_PICKLIST_VALUE = 'Creating Region picklist value: ';
    public final String LOG_PREFIX_SUBREGION_PICKLIST_VALUE = 'Creating Subregion picklist value: ';
    public String log {get; set;}

    public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

    public SyncPicklistValuesController() {}

    public PageReference clearUserRegionPicklistValues() {
        log = '';
        try {
            MetadataService.MetadataPort service = createService();

            // set up metadata for region field
            MetadataService.CustomField regionField = new MetadataService.CustomField();
            regionField.fullName = 'User.UserRegion__c';
            regionField.label = 'Region';
            regionField.type_x = 'Picklist';
            regionField.inlineHelpText = User.UserRegion__c.getDescribe().getInlineHelpText();
            regionField.description = 'The picklist values for this field are maintained by the visualforce page located at https://[salesforce_instance_url]/apex/SyncPicklistValues. Do not update these picklist values directly.';
            MetadataService.Picklist regionPicklist = new MetadataService.Picklist();
            regionPicklist.controllingField = 'Region__c';
            regionPicklist.sorted = false;
            regionField.picklist = regionPicklist;
            regionField.picklist.picklistValues = new List<MetadataService.PicklistValue>();
            MetadataService.PicklistValue regionValue = new MetadataService.PicklistValue();
            regionValue.fullName = 'none';
            regionValue.default_x = false;
            regionField.picklist.picklistValues.add(regionValue);            

            // set up metadata for subregion field
            MetadataService.CustomField subregionField = new MetadataService.CustomField();
            subregionField.fullName = 'User.NA_Subregion__c';
            subregionField.label = 'Subregion';
            subregionField.type_x = 'Picklist';
            subregionField.inlineHelpText = User.NA_Subregion__c.getDescribe().getInlineHelpText();
            subregionField.description = 'The picklist values for this field are maintained by the visualforce page located at https://[salesforce_instance_url]/apex/SyncPicklistValues. Do not update these picklist values directly.';
            MetadataService.Picklist subregionPicklist = new MetadataService.Picklist();
            subregionPicklist.controllingField = 'UserRegion__c';
            subregionPicklist.sorted = false;
            subregionField.picklist = subregionPicklist;
            subregionField.picklist.picklistValues = new List<MetadataService.PicklistValue>();
            MetadataService.PicklistValue subregionValue = new MetadataService.PicklistValue();
            subregionValue.fullName = 'none';
            subregionValue.default_x = false;
            subregionField.picklist.picklistValues.add(subregionValue);            

            // clear picklist values
            log = log + 'Clearing picklist values (asynchronous)\n';
            MetadataService.UpdateMetadata regionUpdate = new MetadataService.UpdateMetadata();
            regionUpdate.currentName='User.UserRegion__c';
            regionUpdate.metadata= regionField;
            MetadataService.UpdateMetadata subregionUpdate = new MetadataService.UpdateMetadata();
            subregionUpdate.currentName='User.NA_Subregion__c';
            subregionUpdate.metadata= subregionField;
            if(!Test.isRunningTest()) {
                MetadataService.AsyncResult[] results = service.updateMetadata(new List<MetadataService.UpdateMetadata> {regionUpdate});
                MetadataService.AsyncResult[] results2 = service.updateMetadata(new List<MetadataService.UpdateMetadata> {subregionUpdate});
                log = log + 'Complete! It may take some time for the new Region and Subregion picklist values to appear on the User page.\n';
            }
            else {
                log = log + 'Test Complete! Callout to metadata API skipped.\n';
            }
            
        }
        catch(Exception ex) {
            log = log + ex.getMessage();
        }

        return null;              
    }

    public PageReference syncUserRegionPicklistValues() {
        log = '';
        try {
            MetadataService.MetadataPort service = createService();

            // set up metadata for region field
            MetadataService.CustomField regionField = new MetadataService.CustomField();
            regionField.fullName = 'User.UserRegion__c';
            regionField.label = 'Region';
            regionField.type_x = 'Picklist';
            regionField.inlineHelpText = User.UserRegion__c.getDescribe().getInlineHelpText();
            regionField.description = 'The picklist values for this field are maintained by the visualforce page located at https://[salesforce_instance_url]/apex/SyncPicklistValues. Do not update these picklist values directly.';
            MetadataService.Picklist regionPicklist = new MetadataService.Picklist();
            regionPicklist.controllingField = 'Region__c';
            regionPicklist.sorted = false;
            regionField.picklist = regionPicklist;
            regionField.picklist.picklistValues = new List<MetadataService.PicklistValue>();

            // set up metadata for subregion field
            MetadataService.CustomField subregionField = new MetadataService.CustomField();
            subregionField.fullName = 'User.NA_Subregion__c';
            subregionField.label = 'Subregion';
            subregionField.type_x = 'Picklist';
            subregionField.inlineHelpText = User.NA_Subregion__c.getDescribe().getInlineHelpText();
            subregionField.description = 'The picklist values for this field are maintained by the visualforce page located at https://[salesforce_instance_url]/apex/SyncPicklistValues. Do not update these picklist values directly.';
            MetadataService.Picklist subregionPicklist = new MetadataService.Picklist();
            subregionPicklist.controllingField = 'UserRegion__c';
            subregionPicklist.sorted = false;
            subregionField.picklist = subregionPicklist;
            subregionField.picklist.picklistValues = new List<MetadataService.PicklistValue>();

            // get region data for APAC, EMEA, LATAM
            List<Region__c> regionList = [
                SELECT 
                    Super_Region__c,
                    Region__c,
                    Sub_Region__c
                FROM 
                    Region__c
                WHERE 
                    Super_Region__c IN ('APAC','EMEA','LATAM')
                ORDER BY 
                    Super_Region__c,
                    Region__c,
                    Sub_Region__c];

            // create map that holds all region data across super regions
            Map<String,Map<String,Set<String>>> superregionMap = new Map<String,Map<String,Set<String>>>();                    

            // create picklist values using APAC, EMEA, LATAM region data
            for(Region__c region : regionList) {
                if(!superregionMap.containsKey(region.Super_Region__c)) {
                    superregionMap.put(region.Super_Region__c, new Map<String,Set<String>>());
                }

                if(region.Region__c != null) {
                    Map<String,Set<String>> regionMap = superRegionMap.get(region.Super_Region__c);

                    if(!regionMap.containsKey(region.Region__c)) {
                        regionMap.put(region.Region__c,new Set<String>());

                        MetadataService.PicklistValue regionValue = new MetadataService.PicklistValue();
                        regionValue.fullName = region.Region__c;
                        regionValue.controllingFieldValues = new List<String>{region.Super_Region__c};
                        regionValue.default_x = false;
                        regionField.picklist.picklistValues.add(regionValue);
                        log = log + LOG_PREFIX_REGION_PICKLIST_VALUE + region.Super_Region__c + ' -> ' + region.Region__c + '\n';                        
                    }

                    if(region.Sub_Region__c != null) {
                        Set<String> subregionSet = regionMap.get(region.Region__c);
                        if(!subregionSet.contains(region.Sub_Region__c)) {   
                            subregionSet.add(region.Sub_Region__c);

                            MetadataService.PicklistValue subregionValue = new MetadataService.PicklistValue();
                            subregionValue.fullName = region.Sub_Region__c;
                            subregionValue.controllingFieldValues = new List<String>{region.Region__c};
                            subregionValue.default_x = false;
                            subregionField.picklist.picklistValues.add(subregionValue);
                            log = log + LOG_PREFIX_SUBREGION_PICKLIST_VALUE + region.Super_Region__c + ' -> ' + region.Region__c + ' -> ' + region.Sub_Region__c + '\n';                            
                        }
                    }
                }
            }

            // get region data for NA
            List<Region_NA__c> regionNaList = [
                SELECT 
                    Super_Region__c,
                    Region__c,
                    Sub_Region__c
                FROM 
                    Region_NA__c
                WHERE 
                    Super_Region__c = 'NA'
                ORDER BY 
                    Super_Region__c,
                    Region__c,
                    Sub_Region__c];

            // create picklist values using NA region data
            for(Region_NA__c region : regionNaList) {
                if(!superregionMap.containsKey(region.Super_Region__c)) {
                    superregionMap.put(region.Super_Region__c, new Map<String,Set<String>>());
                }

                if(region.Region__c != null) {
                    Map<String,Set<String>> regionMap = superRegionMap.get(region.Super_Region__c);

                    if(!regionMap.containsKey(region.Region__c)) {
                        regionMap.put(region.Region__c,new Set<String>());

                        MetadataService.PicklistValue regionValue = new MetadataService.PicklistValue();
                        regionValue.fullName = region.Region__c;
                        regionValue.controllingFieldValues = new List<String>{region.Super_Region__c};
                        regionValue.default_x = false;
                        regionField.picklist.picklistValues.add(regionValue);
                        log = log + LOG_PREFIX_REGION_PICKLIST_VALUE + region.Super_Region__c + ' -> ' + region.Region__c + '\n';                        
                    }

                    if(region.Sub_Region__c != null) {
                        Set<String> subregionSet = regionMap.get(region.Region__c);
                        if(!subregionSet.contains(region.Sub_Region__c)) {   
                            subregionSet.add(region.Sub_Region__c);

                            MetadataService.PicklistValue subregionValue = new MetadataService.PicklistValue();
                            subregionValue.fullName = region.Sub_Region__c;
                            subregionValue.controllingFieldValues = new List<String>{region.Region__c};
                            subregionValue.default_x = false;
                            subregionField.picklist.picklistValues.add(subregionValue);
                            log = log + LOG_PREFIX_SUBREGION_PICKLIST_VALUE + region.Super_Region__c + ' -> ' + region.Region__c + ' -> ' + region.Sub_Region__c + '\n';
                        }
                    }
                }
            }

            log = log + 'Saving updated picklists (asynchronous)\n';
            MetadataService.UpdateMetadata regionUpdate = new MetadataService.UpdateMetadata();
            regionUpdate.currentName='User.UserRegion__c';
            regionUpdate.metadata= regionField;
            MetadataService.UpdateMetadata subregionUpdate = new MetadataService.UpdateMetadata();
            subregionUpdate.currentName='User.NA_Subregion__c';
            subregionUpdate.metadata= subregionField;
            if(!Test.isRunningTest()) {
                MetadataService.AsyncResult[] results = service.updateMetadata(new List<MetadataService.UpdateMetadata> {regionUpdate});
                MetadataService.AsyncResult[] results2 = service.updateMetadata(new List<MetadataService.UpdateMetadata> {subregionUpdate});
                log = log + 'Complete! It may take some time for the new Region and Subregion picklist values to appear on the User page.\n';
            }
            else {
                log = log + 'Test Complete! Callout to metadata API skipped.\n';
            }
            
        }
        catch(Exception ex) {
            log = log + ex.getMessage();
        }

        return null;
    }
}