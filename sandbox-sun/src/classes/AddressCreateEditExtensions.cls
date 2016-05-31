/*********************************************************************************************************
    Name    : AddressCreateEditExtensions
    Desc    : Used to validate and create new address for Sales Accounts 
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
Neha Jaiswal    04/06/2014          Created
Phaniraj        06/06/2014          Modified class to create validation and saving functionality
Scott Coleman   11-Mar-2014         Moving address style and country code to Country__c so config doesn't
                                    break every time country names are updated. US64870
*******************************************************************************************************/
public with sharing class AddressCreateEditExtensions{    
    /************* Properties **********/    
    public Address__c addressRecord{get;set;} 
    public Blob contentFile{get;set;}
    String[] fileLines = new String[]{};
    // check if following address fields are visible and if they are visible, check if they are mandatory as well. 
    // set these boolean values based on the country that will be selected on the visualforce page.
    public Boolean addressline1Mandatory{get;set;} // check if address line 1 field is mandatory for the address style 
    public Boolean addressline1Visibility{get;set;} // check if address line 1 field is visible for the address style 
    public Boolean addressline2Mandatory{get;set;} // check if address line 2 field is mandatory for the address style 
    public Boolean addressline2Visibility{get;set;} // check if address line 2 field is visible for the address style 
    public Boolean addressline3Mandatory{get;set;} // check if address line 3 field is mandatory for the address style 
    public Boolean addressline3Visibility{get;set;} // check if address line 3 field is mandatory for the address style 
    public Boolean addressline4Mandatory{get;set;} // check if address line 4 field is mandatory for the address style 
    public Boolean addressline4Visibility{get;set;} // check if address line 4 field is mandatory for the address style 
    public Boolean cityVisibility{get;set;} // check if city field is visible field for the address style 
    public Boolean cityMandatory{get;set;} // check if city field is mandatory field for the address style 
    public Boolean countyMandatory{get;set;} // check if county field is mandatory field for the address style 
    public Boolean countyVisibility{get;set;} // check if county field is visible field for the address style 
    public Boolean postalCodeMandatory{get;set;} // check if postal code field is mandatory for the address style 
    public Boolean postalCodeVisibilty{get;set;} // check if postal code field is visible for the address style 
    public Boolean provinceMandatory{get;set;} // check if province field is mandatory for the address style 
    public Boolean provinceVisibility{get;set;} // check if province field is visible for the address style 
    public Boolean stateMandatory{get;set;} // check if state field is mandatory for the address style 
    public Boolean stateVisibility{get;set;} // check if state field is visible for the address style 
    public string accountName{get;set;}
    
    // map the countries available in the document to the address styles.
    public Map<String,String> mapAddressCountryget{get;set;} 
    // map the country with list of states.
    public Map<String,List<State__c>> countryStateMap;
    // select list for states
    public List<SelectOption> stateList{get;set;}
    // select list for county
    public List<SelectOption> countyList{get;set;}
    // select list for province
    public List<SelectOption> provinceList{get;set;}
    
    public String stateTextValue{get;set;}  // store the state value in this property           
    public String countyTextValue{get;set;} // store the county value in this property          
    public String provinceTextValue{get;set;} // store the province value in this property  
    
    public Map<string,RH_AddressCountryMapping__c> mapAddressWrapper{get;set;} // get the RH_AddressCountryMapping__c custom setting into a map
    //public Map<string,RH_CountryCode_CountryName__c > countryCodeWrapper{get;set;}  // get the RH_CountryCode_CountryName__c custom setting into a map
    public Map<string,Country__c> countryCodeWrapper{get;set;} // get the Country__c object into a map
    public Map<string,string> codeCountryWrapper{get;set;}  // map to store country code vs country values. 
    public Boolean createModeFlag{get;set;}  // flag to check if record is being created or is being edited  
    public String countryName{get;set;}
    public String isValid{get;set;}
    public String addressRecordId{get;set;}  // string variable to store the address id coming from the URL Parameter.
    public String accountId{get;set;}    // string variable to store account Id from where the address is being created
    public string returnUrl{get;set;} // property to redirect the record
    public string noOfIdentifyingAddress{get;set;}
    public Map<String, States_ISO_codes__c> stateISOCodes = new Map<String, States_ISO_codes__c>(); // map for US Stats ISO Codes
    
    public List<SelectOption> countryList{get;set;}  
    /************ properties end *******************/
    
        
    /************ Constructor **************/    
    public AddressCreateEditExtensions(ApexPages.StandardController controller)
    {
        try{
            
            // if a return url is set, get the id of the record to which the redirection should happen.
            returnUrl = Apexpages.currentpage().getParameters().get('retURL');
            // if a new address is created from related list of sales account, append the sales account master-detail field
            accountId = Apexpages.currentpage().getParameters().get('accountId');            
            // check if record is being edited.  
            addressRecordId = Apexpages.currentpage().getParameters().get('id');   
            // check if account name is present. This is incase of Create Address from Sales Accout Record
            accountName = Apexpages.currentpage().getParameters().get('accountName');   
            // check number of identying address
            noOfIdentifyingAddress = '0';
            noOfIdentifyingAddress = Apexpages.currentpage().getParameters().get('noOfIdentifyingAddress');
            /************* FLAGS *****************/
            /***** Set the flags as false initially, these will change accordingly as per conditions *********/
            createModeFlag = false;      
            countryName = '';           
            isValid = 'false';          
            addressline1Mandatory = true;
            addressline2Mandatory = false;
            addressline3Mandatory = false;
            addressline4Mandatory = false;
            cityVisibility = false;         
            cityMandatory = false;          
            /************* End of FLAGS *****************/
            
            // if record is being edited, get the address details 
            if(addressRecordId != null && addressRecordId != ''){
                createModeFlag = false;
                String query = 'SELECT ';
                for(Schema.FieldSetMember fields : this.getFields()) {   
                    query += fields.getFieldPath() + ', ';
                }
                query += 'Id, Name,Sales_Account__r.Count_Of_Identifying_Address__c FROM Address__c where id =: addressRecordId';
                addressRecord = Database.query(query);  
            }
            // create new address
            else{
                createModeFlag = true;
                addressRecord = new Address__c();
                if(accountId != null)
                    addressRecord.Sales_Account__c = Id.valueOf(accountId);
            }            
            /******* initialize select lists **********/
            stateList = new List<SelectOption>();
            countyList = new List<SelectOption>();
            provinceList = new List<SelectOption>();            
            /************** Initialize maps ***************/
            countryStateMap = new Map<String,List<State__c>>(); // country vs state map
            mapAddressWrapper=new Map<string,RH_AddressCountryMapping__c>(); // Country vs Address style maps
            mapAddressCountryget=new Map<string,string>(); // Country and Country code maps
            // Commented by Scott Coleman 11-Mar-2015. Country Code now found on Country__c object (Iso3166Alpha2).
            //countryCodeWrapper = new Map<string,RH_CountryCode_CountryName__c >(); // Get all country codes into map
            //countryCodeWrapper = RH_CountryCode_CountryName__c.getAll();
            countryCodeWrapper = new Map<string,Country__c>(); // Get all country codes into map
            for(Country__c country : [select Id,Name,Iso3166Alpha2__c,Address_Style__c, (select Id,Name from States__r) from Country__c where Address_Style__c != null]){
                countryCodeWrapper.put(country.Name.toUpperCase(), country);
            }   
            stateISOCodes = States_ISO_codes__c.getAll(); // put all values to map.
            codeCountryWrapper = new map<string,string>();
            // Prepare another map for code vs country
            // Commented by Scott Coleman 11-Mar-2015. Country Code now found on Country__c object (Iso3166Alpha2).
            //for(String countryCode : countryCodeWrapper.keySet()){   
            //    codeCountryWrapper.put(countryCodeWrapper.get(countryCode).RH_TERRITORY_CODE__c,countryCode.toUpperCase()) ;           
            //}
            for(String country : countryCodeWrapper.keySet()){   
                codeCountryWrapper.put(countryCodeWrapper.get(country).Iso3166Alpha2__c,country.toUpperCase());           
            }
            // Commented by Scott Coleman 11-Mar-2015. Address Style now found on Country__c object.         
            //// get all address details from Excel csv file defined in Documents   
            //Document documentRecord = [Select id,Body from Document where name='RH_AddressCountryMapping' limit 1];  
            //// Read the document and get all country related details
            //String documentContent = '';
            //if(!Test.isRunningTest())   // reading a blob value is not possible in test class. So adding test data here.
            //    documentContent = documentRecord.body.toString();
            //else
            //    documentContent = 'united states,Address Style 9\nindia,Address Style 10\nchina,Address Style 8\ncanada,Address Style 8\naustralia,Address Style 10';
            //filelines = documentContent.split('\n');
            //List<String> countryFileList = new List<String>();            
            //// Get all the countries listed in the CSV File
            //for (Integer fileLine=1; fileLine < filelines.size(); fileLine++) //
            //{
            //    String[] inputvalues = new String[]{};
            //    inputvalues = filelines[fileLine].split(',');
            //    countryFileList.add(inputvalues[0]);
            //    // Generate country vs Address line map
            //    system.debug('///////Country//////'+inputvalues);
            //    mapAddressCountryget.put(inputvalues[0],inputvalues[1]);
            //}            
            // Query from the Country object and get all the states defined and generate Country vs state list map
            //for(Country__c country : [select Id,Name,(select Id,Name from States__r) from Country__c where Name IN :countryFileList]){
            for(Country__c country : countryCodeWrapper.values()){ 
                List<State__c> stateList = new List<State__c>();
                for(State__c stateName:country.States__r){  
                    stateList.add(stateName);          
                }
                countryStateMap.put(country.Name.toUpperCase(),stateList);
                mapAddressCountryget.put(country.Name.toLowerCase(),country.Address_Style__c);
            }  
            
            countryList = new List<SelectOption>(); 
            
            CountryList.add(new SelectOption('','--None--'));
            List<String> countryValues = new List<String>();
            // sort countries in map,
            countryValues.addAll(countryStateMap.keySet());
            countryValues.sort();
            // create a select list
            for(String countryName:countryValues) 
            {
                CountryList.add(new SelectOption(countryName,countryName));
            }
                      
            // If record is being created get all the states for the country
            if(!createModeFlag){
                getAllStates();    
            }
        
        }
        // Any exception is handled here
        catch(Exception e){
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured !!!');  // set the exception message
            ApexPages.addMessage(errorMessage); 
        }
    }    
    /**************** Constructor Ends ********************/    
    /***************** Address fieldsets *******************/
    public List<Schema.FieldSetMember> getFields() {
        return SObjectType.Address__c.FieldSets.Address_Validation_field_set.getFields();
    }
    /****************** End of fieldset *******************/    
    
    /******************
        Method to get State, city, county, province, zip code details for the address style defined for the country that is selected.
    ******************/
    public pageReference getAllStates(){
        // setting the flags and properties
        stateTextValue = '';
        countyTextValue = '';
        provinceTextValue = '';        
        mapAddressWrapper=new Map<string,RH_AddressCountryMapping__c>();
        mapAddressWrapper= RH_AddressCountryMapping__c.getAll();        
        // if record is being edited, get the address style for the country`
        if(!createModeFlag && (Apexpages.currentpage().getParameters().get('countryName') == null))
            countryName = codeCountryWrapper.get(addressRecord.Country__c);
        else
            countryName = Apexpages.currentpage().getParameters().get('countryName');
        // modify the string of country that is retrieved
        String countryNameSelected = countryName;
        system.debug('00000000'+countryNameSelected);
        countryName = countryName.toLowerCase();
        system.debug('11111111'+countryName);
        system.debug('+++++++++++++++++'+mapAddressCountryget);
        countryName = mapAddressCountryget.get(countryName);
        system.debug('22222222'+countryName);
        system.debug('----------------'+codeCountryWrapper);
        // set the flag based on visibility and mandatory setting of the address style that is retrieved for the country that is selected.
        if(mapAddressWrapper.get(countryName) != null){
        cityMandatory             =  mapAddressWrapper.get(countryName).RH_city_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_city_mandatory__c : false;
        cityVisibility            =  mapAddressWrapper.get(countryName).RH_city_visibility__c != null ? mapAddressWrapper.get(countryName).RH_city_visibility__c : false;
        postalCodeMandatory       =  mapAddressWrapper.get(countryName).RH_PostalCode_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_PostalCode_mandatory__c : false;
        postalCodeVisibilty       =  mapAddressWrapper.get(countryName).RH_PostalCode_visibilty__c != null ? mapAddressWrapper.get(countryName).RH_PostalCode_visibilty__c : false;
        provinceMandatory         =  mapAddressWrapper.get(countryName).RH_Province_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_Province_mandatory__c : false;
        provinceVisibility        =  mapAddressWrapper.get(countryName).RH_Province_visibility__c != null ? mapAddressWrapper.get(countryName).RH_Province_visibility__c : false;
        stateMandatory            =  mapAddressWrapper.get(countryName).RH_state_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_state_mandatory__c : false;
        stateVisibility           =  mapAddressWrapper.get(countryName).RH_state_visibility__c != null ? mapAddressWrapper.get(countryName).RH_state_visibility__c : false;
        countyMandatory           =  mapAddressWrapper.get(countryName).RH_County_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_County_mandatory__c : false ;
        countyVisibility          =  mapAddressWrapper.get(countryName).RH_County_visibility__c != null ? mapAddressWrapper.get(countryName).RH_County_visibility__c : false ;        
        }
        // Set the country name
        countryName = countryNameSelected.toUpperCase();       
        // if state field visibility is set to true from the address style          
         if(stateVisibility != null && stateVisibility == true){
            stateList.clear(); // clear the state list
            // if the record is being edited and states are being defined for the country and state exists on the record, add to state list
            if(!createModeFlag && countryStateMap.get(countryName) != null && addressRecord.State__c != null)
                stateList.add(new SelectOption(addressRecord.State__c,addressRecord.State__c)); 
            stateList.add(new SelectOption('','--None--'));
            // If states are defined for the selected country in the state object
            if(countryStateMap.get(countryName) != null){
                List<String> stateValues = new List<String>();
                for(State__c stateName:countryStateMap.get(countryName)){   
                    stateValues.add(stateName.Name);
                }
                stateValues.sort();
                for(String stateValue:stateValues){ 
                    if(!createModeFlag && stateValue != addressRecord.State__c){
                        stateList.add(new SelectOption(stateValue,stateValue));
                    }else{
                        stateList.add(new SelectOption(stateValue,stateValue));
                    }     
                }
            }
            // else set the state to the text field
            else if(!createModeFlag && countryStateMap.get(countryName) == null){
                stateTextValue = addressRecord.State__c ;
            }
            // else keep the text field blank
            else{
                stateTextValue = '' ;
            }
        }       
        // if state visibility is not set and Province is set, get all those list and create a Province list
        else if(provinceVisibility != null && provinceVisibility == true){
            provinceList.clear();
            if(stateList.size() < 2){
                // if record is being edited and state is not there and Province is selected, set the province to list
                if(!createModeFlag && countryStateMap.get(countryName) != null && addressRecord.Province__c != null)
                    provinceList.add(new SelectOption(addressRecord.Province__c,addressRecord.Province__c));
                provinceList.add(new SelectOption('','--None--'));
                // generate Province Select list if defined in the object
                if(countryStateMap.get(countryName) != null){
                    List<String> provinceValues = new List<String>();
                    for(State__c stateName:countryStateMap.get(countryName)){    
                        provinceValues.add(stateName.Name);
                    }
                    provinceValues.sort();
                    for(String stateValue:provinceValues){   
                        if(!createModeFlag && stateValue != addressRecord.Province__c){
                            provinceList.add(new SelectOption(stateValue,stateValue));
                        }else{
                            provinceList.add(new SelectOption(stateValue,stateValue));
                        }        
                    }
                }
                // else set the province value to text field
                else if(!createModeFlag && countryStateMap.get(countryName) == null){
                    provinceTextValue = addressRecord.Province__c;
                }
                // else set the text field blank
                else{
                    provinceTextValue = '';
                }
            // else set the province value to text field
            }else if(!createModeFlag){
                provinceTextValue = addressRecord.Province__c;
            }
            // else set the text field blank
            else{
                provinceTextValue = '';
            }
        }
        else{}
        // Set County Value
        if(countyVisibility != null && countyVisibility == true){
            countyList.clear();
            countyList.add(new SelectOption('','--None--'));
            // if record is being edited and state is not there and County is selected, set the County to list
            if(!createModeFlag){
                countyTextValue = addressRecord.County__c;
            }
            // else set the county value
            else{
                countyTextValue = '';
            }
        }
        // return the method
        return null;    
    }    
    // Auto correction and setting the list values to text values
    //commented by Sagar Mehta on 12/05/2015 as per Defect - DE7472 - Google address validation is overwriting
    /*public pageReference setSelectListValues(){ 
        // we are passing the type of list field to be converted to text field. Based on value, we are converting this
        string adminType = apexpages.currentpage().getParameters().get('adminType');
        if(adminType == 'State'){
            stateList.clear();
            stateList.add(new SelectOption('','--None--'));
        }else if(adminType == 'County'){
            countyList.clear();
            countyList.add(new SelectOption('','--None--'));
        }else if(adminType == 'province'){
            provinceList.clear();
            provinceList.add(new SelectOption('','--None--'));
        }
        else{}
        // return the method
        return null;      
    }*/ 
       
    // Save functionality
    // upon saving the record, redirect the page to the record.
    public pageReference saveAddressDetails(){
        //addressRecord.Country__c = countryCodeWrapper.get(countryName).RH_TERRITORY_CODE__c;
        System.debug('*** countryName: ' + countryName);
        System.debug('*** countryCodeWrapper: ' + countryCodeWrapper);
        for(String cn : countryCodeWrapper.keySet()) {
            System.debug('*** cn: ' + cn);
            System.debug('*** countryCodeWrapper.get(cn): ' + countryCodeWrapper.get(cn));
        }
        addressRecord.Country__c = countryCodeWrapper.get(countryName).Iso3166Alpha2__c;
        if(addressRecord.Country__c == 'BR' && (addressRecord.Address_Line2__c == null || (addressRecord.Address_Line2__c != null && addressRecord.Address_Line2__c.trim() == ''))){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Address Line 2: You must enter a value'));    
            return null;        
        }
        System.debug('stateTextValue: '+stateTextValue);
        if(stateTextValue != null)
            addressRecord.State__c = stateISOCodes.get(stateTextValue) != null ? stateISOCodes.get(stateTextValue).ISO_Code__c : stateTextValue;
        else
            addressRecord.State__c = '';
        System.debug('addressRecord.State__c: '+addressRecord.State__c);
        addressRecord.Province__c = provinceTextValue;
        addressRecord.County__c = countyTextValue;
        addressRecord.status__c = 'Active';
        
        /* Changes done as part of User Story US63006
         * Brazil City values are not removing local language characters
         */
        if(addressRecord.City__c != null){
            addressRecord.City__c = addressRecord.City__c.toUpperCase(); 
            if(addressRecord.City__c.contains('Ã'))
                addressRecord.City__c = addressRecord.City__c.replace('Ã', 'A');
                
            if(addressRecord.City__c.contains('Á'))
                addressRecord.City__c = addressRecord.City__c.replace('Á', 'A');

            if(addressRecord.City__c.contains('À'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('À', 'A');
            
            if(addressRecord.City__c.contains('Â'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Â', 'A');
            
            if(addressRecord.City__c.contains('Ç'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ç', 'C');
                
            if(addressRecord.City__c.contains('É'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('É', 'E');
            
            if(addressRecord.City__c.contains('Ê'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ê', 'E');        
            
            if(addressRecord.City__c.contains('Í'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Í', 'I');
                
            if(addressRecord.City__c.contains('Õ'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Õ', 'O');
            
            if(addressRecord.City__c.contains('Ó'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ó', 'O');
                
            if(addressRecord.City__c.contains('Ô'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ô', 'O');            
            
            if(addressRecord.City__c.contains('Ú'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ú', 'U');
            
            if(addressRecord.City__c.contains('Ü'))
                addressRecord.City__c = addressRecord.City__c.replaceAll('Ü', 'U');    
        }
        
        if(!createModeFlag)
            addressRecord.Identifying_Address__c = addressRecord.Sales_Account__r.Count_Of_Identifying_Address__c == 0 ? true : false;
        else
           addressRecord.Identifying_Address__c = Integer.valueOf(noOfIdentifyingAddress) == 0 ? true : false;
        try{
            
            upsert addressRecord;
            PageReference page;
            // if return url is set, redirect to return url
            if(returnUrl != null){
                page = new PageReference(returnUrl);
            }
            
            // if the record is being created from Accoun object, redirect to account record
            else if(accountId != null){
                page = new PageReference('/'+accountId);
            }
            // redirect to address record
            else if(addressRecordId != null){
                page = new PageReference('/'+addressRecordId);
            }
            // redirect to address object.
            else{
                Schema.DescribeSObjectResult r = Address__c.sObjectType.getDescribe();
                String keyPrefix = r.getKeyPrefix();
                page = new PageReference('/'+keyPrefix);
            }
            return page;  
        }
        // Any exception is handled here
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        // return to edit mode if any exception occurs.
        return null;
    }    
    // cancel functionality
    public pageReference Cancel(){
        PageReference page;
        // if return url is set, redirect to return url
        if(returnUrl != null){
            page = new PageReference(returnUrl);
        }
        
        // if the record is being created from Accoun object, redirect to account record
        else if(accountId != null){
            page = new PageReference('/'+accountId);
        }
        // redirect to address record
        else if(addressRecordId != null){
            page = new PageReference('/'+addressRecordId);
        }
        // redirect to address object.
        else{
            Schema.DescribeSObjectResult r = Address__c.sObjectType.getDescribe();
            String keyPrefix = r.getKeyPrefix();
            page = new PageReference('/'+keyPrefix);
        }
        return page;    
    }    
}