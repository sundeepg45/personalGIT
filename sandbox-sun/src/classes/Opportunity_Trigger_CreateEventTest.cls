@isTest
public class Opportunity_Trigger_CreateEventTest{
    
    
    public static testMethod void testCreateEventOnAccTransfer() {
        
        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Operation%' LIMIT 1]; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser;
        
        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');
        insert adminUser;
        
        User adminUser1 = new User(Alias = 'admint1', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com1');
        insert adminUser1;
        
        system.runAs(adminUser1){
            standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
              LocaleSidKey='en_US', ProfileId = standard.Id,
              TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
            insert standardUser;
        }
        
        System.runAs(adminUser){
            Test.startTest();
            
            RecordType accrecordType = [
              select Id,name
              from RecordType
              where name = 'Strategic'
                and SObjectType = 'Account'
                and IsActive = true
              limit 1 ];
            Account account = new Account(
              CurrencyIsoCode='USD',
              name='Test Account',
              RecordTypeId=accrecordType.Id,
              AccountClassification__c=accrecordType.name );
            insert account;
            
            RecordType oppRecordType = [
                  select Id,name
                  from RecordType
                  where name like :'EMEA %'
                    and SObjectType = 'Opportunity'
                    and IsActive = true
                  limit 1 ];
            
            Opportunity oppor = new Opportunity(
              Name='Opportunity Test',
              CurrencyIsoCode=account.CurrencyIsoCode,
              CloseDate=System.today(),
              ContractStartDate__c = System.today().addDays(1),
              StageName='Unqualified',
              OwnerId=UserInfo.getUserId(),
              AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
              RecordTypeId = oppRecordType.Id,
              PrimaryBusinessUnit__c=null,
              POC_Status__c=null);
            
            insert oppor;
            
            list<Event__c> lstEvent = [SELECT Opportunity__c FROM Event__c WHERE Opportunity__c =: oppor.Id AND Processed__c = FALSE];
            delete lstEvent;
            
            oppor.OwnerId = adminuser1.Id;
            update oppor;
            Test.stopTest();
        }
    }
}