/*****************************************************************************************
    Name    : AccountSearchBeforeCreateController
    Desc    : Used in the Account creation page which will search for Accounts from SFDC and customer data hub and also
              help to create a new account if not found
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
Sunay Prasad R K    22/05/2014          Created
Phaniraj N          30/06/2014          Edited - Changed the JSON Parsing for the CDH Returned Data.
Pankaj Banik        22/09/2014          Edited - Enhancement under US55762
Scott Coleman       11-Mar-2014         Moving country code to Country__c so config doesn't break every time country names are updated. US64870
******************************************************************************************/
public class AccountSearchBeforeCreateController{
    
    /************* Properties ****************/
    public string AccName{get;set;}
    public Boolean AliasFlag{get;set;}
    public string PartyNo{get;set;}
    public string Street{get;set;}
    public string city{get;set;}
    public string postalcode{get;set;}
    public string country{get;set;}
    public string state{get;set;}
    public boolean NoResultsDisplay{get;set;}
    public string StrDUNSNumber{get;set;}
    public Boolean showButtons{get;set;}
    public String sbcUrlString ;
    public String selectedSearchOption{get;set;}
    
    //parameters for redendering page components
    public Boolean partyNameComponentRenderFlag{get;set;}
    public Boolean partyNumberComponentRenderFlag{get;set;}
    public Boolean dunsNoComponentRenderFlag{get;set;}
    public Boolean searchComponentRenderFlag{get;set;}
    
    // Commenting this property as Seach within SFDC is out of scope
    //public string strquery;
    //public id tempid;
    
    //public list<account> accountlist{get;set;}
    //public boolean DIsplayResults{get;set;}
    //public boolean displaysearchbutton{get;set;}
    public boolean DisplayMDMResults{get;set;}
    public string SelAccId{get;set;}
    //public string IdentifyingAddress{get;set;}
    
    //Parameters for storing values after parsing
    public String name;
    public String sicDesc;
    public string billlingstreet;
    public string billlingcity;
    public string billlingstate;
    public string billlingcountry;
    public string partynumber;
    public string billingpostalcode;
    public string dunsnumber;
    public string JsonString{get;set;}
    public List<SelectOption> searchOptionList{get;set;}
    public List<SelectOption> stateList{get;set;}
    public List<SelectOption> countryCodeSelectList{get;set;}
    
    public map<Integer,searchResultsWrapper> searchResultsWrapperMap{get;set;}
    public List<searchResultsWrapper> searchResultsWrapperList{get;set;}
    
    public List<recordTypeWrapper> availableAccountTypes{get;set;}
    public String AccountRecordTypesJSON {get;set;} 
    
    // Static JSON String for showing Account Details
    public static String AccountDetailsJSON {get;set;} 
    public static String PartnerDetailsJSON {get;set;} 
    public Map<String,List<State__c>> countryStateMap{get;set;}
    public Map<String, States_ISO_codes__c> stateISOCodes = new Map<String, States_ISO_codes__c>();
    
    public AccountSearchBeforeCreateController(ApexPages.StandardController controller){
        /*Set default values of flags for default search type to Customer search Type
        Code added under US55762- pbanik@redhat.com */
        selectedSearchOption = '3';
        AccName = null;
        searchComponentRenderFlag = true ;
        partyNameComponentRenderFlag = true ;
        partyNumberComponentRenderFlag = false;
        dunsNoComponentRenderFlag = false;
        AliasFlag = false;
        //End of Changes
        stateList = new List<SelectOption>();
        countryCodeSelectList = new List<SelectOption>();  
        availableAccountTypes = new List<recordTypeWrapper>();
        availableAccountTypes = GetAvailableRecordTypeNamesForSObject(Account.SObjectType);  
        
        // Changes as per US63187
        //pbanik@redhat.com
        List <recordTypeWrapper> accountRecordTypesDisplay = new List<recordTypeWrapper>()  ;
        for(recordTypeWrapper accountRecordType :availableAccountTypes){
            if(!accountRecordType.recordTypeName.contains('Partner'))
                accountRecordTypesDisplay.add(accountRecordType);
        }
        AccountRecordTypesJSON = JSON.serialize(accountRecordTypesDisplay);
        //AccountRecordTypesJSON = JSON.serialize(availableAccountTypes);
        //End of Changes
        
        countryCodeSelectList.add(new SelectOption('--None--', '--None--'));
        countryStateMap = new Map<String,List<State__c>>(); // country vs state map
        //Map<String, RH_CountryCode_CountryName__c> countries = RH_CountryCode_CountryName__c.getAll();
        Map<String, Country__c> countries = new Map<String, Country__c>();
        for(Country__c country : [select Id,Name,Iso3166Alpha2__c,Address_Style__c, (select Id,Name from States__r) from Country__c]){
            countries.put(country.Name, country);
        }
        stateISOCodes = States_ISO_codes__c.getAll();
        // Sort them by name
        List<String> countryNames = new List<String>();
        countryNames.addAll(countries.keySet());
        countryNames.sort();
        
        for (String countryName : countryNames) {
            //RH_CountryCode_CountryName__c country = countries.get(countryName);
            //countryCodeSelectList.add(new SelectOption(country.RH_TERRITORY_CODE__c+','+country.Name, country.Name));
            Country__c country = countries.get(countryName);
            countryCodeSelectList.add(new SelectOption(country.Iso3166Alpha2__c+','+country.Name, country.Name));
        } 
        
        //for(Country__c country : [select Id,Name,(select Id,Name from States__r) from Country__c where Name IN :countryNames]){  
        for(Country__c country : countries.values()){
            List<State__c> stateList = new List<State__c>();
            for(State__c stateName:country.States__r){  
                stateList.add(stateName);          
            }
            countryStateMap.put(country.Name.toUpperCase(),stateList);
        } 
        /*Code added under US55762- pbanik@redhat.com
        Add list options for search Type */
        
        searchOptionList = new List<SelectOption>();
        searchOptionList.add(new SelectOption('1','Search using Party Number'));
        searchOptionList.add(new SelectOption('2','Search using DUNS Number'));  
        searchOptionList.add(new SelectOption('3','Search using Customer Information'));
        //End of Changes
    }
    
    //Code added under US55762- pbanik@redhat.com
    /*
     * Method name  : searchTypeSelection
     * Description  : Method to set page components visible depending on type of search selected by User
     * Return Type  : pagereference
     * Parameter    : NA
     */
    public pageReference searchTypeSelection()
    {
        System.Debug('inside Search type----> '+ selectedSearchOption);
        // if search type is on Party Name
        if (selectedSearchOption == '3')
        {
            System.Debug('searchComponentRenderFlag ----> '+ searchComponentRenderFlag );
            System.Debug('partyNameComponentRenderFlag----> '+ partyNameComponentRenderFlag);
            System.Debug('partyNumberComponentRenderFlag----> '+ partyNumberComponentRenderFlag);
            System.Debug('dunsNoComponentRenderFlag----> '+ dunsNoComponentRenderFlag);
            searchComponentRenderFlag = true ;
            partyNameComponentRenderFlag = true ;
            partyNumberComponentRenderFlag = false;
            dunsNoComponentRenderFlag = false;
            DisplayMDMResults = false ;
            AccName = null;
            AliasFlag = false;
            PartyNo = null;
            Street = null;
            city = null;
            postalcode = null;
            country = null;
            state = null;
            StrDUNSNumber = null;
        }
        // if search type is on Party Number
        else if (selectedSearchOption == '1')
        {
            System.Debug('searchComponentRenderFlag ----> '+ searchComponentRenderFlag );
            System.Debug('partyNameComponentRenderFlag----> '+ partyNameComponentRenderFlag);
            System.Debug('partyNumberComponentRenderFlag----> '+ partyNumberComponentRenderFlag);
            System.Debug('dunsNoComponentRenderFlag----> '+ dunsNoComponentRenderFlag);
            searchComponentRenderFlag = true ;
            partyNameComponentRenderFlag = false;
            partyNumberComponentRenderFlag = true ;
            dunsNoComponentRenderFlag = false;
            DisplayMDMResults = false ;
            AccName = null;
            AliasFlag = false;
            PartyNo = null;
            Street = null;
            city = null;
            postalcode = null;
            country = null;
            state = null;
            StrDUNSNumber = null;
        }
        // if search type is on DUNS Number
        else if (selectedSearchOption == '2')
        {
            System.Debug('searchComponentRenderFlag ----> '+ searchComponentRenderFlag );
            System.Debug('partyNameComponentRenderFlag----> '+ partyNameComponentRenderFlag);
            System.Debug('partyNumberComponentRenderFlag----> '+ partyNumberComponentRenderFlag);
            System.Debug('dunsNoComponentRenderFlag----> '+ dunsNoComponentRenderFlag);
            searchComponentRenderFlag = true ;
            partyNameComponentRenderFlag = false;
            partyNumberComponentRenderFlag = false;
            dunsNoComponentRenderFlag = true ;
            DisplayMDMResults = false ;
            AccName = null;
            AliasFlag = false;
            PartyNo = null;
            Street = null;
            city = null;
            postalcode = null;
            country = null;
            state = null;
            StrDUNSNumber = null;
        }
        
        return null;
    }
    //End of changes
    
    public pageReference getAllStates(){
        string countryName = Apexpages.currentpage().getParameters().get('countryName');
        countryName = countryName.toUpperCase();
        System.debug('------------countryName '+countryName);
        System.debug('------------countryStateMap.get(countryName) '+countryStateMap.get(countryName));                 
        stateList.clear(); // clear the state list
         if(countryStateMap.get(countryName) != null){
            stateList.add(new SelectOption('','--None--'));
            for(State__c stateName : countryStateMap.get(countryName)){ 
                if(stateISOCodes.get(stateName.Name) == null)
                    stateList.add(new SelectOption(stateName.Name,stateName.Name));
                else
                    stateList.add(new SelectOption(stateISOCodes.get(stateName.Name).ISO_Code__c,stateName.Name));
            }
            stateList.sort();
            System.debug('------------stateList '+stateList); 
        }else
             state = '' ;
        return null;
    }
    
    
    // Returns a List of the Names of all RecordTypes
    // available to the running user for a given SOBject type
    public List<recordTypeWrapper> GetAvailableRecordTypeNamesForSObject(Schema.SObjectType objType) {
        
        //return recordTypeWrapperList; 
        
        List<recordTypeWrapper> recordTypeWrapperList = new List<recordTypeWrapper>();
        Set<String> objectApiNames= new Set<String>();
        objectApiNames.add('Account');
        User u = [select IsPortalEnabled,Job_Function__c,Region__c,Profile.Name,UserRole.Name from User where Id = :UserInfo.getUserId()];
        Map<String,List<RecordTypeAssignment__c>> recordTypeAssignmentMap = recordTypeSelectController.getRecordTypeAssignmentMap( objectApiNames,u.Region__c,u.Profile.Name);
        Set<String> recordTypeNames = recordTypeSelectController.getRecordTypeNameMap(u,objectApiNames).get('ACCOUNT');
        List<RecordType> recordTypes = [ select id, Description, Name from RecordType where SObjectType = :objectApiNames and IsActive = true
                                        and (Name in :recordTypeNames
                                        or DeveloperName in :recordTypeNames)
                                        order by Name ];
        for(RecordType r:recordTypes ){
            recordTypeWrapper rr = new recordTypeWrapper();
            rr.recordTypeId = r.id;
            rr.recordTypeName = r.Name;
            recordTypeWrapperList.add(rr) ;     
        }
        if(recordTypeWrapperList.size() == 0){          
            List<String> names = new List<String>();
            List<String> nameId = new List<String>();
            recordTypeWrapperList.clear();
            List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
            // If there are 2 or more RecordTypes...
            if (infos.size() > 1) {
               for (RecordTypeInfo i : infos) {
                   if (i.isAvailable() 
                     // Ignore the Master Record Type, whose Id always ends with 'AAA'.
                     // We check the Id because Name can change depending on the user's language.
                        && !String.valueOf(i.getRecordTypeId()).endsWith('AAA')){
                        recordTypeWrapper r = new recordTypeWrapper();
                        r.recordTypeId = i.getRecordTypeId();
                        r.recordTypeName = i.getName();
                        recordTypeWrapperList.add(r);
                   }
                }
            } 
            // Otherwise there's just the Master record type,
            // so add it in, since it MUST always be available
            else {
                //names.add(infos[0].getName());
                recordTypeWrapper r = new recordTypeWrapper();
                r.recordTypeId = infos[0].getRecordTypeId();
                r.recordTypeName = infos[0].getName();
                recordTypeWrapperList.add(r) ;  
            }
        }
        
        return recordTypeWrapperList;
    }
    
    public Jsonparsercls j{get;set;}
    
    // Method to search CDH with parameters provided in the search fields 
     public pageReference searchCDHParty(){
        showButtons = false;
        searchResultsWrapperMap = new Map<Integer,searchResultsWrapper>();
        searchResultsWrapperList = new List<searchResultsWrapper>();
        System.debug('INSIDE SEARCH METHOD---->');
         
          System.debug('AccName----'+AccName);
          System.debug('PartyNo----'+PartyNo);
          System.debug('Street----'+Street);
          System.debug('city----'+city);
          System.debug('postalcode----'+postalcode);
          System.debug('StrDUNSNumber----'+StrDUNSNumber);
          System.debug('Country----'+Country);
          System.debug('state----'+state);
        
        String parmetersToBeSearched = '';
        if(country != null){
            List<String> countryListSplit = country.split(',');
            country = countryListSplit[0];
        } 
        //Code added under US55762- pbanik@redhat.com 
        if (!AliasFlag && AccName != null)
        {   
           parmetersToBeSearched += AccName != '' ? '&partyName='+EncodingUtil.urlEncode(AccName.trim(), 'UTF-8') : '';        
              
        }
        if (PartyNo != null)
        {
            parmetersToBeSearched += PartyNo != '' ? '&partyNumber='+EncodingUtil.urlEncode(PartyNo.trim(), 'UTF-8') : '';  
        }
        if(StrDUNSNumber !=null)
        {    
            System.Debug ('StrDUNSNumber-------> '+StrDUNSNumber) ;
            parmetersToBeSearched += StrDUNSNumber != '' ? '&dunsNumber='+EncodingUtil.urlEncode(StrDUNSNumber.trim(), 'UTF-8') : '';   
        }    
        if (Street != null)
        {
            parmetersToBeSearched += Street != '' ? '&address1='+EncodingUtil.urlEncode(Street.trim(), 'UTF-8') : '';       
        }
        if (city != null)
        {
            parmetersToBeSearched += city != '' ? '&city='+EncodingUtil.urlEncode(city.trim(), 'UTF-8') : '';       
        }
        if (state != null )
        {
            parmetersToBeSearched += state != null ? '&state='+EncodingUtil.urlEncode(state.trim(), 'UTF-8') : '';      
        }
        if (country != null)
        {
            parmetersToBeSearched += country != '--None--' ? '&country='+country.trim() : '';
        }
        if (postalcode != null)
        {
            parmetersToBeSearched += postalcode != '' ? '&postalCode='+EncodingUtil.urlEncode(postalcode.trim(), 'UTF-8') : '';
        }
       
        if (AliasFlag && AccName != null)
        {
            parmetersToBeSearched += AccName != '' ? '&knownAs='+EncodingUtil.urlEncode(AccName.trim(), 'UTF-8') : ''; 
               
        }
        
        //End of changes
        parmetersToBeSearched = parmetersToBeSearched.substring(1, parmetersToBeSearched.length());
        System.debug('parmetersToBeSearched ----'+parmetersToBeSearched);
        //parmetersToBeSearched = parmetersToBeSearched.replaceAll(' ','%20');
        //parmetersToBeSearched = parmetersToBeSearched.replaceAll('\n','');
        
        //Getting URL for search before create from Custom settings
        SearchBeforeCreateURL__c sbcCustomsetting = SearchBeforeCreateURL__c.getValues('CDH URL');
        sbcUrlString = sbcCustomsetting.Cdh_URL__c;
        
        string httpRequestString = sbcUrlString+parmetersToBeSearched;
        //httpRequestString = EncodingUtil.urlEncode(httpRequestString,'UTF-8');
        System.debug('--------URL------'+httpRequestString);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(httpRequestString);
        req.setMethod('GET');
        
        //increase the time out to 120 seconds
        req.setTimeOut(120000);
        
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        boolean successResult = true;
        /*
        HTTPResponse res1;
        res1.setStatus('OK');
        String jsonBody1='{\"ORACLEMESSAGE\":{\"PAYLOAD\":{\"HZ_PARTY\":{\"HZ_PARTY_ROW\":{\"ATTRIBUTE3\":\"\",\"ATTRIBUTE2\":\"\",\"PARTY_NAME\":\"Canopy Cloud Ltd\",\"ATTRIBUTE1\":\"\",\"PARTY_ID\":1230665,\"TAX_REFERENCE\":\"GB232327983\",\"PARTY_NUMBE\":1221437,\"STATUS\":\"Active\",\"ATTRIBUTE5\":\"\",\"DUNS_NUMBER\":\"\",\"ATTRIBUTE4\":\"\",\"CROSS_REFERENCE\":{\"CROSS_REFERENCE_ROW\":[{\"ORIG_SYSTEM\":\"EBS\",\"ORIG_SYSTEM_REFERENCE\":6261266},{\"ORIG_SYSTEM\":\"SFDC\",\"ORIG_SYSTEM_REFERENCE\":\"0016000000lBukAAAS_ICUST\"},{\"ORIG_SYSTEM\":\"WEB\",\"ORIG_SYSTEM_REFERENCE\":\"6868870_ICUST\"}]},\"HZ_PARTY_SITES\":{\"HZ_PARTY_SITES_ROW\":{\"PARTY_SITE_NUMBER\":324371,\"STATE\":\"\",\"COUNTRY\":\"GB\",\"STATUS\":\"Active\",\"ADDRESS4\":\"\",\"CROSS_REFERENCE\":\"\",\"ADDRESS2\":\"PO Box 14\",\"ADDRESS3\":\"\",\"COUNTY\":\"\",\"ADDRESS1\":\"Finance Management Services\",\"IDENTIFYING_ADDRESS_FLAG\":\"Y\",\"PROVINCE":\"\",\"CITY\":\"Crewe\",\"POSTAL_CODE\":\"CW2 6DR\"}},\"JGZZ_FISCAL_CODE\":\"\",\"HZ_CONTACT_POINT\":\"\",\"HZ_CLASSIFICATION\":\"\",\"MATCH_PERCENTAGE\":100,\"PARTY_TYPE\":\"ORGANIZATION\",\"KNOWN_AS\":\"\"}}},\"xmlns\":\"http://rhcdh.redhat.com/1\"}}';
        res1.setBody(jsonBody1);
        res1.setStatusCode(200);
        System.debug('---->'+res1);
        */
        try{
            if (!Test.isRunningTest()){
                res = http.send(req);
                System.debug('==========> res '+res);
            }  
            else
            {
                res.setStatus('OK');
                String jsonBody='{\"ORACLEMESSAGE\":{\"PAYLOAD\":{\"HZ_PARTY\":{\"HZ_PARTY_ROW\":{\"ATTRIBUTE3\":\"\",\"ATTRIBUTE2\":\"\",\"PARTY_NAME\":\"Canopy Cloud Ltd\",\"ATTRIBUTE1\":\"\",\"PARTY_ID\":1230665,\"TAX_REFERENCE\":\"GB232327983\",\"CLASS_CODE\":\"C1\",\"CLASS_CODE_DESCRIPTION\":\"NEWCLASS\",\"CLASS_CATEGORY\":\"C3\",\"PRIMARY_FLAG\":\"P1\",\"START_DATE_ACTIVE\":\"29/02/2006\",\"END_DATE_ACTIVE\":\"29/02/2010\",\"STATUS\":\"NEWSTAT\",\"PARTY_NUMBER\":1221437,\"STATUS\":\"Active\",\"ATTRIBUTE5\":\"\",\"DUNS_NUMBER\":\"\",\"ATTRIBUTE4\":\"\",\"CROSS_REFERENCE\":{\"CROSS_REFERENCE_ROW\":[{\"ORIG_SYSTEM\":\"EBS\",\"ORIG_SYSTEM_REFERENCE\":6261266},{\"ORIG_SYSTEM\":\"SFDC\",\"ORIG_SYSTEM_REFERENCE\":\"0016000000lBukAAAS_ICUST\"},{\"ORIG_SYSTEM\":\"WEB\",\"ORIG_SYSTEM_REFERENCE\":\"6868870_ICUST\"}]},\"HZ_PARTY_SITES\":{\"HZ_PARTY_SITES_ROW\":{\"PARTY_SITE_NUMBER\":324371,\"STATE\":\"\",\"COUNTRY\":\"GB\",\"STATUS\":\"Active\",\"ADDRESS4\":\"\",\"CROSS_REFERENCE\":\"\",\"ADDRESS2\":\"PO Box 14\",\"ADDRESS3\":\"\",\"COUNTY\":\"\",\"ADDRESS1\":\"Finance Management Services\",\"IDENTIFYING_ADDRESS_FLAG\":\"Y\",\"PROVINCE":\"\",\"CITY\":\"Crewe\",\"POSTAL_CODE\":\"CW2 6DR\"}},\"JGZZ_FISCAL_CODE\":\"\",\"HZ_CONTACT_POINT\":\"\",\"HZ_CLASSIFICATION\":\"\",\"MATCH_PERCENTAGE\":100,\"PARTY_TYPE\":\"ORGANIZATION\",\"KNOWN_AS\":\"\"}}},\"xmlns\":\"http://rhcdh.redhat.com/1\"}}';
                res.setBody(jsonBody);
                res.setStatusCode(200);
            }  
        }catch(System.CalloutException e) { // callout exception
            successResult = false;
            System.debug('exception ----->'+ e);
            //showButtons = true;    
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Large set of records retrieved. Please refine your search and search again');  // set the exception message
            ApexPages.addMessage(Message); 
            return null;
        }catch(System.NullPointerException e){ // null pointer exception
            successResult = false;
            //showButtons = true;
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'No data returned');  // set the exception message
            ApexPages.addMessage(Message); 
            return null;
        }
        
        if(res.getStatus() == 'OK'){
            
            if(res.getBody() != null){
                
                JSONParser errorParser;
                JSONParser parser;
                try{
                    errorParser = JSON.createParser(res.getBody());
                    string errorStr = res.getBody();
                    System.debug('----------------1'+errorStr);
                }catch(Exception e){
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message); 
                    return null;        
                }
                try{
                    parser = JSON.createParser(res.getBody());
                    string errorStr = res.getBody();
                    System.debug('----------------2'+errorStr);
                }catch(Exception e){
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message); 
                    return null;        
                }
                System.debug('---------'+parser);
                
                List<Jsonparsercls> JsonparserclsList = new List<Jsonparsercls>();
                Integer i = 0;
                j = new Jsonparsercls();
                j.ORIG_SYSTEM = new List<String> ();
                j.ORIG_SYSTEM_REFERENCE = new List<String> ();
                j.CLASS_CODE = new List<String> ();
                j.CLASS_CODE_DESCRIPTION = new List<String> ();
                j.CLASS_CATEGORY = new List<String> ();
                j.PRIMARY_FLAG = new List<String> ();
                j.START_DATE_ACTIVE = new List<String> ();
                j.END_DATE_ACTIVE = new List<String> ();
                j.STATUS = new List<String> ();
                
                string errorMessage = '';
                while (errorParser.nextToken() != null) {
                    if ((errorParser.getCurrentToken() == JSONToken.FIELD_NAME) &&(errorParser.getText() == 'ERROR_MESSAGE')) {
                        errorParser.nextToken();
                        System.debug('==============Error'+errorParser.getText());
                        errorMessage = errorParser.getText();
                    }    
                }
                
                if(errorMessage == ''){
                    System.debug('================================entered data parsing');
                    while (parser.nextToken() != null) {
                        if(i == 0){
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PARTY_TYPE')) {
                                parser.nextToken();
                                j.PARTY_TYPE = parser.getText();
                                System.debug('========================================PARTY_TYPE '+parser.getText());
                                i++;
                                JsonparserclsList.add(j);
                                j = new Jsonparsercls();
                                j.ORIG_SYSTEM = new List<String> ();
                                j.ORIG_SYSTEM_REFERENCE = new List<String> ();
                                j.CLASS_CODE = new List<String> ();
                                j.CLASS_CODE_DESCRIPTION = new List<String> ();
                                j.CLASS_CATEGORY = new List<String> ();
                                j.PRIMARY_FLAG = new List<String> ();
                                j.START_DATE_ACTIVE = new List<String> ();
                                j.END_DATE_ACTIVE = new List<String> ();
                                j.STATUS = new List<String> ();
                                System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'+i);
                            }
                            //Jsonparsercls j = new Jsonparsercls();
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PARTY_NAME')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_NAME '+parser.getText());
                                j.PARTY_NAME = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PARTY_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_NUMBER '+parser.getText());
                                j.PARTY_NUMBER = parser.getText();
                            }
                            
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'DUNS_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================DUNS_NUMBER '+parser.getText());
                                j.DUNS_NUMBER = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PARTY_SITE_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_SITE_NUMBER '+parser.getText());
                                j.PARTY_SITE_NUMBER = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'ADDRESS1')) {
                                parser.nextToken();
                                System.debug('========================================ADDRESS1 '+parser.getText());
                                j.ADDRESS1 = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'ADDRESS2')) {
                                parser.nextToken();
                                System.debug('========================================ADDRESS2 '+parser.getText());
                                j.ADDRESS2 = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'CITY')) {
                                parser.nextToken();
                                System.debug('========================================CITY '+parser.getText());
                                j.CITY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'COUNTY')) {
                                parser.nextToken();
                                System.debug('========================================COUNTY'+parser.getText());
                                j.COUNTY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'STATE')) {
                                parser.nextToken();
                                System.debug('========================================STATE '+parser.getText());
                                j.STATE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PROVINCE')) {
                                parser.nextToken();
                                System.debug('========================================PROVINCE '+parser.getText());
                                j.PROVINCE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'COUNTRY')) {
                                parser.nextToken();
                                System.debug('========================================COUNTRY '+parser.getText());
                                j.COUNTRY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'POSTAL_CODE')) {
                                parser.nextToken();
                                System.debug('========================================POSTAL_CODE '+parser.getText());
                                j.POSTAL_CODE = parser.getText();
                            }
                            if(j.PHONENO == null){
                                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'RAW_PHONE_NUMBER')) {
                                    parser.nextToken();
                                    System.debug('========================================POSTAL_CODE '+parser.getText());
                                    j.PHONENO = parser.getText();
                                }
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'ORIG_SYSTEM')) {
                                parser.nextToken();
                                System.debug('========================================ORIG_SYSTEM '+parser.getText());
                                j.ORIG_SYSTEM.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'ORIG_SYSTEM_REFERENCE')) {
                                parser.nextToken();
                                System.debug('========================================ORIG_SYSTEM_REFERENCE '+parser.getText());
                                j.ORIG_SYSTEM_REFERENCE.add(parser.getText());
                            }  
                            
                            //Code added under US55762- pbanik@redhat.com                              
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'TAX_REFERENCE')) {
                                parser.nextToken();
                                System.debug('========================================TAX_REFERENCE '+parser.getText());
                                j.TAX_REFERENCE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'CLASS_CODE')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CODE '+parser.getText());
                                j.CLASS_CODE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'CLASS_CODE_DESCRIPTION')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CODE_DESCRIPTION '+parser.getText());
                                j.CLASS_CODE_DESCRIPTION.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'CLASS_CATEGORY')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CATEGORY '+parser.getText());
                                j.CLASS_CATEGORY.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PRIMARY_FLAG')) {
                                parser.nextToken();
                                System.debug('========================================PRIMARY_FLAG '+parser.getText());
                                j.PRIMARY_FLAG.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'START_DATE_ACTIVE')) {
                                parser.nextToken();
                                System.debug('========================================START_DATE_ACTIVE '+parser.getText());
                                j.START_DATE_ACTIVE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'END_DATE_ACTIVE')) {
                                parser.nextToken();
                                System.debug('========================================END_DATE_ACTIVE '+parser.getText());
                                j.END_DATE_ACTIVE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'STATUS')) {
                                parser.nextToken();
                                System.debug('========================================STATUS '+parser.getText());
                                j.STATUS.add(parser.getText());
                            }
                            //End of Changes
                            i = 0;
                        }
                    }
                    
                    //Syste
            
                    Integer rowNum = 0;
                    
                    for(Jsonparsercls row:JsonparserclsList){
                        searchResultsWrapper SRW = new searchResultsWrapper();
                        SRW.rowNum = string.valueOf(rowNum);
                        SRW.partyName = row.PARTY_NAME;
                        SRW.partyNumber = row.PARTY_NUMBER;
                        SRW.partyType = row.PARTY_TYPE;
                        SRW.partyTier = '';
                        SRW.DUNSNumber = row.DUNS_NUMBER;
                        SRW.PARTY_SITE_NUMBER = row.PARTY_SITE_NUMBER;
                        SRW.ADDRESS1 = row.ADDRESS1;
                        SRW.ADDRESS2 = row.ADDRESS2;
                        SRW.CITY = row.CITY;
                        SRW.COUNTY = row.COUNTY;
                        SRW.STATE = row.STATE;
                        SRW.PROVINCE = row.PROVINCE;
                        SRW.COUNTRY = row.COUNTRY;
                        SRW.POSTAL_CODE = row.POSTAL_CODE;
                        SRW.IdentifyingAddress = row.ADDRESS1;
                        //Code added under US55762- pbanik@redhat.com
                        SRW.TaxReference = row.TAX_REFERENCE;
                        //End of changes
                        SRW.IdentifyingAddress += row.ADDRESS2 != '' ? ' '+row.ADDRESS2 : '';
                        SRW.IdentifyingAddress += row.CITY != '' ? ', '+row.CITY : '';
                        //SRW.IdentifyingAddress += row.COUNTY != '' ? ', '+row.COUNTY : '';
                        SRW.IdentifyingAddress += row.STATE != '' ? ', '+row.STATE : '';
                        SRW.IdentifyingAddress += row.PROVINCE != '' ? ', '+row.PROVINCE : '';
                        SRW.IdentifyingAddress += row.COUNTRY != '' ? ', '+row.COUNTRY : '';
                        SRW.IdentifyingAddress += row.POSTAL_CODE != '' ? ', '+row.POSTAL_CODE : '';
                        SRW.phone = row.PHONENO;
                        String salesforceLinks = '';
                        for(Integer ii = 0; ii < row.ORIG_SYSTEM.size(); ii++){
                            if(row.ORIG_SYSTEM[ii] == 'SFDC'){
                                List<String> salesforceIDs = new List<String>();
                                salesforceIDs = row.ORIG_SYSTEM_REFERENCE[ii].split('_');
                                System.Debug('Split Osr----->'+salesforceIDs[0]);
                                salesforceLinks += salesforceLinks == '' ? salesforceIDs[0] : ','+salesforceIDs[0]; 
                            }
                        }
                        SRW.relatedLinks = salesforceLinks ;
                        String partnerCode = '';
                        List<String> partnerCodes= new List<String>();
                        for(Integer ii = 0; ii < row.CLASS_CATEGORY.size(); ii++){
                            
                            System.debug ('Partner ---->'+row.CLASS_CATEGORY[ii]) ;
                            System.debug ('new data ---->'+row.CLASS_CODE[ii]+' : '+ row.CLASS_CODE_DESCRIPTION[ii]) ;
                            if(row.CLASS_CATEGORY[ii] == 'Partner'){
                                if(row.CLASS_CODE[ii] != '')
                                {
                                    
                                    System.debug ('new data ---->'+row.CLASS_CODE[ii]+' : '+ row.CLASS_CODE_DESCRIPTION[ii]) ;
                                    if (ii < row.CLASS_CATEGORY.size()-1)
                                    {
                                        partnerCodes.add(row.CLASS_CODE_DESCRIPTION[ii] +';');
                                    }
                                    else
                                    {
                                        partnerCodes.add( row.CLASS_CODE_DESCRIPTION[ii]);
                                    }
                                    
                                 } 
                            }    
                        }
                        
                        
                        
                        SRW.partnerCodes = partnerCodes ;
                        System.debug('========================================partnerCodes  '+partnerCodes );
                        System.debug('========================================partnerCode  '+partnerCode );
                        searchResultsWrapperList.add(SRW);   
                        searchResultsWrapperMap.put(rowNum,SRW);
                        rowNum ++;
                    }
                    
                }else{
                    showButtons = true; 
                    DisplayMDMResults = true;
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage);  // set the exception message
                    ApexPages.addMessage(Message); 
                    return null;
                }    
                
                
                //if(searchResultsWrapperList.size() > 0)
                
                /* To parse the response received from Middleware and show it to the user in the list ends*/        
            }else{
                showButtons = true; 
                DisplayMDMResults = true;
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'No Data returned');  // set the exception message
                ApexPages.addMessage(Message); 
                return null;
            }
            
            showButtons = true; 
            DisplayMDMResults = true;
        }else if(res.getStatus() == 'Bad Request'){
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Records could not be retrieved for the search criteria provided');  // set the exception message
            ApexPages.addMessage(Message); 
        }else{
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'CDH system is down, please try later.');  // set the exception message
            ApexPages.addMessage(Message); 
        }
        
        return null;
     }
     
     
     /*
     * Method name  : createAccountWithUserSelected
     * Description  : Method to create an Account with a record found from customer data hub
     * Return Type  : pagereference
     * Parameter    : NA
     */
    public pageReference redirectAccountUrl(){
        string selectedCDHAccount = Apexpages.currentpage().getParameters().get('selectedCDHAccount');
        string recordTypeId = Apexpages.currentpage().getParameters().get('recordTypeId');
        string CDHPartyNumber = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyNumber;
        string CDHPartyType = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyType;
        List<CDH_Party__c> CDHPartyList = [select Id,Name from CDH_Party__c where Name = :CDHPartyNumber limit 1];
        string CDHPartyNumberId;
        string CDHPartyName;
        CDH_Party__c newCDHRecord;
        if(CDHPartyList.size() > 0){
            CDHPartyNumberId = string.valueOf(CDHPartyList[0].id);
            CDHPartyName = CDHPartyList[0].Name;
        }else{
            newCDHRecord = new CDH_Party__c(Name = CDHPartyNumber,CDH_Party_Number_Ext__c = CDHPartyNumber,CDH_Party_Type__c = CDHPartyType);
            try{
                insert newCDHRecord;
                CDHPartyName = CDHPartyNumber;
                CDHPartyNumberId = string.valueOf(newCDHRecord.id);   
            }catch(Exception e){
                System.debug('------------------>'+e);
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error inserting CDH Record');  // set the exception message
                ApexPages.addMessage(Message); 
                return null;        
            }    
        }
        /***************************************
        //searchResultsWrapperMap.get(selectedCDHAccount);
        /*string urlToBeRedirected = '/001/e?retURL=%2F001%2Fo&RecordType='+recordTypeId+'&nooverride=1';
        urlToBeRedirected += '&'+AccountFields__c.getValues('accountName').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyName;
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).IdentifyingAddress != null ? '&'+AccountFields__c.getValues('IdentifyingAddress').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).IdentifyingAddress : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS1 != null ? '&'+AccountFields__c.getValues('Address1').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS1 : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS2 != null ? '&'+AccountFields__c.getValues('Address2').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS2 : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).CITY != null ? '&'+AccountFields__c.getValues('City').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).CITY : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTY != null ? '&'+AccountFields__c.getValues('County').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTY : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).STATE != null ? '&'+AccountFields__c.getValues('State').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).STATE : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).PROVINCE != null ? '&'+AccountFields__c.getValues('Province').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).PROVINCE : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY != null ? '&'+AccountFields__c.getValues('Country').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).POSTAL_CODE != null ? '&'+AccountFields__c.getValues('PostalCode').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).POSTAL_CODE : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).phone != null ? '&'+AccountFields__c.getValues('Phone').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).phone : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber != null ? '&'+AccountFields__c.getValues('DUNSNumberCustom').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber : '';
        urlToBeRedirected += searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber != null ? '&'+AccountFields__c.getValues('DUNSNumberStd').fieldId__c+'='+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber : '';
        urlToBeRedirected += '&'+AccountFields__c.getValues('CDHPartyLookupName').fieldId__c+'='+CDHPartyName;
        urlToBeRedirected += '&'+AccountFields__c.getValues('CDHPartyLookupId').fieldId__c+'='+CDHPartyNumberId;
        
        pageReference page = new pageReference(urlToBeRedirected);
        return page;
        *******************************************/
        System.debug('-----------------searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY : '+searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY+'-------');
        // Create a savepoint while accountRecord is null
        Savepoint sp = Database.setSavepoint();
        Account accountRecord = new Account(Name = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyName,
                                            phone = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).phone,
                                            DunsNumber = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber,
                                            D_U_N_S__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).DUNSNumber,
                                            VATNumber__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).TaxReference,
                                            recordTypeId = recordTypeId,
                                            CDH_Party_Name__c = Id.valueOf(CDHPartyNumberId),
                                            BillingCountry = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY != null ? searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY : 'US'         
                                );
        try{
            insert accountRecord;
            
        }catch(Exception e){
            // Rollback if account is not created because of any exception or any error
            Database.rollback(sp);
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'Error in creating SalesAccount');  // set the exception message
            ApexPages.addMessage(Message); 
            return null;    
        }
        if(accountRecord.Id != null){
            Address__c addressRecord = new Address__c(Address_Line1__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS1,
                                                      Address_Line2__c= searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).ADDRESS2,
                                                      City__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).CITY,
                                                      County__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTY,
                                                      State__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).STATE,
                                                      Province__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).PROVINCE,
                                                      Country__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).COUNTRY,
                                                      Zip_Postal_Code__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).POSTAL_CODE,
                                                      Sales_Account__c = accountRecord.Id,
                                                      CDH_Party__c =  Id.valueOf(CDHPartyNumberId),
                                                      CDH_Party_Site_Number__c = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).PARTY_SITE_NUMBER,
                                                      Identifying_Address__c = true,
                                                      Bill_To_Address__c = true,
                                                      Status__c = 'Active'
                                                     );
             System.debug('----------------addressRecord '+addressRecord);
            try{
                insert addressRecord;
            }catch(Exception e){
                // Rollback if address record is not created.
                Database.rollback(sp);
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'Error in creating Address');  // set the exception message
                ApexPages.addMessage(Message); 
                return null;    
            }     
        }
        pageReference page = new pageReference('/'+accountRecord.Id);
        page.setRedirect(true);
        return page;
    }
    
    
    // Wrapper class for displaying search results after parsing the JSOn returned from Search functionality
    public class searchResultsWrapper{
        public string rowNum{get;set;}
        public string partyName{get;set;}
        public string partyNumber{get;set;}
        public string partyType{get;set;}
        public string partyTier{get;set;}
        public string DUNSNumber{get;set;}
        public String PARTY_SITE_NUMBER{get;set;}
        public string IdentifyingAddress{get;set;}
        public string TaxReference{get;set;}
        public string phone{get;set;}
        public string relatedLinks{get;set;}
        public List<string> partnerCodes{get;set;}
        public String ADDRESS1{get;set;}
        public string ADDRESS2 {get;set;}
        public String CITY{get;set;}
        public string COUNTY {get;set;}
        public String STATE{get;set;}
        public string PROVINCE{get;set;}
        public String COUNTRY{get;set;}
        public string POSTAL_CODE {get;set;}
        public string classification {get;set;}
    } 
     
    // Get the CDH - Salesforce records.   
    @RemoteAction 
    public static string showAccounts(String CDHAccounts){
        // split the CDHAccounts
        List<String> CDHAccountsSplit = CDHAccounts.split(','); 
        
        List<AccountWrapper> AccountWrapperList = new List<AccountWrapper>();
        for(Account a: [select id, Name, Owner.Name,Owner.Email,CDH_Party_Name__c,CDH_Party_Name__r.Name,Identifying_Address__c,// BillingAddress,
        BillingCity,BillingCountry,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,BillingStreet,RecordType.Name 
                from Account where Id in :CDHAccountsSplit]){
            AccountWrapper aw = new AccountWrapper();
            aw.id = string.valueOf(a.id);
            aw.name = a.Name;
            aw.ownerName = a.Owner.Name;
            aw.ownerEmail = a.Owner.Email;
            aw.CDHPartyNumber = a.CDH_Party_Name__r.Name != null ? a.CDH_Party_Name__r.Name : '';
            aw.RecordName=a.RecordType.Name;
            //aw.identifyingAddress = a.Identifying_Address__c != null ? a.Identifying_Address__c : '';
            aw.identifyingAddress =(a.BillingStreet != null ? a.BillingStreet : '')+', '+
                                    (a.BillingCity != null ? a.BillingCity : '')+' ,'+
                                    (a.BillingState != null ? a.BillingState : '')+', '+
                                    (a.BillingCountry != null ? a.BillingCountry : '')+' ,'+
                                    (a.BillingPostalCode != null ? a.BillingPostalCode : '');
            AccountWrapperList.add(aw);
        } 
        AccountDetailsJSON = JSON.serialize(AccountWrapperList);
        return AccountDetailsJSON;
    }
    
    
   
    // Wrapper class for settinig account details for CDH Party Record
    public class AccountWrapper{
        public string id{get;set;}
        public string name{get;set;}
        public string ownerName{get;set;}
        public string ownerEmail{get;set;}
        public string CDHPartyNumber{get;set;}
        public string identifyingAddress{get;set;}
        public string RecordName{get;set;}
    }
   
    // Wrapper class for getting record type details accessible for current logged in 
    public class recordTypeWrapper{
        public string recordTypeId;
        public string recordTypeName;    
    }
    
    
    /**************************************************
        New Way to parse JSON
        Wrapper class for parsing the JSON Class
    **************************************************/
    
    public class Jsonparsercls{  
      public String PARTY_NAME{get;set;}
      public string PARTY_NUMBER{get;set;}
      public String PARTY_TYPE{get;set;}
      public string DUNS_NUMBER{get;set;}
      public String PARTY_SITE_NUMBER{get;set;}
      public String TAX_REFERENCE{get;set;}
      public String ADDRESS1{get;set;}
      public string ADDRESS2 {get;set;}
      public String CITY{get;set;}
      public string COUNTY {get;set;}
      public String STATE{get;set;}
      public string PROVINCE{get;set;}
      public String COUNTRY{get;set;}
      public string POSTAL_CODE {get;set;}
      public string PHONENO{get;set;}
      public List<String> ORIG_SYSTEM {get;set;}
      public List<string> ORIG_SYSTEM_REFERENCE{get;set;}
      public List<string> CLASS_CODE{get;set;}
      public List<string> CLASS_CODE_DESCRIPTION{get;set;}
      public List<string> CLASS_CATEGORY{get;set;}
      public List<string> PRIMARY_FLAG{get;set;}
      public List<string> START_DATE_ACTIVE{get;set;}
      public List<string> END_DATE_ACTIVE{get;set;}
      public List<string> STATUS{get;set;}
    }
    
    
    /**************************************************
       END OF New Way to parse JSON
        Wrapper class for parsing the JSON Class
    **************************************************/
 
    
    /**************************************************************************************************************************************************************** 
      
    /*public pagereference SearchSFDCData()
    {   
        
        strquery = 'select id,Name,phone,website,billingstreet,billingcity,billingstate,billingpostalcode,billingcountry,OraclePartyNumber__c,Owner.Email,DunsNumber,Type,Finder_Partner_Tier_Name__c from Account';
        try{

            if(AccName!=null && AccName!='')
            strquery += ' where Name like \'%' + AccName.trim()+ '%\''; 
            System.debug(strquery);
            if(street!=null && street!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and '+'billingstreet like \'%' + street.trim()+ '%\''; 
                else
                strquery += ' where billingstreet like \'%' + street.trim()+ '%\''; 
            }            
            if(PartyNo!=null && PartyNo!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and '+'OraclePartyNumber__c like \'%' + PartyNo.trim()+ '%\''; 
                else
                strquery += ' where OraclePartyNumber__c like \'%' + PartyNo.trim()+ '%\''; 
            }
            System.debug(strquery);
            if(city!=null && city!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and billingcity like \'%' + city.trim()+ '%\'';
                else
                strquery += ' where billingcity like \'%' + city.trim()+ '%\'';
            }
            System.debug(strquery);
            if(state!=null && state!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and billingstate like \'%' + state.trim()+ '%\'';
                else
                strquery += ' where billingstate like \'%' + state.trim()+ '%\'';
            }
            System.debug(strquery);
            if(country!=null && country!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and billingcountry like \'%' + country.trim()+ '%\'';
                else
                strquery += ' where billingcountry like \'%' + country.trim()+ '%\'';        
            }
            System.debug(strquery);
            if(postalcode!=null && postalcode!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and billingpostalcode like \'%' + postalcode.trim()+ '%\'';
                else
                strquery += ' where billingpostalcode like \'%' + postalcode.trim()+ '%\'';
            }
            System.debug(strquery);
            if(StrDUNSNumber!=null && StrDUNSNumber!=''){
                if(strquery.indexof('where')>0)
                strquery += ' and DunsNumber like \'%' + StrDUNSNumber.trim()+ '%\'';
                else
                strquery += ' where DunsNumber like \'%' + StrDUNSNumber.trim()+ '%\'';
            }
            strquery += ' limit 1000';
            System.debug(strquery);
            
            
            
            if(strquery!=null && strquery!='')
            accountlist = Database.query(strquery);
            
            IdentifyingAddress = accountlist[0].billingstreet + ', ' +accountlist[0].billingcity + ', ' + accountlist[0].billingstate + ', ' + accountlist[0].billingcountry + ', ' + accountlist[0].billingpostalcode;
            
            displaysearchbutton = true;
            if(accountlist!=null && accountlist.size()>0){
                DIsplayResults = true;
                //NoResultsDisplay = false;
               DisplayMDMResults = false;
                //displaycreateselected=true; //added by pardeep to display create new button
               }
            else{
                DIsplayResults = false;
                //NoResultsDisplay = true;
                DisplayMDMResults = false;
                //displaycreateselected=true; //added by pardeep to display create new button
            }    
        }
        catch(Exception ex)
        {
            system.debug(ex);
            system.debug(ex.getStackTraceString());
            Apexpages.addMessages(ex);
            return null;
        }
        return null;
     }*/
     
    /*****************************************************************************************************************************/ 
     
}