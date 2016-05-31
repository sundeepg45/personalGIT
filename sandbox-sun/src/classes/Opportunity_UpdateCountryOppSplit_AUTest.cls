@isTest
private class Opportunity_UpdateCountryOppSplit_AUTest {
//depreciated	    public static final String SUPER_REGION = 'EMEA';

//depreciated	    public static RecordType preferredRecordType {
//depreciated	        get {
//depreciated	            if(preferredRecordType == null) {
//depreciated	                preferredRecordType = [
//depreciated	                  select Id,name
//depreciated	                  from RecordType
//depreciated	                  where name like :(SUPER_REGION+' %')
//depreciated	                    and SObjectType = 'Opportunity'
//depreciated	                    and IsActive = true
//depreciated	                  limit 1 ];
//depreciated	            }
//depreciated	            return preferredRecordType;
//depreciated	        }
//depreciated	    }

//depreciated	    public static Account account {
//depreciated	        get {
//depreciated	          if(account == null) {
//depreciated	            RecordType recordType = [
//depreciated	              select Id,name
//depreciated	              from RecordType
//depreciated	              where name = 'Strategic'
//depreciated	                and SObjectType = 'Account'
//depreciated	                and IsActive = true
//depreciated	              limit 1 ];
//depreciated	            account = new Account(
//depreciated	              CurrencyIsoCode='USD',
//depreciated	              name='Test Account',
//depreciated	              RecordTypeId=recordType.Id,
//depreciated	              AccountClassification__c=recordType.name );
//depreciated	            insert account;
//depreciated	            account.RecordType = recordType;
//depreciated	          }
//depreciated	          return account;
//depreciated	        }
//depreciated	    }

//depreciated	    public static Opportunity opp {
//depreciated	        get {
//depreciated	          if(opp == null) {
//depreciated	            opp = new Opportunity(
//depreciated	              Name='Opportunity Test',
//depreciated	              CurrencyIsoCode=account.CurrencyIsoCode,
//depreciated	              CloseDate=System.today(),
//depreciated	              ContractStartDate__c = System.today().addDays(1),
//depreciated	              StageName='Unqualified',
//depreciated	              OwnerId=UserInfo.getUserId(),
//depreciated	              AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
//depreciated	              RecordTypeId = preferredRecordType.Id,
//depreciated	              PrimaryBusinessUnit__c=null,
//depreciated	              POC_Status__c=null);
//depreciated	          }
//depreciated	          return opp;
//depreciated	        }
//depreciated	    }
//depreciated	    
//depreciated	    static testMethod void testOpportunity_UpdateCountryOppSplit_AU(){
//depreciated	        
//depreciated	        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
//depreciated	        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

//depreciated	        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
//depreciated	          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
//depreciated	          LocaleSidKey='en_US', ProfileId = standard.Id, 
//depreciated	          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
//depreciated	        insert standardUser;
//depreciated	        
//depreciated	        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
//depreciated	          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
//depreciated	          LocaleSidKey='en_US', ProfileId = admin.Id, 
//depreciated	          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');
//depreciated	        insert adminUser;
//depreciated	        
//depreciated	        OpportunityTeamMember otm;
//depreciated	        OpportunityTeamMember otm1;
//depreciated	        OpportunitySplitType ost;
//depreciated	        OpportunitySplit os;
//depreciated	        OpportunitySplit os1;
//depreciated	        
//depreciated	        system.runAs(adminUser){
//depreciated	            //create opportunity
//depreciated	            insert opp;
//depreciated	            
//depreciated	            //create opportunity team member
//depreciated	            otm = new OpportunityTeamMember(
//depreciated	                                                    TeamMemberRole = 'Sales Manager',
//depreciated	                                                    OpportunityId = opp.Id,
//depreciated	                                                    UserId        = opp.OwnerId);
//depreciated	            insert otm;
//depreciated	            
//depreciated	            otm1 = new OpportunityTeamMember(
//depreciated	                                                    TeamMemberRole = 'Sales Manager',
//depreciated	                                                    OpportunityId = opp.Id,
//depreciated	                                                    UserId        = standardUser.Id);
//depreciated	            insert otm1;
//depreciated	            
//depreciated	            ost =  [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = 'Overlay Credit' Limit 1];
//depreciated	                                                               
//depreciated	            
//depreciated	            os = new OpportunitySplit(OpportunityId=opp.Id,
//depreciated	                                                        SplitOwnerId=opp.ownerId, SplitPercentage=20,
//depreciated	                                                        SplitTypeId=ost.Id);
//depreciated	                                                        
//depreciated	            insert os;
//depreciated	            os1 = new OpportunitySplit(OpportunityId=opp.Id,
//depreciated	                                                        SplitOwnerId=standardUser.Id, SplitPercentage=20,
//depreciated	                                                        SplitTypeId=ost.Id);
//depreciated	                                                        
//depreciated	            insert os1;
//depreciated	            
//depreciated	            //update country of order
//depreciated	            opp.Country_of_Order__c = 'testCountry';
//depreciated	            
//depreciated	            update opp;
//depreciated	            
//depreciated	            system.assertEquals([SELECT Country_of_Order__c FROM Opportunity WHERE Id =: opp.Id].Country_of_Order__c, 'testCountry');
//depreciated	        }
//depreciated	    }
}