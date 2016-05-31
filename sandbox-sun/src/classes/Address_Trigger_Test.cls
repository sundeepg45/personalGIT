/*****************************************************************************************
//depreciated	Name    : Address_Trigger_Test
//depreciated	Desc    : This is the test class for Address_Trigger and Address_Trigger_Handler
//depreciated	                  
//depreciated	                        
Modification Log : 
---------------------------------------------------------------------------
//depreciated	Developer       Date                Description
---------------------------------------------------------------------------
//depreciated	Vipul Jain      23 JULY 2014        Created
******************************************************************************************/   
@isTest
private class Address_Trigger_Test {
//depreciated	public static testmethod void SingleAddressRecordCreation_Update(){
//depreciated	    
//depreciated	    // insert CDH Party record
//depreciated	    CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
//depreciated	    insert cdhParty;
//depreciated	    
//depreciated	    // insert account records.
//depreciated	    Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
//depreciated	    insert account;
//depreciated	    test.starttest();
//depreciated	    // insert address record 
//depreciated	    Address__c address = IntegrationObjectsTestUtil.getSFAddress(account,'123 Entitle St', 'Raleigh', 'NC');
//depreciated	    insert address;
//depreciated	    
//depreciated	    // insert second address record (not in list because user will create one address record using UI )
//depreciated	    Address__c addressSecond = IntegrationObjectsTestUtil.getSFAddress(account,'123 Entitle St', 'Raleigh', 'NC');
//depreciated	    insert addressSecond; 
//depreciated	    system.assertequals(True,[select id,Identifying_Address__c from Address__c where id = :addressSecond.Id].Identifying_Address__c);
//depreciated	    system.assertequals(1,[select id,Count_Of_Identifying_Address__c from Account].Count_Of_Identifying_Address__c);
//depreciated	    // update address record.
//depreciated	    address.Identifying_Address__c = True;
//depreciated	    update address;
//depreciated	    system.assertequals(False,[select id,Identifying_Address__c from Address__c where id = :addressSecond.Id].Identifying_Address__c);
//depreciated	    test.stoptest();
//depreciated	}
//depreciated	
//depreciated	
//depreciated	public static testmethod void BulkAddressRecordCreation_Update() {
//depreciated	    // insert CDH Party record
//depreciated	    CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
//depreciated	    insert cdhParty;
//depreciated	    
//depreciated	    // insert account records.
//depreciated	    List<Account> accoutList = new List<Account>();
//depreciated	    for(integer i=0 ; i<20 ;i++){
//depreciated	    
//depreciated	        accoutList.add(IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'+string.valueof(i)));
//depreciated	    }
//depreciated	    insert accoutList;
//depreciated	    
//depreciated	    system.assertequals(20,[select id from account].size());
//depreciated	    test.starttest();
//depreciated	    List<Address__c> addressList = new List<Address__c>();
//depreciated	    for(integer i=0 ; i<20 ;i++){
//depreciated	        addressList.add(IntegrationObjectsTestUtil.getSFAddress(accoutList[i],'123 Entitle St'+string.valueof(i), 'Raleigh', 'NC'));
//depreciated	    }
//depreciated	    insert addressList;
//depreciated	    system.assertequals(20,[select id from Address__c].size());
//depreciated	    addressList = new List<Address__c>();
//depreciated	    for(integer i=0 ; i<20 ;i++){
//depreciated	        addressList.add(IntegrationObjectsTestUtil.getSFAddress(accoutList[i],'123 Entitle St'+string.valueof(i), 'Raleigh', 'NC'));
//depreciated	    }
//depreciated	    insert addressList;
//depreciated	    system.assertequals(40,[select id from Address__c].size());
//depreciated	    system.assertequals(1,[select id,Count_Of_Identifying_Address__c from Account where id = :accoutList[1].Id].size());
//depreciated	    
//depreciated	    test.stoptest();
//depreciated	}
//depreciated	   
}