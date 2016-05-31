@isTest

public class OLICheckCreateEventRecs_AI_AU_BD_Test{
    public static final String SUPER_REGION = 'EMEA';

    public static RecordType preferredRecordType {
        get {
            if(preferredRecordType == null) {
                preferredRecordType = [
                  select Id,name
                  from RecordType
                  where name like :(SUPER_REGION+' %')
                    and SObjectType = 'Opportunity'
                    and IsActive = true
                  limit 1 ];
            }
            return preferredRecordType;
        }
    }

    public static Account account {
        get {
          if(account == null) {
            RecordType recordType = [
              select Id,name
              from RecordType
              where name = 'Strategic'
                and SObjectType = 'Account'
                and IsActive = true
              limit 1 ];
            account = new Account(
              CurrencyIsoCode='USD',
              name='Test Account',
              RecordTypeId=recordType.Id,
              AccountClassification__c=recordType.name );
            insert account;
            account.RecordType = recordType;
          }
          return account;
        }
    }

    public static Opportunity opp {
        get {
          if(opp == null) {
            opp = new Opportunity(
              Name='Opportunity Test',
              CurrencyIsoCode=account.CurrencyIsoCode,
              CloseDate=System.today(),
              ContractStartDate__c = System.today().addDays(1),
              StageName='Unqualified',
              OwnerId=UserInfo.getUserId(),
              AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
              RecordTypeId = preferredRecordType.Id,
              PrimaryBusinessUnit__c=null,
              POC_Status__c=null);
          }
          return opp;
        }
    }
    
    public static testMethod void testOLICheckCreateEventRecs_AI_AU_BD(){
        
        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
        insert standardUser;
        
        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');
        insert adminUser;
        
        OpportunityTeamMember otm;
        OpportunityTeamMember otm1;
        OpportunitySplitType ost;
        OpportunitySplit os;
        OpportunitySplit os1;
        
        system.runAs(adminUser){
            //create opportunity
            insert opp;
            //create opportunity Line Item
            
            Product2 prod = new Product2(
                                            Name='testProduct',
                                            ProductCode = 'TC',
                                            IsActive = TRUE);
            insert prod;
            
            
            PriceBookEntry pbe = new PriceBookEntry(
                                                        IsActive = TRUE,
                                                        Pricebook2Id = Test.getStandardPricebookId(),
                                                        Product2Id = prod.Id,
                                                        UnitPrice = 100,
                                                        UseStandardPrice = FALSE);
                                                        
            insert pbe;
            
            list<Event__c> events = new list<Event__c>([SELECT Id FROM Event__c]);
            delete events;
            
            OpportunityLineItem oli = new OpportunityLineItem(
                                                                PricebookEntryId = pbe.Id, 
                                                                OpportunityId = opp.Id,
                                                                UnitPrice = 100,
                                                                Quantity = 2);
            
            insert oli;
            
            update oli;
            
            delete oli;
            
            
            system.assertEquals([SELECT Id FROM OpportunityLineItem WHERE Id =: oli.Id].isEmpty(), TRUE);
           
            
        }
    
    }
}