/*****************************************************************************************
    Name    : Address_MergeRequestRecievedByCDH
    Desc    : This class defines the logic for merging the addresses for the request revieved from CDH for a particular account.           
    
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Neha Jaiswal        15/06/2014          Created
******************************************************************************************/
public with sharing class Address_MergeRequestRecievedByCDH {
    
    // Variable declarations starts here.
    public list<AddressWrapper> addressWrapperList {get;set;}
    public string salesAccountIDPassedForAddressMerge{get;set;}
    public list<Id> selectedAddressToPassInURLList{get;set;} 
    public map<string,string> codeCountryWrapper{get;set;}     
    public map<string,Country__c> countryCodeWrapper{get;set;}
    // variable declaration ends here.
      
    //This constructor will fetch the sales account id for which address needs to be merged and fetches the details of address from address custom object.  
    public Address_MergeRequestRecievedByCDH()  
    {
        try{
            //initializing the variables and querying the custom setting for country code.
            list<Address__c> listAddressRequestRecievedByCDH = new list<Address__c> ();
            addressWrapperList = new list<AddressWrapper>();
            countryCodeWrapper = new map<string,Country__c >();
            for(Country__c country : [select Id,Name,Iso3166Alpha2__c from Country__c]){
                countryCodeWrapper.put(country.Name, country);
            }
            codeCountryWrapper = new map<string,string>();
            
            //iterating through the countryCodeWrapper list from custom setting of country code and getting it's name by converting them in upper case.
            for(String countryCodeToName : countryCodeWrapper.keySet()){ 
               codeCountryWrapper.put(countryCodeWrapper.get(countryCodeToName).Iso3166Alpha2__c,countryCodeToName.toUpperCase()) ;           
            }
            
            //checking the null exception if the url doesn't have accountid
            if(apexPages.currentPage().getParameters().get('accountId')!=null && apexPages.currentPage().getParameters().get('accountId')!='')
            {
                //getting the accountid in string.
                salesAccountIDPassedForAddressMerge=apexPages.currentPage().getParameters().get('accountId');
            
                //Querying the  address related list of a sales account that user selects to get it's address merged.
                listAddressRequestRecievedByCDH=[Select id,Address_Line1__c,Address_Line2__c,Address_Line3__c,Address_Line4__c,Bill_To_Address__c,CDH_Party_Site_Number__c,Sold_To_Address__c,
                                                 CDH_Party__c,City__c,Country__c,County__c,Entitle_To_Address__c,Identifying_Address__c,Name,Province__c,RecordTypeId,Sales_Account__c,Ship_To_Address__c,
                                                 State__c,Status__c,Zip_Postal_Code__c FROM Address__c where Sales_Account__c =: salesAccountIDPassedForAddressMerge  AND Status__c='Active'];
         
                //checking the size of list of the address for which merge request has been recieved by cdh.   
                if(listAddressRequestRecievedByCDH.size()>0)
                {   
                    //iterating through the list of the address queried above.
                    for(Address__C AddressObjectFetchedForMerge:listAddressRequestRecievedByCDH)
                    {   
                        //initializing  the instance of wrapper class.
                        AddressWrapper addressObjectToMerge = new AddressWrapper();
                        
                        //assigning the selected address to the wrapper class.
                        addressObjectToMerge.addressRecord  = AddressObjectFetchedForMerge;
                        
                        //initializing the radio button of selection of the address as false.
                        addressObjectToMerge.checkboxSelected = false;
                        
                        //getting the name of the country from the custom setting of country code.
                        addressObjectToMerge.strCountryName = codeCountryWrapper.get(AddressObjectFetchedForMerge.Country__c) ;
                        
                        //adding each wraapeer to the list.
                        addressWrapperList.add(addressObjectToMerge);
                    }
                }
            }   
        }
        
        //catch the system exception if any.  
        catch(Exception e){
              system.debug('exception occured-->'+e.getmessage());
        }
    }
    
    //This method gets call on the click of select button to pass the id of the address being selected for merge as a parameter in the url of address_merge page
    //and redirects to it.
     
    public pageReference OnSelectButtonClick()
    { 
        system.debug('method executed--');
        selectedAddressToPassInURLList = new list<id>();
        for(AddressWrapper selectedAddressWrapperRecord:addressWrapperList)
        {
            //checking if the adddress record is selected to get merge.
            if(selectedAddressWrapperRecord.checkboxSelected == true && selectedAddressWrapperRecord.addressRecord != Null)
            {
                //adding the selected address record id into yhe list to be passed in URL of the other vf page.
                selectedAddressToPassInURLList.add(selectedAddressWrapperRecord.addressRecord.id);
            }
        }
        //this will redirect user to the vf page and passing the id of selected records.
        pageReference pageRedirectedWithSelectedAddressIdInUrl = new pageReference('/apex/Address_MergePage?addressId1='+selectedAddressToPassInURLList[0]+ '&addressId2='+selectedAddressToPassInURLList[1]);
        return pageRedirectedWithSelectedAddressIdInUrl;
    }
    
    //This redirects to the standard view page of the sales account passed in URL for which addresses needs to be merged.
    public pageReference Cancel()
    {
        Pagereference pageRedirectedToRelatedSalesAccount = new Pagereference('/'+salesAccountIDPassedForAddressMerge);
        return pageRedirectedToRelatedSalesAccount;
    }
    
    // structure of wrapper class hold the address related information
    public class AddressWrapper   
    {
        //associating selected address record to the wrapper class.
        public Address__c addressRecord{get;set;} 
        
        // boolean variable to associate check box selection with address     
        public boolean checkboxSelected{get;set;}    
        
        //string will hold the value of country from custom setting.    
        public string strCountryName{get;set;}
    }

}