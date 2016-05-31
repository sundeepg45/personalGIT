/*****************************************************************************************
    Name    : Address_MergeRequestRecievedByCDHTest
    Desc    : This test class covers the logic for merging the addresses for the request received from CDH for a particular account.           
                            
Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Neha Jaiswal        15/06/2014          Created
******************************************************************************************/
@IsTest
private class Address_MergeRequestRecievedByCDHTest {
    
    //this implements the logic to cover the code on selecting of the addresses for which merge request has been recieved from CDH and sending their id to the vf page.
    public static testmethod void testAddressMerge() {
       
        //create sales account  to associate it with address.
        Account account = new Account();
        account.Name = 'Partner Account';
        account.BillingCountry = 'US';
        insert account;
        
        // test the account has no partner statuses
        system.assertEquals('Partner Account', [select Name from Account limit 1].Name);
            
        List<Address__c> addressList = new List<Address__c>();
        
        // creating address record with active status
        for(integer counter = 0; counter < 10 ; counter++){
            //Create the test address to get merged.
            Address__c addresssActiveRecord = new Address__c();
            addresssActiveRecord.Sales_Account__c = account.id;
            addresssActiveRecord.Status__c = 'Active';
            addresssActiveRecord.identifying_address__c = true;
            addressList.add(addresssActiveRecord);
        }
        
        // creating address record with inactive status
        for(integer counter = 0;counter < 10; counter++){
           //Create the test address to get merged.
           Address__c addresssInactiveRecord = new Address__c();
           addresssInactiveRecord.Sales_Account__c = account.id;
           addresssInactiveRecord.Status__c = 'Inactive';
           addressList.add(addresssInactiveRecord);
        }
        
        //inserting the list of address
        insert addressList;
        
        // system.assert to check the size of the list of address inserted.
        system.assertEquals(20,[select id from Address__c].size());
          
        //create the RH_CountryCode_CountryName__c custom setting instance:
        //RH_CountryCode_CountryName__c ContryCodeName = new RH_CountryCode_CountryName__c();
        //ContryCodeName.RH_TERRITORY_CODE__c = 'IN';
        //ContryCodeName.RH_DESCRIPTION__c = 'India';
        //ContryCodeName.Name = 'IN';
        //insert ContryCodeName;
        Country__c country_IN = new Country__c();
        country_IN.Name = 'INDIA';
        country_IN.Address_Style__c = 'Address Style 10';
        country_IN.IsAgreementSignatureRequired__c = false;
        country_IN.Country_of_Order__c = 'India'; 
        country_IN.Global_Region__c = 'APAC'; 
        country_IN.Iso3166Alpha2__c = 'IN'; 
        country_IN.Iso3166Alpha3__c = 'IND'; 
        country_IN.Iso3166Numeric3__c = 356; 
        insert country_IN;        
        
        //start the test
        test.starttest();  
        
        //Setting the Address_MergeRequestRecievedByCDHPage page as a test page for the test class and passing the accountId as a parameter for which address will get merged.
        PageReference pageReference = Page.Address_MergeRequestRecievedByCDHPage;
        Test.setCurrentPage(pageReference);
        ApexPages.CurrentPage().getParameters().put('accountId',account.id);  

        //initializing the class here.
        Address_MergeRequestRecievedByCDH mergeAddress = new Address_MergeRequestRecievedByCDH();
           
        //system.assert used to verify the sales account id passed in controller.
        system.assertEquals(mergeAddress.salesAccountIDPassedForAddressMerge,account.Id);
        system.assertequals(mergeAddress.addressWrapperList.size() , 10);  
        
        //set the addresses records to be merged.
        mergeAddress.addressWrapperList[0].CheckboxSelected  = true;  
        mergeAddress.addressWrapperList[4].CheckboxSelected  = true;
           
        //calling OnSelectButtonClick method. 
        mergeAddress.OnSelectButtonClick();
        
        // assert statement to verify the behaviour of select button.'
        system.assertequals('/apex/Address_MergePage?addressId1='+mergeAddress.selectedAddressToPassInURLList[0]+'&addressId2='+mergeAddress.selectedAddressToPassInURLList[1], 
                             mergeAddress.OnSelectButtonClick().geturl());   
        
        //calling the method cancel .
        mergeAddress.cancel(); 
        
        //assert statement to verify the behaviour of cancel button.
        system.assertequals('/'+account.Id , mergeAddress.cancel().geturl());  
        
        // end of test     
        test.stoptest(); 
    }     
}