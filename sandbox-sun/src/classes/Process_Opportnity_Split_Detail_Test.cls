@isTest

public class Process_Opportnity_Split_Detail_Test{
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
    
    public static testMethod void testProcess_Opportnity_Split_Detail(){
        
        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
        insert standardUser;
        
        User standardUser1 = new User(Alias = 'standt1', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser1@testorg.com');
        insert standardUser1;
        
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
            
            otm1 = new OpportunityTeamMember(
                                                    TeamMemberRole = 'Sales Manager',
                                                    OpportunityId = opp.Id,
                                                    UserId        = standardUser1.Id);
            insert otm1;
            
            //ost =  [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = 'Commissions' Limit 1];
            ost =  [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = 'Overlay Credit' Limit 1];
            
            
                                                               
            
            os = new OpportunitySplit(OpportunityId=opp.Id,
                                                        SplitOwnerId=opp.ownerId, SplitPercentage=20,
                                                        SplitTypeId=ost.Id);
                                                        
            insert os;
            os1 = new OpportunitySplit(OpportunityId=opp.Id,
                                                        SplitOwnerId=standardUser.Id, SplitPercentage=20,
                                                        SplitTypeId=ost.Id);
                                                        
            insert os1;
            
            update os1;
            
            Product2 prod = new Product2(
                                            Name='testProduct',
                                            ProductCode = 'TC',
                                            IsActive = TRUE,
                                            Primary_BU__c = 10,
                                            Secondary_BU__c = 10,
                                            Tertiary__c = 10,
                                            Quaternary_BU__c = 10,
                                            Quinary_BU__c = 10);
            insert prod;
            
            
            PriceBookEntry pbe = new PriceBookEntry(
                                                        IsActive = TRUE,
                                                        Pricebook2Id = Test.getStandardPricebookId(),
                                                        Product2Id = prod.Id,
                                                        UnitPrice = 100,
                                                        UseStandardPrice = FALSE);
                                                        
            insert pbe;
            
           
            
            OpportunityLineItem oli = new OpportunityLineItem(
                                                                PricebookEntryId = pbe.Id, 
                                                                OpportunityId = opp.Id,
                                                                Quantity = 2,
                                                                UnitPrice = 200,
                                                                BM_Discretionary_discount_operator__c = '$',
                                                                BM_Discretionary_Discount__c = 2,
                                                                Adjusted_Price__c = 300,
                                                                BM_One_time_discount_operator__c = '$',
                                                                One_Time_Discount__c = 4);
            
            insert oli;
            
            system.debug('---oli---'+oli);
            
            Opportunity_Split_Detail__c oppSplitDetail = new Opportunity_Split_Detail__c();
            oppSplitDetail.Opportunity__c = opp.Id;
            
            insert oppSplitDetail;
            test.startTest();
            Process_Opportnity_Split_Detail posd = new Process_Opportnity_Split_Detail();
            posd.rebuildSplitDetails(new set<Id>{opp.Id});
            
            system.assertEquals([SELECT Id FROM Opportunity_Split_Detail__c].size(), 4);
            
            events = new list<Event__c>([SELECT Id FROM Event__c]);
            delete events;
            
            opp.StageName = 'Closed Booked';
            opp.CloseDate = system.today().addDays(-3);
            update opp;
            
            posd.rebuildSplitDetails(new set<Id>{opp.Id});
            test.stopTest();
        }
    
    }
}