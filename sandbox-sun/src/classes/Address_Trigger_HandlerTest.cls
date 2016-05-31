/**
 * This class is a set of unit test for the Address_Trigger_Handler class.
 * 
 * @version 2014-02-07
 * @author Neha Jaiswal <nejaiswal@deloitte.com>
 * 2015-11-13 - Depreciated
 */
@isTest
private class Address_Trigger_HandlerTest {}
//depreciated public with sharing class Address_Trigger_HandlerTest
//depreciated {

//depreciated  public testMethod static void testAddressTrigger()
//depreciated      {

//depreciated           //create a new Sales Account 
//depreciated           Account acct=new Account();
//depreciated           acct.Name='RedHat';
//depreciated           acct.BillingCountry='IN';
//depreciated           insert acct;
//depreciated           
//depreciated           //insert a new address for the sales account and make it as Identiying Address.
//depreciated           Address__c address = new Address__c();
//depreciated           address.Status__c = 'Active';
//depreciated           address.identifying_address__c = true;
//depreciated           address.Address_Line1__c='Deloitte drive';
//depreciated           address.Country__c = 'India';
//depreciated           address.City__c='Hyderabad';
//depreciated           address.State__c = 'Andhra Pradesh';
//depreciated           address.Zip_Postal_Code__c = '530800'; 
//depreciated           address.Sales_Account__c=acct.Id;
//depreciated           insert address;
//depreciated           
//depreciated           //insert a second address for the sales account created.
//depreciated           Address__c secondAddress = new Address__c();
//depreciated           secondAddress.Status__c = 'Active';
//depreciated           secondAddress.identifying_address__c = true;
//depreciated           secondAddress.Address_Line1__c='Deloitte drive';
//depreciated           secondAddress.Country__c = 'India';
//depreciated           secondAddress.City__c='Hyderabad';
//depreciated           secondAddress.State__c = 'Andhra Pradesh';
//depreciated           secondAddress.Zip_Postal_Code__c = '530800'; 
//depreciated           secondAddress.Sales_Account__c=acct.Id;
//depreciated           insert secondAddress;
//depreciated           
//depreciated           //Update the address to invoke the Update Address Scenario
//depreciated            address.Zip_Postal_Code__c='500909';
//depreciated            update address;
//depreciated            
//depreciated        
//depreciated        }  
//depreciated        
//depreciated   }