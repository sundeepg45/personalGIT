/*****************************************************************************************
    Name    : Address_Merge
    Desc    : This class is used to implement the logic to merge the address under one account.This class will handle the page controller logic for Address_MergePage where two address id will be passed in URL,
                user selects one of the address record as master and making second address record as inactive after merging.     
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Neha Jaiswal          05/28/2014          Created
******************************************************************************************/
public with sharing class Address_Merge {
    
    // variable declaration starts here.
    public list<string> listOfAddressIdToBeMerged{get;set;}
    public list<Address__c> addressMergeDetailList{get;set;}  
    public Boolean pageErrorVisible{get;set;}
    public String exceptionMessage {get;set;}
    public string relatedSalesAccount{get;set;}
    public Address__c addressRecordInactive{get;set;}
    // variable declaration ends here.       
      
    //Constructor to get the details of the address record that are passed in URL to get merge.
    public Address_Merge()
    { 
        try{ 
            //initializing the variables and creating the list of address id passed in url to get merged.  
            listOfAddressIdToBeMerged     = new list<string>();
            
            //string holds the first selected address passed in URL to get merge.
            string strAddress1PassedInURL = apexPages.currentPage().getParameters().get('addressId1');
            
            //string holds the second selected  address passed in URL  to get merge.
            string strAddress2PassedInURL = apexPages.currentPage().getParameters().get('addressId2');
            
            //initializing a list to hold the addresses selected to get merged.
            listOfAddressIdToBeMerged     = new list<string>();  
            
            //initializing address record instance
            addressRecordInactive = new Address__c();
                        
            // adding id`s of address to be merged into one list of string.
            listOfAddressIdToBeMerged.add(strAddress1PassedInURL);
            listOfAddressIdToBeMerged.add(strAddress2PassedInURL);  
            
            //invoking a method to fetch the details of the address records ID being passed in URL.
            SelectedAddressObjectDetail();  
        }  
          
        //catch exception here if any.  
        catch(Exception e){
            pageErrorVisible = true;
            exceptionMessage = 'Something went wrong!Please contact your System Administrator : Error Message :'+e.getMessage();    
        }
    }   
    
    //this is the method called in constructor to fetch the details of the addresses passed in url.
    //it fetches all field values of the address that are selected to be merged.
    public void SelectedAddressObjectDetail() {   
        //this will query the field values of the address records selected to get merge.  
        addressMergeDetailList = new list<Address__c>();
        addressMergeDetailList = [SELECT Address_Line1__c,Address_Line2__c,Address_Line3__c,Address_Line4__c,Bill_To_Address__c,CDH_Party_Site_Number__c,City__c,
                                   Country__c,County__c,CreatedById,CreatedDate,CurrencyIsoCode,Entitle_To_Address__c,Id,Identifying_Address__c,IsDeleted,
                                   Name,RecordTypeId,Sales_Account__c,Ship_To_Address__c,Sold_To_Address__c,State__c,Status__c,Province__c,
                                   Zip_Postal_Code__c FROM Address__c where id IN: listOfAddressIdToBeMerged];
                                   
        // both of the address records to be merged would be associated with single sales account , capture the sales account id in one variable.
        if(addressMergeDetailList.size() > 0){
            relatedSalesAccount    = addressMergeDetailList[0].Sales_Account__c;
        }
   }  
    
    //on merge button clicked , this method will be invoked to get the id of the record being selected as master and making the other record of the adddress
    // inactive by matching that to the list of address queried above.  
    public pageReference OnMergeButtonClicked()
    {  
        try{ 
            //getting the id of the address from the parameter sent by vf page.
            String mergeAddressIdDetail = apexpages.currentpage().getParameters().get('addressFieldSelectedString');
            if(mergeAddressIdDetail != null  && mergeAddressIdDetail.trim().length()>0 && mergeAddressIdDetail != ''){
                List<String> addressMergedSelectedList = mergeAddressIdDetail.split(';');
                
                //iteration on address record list to check which has not been selected as master, if no then making that as inactive in status.
                for(Address__c addressRecord:addressMergeDetailList){
                
                    if (addressRecord.Id != addressMergedSelectedList[1]){
                        // set the address record as 'Inactive' which has not been selected as to be the master address.
                        addressRecord.Status__c = 'Inactive';
                        addressRecordInactive = addressRecord;
                    } 
                }
                
                //updating here the address record as inactive if not chosen as master while merging.
                update addressRecordInactive;
               
                //redirecting to the view page of the address that is selected as master.
                pagereference pageRedirectedToMasterAddressRecord = new pagereference('/'+addressMergedSelectedList[1]);
                return pageRedirectedToMasterAddressRecord;
            }
            else{
            
                return null;
            }
        }
       
        //catch the exception if any    
        catch(exception e){
            system.debug('exception occured-->'+e.getmessage());
            return null;
        }
    }
    
    //redirecting to the related sales account if user clicks on cancel button.
    public pagereference Cancel()
    {
        Pagereference pageRedirectedToRelatedSalesAccount = new pagereference('/'+relatedSalesAccount); 
        return pageRedirectedToRelatedSalesAccount;  
    }
}