public with sharing class AudienceInput {

    public Audience__c audience { get; set; }
    public Map<String,String> profileIdToName { get; set; }
    public Map<String,String> permissionSetIdToName { get; set; }

    public List<String> selectedRegions { get; set; }
    public List<String> selectedCountries {get; set; }
    public List<String> selectedsubRegions { get; set; }
    public List<String> selectedRoles { get; set; }
    public List<String> selectedProfiles { get; set ;}
    public List<String> selectedPermissionSets { get; set; }
    public List<String> selectedSpecs { get; set; }
    public List<String> selectedTiers { get; set; }
    public List<String> selectedTypes { get; set; }
    public List<String> selectedPrograms { get; set; }

    public List<Classification__c> partnerTiers { get; set; }
    public List<Classification__c> partnerTypes { get; set; }
    
    public List<SelectOption> tierSelectOptions { get; set; }
    public List<SelectOption> typeSelectOptions { get; set; }
    public List<SelectOption> programSelectOptions { get; set; }
    public List<SelectOption> profileSelectOptions { get; set; }
    public List<SelectOption> permissionSetSelectOptions { get; set; }
    public List<SelectOption> regionSelectOptions { get; set; }
    public List<SelectOption> countrySelectOptions { get; set; }
    public List<SelectOption> subregionSelectOptions { get; set; }
    public List<SelectOption> specSelectOptions { get; set; }
    public List<SelectOption> roleSelectOptions { get; set; }

    public Boolean hasErrors { get; set; }
    
    private Set<Id> targetAccountIdSet = new Set<Id>();
    
    // Target account search
    public List<Account> searchResults {get;set;}
    public List<Account> targetAccounts {get;set ; }
    public String acctSearch {get;set;}
    public String selectedAccountId {get;set;}
    public Account selectedAccount {get;set;}
    public String searchSoql {get; set;}
    
    private Map<Id,Account> acctMap = new Map<Id,Account>();     
   
    
	public Boolean IsRegionNA{
		get{
			return selectedRegions.size() == 1 && selectedRegions[0] == 'NA';
		}
	}

    
    private map<Id, Account> savedAccountmap;// = new map<id,Account>();
    
    public AudienceInput(ApexPages.StandardController sc) {
        
        hasErrors = false;
        
        string audienceId = ((Audience__c)sc.getRecord()).Id;
        savedAccountmap = new map<id,Account>();
        
        // Keep track of any targeted accounts for this audience
        targetAccounts = new List<Account>();
        // See if any accounts have been added as a target acccount already
        for(Audience_Account__c targeted : [select Id, Audience__c, Account__c from Audience_Account__c where Audience__c = :audienceId]) 
            targetAccountIdSet.add(targeted.Account__c);        
        // Add targeted accounts to the list so we can display them in the edit page.
        for(Account a:[select Id, Name, BillingCity, BillingCountry, PartnerStatuses__c, Global_Region__c from Account where Id in :targetAccountIdSet]){
        	targetAccounts.add(a);
        	savedAccountMap.put(a.Id, a);
        } 
            
        
        String audienceQuery = 'SELECT ';
        For(String s : audienceFieldList()){
            audienceQuery += s+', ';
        }
        audienceQuery = audienceQuery.removeEnd(', ');
        audienceQuery += ' FROM Audience__c WHERE Id = :audienceId';

        if(audienceId != null && audienceId != ''){
            audience = database.query(audienceQuery);
        }else{
            audience = new Audience__c();
        }

        prepareSelectLists();

        populateProfileAndPermissionSetMaps();
        profileSelectOptions = getOptions(profileIdToName);
        permissionSetSelectOptions = getOptions(permissionSetIdToName);

        partnerTiers = getClassifications('Partner Tier');
        partnerTypes = getClassifications('Partner Type');
        specSelectOptions = getSpecializations();
        programSelectOptions = getPrograms();
        tierSelectOptions = getOptions(partnerTiers);
        typeSelectOptions = getOptions(partnerTypes);

        regionSelectOptions = createStaticSelectOptions(New List<String>{'NA','EMEA','APAC','LATAM'});
        subregionSelectOptions = createStaticSelectOptions(existingSubRegions(), true);
        //countrySelectOptions = createStaticSelectOptions(existingCountries(), true);
        countrySelectOptions = createStaticSelectOptions(selectedCountries, false); 
        roleSelectOptions = createStaticSelectOptions(existingRoles());
        specSelectOptions = createStaticSelectOptions(existingSpecs());
    }




    public PageReference save(){
        hasErrors = false;
        
        if(IsRegionNA){
        	selectedCountries.clear();
        	selectedCountries.add('All');
        }
        
        audience.Profile_Id__c = processSelectedOptions(selectedProfiles);
        audience.Profile__c = processSelectedOptions(selectedProfiles,true,profileIdToName);
        audience.Permission_Set_Id__c = processSelectedOptions(selectedPermissionSets);
        audience.Permission_Set__c = processSelectedOptions(selectedPermissionSets,true,permissionSetIdToName);
        audience.Partner_Program__c = processSelectedOptions(selectedPrograms);
        audience.Partner_Region__c = processSelectedOptions(selectedRegions);
        audience.Partner_Country__c = processSelectedOptions(selectedCountries);
        audience.Partner_SubRegion__c = processSelectedOptions(selectedSubRegions);
        audience.Partner_Tier__c = processSelectedOptions(selectedTiers);
        audience.Partner_Type__c = processSelectedOptions(selectedTypes);
        audience.Role__c = processSelectedOptions(selectedRoles);
        audience.Specialization__c = processSelectedOptions(selectedSpecs);

        Integer categoryCount = 0;

        // Targeted by Account
        Boolean isAccountTargeted = targetAccounts.size() > 0;
        /*if(audience.Total_Targeted_Accounts__c != null && audience.Total_Targeted_Accounts__c > 0){ // use the Total_Targeted_Accounts__c roll-up summary to check if there are any related Targeted Accounts.
            isAccountTargeted=true; 
            categoryCount++;
        }*/

        // Partner Status Targeted (Tier, Type, Region, Subregion, Role)
        Boolean isPartnerStatusTargeted = false;
        Boolean incompleteStatusOptions = false;
        if((audience.Partner_Tier__c != null && audience.Partner_Tier__c != '') || (audience.Partner_Type__c != null && audience.Partner_Type__c != '')
            || (audience.Partner_Region__c != null && audience.Partner_Region__c != '') || (audience.Partner_Subregion__c != null && audience.Partner_Subregion__c != '')
            || (audience.Role__c != null && audience.Role__c != '')
            || (!String.isEmpty(audience.Partner_Country__c))
            || (!String.isEmpty(audience.Specialization__c))
            ){
            isPartnerStatusTargeted=true;
            if(
                audience.Partner_Tier__c == null || audience.Partner_Tier__c == '' 
                || audience.Partner_Type__c == null || audience.Partner_Type__c == ''
                || audience.Partner_Region__c == null || audience.Partner_Region__c == '' 
                || audience.Partner_Subregion__c == null || audience.Partner_Subregion__c == ''
                || audience.Role__c == null|| audience.Role__c == ''
                || (audience.Partner_Region__c != 'NA' && String.isEmpty(audience.Partner_Country__c)) // Country can be empty if the Region is NA
                || String.isEmpty(audience.Specialization__c)
                ){
                incompleteStatusOptions=true;
            }
            categoryCount++;
        }

        // Partner Program Targeted
        Boolean isProgramTargeted = false;
        if(audience.Partner_Program__c != null && audience.Partner_Program__c != ''){
            isProgramTargeted=true;
            categoryCount++;
        }

        // Profile/Permission Set Targeted
        Boolean isProfilePermissionSetTargeted = false;
        if((audience.Profile__c != null && audience.Profile__c != '') || (audience.Permission_Set__c != null && audience.Permission_Set__c != '')){
            isProfilePermissionSetTargeted = true;
            categoryCount++;
        }

        List<String> errorMessages = new List<String>();
        if(audience.Name==null || audience.Name==''){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a name for the Audience.'));
            hasErrors = true;
            return null;
        }
        if(audience.Available_To_Unauthenticated_Users__c){
            if(categoryCount==0){
                if(audience.id==null){
                    insert audience;
                }else{
                    update audience;
                }
	            PageReference audiencePage = new ApexPages.StandardController(audience).view();
	            audiencePage.setRedirect(true);
	            return audiencePage;
            }else{
                String error = 'An Audience set to be publicly available can have no other criteria because it will be available to anyone.';
                errorMessages.add(error);
            }

        }
        if(categoryCount==0 && targetAccounts.isEmpty()){
            String error = 'You must select some Audience criteria OR select 1 or more target accounts in order to save the record.';
            errorMessages.add(error);
        }
        
        
        if( isAccountTargeted == true && categoryCount > 0){
        	system.debug('Audience has both a targeted account AND filter criteria. This is not allowed.');
            String error = 'There are targeted accounts for this audience. If you select a Target Account for the Audience, you can not select any other Audience options.';
            errorMessages.add(error);
        } else  {
            System.debug('PASSED TARGETED ACCOUNT VALIDATION - isAccountTargeted: [' + isAccountTargeted+ '], categoryCount: [' + categoryCount + ']');        	
        }
        
        if(isPartnerStatusTargeted && categoryCount>1){
            String error = 'If you select any Partner Status criteria (Tier, Type, Region, Country, Subregion, Role, Specialization) for the Audience, you can not select any other Audience options.';
            errorMessages.add(error);
        }
        if(incompleteStatusOptions && isPartnerStatusTargeted){
            String partnerStatusError = 'If you select any Partner Status criteria (Tier, Type, Region, Country, Subregion, Role, Specialization), you must select a value for all seven fields.';
            errorMessages.add(partnerStatusError);
        }
        if(isProgramTargeted && categoryCount>1){
            String error = 'If you select Partner Programs for the Audience, you can not select any other Audience options.';
            errorMessages.add(error);
        }
        if(isProfilePermissionSetTargeted && categoryCount>1){
            String error = 'If you select Profiles or Permission Sets for the Audience, you can not select any other Audience options.';
            errorMessages.add(error);
        }
        For(String s : errorMessages){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,s));
        }
        if(errorMessages.size()>0){ 
            hasErrors = true;
            system.debug('Save errors exist, audience will NOT be saved. Errors: [' + errorMessages + ']'); 
            return null;
        }

        if(audience.id==null){
            insert audience;
        }else{
            update audience;
        }
        
        
        
        // INSERT TARGET ACCOUNTS
        List<Audience_Account__c> newAudienceAccounts = new List<Audience_Account__c>();
        for(Account acct:targetAccounts){
        	
        	// todo: CHECK IF THE ACCOUNT HAS ALREADY BEEN SAVED
        	if(!savedAccountMap.containsKey(acct.Id)){
        	   newAudienceAccounts.add( new Audience_Account__c(Account__c = acct.Id, Audience__c = audience.Id) );
        	}
        	
        	
        }
        system.debug('Inserting [' + newAudienceAccounts.size() + '] new audience (target) accounts.');
        if(!newAudienceAccounts.isEmpty()) insert(newAudienceAccounts);
        
        
        
        PageReference audiencePage = new ApexPages.StandardController(audience).view();
        audiencePage.setRedirect(true);
        return audiencePage;
    }

    public List<SelectOption> getPrograms(){
        List<SelectOption> options = new List<SelectOption>();
            SelectOption soAll = new SelectOption('All','All');
            options.add(soAll);
        for(Partner_Program_Definition__c ppd : [SELECT Program_Category__c FROM Partner_Program_Definition__c WHERE Program_Status__c = 'Active']){
            SelectOption so = new SelectOption(ppd.Program_Category__c,ppd.Program_Category__c);
            options.add(so);
        }
        return options;
    }
    
    public List<SelectOption> getSpecializations(){
        List<SelectOption> results = new List<SelectOption>();
        for(String val : getPicklistValues('Account', 'Select_Specialization_s__c')){
           results.add( new SelectOption(val,val) );    
        }
        return results;
    }

    public void prepareSelectLists(){
        selectedProfiles = preparedSelectList(audience.Profile_Id__c);
        selectedPermissionSets = preparedSelectList(audience.Permission_Set_Id__c);
        selectedTiers = preparedSelectList(audience.Partner_Tier__c);
        selectedTypes = preparedSelectList(audience.Partner_Type__c);
        selectedRegions = preparedSelectList(audience.Partner_Region__c);
        selectedCountries = preparedSelectList(audience.Partner_Country__c);
        selectedsubRegions = preparedSelectList(audience.Partner_Subregion__c);
        selectedRoles = preparedSelectList(audience.Role__c);
        selectedPrograms = preparedSelectList(audience.Partner_Program__c);
        selectedSpecs = preparedSelectList(audience.Specialization__c);
        //system.debug('***selectedPrograms: ' + selectedPrograms);
    }

    public List<String> existingRoles(){
        List<String> roleNames = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('PartnerTrack__c');
        Sobject roleNameField = targetType.newSObject();
        Schema.sObjectType sobject_type = roleNameField.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get('Partner_Function__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            roleNames.add(a.getValue());
        }
        return roleNames;
    }

    public List<String> existingCountries(){
        return getPicklistValues('Country__c','Country_Name__c');
    }
    
    public List<String> existingSpecs(){
        return getPicklistValues('Account','Select_Specialization_s__c');
    }
    
    private List<String> getPicklistValues(String sObjectName, String fieldName){
        List<String> results = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName);
        Sobject obj = targetType.newSObject();
        Schema.sObjectType sobject_type = obj.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            results.add(a.getValue());
        }
        return results;
    }

    public List<String> existingSubRegions(){
        /*
        List<String> subRegions = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Account');
        Sobject subRegionField = targetType.newSObject();
        Schema.sObjectType sobject_type = subRegionField.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get('SubRegion__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            subRegions.add(a.getValue());
        }
        return subRegions;
        */
        return getPicklistValues('Account','SubRegion__c');
    }

   
    
    
    public void resetRegions(){
    	system.debug('RESET REGIONS..');
    	selectedRegions = new List<String>{'All'};
    	regionSelectOptions = createStaticSelectOptions(selectedRegions, false);
    	selectedsubRegions = new List<String>{'All'};
    	subregionSelectOptions = createStaticSelectOptions(selectedSubRegions, false);
    }
    
    
     public void resetSubregions(){
        
        system.debug('RESET SUBREGIONS...');
        
        //subregionSelectOptions = createStaticSelectOptions(existingSubRegions(), true);
       
       
       // Clear out selectedSubRegions
       selectedSubRegions.clear();
       
        Set<String> subRegionSet = new Set<String>();
        AggregateResult[] results;
            
       
       // 2. Query for subregions in the selected regions
        if(selectedRegions.size() == 1 && selectedRegions[0] == 'All'){
            // Show all subregions
            results = [SELECT Subregion__c FROM Country__c WHERE IsDeleted = false AND Subregion__c != '' GROUP BY Subregion__c ORDER BY Subregion__c]; // Using GROUP BY to filter out duplicates    
        } else if (selectedRegions.size() == 1 && selectedRegions[0] == 'NA'){ 
            // NA is treated special
            //addNAregions(subRegionSet);
            //return;
        } else {            
            // Filter the countries by the regions selected
            results = [SELECT Subregion__c FROM Country__c WHERE IsDeleted = false AND Subregion__c != '' AND Global_Region__c IN :selectedRegions GROUP BY Subregion__c ORDER BY Subregion__c]; // Using GROUP BY to filter out duplicates
            for(AggregateResult ar:results){
                //string subregion = (string)ar.get('Subregion__c');
                //subregionSelectOptions.add(new SelectOption(subregion, subregion));
                subRegionSet.add( (string)ar.get('Subregion__c') );
            }
        }
            
            
            // 3. Update the subregionSelectOptions list..
           
            
            
            // 4. Add NA's special sub-regions if more than one global region was specified and NA was one of them...
            Boolean hasNA = false;
            for(String region:selectedRegions){
                if(region == 'NA') {
                    hasNA = true;
                    continue;
                }
            }
            
            if(hasNA) addNAregions(subRegionSet);
            
            // 5. Add subregions to select list
            subregionSelectOptions.clear(); // flush the country list so it can be repopulated with a new region-specific list of countries..
            subregionSelectOptions.add(new SelectOption('All','All')); // always provide an "All" option
            for(String subreg:subRegionSet){
                subregionSelectOptions.add(new SelectOption(subreg, subreg));
            }
            
            resetCountries();
            
    }
    
    
    
    public void resetCountries(){
        
        system.debug('RESET COUNTRIES...');
        
        List<Country__c> countryResults;
        Boolean hideCountryOptions = false;
        
        // ALL Subregions
        if(selectedSubRegions.size() == 1 && selectedSubRegions[0] == 'All'){
        	System.debug('Resetting countries for subregion ALL');
        	if(selectedRegions.isEmpty()){
        		system.debug('Showing all countries.');
                countryResults = [SELECT c.Global_Region__c, c.Iso3166Alpha2__c, c.Abbreviation__c, c.Subregion__c, c.Name FROM Country__c c WHERE c.IsDeleted = false ORDER BY c.Name];
        	} else {
        		System.debug('Showing all countries for these regions: [' + selectedRegions + ']');
        		countryResults = [SELECT c.Global_Region__c, c.Iso3166Alpha2__c, c.Abbreviation__c, c.Subregion__c, c.Name FROM Country__c c WHERE c.IsDeleted = false AND c.Global_Region__c IN :selectedRegions ORDER BY c.Name];
        	}
            								
        // NA Subregion ONLY    								
        } else if (selectedSubRegions.size() == 1 && selectedSubRegions[0] == 'NA'){
        	hideCountryOptions = true; // Don't show anything (not even the "All" option) when Subregion is NA	
        } else {        	
        	// Filter the countries by the sub-regions selected
        	if(!selectedSubRegions.isEmpty()){
        		System.debug('Resetting countries for these SUB-regions: [' + selectedSubRegions + ']');
                countryResults = [SELECT c.Global_Region__c, c.Iso3166Alpha2__c, c.Abbreviation__c, c.Subregion__c, c.Name FROM Country__c c WHERE c.IsDeleted = false AND  c.Subregion__c IN :selectedSubRegions ORDER BY c.Name];
        	} else {
        		// Use only global region to filter the country list
        		system.debug('Resetting countries for these Regions: [' + selectedRegions + ']');
        		countryResults = [SELECT c.Global_Region__c, c.Iso3166Alpha2__c, c.Abbreviation__c, c.Subregion__c, c.Name FROM Country__c c WHERE c.IsDeleted = false AND  c.Global_Region__c IN :selectedRegions ORDER BY c.Name];
        	}
        }
        
        system.debug('There are [' + countryResults.size()  + ' results in countryResults.]');
        
        
        // flush the country list so it can be repopulated with a new region-specific list of countries..
        countrySelectOptions.clear();
        if(!hideCountryOptions){
        	countrySelectOptions.add(new SelectOption('All','All')); // always provide an "All" option
	        for(Country__c c: countryResults){
	            countrySelectOptions.add(new SelectOption(c.Name, c.Name));
	        }
        }
        
    }
    
    
    
    private void addNAregions(Set<String> subRegionSet){
        subRegionSet.add('Northeast');
        subRegionSet.add('Northwest');
        subRegionSet.add('Southwest');
        subRegionSet.add('Southeast');
        subRegionSet.add('North Central');
        subRegionSet.add('South Central');
        subRegionSet.add('Mid-Atlantic');
        subRegionSet.add('Fed Sled');
        subRegionSet.add('Canada');
    }
    
    

    public List<String> preparedSelectList(String audienceFieldValue){
        List<String> theList = new List<String>();
        if(audienceFieldValue!=null){
            theList = audienceFieldValue.split(';',-1);
        }

        return theList;
    }

    public List<SelectOption> createStaticSelectOptions(List<String> stringList){
        return createStaticSelectOptions(stringList, false);
    }

    
    //public List<SelectOption> createStaticCountrySelectOptions(List<String> stringList, Boolean )

    public List<SelectOption> createStaticSelectOptions(List<String> stringList, boolean isDependent){
        
        // Select Option list to be populated
        List<SelectOption> options = New List<SelectOption>();
        
        // Add an "ALL" option
        selectOption soAll = new SelectOption('All','All');
        options.add(soAll);
        
        
        for(string s : stringList){
            if(isDependent){
                if(!subregionIsDisabled(s)){   // ****** CHECK THAT SUBREGIONS ARE PROPERLY BEING MARKED AS DISABLED ******
                    selectOption so = new SelectOption(s,s);
                    options.add(so);
                }
            }else{
                selectOption so = new SelectOption(s,s);
                options.add(so);
            }
        }
        return options;
    }

    public boolean subregionIsDisabled(String controlledFieldValue){
        
        String currentSelections = '';
                
        if(selectedRegions != null && selectedRegions.size()>0)
            currentSelections = processSelectedOptions(selectedRegions);
            
        system.debug('currentSelections: [' + currentSelections + ']');
        
        if(currentSelections != null && currentSelections.length() > 0){
            if(currentSelections.contains('All')){
                return false;
            }
            if(currentSelections.contains('NA')){
                if(    controlledFieldValue=='Northeast' 
                    || controlledFieldValue=='Southeast' 
                    || controlledFieldValue=='West' 
                    || controlledFieldValue=='Canada'
                    || controlledFieldValue=='Fed Sled' 
                    || controlledFieldValue=='High Volume' 
                    || controlledFieldValue=='Distributor' 
                    || controlledFieldValue== 'NA'
                    || controlledFieldValue=='Northwest' 
                    || controlledFieldValue=='Southwest' 
                    || controlledFieldValue=='North Central'
                    || controlledFieldValue=='South Central' 
                    || controlledFieldValue=='Mid-Atlantic'){
                    return false;
                }
            }
            
            
            
            
            if(currentSelections.contains('EMEA')){
                system.debug('currentSelections contains EMEA');
                if(controlledFieldValue=='CE' || controlledFieldValue=='NEE' || controlledFieldValue=='SEMEA'){
                    return false;
                }
            }
            if(currentSelections.contains('APAC')){
                system.debug('currentSelections contains APAC');
                if(controlledFieldValue=='ASEAN' || controlledFieldValue=='ANZ' || controlledFieldValue=='India' || controlledFieldValue=='Hong Kong'
                    || controlledFieldValue=='Greater China' || controlledFieldValue=='Japan' || controlledFieldValue=='Korea' || controlledFieldValue=='Taiwan'){
                    return false;
                }
            }
            if(currentSelections.contains('LATAM')){
                system.debug('currentSelections contains LATAM');
                if(controlledFieldValue=='Brazil' || controlledFieldValue=='Mexico' || controlledFieldValue=='SAC'){
                    return false;
                }
            }
        }
        return true;
    }

    String processSelectedOptions(List<String> theSelections){
        return processSelectedOptions(theSelections,false,null);
    }

    String processSelectedOptions(List<String> theSelections, boolean forId, Map<String,String> idToNameMap){
        String selectionString = '';

        Integer x = 0;
        For(String s : theSelections){
            if(x==0){
                if(!forId){
                    selectionString = s;
                }else{
                    selectionString = idToNameMap.get(s);
                }
            }else{
                if(!forId){
                    selectionString += ';'+s;
                }else{
                    selectionString += ';'+idToNameMap.get(s);
                }
            }
            x++;
        }

        return selectionString;
    }

    public static List<String> audienceFieldList(){
        List<String> fields = new List<String>{
            'Id'
            ,'Name'
            ,'Partner_Region__c'
            ,'Partner_Tier__c'
            ,'Partner_Type__c'
            ,'Permission_Set__c'
            ,'Permission_Set_Id__c'
            ,'Profile__c'
            ,'Profile_Id__c'
            ,'Target_Account__c'
            ,'Role__c'
            ,'Available_To_Unauthenticated_Users__c'
            ,'Partner_SubRegion__c'
            ,'Partner_Program__c'
            ,'Partner_Country__c'
            ,'Specialization__c'
            ,'Total_Targeted_Accounts__c'
        };
        return fields;
    }

    void populateProfileAndPermissionSetMaps(){
        profileIdToName = new Map<String,String>();
        permissionSetIdToName = new Map<String,String>();
        for(Profile p : [SELECT Name, Id FROM Profile WHERE Name LIKE '%Partner Portal%']){
            String profileId = p.id;
            String trimmedProfileId = profileId.subString(0,15);
            profileIdToName.put(trimmedProfileId,p.name);
        }
        for(PermissionSet ps : [SELECT Label, Id FROM PermissionSet WHERE ProfileId=null AND Label LIKE '%Partner%']){
            String permissionSetId = ps.id;
            String trimmedPermissionsetId = permissionSetId.subString(0,15);
            permissionSetIdToName.put(trimmedPermissionsetId,ps.label);
        }
        system.debug('****PSet map: ' + permissionSetIdToName);
        system.debug('****Profile map: ' + profileIdToName);
    }

    List<SelectOption> getOptions(List<Classification__c> theList){
        List<SelectOption> options = new List<SelectOption>();

        SelectOption soAll = new SelectOption('All','All');
        options.add(soAll);

        for(Classification__c c : theList){
            SelectOption so = new SelectOption(c.name,c.name);
            options.add(so);
        }
        return options;
    }

    List<SelectOption> getOptions(Map<String,String> theMap){
        List<SelectOption> options = new List<SelectOption>();
        for(String s : theMap.keyset()){
            SelectOption so = new SelectOption(s,theMap.get(s));
            options.add(so);
        }
        return options;
    }

    List<Classification__c> getClassifications(String hierarchyKey){
        String unaffiliatedString = 'Unaffiliated%';
        String classificationQuery = 'SELECT Id, Name, IsActive__c FROM Classification__c ';
        classificationQuery+= 'WHERE IsActive__c = true AND HierarchyRootName__c = :hierarchyKey ';
        classificationQuery+= 'AND HierarchyDepth__c = 2 AND (NOT Name LIKE :unaffiliatedString)';
        List<Classification__c> classifications = database.query(classificationQuery);
        return classifications;
    }



    
        
    public PageReference doAccountSearch(){
    	//refreshTargetAccounts(); // refresh the list of already added accounts
    	String acctSearch = ApexPages.currentPage().getParameters().get('accountName');
    	if( !String.isEmpty(acctSearch)){
    		searchSoql = 'SELECT Id, Name, BillingCity, BillingState, BillingCountry, PartnerStatuses__c, Global_Region__c FROM Account WHERE IsPartner = true AND Name like \'' + acctSearch + '%\' AND Id NOT IN :targetAccountIdSet LIMIT 20 ';
    		searchResults = Database.query(searchSoql);
    		for(Account a:searchResults) acctMap.put(a.Id,a);
    	}
    	return null;
    }

    public PageReference selectAccount(){
    	
    	system.debug( 'Adding [' + selectedAccountId + '] to the targetAccounts collection..');
    	
    	if(String.isEmpty(selectedAccountId)) return null;
    	if(targetAccountIdSet.contains(selectedAccountId)) return null; // account has already been added
    	
    	Account targetAccount =acctMap.get(selectedAccountId); 
        
    	if(targetAccount != null){
    		targetAccounts.add(targetAccount);
            targetAccountIdSet.add(selectedAccountId);
            ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.Confirm, targetAccount.Name + ' added.'));
    	} else {
    		ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.ERROR,'targetAccount is null.'));
    	}
    	
    	// refresh the search results
    	doAccountSearch();
    	
    	return null;
    }
    
}