/**
 * This is a test class for OpportunityOwner_Batchable.
 *
 * @version 2013-11-20
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-11-20 - created
 */
@isTest
private class OpportunityOwner_BatchableTest {
	static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name='TestAccount',
					Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
					AccountClassification__c='EMEA - Hosting',
					BillingCity='Testville',
					BillingStreet='1 no where',
					BillingCountry='US',
					Middleware_Supported__c='None',
					OwnerId = UserInfo.getUserId(),
					Ownership = 'Private',
					Total_of_Subsidiaries_if_Parent__c=5,
					VATNumber__c=null,
					What_Markets_are_Targeted__c='Vertical market');
				insert account;
			}
			return account;
		}
	}

	public static User testUser {
		get {
			if(testUser == null) {
				Profile profile = [select id from profile where Name like '%Sales%' limit 1];
				testUser = new User(
					alias = 'test4870', 
					email='testuser4870@testorg.com',
					emailencodingkey='UTF-8',
					lastname='Testing4870',
					languagelocalekey='en_US',
					localesidkey='en_US',
					profileid = profile.Id,
					timezonesidkey='America/Los_Angeles',
					username='testuser4870@testorg.com');
				system.runAs(new User(Id = userInfo.getUserId())) {
					insert testUser;
				}
			}
			return testUser;
		}
	}

	public static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CloseDate=System.today(),
					StageName='Unqualified',
					Owner__c=UserInfo.getUserId(),
					OwnerId=UserInfo.getUserId(),
					AccountId=account.Id,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM',
					RecordTypeId = RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity'),
					Engagement_SA__c=null);
				AbstractTrigger.setBooleanSettings('Opp_Before.',false);
				AbstractTrigger.setBooleanSettings('Opp_After.',false);
				insert opportunity;
				opportunity.Owner__c = testUser.Id;
				update opportunity;
				AbstractTrigger.booleanSettingMap.clear();
				AbstractTrigger.overrideSettingMap.clear();
				Opportunity opp = [select OwnerId, Owner__c, IsOwnerLookupCurrent__c from Opportunity where Id = :opportunity.Id ];
				System.assertEquals(opportunity.OwnerId,opp.OwnerId);
				System.assertEquals(opportunity.Owner__c,opp.Owner__c);
				System.assert(! opp.IsOwnerLookupCurrent__c, 'Expected Is Owner Lookup Current to be false.');
			}
			return opportunity;
		}
	}

	@isTest
	static void startTest() {
		Opportunity opp = opportunity;
		OpportunityOwner_Batchable batchable = new OpportunityOwner_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Opportunity> opps = ssc.getRecords();
		System.assertEquals(1,opps.size());
		System.assertEquals(opportunity.Id,opps[0].Id);
	}

	@isTest
	static void executeTest1() {
		DateTime currentDateTime = DateTime.now();
		Opportunity poc = [select OwnerId, SystemModstamp from Opportunity where Id = :opportunity.Id ];
		OpportunityOwner_Batchable batchable = new OpportunityOwner_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Opportunity> opps = ssc.getRecords();
		System.assertEquals(1,opps.size());
		System.assertEquals(poc.Id,opps[0].Id);
		Test.startTest();
		batchable.execute(null,opps);
		Test.stopTest();
		System.assert(batchable.lastProcessedDateTime >= poc.SystemModstamp,'Expected a more recent lastProcessedDateTime');
		Opportunity opp = [select OwnerId, Owner__c, IsOwnerLookupCurrent__c from Opportunity where Id = :opportunity.Id ];
		System.assertEquals(poc.OwnerId,opp.OwnerId);
		System.assertEquals(poc.OwnerId,opp.Owner__c);
		System.assert(opp.IsOwnerLookupCurrent__c, 'Expected Is Owner Lookup Current to be true.');
	}

	@isTest
	static void finishTest() {
		OpportunityOwner_Batchable batchable = new OpportunityOwner_Batchable();
		batchable.lastProcessedDateTime = DateTime.now();
		batchable.lastProcessedDateTimeMax = DateTime.now().addMinutes(-1);
		Test.startTest();
		try {
			batchable.finish((Database.BatchableContext)null);
		}
		catch(Exception e) {}
		batchable.finish((AsyncApexJob)null);
		Test.stopTest();
	}

	@isTest
	static void sendErrorsTest() {
		OpportunityOwner_Batchable batchable = new OpportunityOwner_Batchable();
		batchable.errorList.add('anything');
		Test.startTest();
		System.assertNotEquals(null,batchable.sendErrors(null));
		Test.stopTest();
	}
}