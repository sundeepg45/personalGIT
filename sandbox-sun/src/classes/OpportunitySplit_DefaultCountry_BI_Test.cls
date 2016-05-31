@isTest
public class OpportunitySplit_DefaultCountry_BI_Test {
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
    
    static testMethod void testOpportunitySplit_DefaultCountry_BI(){
        
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
            
            list<Event__c> events = new list<Event__c>([SELECT Id FROM Event__c]);
            delete events;
            
            
            //create opportunity team member
            otm = new OpportunityTeamMember(
                                                    TeamMemberRole = 'Sales Manager',
                                                    OpportunityId = opp.Id,
                                                    UserId        = opp.OwnerId);
            insert otm;
            
            otm1 = new OpportunityTeamMember(
                                                    TeamMemberRole = 'Sales Manager',
                                                    OpportunityId = opp.Id,
                                                    UserId        = standardUser.Id);
            insert otm1;
            
            ost =  [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = 'Overlay Credit' Limit 1];
                                                               
            
            os = new OpportunitySplit(OpportunityId=opp.Id,
                                                        SplitOwnerId=opp.ownerId, SplitPercentage=20,
                                                        SplitTypeId=ost.Id);
                                                        
            insert os;
            os1 = new OpportunitySplit(OpportunityId=opp.Id,
                                                        SplitOwnerId=standardUser.Id, SplitPercentage=20,
                                                        SplitTypeId=ost.Id);
                                                        
            insert os1;
            
            Region__c reg = new Region__c(Country__c = 'India', Region__c = 'APAC');
            insert reg;
            
            update os1;
            
            os1.Country__c = '';
            update os1;
            system.assertEquals([SELECT Id FROM OpportunitySplit WHERE Id =: os1.Id].isEmpty(), FALSE);
        }
    }
}