/*****************************************************************************************
    Name    : Address_MergeTest
    Desc    : This test class covers the logic for merging the addresses for the request revieved from CDH for a particular account.           
                            
Modification Log : 
---------------------------------------------------------------------------
     Developer              Date            Description
---------------------------------------------------------------------------
    Neha Jaiswal        15/06/2014          Created
******************************************************************************************/
@IsTest
private class Address_MergeTest {

    //implements the logic to cover code on merge address by selecting two address record and making one master. 
    
    static testMethod void MergeAddressTest(){
        
        //Creating a CDH_PArty__c record to get it's reference for cdh fields in sales account.
        CDH_Party__c cdhParty =new CDH_Party__c();
        cdhParty.CDH_Party_Name__c = 'test CDH party';
        cdhParty.CDH_Party_Type__c = 'Group';
        
        //Create Sales Account
        Account account= new Account();
        account.Name = 'Test Sales Account1';
        account.CurrencyIsoCode = 'USD';
        insert account;
        
        //system.assert to check the name of the account inserted.
        system.assertEquals(1,[select Name from Account].size());
        
        //Instantiate  Address records to get merged.
        Address__c firstAddressForMerge = new Address__c();
        Address__c secondAddressForMerge = new Address__c();   
        
        //List of address to hold the address records.
        List<Address__c> addressList = new List<Address__c>();
            
        // setting the attributes of address record
        firstAddressForMerge.Sales_Account__c = account.id;
        firstAddressForMerge.Status__c = 'Active';
        firstAddressForMerge.Address_Line1__c = 'test address 1';
        firstAddressForMerge.Address_Line2__c = 'test address 2';
        firstAddressForMerge.Address_Line3__c = 'test address 3';
        firstAddressForMerge.Address_Line4__c = 'test address 4';
        firstAddressForMerge.Bill_To_Address__c = true;
        firstAddressForMerge.CDH_Party__c = cdhParty.id;
        firstAddressForMerge.CDH_Party_Site_Number__c = '124';
        firstAddressForMerge.City__c = 'test city';
        firstAddressForMerge.State__c = 'test state';
        firstAddressForMerge.Province__c = 'test Province';
        firstAddressForMerge.Country__c = 'test country';
        firstAddressForMerge.County__c = 'test county';
        firstAddressForMerge.Entitle_To_Address__c = true;
        firstAddressForMerge.Sold_To_Address__c = true;
        firstAddressForMerge.Ship_To_Address__c = true;
        firstAddressForMerge.Identifying_Address__c = true;
        firstAddressForMerge.Identifying_Address__c = true;
        firstAddressForMerge.Zip_Postal_Code__c = '13123';
        
        // add the address record into list    
        addressList.add(firstAddressForMerge);
            
        // setting the attributes of address record
        secondAddressForMerge.Sales_Account__c = account.id;
        secondAddressForMerge.Status__c = 'Active';
        secondAddressForMerge.Address_Line1__c = 'test address 1';
        secondAddressForMerge.Address_Line2__c = 'test address 2';
        secondAddressForMerge.Address_Line3__c = 'test address 3';
        secondAddressForMerge.Address_Line4__c = 'test address 4';
        secondAddressForMerge.Bill_To_Address__c = true;
        secondAddressForMerge.CDH_Party__c = cdhParty.id;
        secondAddressForMerge.CDH_Party_Site_Number__c = '124';
        secondAddressForMerge.City__c = 'test city';
        secondAddressForMerge.State__c = 'test state';
        secondAddressForMerge.Province__c = 'test Province';
        secondAddressForMerge.Country__c = 'test country';
        secondAddressForMerge.County__c = 'test county';
        secondAddressForMerge.Entitle_To_Address__c = true;
        secondAddressForMerge.Sold_To_Address__c = true;
        secondAddressForMerge.Ship_To_Address__c = true;
        secondAddressForMerge.Identifying_Address__c = false;
        secondAddressForMerge.Zip_Postal_Code__c = '13123';
        
        // add the address record into list    
        addressList.add(secondAddressForMerge);
         
        // insert list of address records 
        insert  addressList;
        
        //system.assert to check the size of the address records list that is inserted above.
        system.assertEquals(2,[select id from Address__c].size());
        
        // start test
        test.starttest();
        
        // initilaize the page as the 'Addres_MergePage'.
        PageReference pageReference = Page.Address_MergePage;
        
        // set the current page as 'Address_MergePage'
        Test.setCurrentPage(pageReference);
        
        //passing Sales Account Id into the current pageReference.
        ApexPages.currentPage().getParameters().put('addressId1', AddressList[0].Id);
        ApexPages.currentPage().getParameters().put('addressId2', AddressList[1].Id);
                
        // Creating object for addressMerge class
        Address_Merge addressMergeContollerInstance= new Address_Merge ();
         
        // Passing the String of selected values and fields back to the controller.
        string addressFieldSelectedString = 'Id;'+AddressList[0].Id;
        ApexPages.currentPage().getParameters().put('addressFieldSelectedString', addressFieldSelectedString);
  
        //Clicking of Select Button to select the records to be merged
        addressMergeContollerInstance.OnMergeButtonClicked();
        
        //assert statement to verify the behaviour of merge button.
        system.assertequals('/'+addressList[0].Id,addressMergeContollerInstance.OnMergeButtonClicked().geturl());
        //Clicking of Cancel Button
        addressMergeContollerInstance.cancel(); 
        
        // assert statement to check the redirect url of cancel button.
        system.assertequals('/'+account.id,addressMergeContollerInstance.cancel().geturl());
        
        // below logic used to cover one else condition.
        ApexPages.currentPage().getParameters().put('addressFieldSelectedString', '  ');
        addressMergeContollerInstance.OnMergeButtonClicked();
 
        // stop test  
        test.stoptest();   
             
    } // test  method ends here
}