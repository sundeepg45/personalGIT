/*****************************************************************************************
    Name    : CustomLeadConversionController 
    Desc    : Used in the Custom Lead conversion page which includes all the functionality used in custom lead
              conversion process
              
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
Sunay Prasad R K       12/06/2014          Created
Pankaj Banik           22/09/2014          Edited - Added code under US55762
Scott Coleman          02-Mar-2014         Edited to add alternate flow for lead dev users to LeadConvertWizard.page
******************************************************************************************/
public with sharing class CustomLeadConversionController {
    public id leadid;
    public id orgid{get;set;}
    public id tempid{get;set;} 
    
    public lead leadobjvar{get;set;}
    public lead leadobj{get;set;}
    public Task Taskobj{get;set;}
    public Event Eventobj{get;set;}
    public String strquery;       
    public integer count;
    public String AccName{get;set;}
    public String AliasName{get;set;}
    public Boolean AliasFlag{get;set;}
    public String PartyNo{get;set;}
    public String Street{get;set;}
    public String city{get;set;}
    public String postalcode{get;set;}
    public String country{get;set;}
    public String state{get;set;}
    public list<account> accountlist{get;set;}
    
    //Added as aper User Story US55762
    //pbanik@redhat.com
    public Boolean displaysearchbutton{get;set;}
    public Boolean DIsplayResults{get;set;}
    public String StrDUNSNumber{get;set;}
    public String selectedSearchOption{get;set;}
    public List<SelectOption> searchOptionList{get;set;}
    
    //parameters for redendering page components
    public Boolean partyNameComponentRenderFlag{get;set;}
    public Boolean partyNumberComponentRenderFlag{get;set;}
    public Boolean dunsNoComponentRenderFlag{get;set;}
    public Boolean searchComponentRenderFlag{get;set;}
    //end of changes
    
    public String SelUserValue{get;set;}
    public String SelUserValueID{get;set;}
    public String SelAccountName{get;set;}
    public String SelContactName{get;set;}
    public String StrAccountId{get;set;}
    public String BaseUrlVar{get;set;}
    public String stroppname{get;set;}
    public String strconverStatus{get;set;}
    public String StrSubject{get;set;}
    public String StrComments{get;set;}
    public String selectedtime{get;set;}
    public String StrAddress1{get;set;}
    public String StrAddress2{get;set;}
    public String StrAddress3{get;set;}
    public String StrAddress4{get;set;}
    public String Strcity{get;set;}
    public String Strstate{get;set;}
    public String Strcountry{get;set;}
    public String Strpostalcode{get;set;}
    public String strCountryCode{get;set;}
    public Boolean NoResultsDisplay{get;set;}
    //values to get from customer master data
    public String StrAccountName{get;set;}
    public String straddress{get;set;}
    public String SelAccId{get;set;}
    public String strleadphone{get;set;}
    public String Strleadcompany{get;set;}
    public String StrLeadNmae{get;set;}
    public Boolean customerDataHubRecord{get;set;}
    public Boolean duplicateContact{get;set;}
    public Boolean AttchtoExisting{get;set;}
    public Boolean AttachtoConExisting{get;set;}
    public Boolean OppConExisting{get;set;}
    public String compName{get;set;}
    public Boolean dupeCon{get;set;}
    public Boolean setConID{get;set;}
    
    public Boolean convertAssets{get;set;} 
    public Boolean stopAction{get;set;} 
    public Boolean ischecked{get;set;}
    public Boolean createOpp{get;set;}
    public Boolean SendNotificMail{get;set;} 
    public Boolean Setreminder{get;set;} 
    public Boolean displayPopup {get; set;}
    public Boolean DisplaySearchMDMDataPage{get;set;}  
    public Boolean DisplayCreateLeadPage{get;set;}
    public Boolean displayMDMResults{get;set;}
    public Boolean SelAccName{get;set;}
    public Boolean AccSelectedByUser;
    public Boolean Setcontinueuserselection;
    public Boolean SetCreatenewAccount;
    public Boolean DispEnterAddressFields{get;set;}
    public Boolean showCompAssetsPopUp{get;set;}
    public String Changedpicklistval{get;set;}
    public List<SelectOption> conOptions{get;set;}
    
    public list<wrappersearchresults> wrapperlist{get;set;}
    public List<SelectOption> options{get;set;}
    public List<clsLeadWrapper> compAssetsLeadList{get;set;}
    public Boolean InactiveUser = false;
    public Boolean validation = false;//Used to avoid lead conversion in case of errors
    public User u;
    public class myexception extends Exception{}
    public String JsonString;
    public String name;
    public String sicDesc;
    public String billlingstreet;
    public String billlingcity;
    public String billlingstate;
    public String billlingcountry;
    public String partynumber;
    public String billingpostalcode;
    
    public map<Integer,searchResultsWrapper> searchResultsWrapperMap{get;set;}
    public List<searchResultsWrapper> searchResultsWrapperList{get;set;}
    public List<recordTypeWrapper> availableAccountTypes{get;set;}
    
    public String sbcUrlString; 
    
    // Static JSON String for showing Account Details
    public static String AccountDetailsJSON {get;set;} 
    public List<SelectOption> countryCodeSelectList{get;set;}
    public Boolean showButtons{get;set;}
    public Jsonparsercls j{get;set;}
    public String AccountRecordTypesJSON {get;set;} 
    
    map<String,Task> TaskObjMap = new map<String,Task>(); 
    
    
    public List<SelectOption> stateList{get;set;}
    public Map<String,List<State__c>> countryStateMap{get;set;}
    public Map<String, States_ISO_codes__c> stateISOCodes = new Map<String, States_ISO_codes__c>();
    public map<id,user> userDetailsMap{get;set;}
    
    
    //Standard constructor to get data on page load
    public CustomLeadConversionController(ApexPages.StandardController controller) {
        
        //Added as aper User Story US55762
        //pbanik@redhat.com
        //Setting values of flag to display search page to default search type No 3
        selectedSearchOption = '3';
        searchComponentRenderFlag = true ;
        partyNameComponentRenderFlag = true ;
        partyNumberComponentRenderFlag = false;
        dunsNoComponentRenderFlag = false;
        AliasFlag = false;
        
        // Add list options for search options
        searchOptionList = new List<SelectOption>();
        searchOptionList.add(new SelectOption('1','Search using Party Number'));
        searchOptionList.add(new SelectOption('2','Search using DUNS Number'));  
        searchOptionList.add(new SelectOption('3','Search using Customer Information'));
        // End of Changes
        
        stateList = new List<SelectOption>();
        countryCodeSelectList = new List<SelectOption>();  
        availableAccountTypes = new List<recordTypeWrapper>();
        availableAccountTypes = GetAvailableRecordTypeNamesForSObject(Account.SObjectType);  
        AccountRecordTypesJSON = JSON.serialize(availableAccountTypes);
        countryCodeSelectList.add(new SelectOption('--None--', '--None--'));
        //Map<String, RH_CountryCode_CountryName__c> countries = RH_CountryCode_CountryName__c.getAll();
        Map<String, Country__c> countries = new Map<String, Country__c>();
        for(Country__c country : [select Id,Name,Iso3166Alpha2__c,Address_Style__c, (select Id,Name from States__r) from Country__c]){
            countries.put(country.Name, country);
        }
        countryStateMap = new Map<String,List<State__c>>(); // country vs state map
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
        
        
        //orgid = UserInfo.getOrganizationId();
        // BaseUrlVar = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        duplicateContact = false;
        showCompAssetsPopUp = false; 
        convertAssets = false;
        
        
        this.leadobjvar = (Lead)controller.getRecord();
        
        leadid = Apexpages.currentpage().getParameters().get('id');   
        if(leadid!=null){        
            leadobj = [select id,Name,FirstName,LastName,Industry,Email,Company,ownerid,street,city,state,postalcode,country,Phone from lead where id=:leadid];
        }
        
        userDetailsMap = new map<id,user>();
        for(User userDetails:[select id, Name, isActive from User where id = :leadobj.ownerid or id = :UserInfo.getUserId()]){
            userDetailsMap.put(userDetails.id,userDetails);
        } 
        
        if(leadobj!=null ) 
        {   
            /*integer count = [select count() from User where IsActive=true And id=:leadobj.ownerid];
            if(count>0)          
                SelUserValue = [select id,Name,IsActive from User where IsActive=true And id=:leadobj.ownerid].Name;
            else
                //InactiveUser = true;
                SelUserValue = [select id,Name,IsActive from User where IsActive=true And id=:UserInfo.getUserId()].Name;
            */
            if(userDetailsMap.get(leadobj.ownerid) != null){
                if(userDetailsMap.get(leadobj.ownerid).isActive == true){
                    SelUserValue = userDetailsMap.get(leadobj.ownerid).Name;
                    SelUserValueID = String.valueOf(leadobj.ownerid);
                }
            }else{
                SelUserValue = UserInfo.getName();
                SelUserValueID = String.valueOf(UserInfo.getUserId());
            }
            //strcountry = leadobj.country; 
        }   
        
        // u = [Select id,Name from User where id=:UserInfo.getUserId()];
        
        if(leadid!=null)
        {   
            Taskobj = new task();
            Eventobj = new Event();
            stroppname = leadobj.company;
            
            
            StrLeadNmae = leadobj.Name;
            Strleadcompany = leadobj.Company;
            strleadphone = leadobj.Phone;
            Strcity = leadobj.city;
            Strstate = leadobj.state;
            Strcountry = leadobj.country;
            Strpostalcode = leadobj.postalcode;
            //strCountryCode = leadobj.Country_Code__c;
            
            
            integer count = [select count() from Account where name=:leadobj.company];
            //if(count>0)
            //{
                DisplaySearchMDMDataPage=false;
                DisplayCreateLeadPage = true;
            /*}
            else
            {            
                 DisplaySearchMDMDataPage=true;
                DisplayCreateLeadPage = false;
            }*/
            prepareaccounts();
            preparecontacts();
            DispEnterAddressFields = false;
            //DisplayUserErrors();
            //system.debug('Changedpicklistval===='+Changedpicklistval); 
        }
    }

    /**
     * Redirect to the lead conversion wizard if user and lead meet the following criteria (per story US63288):
     *  - User record has the Lead Dev User checkbox checked (API name Is_Marketing_User__c)
     *  - Lead is in stage Marketing Accepted or Marketing Qualified
     *  - Lead has record type Lean Gen, APAC Sales, EMEA Sales, LATAM Sales, or NA Sales
     * @return a PageReference that redirects to LeadConvertWizard.page or null
     */
    public PageReference marketingLeadDevRedirect() {
        System.debug('+++ in marketingLeadDevRedirect()');
        PageReference retval = null;
        if(Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(leadobjvar.RecordTypeId)
            && (leadobjvar.Stage__c == Lead_GlobalManagement.MARKETING_ACCEPTED || leadobjvar.Stage__c == Lead_GlobalManagement.MARKETING_QUALIFIED)
            && Lead_GlobalManagement.getCurrentUser().Is_Marketing_User__c) {

            retval = new PageReference('/apex/LeadConvertWizard');
            retval.getParameters().putAll(ApexPages.currentPage().getParameters());
            retval.getParameters().put('retURL','/'+leadobjvar.Id);
            retval.setRedirect(true);
        }
        return retval;
    }    
    
    //Added as aper User Story US55762
    //pbanik@redhat.com
    /*
     * Method name  : searchTypeSelection
     * Description  : Method used to set the Search before create page layouts and default search options
     * Return Type  : pagereference
     * Parameter    : NA
     */
    public pageReference searchTypeSelection()
    {
        System.Debug('inside Search type----> '+ selectedSearchOption);
        
        // if search type is on Party Name
        if (selectedSearchOption == '3')
        {
            
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
    //End of Changes
    
    /*
     * Method name  : prepareaccounts
     * Description  : Method used to get the accounts based on the lead company name and show it as the attach to existing option
     * Return Type  : List<SelectOption>
     * Parameter    : NA
     */
    public List<SelectOption> prepareaccounts() {
            String strAccountName,strAccountName2,strAccountName3;
            String NewAccName;
            String splitAccName;
            String strAccountName1 = leadobj.company;
            options = new List<SelectOption>();
            List<String> existingaccList = new List<String>();
            List<Account> accountList;
            //integer count = [select count() from Account where name=:strAccountName and BillingStreet  = : leadobj.street and BillingCity = : leadobj.city and BillingState = :leadobj.state and BillingPostalCode =:leadobj.postalcode and BillingCountry =: leadobj.country ];
           /* if(SelAccId!=null && SelAccId!=''  && AccSelectedByUser == true)
            {
                integer AcCount = [select count() from Account where Name=:SelAccId];
                if(AcCount>0)
                {
                    NewAccName = [select Name from Account where Name=:SelAccId].Name;
                    strAccountName3 = 'Create New Account : '+NewAccName;
                }
                 if(strAccountName3!=null && strAccountName3!='')
                    options.add(new SelectOption(strAccountName3,strAccountName3));
                    stroppname = NewAccName;
            }
            else{*/
            system.debug('changedvalue========'+changedvalue);
                if(changedvalue!=null && changedvalue!='')
                {
                    
                    integer AcCount = [select count() from Account where Name LIKE :changedvalue+'%'];
                    if(AcCount>0)
                    {
                        //NewAccName = [select Name from Account where Name=:changedvalue limit 1].Name;
                        //strAccountName3 = 'Attach to Existing: '+NewAccName;
                        for(Account acc:[select Name from Account where Name LIKE :changedvalue+'%' order by lastmodifiedDate Desc limit 990]){
                            existingaccList.add(acc.Name);
                            //strContactName = 'Attach to Existing : '+existingConName;
                        } 
                        for(String str:existingaccList){
                            strAccountName3 = 'Attach to Existing: '+str;
                            options.add(new SelectOption(strAccountName3,strAccountName3));
                        }
                    }
                     //if(strAccountName3!=null && strAccountName3!='')
                       // options.add(new SelectOption(strAccountName3,strAccountName3));
                        
                        preparecontacts();
                }
            
                integer count = [select count() from Account where name LIKE :leadobj.company+'%'];
                if(count>0)
                {
                    strAccountName2 = 'Create New Account: '+strAccountName1;
                    accountList = [Select Name from Account where Name LIKE :leadobj.company+'%' order by lastmodifiedDate Desc limit 990];
                    for(Account acc:accountList){
                        existingaccList.add(acc.Name);
                        //strContactName = 'Attach to Existing : '+existingConName;
                    } 
                    System.debug(existingaccList);
                    for(String str:existingaccList){
                        strAccountName = 'Attach to Existing: '+str;
                        options.add(new SelectOption(strAccountName,strAccountName));
                    }
                    //strAccountName = 'Attach to Existing: '+strAccountName1;
                }
                else{
                    strAccountName = 'Create New Account: '+strAccountName1;                               
                    
                    options.add(new SelectOption(strAccountName,strAccountName));
                }    
                if(strAccountName2!=null && strAccountName2!='')
                options.add(new SelectOption(strAccountName2,strAccountName2));
            //}
                
            system.debug('options====='+options);
            return options;
     }
    
    /*
     * Method name  : preparecontacts
     * Description  : Method used to get the accounts based on the lead company name and show it as the attach to existing option
     * Return Type  : List<SelectOption>
     * Parameter    : NA
     */
    public List<SelectOption> preparecontacts() {
            String strContactName,strContactName2,strContactName3;
            String NewConName;
            String existingConName;
            String FirstNewConName;
            String SecondNewConName;
            String strContactName1;
            if(leadobj.FirstName!=Null)
                strContactName1 = leadobj.FirstName + ' ' + leadobj.LastName;
            else
                strContactName1 = leadobj.LastName;
            conOptions = new List<SelectOption>();
            List<String> existingconList = new List<String>();
            integer count;          
            List<Contact> contactList;
            
                if(changedConvalue!=null && changedConvalue!='')
                {
                    
                    integer ConCount = [select count() from Contact where Name=:changedConvalue];
                    if(ConCount>0)
                    {
                        //FirstNewConName = [select Name from Contact where Name=:changedConvalue limit 1].FirstName; 
                        //SecondNewConName = [select Name from Contact where Name=:changedConvalue limit 1].LastName;
                        //if(FirstNewConName!=null)
                           // NewConName = FirstNewConName + ' ' + SecondNewConName;
                       // else
                           // NewConName = SecondNewConName;
                        for(Contact con:[select Name,FirstName,LastName from Contact where Name=:changedConvalue]){
                            if(con.FirstName!=null)
                                existingconList.add(con.FirstName + ' ' + con.LastName);
                            else
                                existingconList.add(con.LastName);
                            //strContactName = 'Attach to Existing : '+existingConName;
                        } 
                        for(String str:existingconList){
                            strContactName3 = 'Attach to Existing: '+str;
                            conOptions.add(new SelectOption(strContactName3,strContactName3));
                        }
                        //System.debug(NewConName);
                        //strContactName3 = 'Attach to Existing: '+NewConName;
                    }
                     //if(strContactName3!=null && strContactName3!='')
                        //conOptions.add(new SelectOption(strContactName3,strContactName3));
                }
                if(SelAccId != NULL)
                     count = [select count() from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName)];
                else if(changedvalue == null)
                     count = [select count() from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name =:leadobj.Company];
                else if(compName != null)
                     count = [select count() from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name =:compName];
                else
                     count = [select count() from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name =:changedvalue];
                
                if(count>0)
                {
                    if(SelAccId != NULL)
                         contactList = [select Name,FirstName,LastName from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName)];
                    else if(changedvalue == null)
                         contactList = [select Name,FirstName,LastName from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name = :leadobj.Company];
                    else if(compName != null)
                         contactList = [select Name,FirstName,LastName from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name =:compName];
                    else
                        contactList = [select Name,FirstName,LastName from Contact where (FirstName=:leadobj.FirstName OR LastName=:leadobj.LastName OR FirstName=:leadobj.LastName OR LastName=:leadobj.FirstName) AND Account.Name = :changedvalue];
                    
                    strContactName2 = 'Create New Contact: '+strContactName1;
                    for(Contact con:contactList){
                        if(con.FirstName!=null)
                            existingconList.add(con.FirstName + ' ' + con.LastName);
                        else
                            existingconList.add(con.LastName);
                        //strContactName = 'Attach to Existing : '+existingConName;
                    }   
                    System.debug('existingList===='+existingconList);
                    for(String str:existingconList){
                        strContactName = 'Attach to Existing: '+str;
                        conOptions.add(new SelectOption(strContactName,strContactName));
                    }
                }
                else
                strContactName = 'Create New Contact: '+strContactName1;                               
                
                //conOptions.add(new SelectOption(strContactName,strContactName));
                if(strContactName2!=null && strContactName2!='')
                conOptions.add(new SelectOption(strContactName2,strContactName2));
            //}
                
            system.debug('conOptions====='+conOptions);
            return conOptions;
     }
     
    /*
     * Method name  : gettimes
     * Description  : Method used to get the times to display in reminder section of the page
     * Return Type  : List<SelectOption>
     * Parameter    : NA
     */
    public List<SelectOption> gettimes() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('12:00 AM','12:00 AM'));
            options.add(new SelectOption('12:30 AM','12:30 AM'));
            for(integer i=1;i<24;i++)
            {
                if(i<12)
                {
                    String str = String.valueof(i)+':00 AM';
                    String str1 = String.valueof(i)+':30 AM';        
                    options.add(new SelectOption(str,str));
                    options.add(new SelectOption(str1,str1));
                }
                if(i>=12)
                {
                    if(i==12)
                    {
                        String str = String.valueof(i)+':00 PM';
                        String str1 = String.valueof(i)+':30 PM';        
                        options.add(new SelectOption(str,str));
                        options.add(new SelectOption(str1,str1));    
                    }
                    else{
                    integer p = i-12;
                     String str = String.valueof(p)+':00 PM';
                    String str1 = String.valueof(p)+':30 PM';        
                    options.add(new SelectOption(str,str));
                    options.add(new SelectOption(str1,str1));
                    }
                }
            }
            return options;
        }    
    
    /*
     * Method name  : cancel
     * Description  : Method used to redirect the page back when the user click on cancel
     * Return Type  : pageReference
     * Parameter    : NA
     */
    Public pagereference cancel(){
        pagereference p = new pagereference('/'+leadobj.id);
        p.setredirect(true);
        return p;
    }    
    
   
    
    /*
     * Method name  : continuetoPage
     * Description  : Method used to do the lead conversion by calling convert lead method
     * Return Type  : pageReference
     * Parameter    : NA
     */ 
    public pagereference continuetoPage(){        
        //system.debug('tempid====='+SelAccId);
        //DisplaySearchMDMDataPage=false;
        //DisplayCreateLeadPage = true;
        pagereference pageref;
        String URLvar;
        String str;
        try{
            SetCreatenewAccount = true;  
            dupecon = false;     
            pageref =  ConvertLead();
        }
        catch(exception ex)
        {
            Apexpages.addMessages(ex);
            pageref = null;
        }      
        return pageref;    
    }    
    
    /*
     * Method name  : convertFromContact
     * Description  : Method to call the convert lead method if a duplicate contact is found
     * Return Type  : pageReference
     * Parameter    : NA
     */
    public pagereference convertFromContact()
    {        
         pagereference pageref;
         try{
            if(AttachtoConExisting == false)
                AttchtoExisting = true;
            else
                AttchtoExisting = false;
                
            AttachtoConExisting = false;
            dupeCon = false;
            if(customerDataHubRecord == true)
                Setcontinueuserselection = true;
            duplicateContact = false;
            convertAssets = true;
            pageref =  ConvertLead();    
            return pageref;  
         }
         catch(Exception ex)
         {
            Apexpages.addMessages(ex);
            system.debug('exception======'+ex);
            system.debug('exception======'+ex.getstacktracestring());
            pageref=null;
         }
         return pageref;           
        
    }
    
    /*
     * Method name  : SearchCustomerMaster
     * Description  : Method used to search for Customer data in FCH server/Customer Data Hub
     * Return Type  : pageReference
     * Parameter    : NA
     */ 
    public pagereference SearchCustomerMaster()
    {
        showButtons = false;
        searchResultsWrapperMap = new Map<Integer,searchResultsWrapper>();
        searchResultsWrapperList = new List<searchResultsWrapper>();
        
        //Modified code as aper User Story US55762
        //pbanik@redhat.com
        String parmetersToBeSearched = '';
        if(country != null){
            List<String> countryListSplit = country.split(',');
            country = countryListSplit[0];
        }  
        
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
            parmetersToBeSearched += Street != '' ? '&address='+EncodingUtil.urlEncode(Street.trim(), 'UTF-8') : '';       
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
        //End of Changes
        
        parmetersToBeSearched = parmetersToBeSearched.substring(1, parmetersToBeSearched.length());
        //Getting Search before create URL from custom settings
        SearchBeforeCreateURL__c sbcCustomsetting = SearchBeforeCreateURL__c.getValues('CDH URL');
        sbcUrlString = sbcCustomsetting.Cdh_URL__c;
        
        String httpRequestString = sbcUrlString+parmetersToBeSearched;
        //httpRequestString = EncodingUtil.urlEncode(httpRequestString,'UTF-8');
        System.debug('--------URL------'+httpRequestString);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(httpRequestString);
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res;
        Boolean successResult = true;
        try{
            res = http.send(req);
            System.debug('------------------------------------------RES'+res);
        }catch(System.CalloutException e) { // callout exception
            successResult = false;
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
                    String errorStr = res.getBody();
                    System.debug('----------------1'+errorStr);
                }catch(Exception e){
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message); 
                    return null;        
                }
                try{
                    parser = JSON.createParser(res.getBody());
                    String errorStr = res.getBody();
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
                
                String errorMessage = '';
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
                            
                            //Added as aper User Story US55762
                            //pbanik@redhat.com
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
                        SRW.rowNum = String.valueOf(rowNum);
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
                        
                        //Added as aper User Story US55762
                        //pbanik@redhat.com
                        SRW.TaxReference = row.TAX_REFERENCE;
                        //End of Changes
                        
                        SRW.IdentifyingAddress = row.ADDRESS1;
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
                                salesforceLinks += salesforceLinks == '' ? salesforceIDs[0] : ','+salesforceIDs[0]; 
                            }
                        }
                        SRW.relatedLinks = salesforceLinks;
                        String partnerCode = '';
                        List<String> partnerCodes= new List<String>();
                        for(Integer ii = 0; ii < row.CLASS_CATEGORY.size(); ii++){
                            
                            if(row.CLASS_CATEGORY[ii] == 'Partner'){
                                if(row.CLASS_CODE_DESCRIPTION[ii] != '')
                                {
                                    if (ii < row.CLASS_CATEGORY.size()-1)
                                    {
                                        partnerCodes.add(row.CLASS_CODE_DESCRIPTION[ii]+';');
                                    }
                                    else
                                    {
                                        partnerCodes.add(row.CLASS_CODE_DESCRIPTION[ii]);
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
     * Method name  : COntinueWithUserSelection
     * Description  : Method to use the account retrieved from Customer data hub
     * Return Type  : pageReference
     * Parameter    : NA
     */
    public pagereference COntinueWithUserSelection()
    {
         AccSelectedByUser = true;
         customerDataHubRecord = false;
         dupecon = true;
         pagereference pageref;
         try{
            if(SelAccId == '' || SelAccId == NULL)
            throw new myexception('Please select An account to proceed with continue');
            Setcontinueuserselection = true;
            customerDataHubRecord = true;
            //OppConExisting = true;
            convertAssets = true;
            pageref =  ConvertLead();    
            return pageref;  
         }
         catch(Exception ex)
         {
            Apexpages.addMessages(ex);
            system.debug('exception======'+ex);
            system.debug('exception======'+ex.getstacktracestring());
            pageref=null;
         }
         return pageref;           
        
    }
    
     /*
     * Method name  : createAccountWithUserSelected
     * Description  : Method to create an Account with a record found from customer data hub
     * Return Type  : pagereference
     * Parameter    : NA
     */
    public pagereference createAccountWithUserSelected()
    {
        Account acc;
        pagereference p;
        try{
            
            JsonString = '{"NumberOfEmployees" : 0,"SicDesc" : "TestDesc21","AccountName" : "Kiersten Test Account","Phone" : "1234657890","Website" : "test.com","Fax" : "1234567890","YearStarted" : "2008","Id" : "001m0000004G4gWAAS","All_NAICS_Codes__c" : "123123232","VATNumber__c" : "12345","Sales_Account_type__c" : "TestType21","Sic" : "123243","Do_Not_Do_Business_With__c" : false,"IdentifyingAddress" : {"Bill_To_Address__c" : false,"Name" : "Add-0000005","Ship_To_Address__c" : false,"Entitle_To_Address__c" : false,"Id" : "a2Nm0000000096IEAQ","Identifying_Address__c" : false,"Sold_To_Address__c" : false}}';   
            
            JSONParser parser = JSON.createParser(JSONString);
            
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'AccountName')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    name = parser.getText();
                    
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'SicDesc')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    sicDesc = parser.getText();
                    System.debug('sicDesc'+sicDesc);
                }
            }
            
            if(name == SelAccId.trim()){
                acc = new Account();
                acc.Name = name;
                acc.SicDesc = sicDesc;
            }
            
            if(acc!=null)
                database.insert(acc);
                
            p = new pagereference('/'+acc.id);
        }
        catch(exception e){
            Apexpages.addMessages(e);
            return null;
        }
        
        p.setredirect(true);
        return p;
     
    } 
    
    
     /*
     * Method name  : createNewaccount
     * Description  : Method to create new Account if no data is found in customer data hub
     * Return Type  : pagereference
     * Parameter    : NA
     */
    public pagereference createNewaccount(){
        
        pagereference p;
        String URLvar;
         
         try{
            
                        
            URLvar = 'setup/ui/recordtypeselect.jsp?ent=Account&retURL=%2F001%2Fo&save_new_url=%2F001%2Fe%3FretURL%3D%252F001%252Fo&nooverride=1';
            
            
            if(AccName!=null && AccName!='')
            AccName = EncodingUtil.urlencode(AccName,'UTF-8');
            URLvar +='&'+Label.Account_Name_ID+'='+AccName; 
            
            if(country!=null && country!='')
            URLvar +='&'+Label.Country_In_Account+'='+country;
            
            if(PartyNo!=null && PartyNo!='')
            URLvar +='&'+Label.Party_Number_Id+'='+PartyNo;
            
            if(Street!=null && Street!='')
            URLvar +='&'+Label.Street_Address_Id+'='+Street;
            
             if(city!=null && city!='')
            URLvar +='&'+Label.City_Id+'='+city;
            
             if(postalcode!=null && postalcode!='')
            URLvar +='&'+Label.Postal_Code_Id+'='+postalcode;
            
             if(state!=null && state!='')
            URLvar +='&'+Label.State_Id+'='+state;
            
            //p = new pagereference('/'+'setup/ui/recordtypeselect.jsp?ent=Account&retURL=%2F001%2Fo&save_new_url=%2F001%2Fe%3FretURL%3D%252F001%252Fo&nooverride=1');
            p = new pagereference('/'+URLvar);
           
            p.setredirect(true);
        }
        catch(exception ex)
        {
            Apexpages.addMessages(ex);
            system.debug('exception ====='+ex);
            system.debug('exception ====='+ex.getStackTraceString());
            p = null;
        } 
        
        return p;
        //return null;
    }  
    
 
    
    /*
     * Method name  : ConvertLead
     * Description  : Method used to the convert the lead
     * Return Type  : pageReference
     * Parameter    : NA
     */
     
     Public pagereference ConvertLead(){
        Boolean createCon;
        Boolean convert;
        String accid;
        String struserid;
        String contactid;
        integer hourvar;
        integer minutevar;
        integer secondsvar = 0;
        integer millisecondsvar = 0;
        Database.LeadConvertResult lcr;
        Database.LeadConvert lc = new Database.LeadConvert();
        id straccid;
        pagereference p;
        displaysearchbutton = true;
        integer usercount = [select count() from user where IsActive=true And name=: SelUserValue AND UserRoleId != NULL];
        
        Id recordTypeId =null;
        for (Schema.RecordTypeInfo rtInfo : Account.SObjectType.getDescribe().getRecordTypeInfos()) {
        
            if (rtInfo.isDefaultRecordTypeMapping()) {
              recordTypeId =rtInfo.getRecordTypeId();
            }
        }
        
        if(usercount>0)
            struserid = SelUserValueID; //[select id,Name from user where IsActive=true And name=: SelUserValue AND UserRoleId != NULL].id;
        
        AttachtoConExisting = false; 
        createCon = false;   
        try{
            //Code to check if the user has selected to create new account or existing account
            if(SelAccountName!=null && SelAccountName!='' ){   
                if(SelAccountName.contains(':')){
                   String[] stracc = SelAccountName.split(':');
                   SelAccountName = stracc[1];
                   stracc[0] = stracc[0].trim();
                   if(stracc[0]!=null && stracc[0]!='' && stracc[0].equalsIgnoreCase('Attach to Existing') ){
                     AttchtoExisting = true;
                     dupecon = true;
                   } 
                   else
                     AttchtoExisting = false; 
                }else{
                    if(SetCreatenewAccount == true){
                        AttchtoExisting = false;
                    }
                }
            }
            
            //Code to check if the user has selected to create new contact or existing contact
            if(SelContactName!=null && SelContactName!=''){
                if(SelContactName.contains(':')){
                    String[] stracc = SelContactName.split(':');
                    SelContactName = stracc[1];
                    stracc[0] = stracc[0].trim();
                    if(stracc[0]!=null && stracc[0]!='' && stracc[0].equalsIgnoreCase('Attach to Existing') ){
                        AttachtoConExisting = true;
                        dupecon = true;
                    }    
                    else{
                        AttachtoConExisting = false; 
                        //AttchtoExisting = true;
                        createCon = true;
                        OppConExisting = false;
                    }
                }
            }
            
            //for loop to get the tasks if the details are entered in the page
            for(Task taskobjvar:[select id,Description,IsReminderSet,WhoId,OwnerId,ReminderDateTime from Task where whoid = : leadobj.id]){
                TaskObjMap.put(taskobjvar.WhoId,taskobjvar);
            }
            
            if(leadid!=null){
                lc.setLeadId(leadid);// Set the lead id for conversion
                
                if(createOpp == true)
                  lc.setDoNotCreateOpportunity(True);
                if(SendNotificMail == true)
                  lc.setsendNotificationEmail(true);
                if(stroppname!=null && stroppname!='' && stroppname!= leadobj.company)
                  lc.setopportunityname(stroppname);
                  
                  
                if((AttchtoExisting == true || OppConExisting == true || AttachtoConExisting == true) && SelAccountName != null && (dupeCon==true || createCon == true)){
                    if(SelAccountName != NUll){
                       List<Account> accList = [select id,name from Account where Name = :SelAccountName.trim() order by CreatedDate  limit 1 ];
                       if(!accList.isEmpty()){
                          accid = accList[0].Id; 
                       }
                    }
                    
                    if(accid!=null && accid!=''){
                        lc.setaccountId(accid);
                    }
                    preparecontacts();//Prepare the list of contacts if dupicate contacts found
                    
                    integer concount = [select count() from contact where AccountId = :accid AND (FirstName =:leadobj.FirstName OR LastName =:leadobj.LastName OR FirstName =:leadobj.LastName OR LastName =:leadobj.FirstName)];   
                    
                    if(concount>0 && ((AttachtoConExisting == false && createCon == false) || OppConExisting == true)){
                        duplicateContact = true;
                        convert = false;
                        AttchtoExisting = true;
                    }else{
                        convert = true;
                        OppConExisting = false;
                    } 
                    
                    System.debug('Pardeep+accid'+accid+'duplicateContact='+duplicateContact+'AttachtoConExisting='+AttachtoConExisting+createCon+OppConExisting);
                    
                    if(AttachtoConExisting == true){
                        List<Contact> contList = [select id,Name,AccountId from contact where AccountId = :accid AND Name = :SelContactName.trim() limit 1];
                        if(!contList.isEmpty()){
                            contactid = contList[0].Id;
                        }
                        
                        lc.setcontactId(contactid);
                        duplicateContact = false;
                        convert = true;
                    }
                    
                    /* To insert a task if the reminder is selected on lead conversion starts*/
                    if(Taskobj !=null){   
                        if(TaskObjMap.get(leadobj.id)!=null)
                            Taskobj = TaskObjMap.get(leadobj.id);
                        
                        Taskobj.Description = StrComments;
                        Taskobj.IsReminderSet = true;
                        Taskobj.WhoId = leadobj.id;
                        //Taskobj.WhatId = straccid;
                        Taskobj.OwnerId = struserid;
                        if(Setreminder == true){
                            date datevar = Eventobj.Activitydate;
                            if(selectedtime!=null && selectedtime!=''){
                                String[] timesplitArr = selectedtime.split(':');
                                hourvar = integer.valueof(timesplitArr[0]);
                                
                                String[] timesplitArr1 = timesplitArr[1].split(' ');
                                minutevar = integer.valueof(timesplitArr1[0]);                       
                            }    
                            if(Eventobj.Activitydate!=null)
                                Taskobj.ReminderDateTime = Datetime.newinstance(Eventobj.Activitydate,Time.newInstance(hourvar ,minutevar ,secondsvar ,millisecondsvar ));
                        }    
                    }
                    
                    if(Taskobj!=null && taskobj.subject!=null && taskobj.subject!='')
                        upsert Taskobj;
                    /* To insert a task if the reminder is selected on lead conversion starts*/
                    
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1]; 
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    
                    if(struserid!=null && struserid!='')
                       lc.setOwnerId(struserid);
                       
                    if(convert == true && OppConExisting == false){
                        lcr = Database.convertLead(lc);
                        System.assert(lcr.isSuccess());
                        
                        straccid = lcr.getaccountid();
                        
                        if(accid!=null && accid!='')
                        straccid = accid ;
                        //for task creation
                        
                        p = new pagereference('/'+straccid);
                        p.setredirect(true);
                        //return p; 
                    }    
                    
                }
                
                if(SetCreatenewAccount == true && (AttchtoExisting == false || AttchtoExisting == null)){
                    //for task creation
                    if(Taskobj !=null){   
                        if(TaskObjMap.get(leadobj.id)!=null)
                           Taskobj = TaskObjMap.get(leadobj.id);
                        
                        Taskobj.Description = StrComments;
                        Taskobj.IsReminderSet = true;
                        Taskobj.WhoId = leadobj.id;
                        //Taskobj.WhatId = straccid;
                        Taskobj.OwnerId = struserid;
                        if(Setreminder == true){
                            date datevar = Eventobj.Activitydate;
                            if(selectedtime!=null && selectedtime!=''){
                                String[] timesplitArr = selectedtime.split(':');
                                hourvar = integer.valueof(timesplitArr[0]);
                                
                                String[] timesplitArr1 = timesplitArr[1].split(' ');
                                minutevar = integer.valueof(timesplitArr1[0]);                       
                            }    
                            
                            if(Eventobj.Activitydate!=null)
                            Taskobj.ReminderDateTime = Datetime.newinstance(Eventobj.Activitydate,Time.newInstance(hourvar ,minutevar ,secondsvar ,millisecondsvar ));
                        }    
                    }
                    //DML operation to upsert the task record
                    if(Taskobj!=null && taskobj.subject!=null && taskobj.subject!='')
                       upsert Taskobj;
                    
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1]; 
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    
                    if(struserid!=null && struserid!='')
                       lc.setOwnerId(struserid);
                    
                    lcr = Database.convertLead(lc);
                    System.assert(lcr.isSuccess());
                    
                    straccid = lcr.getaccountid();  
                    
                    p = new pagereference('/'+straccid);
                    //p = new pagereference('/001/e?retURL=%2F001%2Fo&RecordType='+recordTypeId+'&ent=Account&nooverride=1');
                    p.setredirect(true);
                    system.debug('pagereference======'+p);
                }
                
                if((AttchtoExisting == false && Setcontinueuserselection == false && SetCreatenewAccount == false && convert!= true) || (AttchtoExisting == false && Setcontinueuserselection == null && SetCreatenewAccount == null && convert!= true)){
                    AccName = SelAccountName.substring(1,SelAccountName.length());
                    DisplaySearchMDMDataPage=true;
                    DisplayCreateLeadPage = false; 
                    p = null;               
                }
            
            }
        }
        catch(exception ex){
            ApexPages.addMessages(ex);
            p = null;
        }
        
        return p;
     }
   
   /*
     * Method name  : cancelAction
     * Description  : Method to cancel the action on click of cancel button
     * Return Type  : pageReference
     * Parameter    : NA
   */  
   public pagereference cancelAction()
   {
        /*DisplaySearchMDMDataPage=false;
        DisplayCreateLeadPage = true;
        displayMDMResults = false;*/
        pagereference p = new pagereference('/apex/CustomLeadConversionPage?id='+leadobj.id);
        p.setredirect(true);
        return p; 
   }
   
   
   public class wrappersearchresults{
    
     //public Double noofemp{get;set;}
    //public String sicDesc{get;set;}
    
    public String accname{get;set;}
    public String billlingstreet{get;set;}
    public String billlingcity{get;set;}
    public String billlingstate{get;set;}
    public String billlingcountry{get;set;}
    public String partynumber{get;set;}
    public String billingpostalcode{get;set;}
    
    public wrappersearchresults(String accname,String billlingstreet,String billlingcity,String billlingstate,String billlingcountry,String partynumber,String billingpostalcode){
    //public wrappersearchresults(Double noofemp, String sicDesc){
        /*this.noofemp = noofemp;
        this.sicDesc = sicDesc;*/
        
        this.accname=accname;
        this.billlingstreet=billlingstreet;
        
        this.billlingcity=billlingcity;
        
        this.billlingstate=billlingstate;
        
        this.billlingcountry=billlingcountry;
        this.partynumber=partynumber;
        this.billingpostalcode = billingpostalcode;
        
        }          
   } 
   
   public String changedvalue{get;set;}
   public void reorderpickValues(){
    system.debug('changedvalue===='+changedvalue);
    prepareaccounts();
    //return null;
   }
   
   public String changedConvalue{get;set;}
   public void reorderConPickValues(){
     prepareContacts();
   }
   
   
   public class clsLeadWrapper{
      public Boolean isSelected{get;set;}
      
   }
   
   
   
   
   
   
   
    /******************************************************/
     
    public pageReference getAllStates(){
        String countryName = Apexpages.currentpage().getParameters().get('countryName');
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
   
   // Wrapper class for displaying search results after parsing the JSOn returned from Search functionality
    public class searchResultsWrapper{
        public String rowNum{get;set;}
        public String partyName{get;set;}
        public String partyNumber{get;set;}
        public String partyType{get;set;}
        public String partyTier{get;set;}
        public String DUNSNumber{get;set;}
        public String IdentifyingAddress{get;set;}
        //Added as aper User Story US55762
        //pbanik@redhat.com
        public string TaxReference{get;set;}
        public List<string> partnerCodes{get;set;}
        //End of changes
        public String phone{get;set;}
        public String relatedLinks{get;set;}
        public String PARTY_SITE_NUMBER;
        public String ADDRESS1{get;set;}
        public String ADDRESS2 {get;set;}
        public String CITY{get;set;}
        public String COUNTY {get;set;}
        public String STATE{get;set;}
        public String PROVINCE{get;set;}
        public String COUNTRY{get;set;}
        public String POSTAL_CODE {get;set;}
    } 
    
    public pageReference redirectAccountUrl(){
        String selectedCDHAccount = Apexpages.currentpage().getParameters().get('selectedCDHAccount');
        String recordTypeId = Apexpages.currentpage().getParameters().get('recordTypeId');
        String CDHPartyNumber = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyNumber;
        String CDHPartyType = searchResultsWrapperMap.get(Integer.valueOf(selectedCDHAccount)).partyType;
        List<CDH_Party__c> CDHPartyList = [select Id,Name from CDH_Party__c where Name = :CDHPartyNumber limit 1];
        String CDHPartyNumberId;
        String CDHPartyName;
        CDH_Party__c newCDHRecord;
        if(CDHPartyList.size() > 0){
            CDHPartyNumberId = String.valueOf(CDHPartyList[0].id);
            CDHPartyName = CDHPartyList[0].Name;
        }else{
            newCDHRecord = new CDH_Party__c(Name = CDHPartyNumber,CDH_Party_Number_Ext__c = CDHPartyNumber,CDH_Party_Type__c = CDHPartyType);
            try{
                insert newCDHRecord;
                CDHPartyName = CDHPartyNumber;
                CDHPartyNumberId = String.valueOf(newCDHRecord.id);   
            }catch(Exception e){
                System.debug('------------------>'+e);
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error inserting CDH Record');  // set the exception message
                ApexPages.addMessage(Message); 
                return null;        
            }    
        }
        /*************************************************
        //searchResultsWrapperMap.get(selectedCDHAccount);
        String urlToBeRedirected = '/001/e?retURL=%2F001%2Fo&RecordType='+recordTypeId+'&nooverride=1';
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
        ***************************************************/
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
     
    // Get the CDH - Salesforce records.   
    @RemoteAction 
    public static String showAccounts(String CDHAccounts){
        // split the CDHAccounts
        List<String> CDHAccountsSplit = CDHAccounts.split(','); 
        List<AccountWrapper> AccountWrapperList = new List<AccountWrapper>();
        for(Account a: [select id, Name, Owner.Name,Owner.Email,CDH_Party_Name__c,CDH_Party_Name__r.Name,Identifying_Address__c from Account where Id in :CDHAccountsSplit]){
            AccountWrapper aw = new AccountWrapper();
            aw.id = String.valueOf(a.id);
            aw.name = a.Name;
            aw.ownerName = a.Owner.Name;
            aw.ownerEmail = a.Owner.Email;
            aw.CDHPartyNumber = a.CDH_Party_Name__r.Name != null ? a.CDH_Party_Name__r.Name : '';
            aw.identifyingAddress = a.Identifying_Address__c != null ? a.Identifying_Address__c : '';
            AccountWrapperList.add(aw);
        } 
        AccountDetailsJSON = JSON.serialize(AccountWrapperList);
        return AccountDetailsJSON;
    }
   
    // Wrapper class for settinig account details for CDH Party Record
    public class AccountWrapper{
        public String id{get;set;}
        public String name{get;set;}
        public String ownerName{get;set;}
        public String ownerEmail{get;set;}
        public String CDHPartyNumber{get;set;}
        public String identifyingAddress{get;set;}
    }
   
    // Wrapper class for getting record type details accessible for current logged in 
    public class recordTypeWrapper{
        public String recordTypeId;
        public String recordTypeName;    
    }
    
    
    /**************************************************
        New Way to parse JSON
        Wrapper class for parsing the JSON Class
    **************************************************/
    
    public class Jsonparsercls{  
      public String PARTY_NAME{get;set;}
      public String PARTY_NUMBER{get;set;}
      public String PARTY_TYPE{get;set;}
      public String DUNS_NUMBER{get;set;}
      //Added as aper User Story US55762
      //pbanik@redhat.com
      public String TAX_REFERENCE{get;set;}
      //End of Changes
      public String PARTY_SITE_NUMBER;
      public String ADDRESS1{get;set;}
      public String ADDRESS2 {get;set;}
      public String CITY{get;set;}
      public String COUNTY {get;set;}
      public String STATE{get;set;}
      public String PROVINCE{get;set;}
      public String COUNTRY{get;set;}
      public String POSTAL_CODE {get;set;}
      public String PHONENO{get;set;}
      public List<String> ORIG_SYSTEM {get;set;}
      public List<String> ORIG_SYSTEM_REFERENCE{get;set;}
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
   
   
  
   
}