/**
 * This is the test class for Subscription_Batchable.
 *
 * @version 2015-03-17
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-03-17 - update tests for changes to time restrictions and deletes
 * 2015-02-19 - set AGE_IN_MINUTES to 0 for testing
 * 2014-10-15 - added processErrorMapTest
 * 2013-10-17 - created
 */
@isTest
private class Subscription_BatchableTest {
	@IsTest
	static void startAndExecuteTest() {
		Subscription_Batchable.MIN_AGE_IN_MINUTES = -1000;
		Id oppId = Opportunity_SubscriptionTest.getOpportunityId();
		Opportunity_SubscriptionTest.subscription1.Opportunity__c = oppId;
		Opportunity_SubscriptionTest.subscription1.Status__c = SubscriptionControllerExtension.READY_STATUS;
		Id subscriptionId = Opportunity_SubscriptionTest.getSubscriptionId();
		System.assert(! Opportunity_SubscriptionTest.subscriptionLineMap.isEmpty());
		Subscription_Batchable batchable = new Subscription_Batchable();
		Test.startTest();
		System.assert(batchable.hasWork(),'Expected to have work.');
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		Opportunity opp = [
			select IsDeleted
			from Opportunity
			where Id = :oppId
			ALL ROWS ];
		System.assert(opp.IsDeleted, 'Expecting opportunity to be deleted...');
		ssc.setPageSize(100);
		List<Subscription__c> subscriptions = ssc.getRecords();
		System.assertEquals(1,subscriptions.size());
		System.assertEquals(subscriptionId,subscriptions[0].Id);
		System.assertEquals(null,subscriptions[0].Opportunity__c);
		undelete opp;
		subscriptions[0].Opportunity__c = oppId;
		batchable.execute(null,subscriptions);
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		opp = [
			select IsDeleted
			from Opportunity
			where Id = :oppId
			ALL ROWS ];
		System.assert(opp.IsDeleted, 'Expecting opportunity to be deleted...');
		subscriptions[0].Opportunity__c = null;
		batchable.execute(null,subscriptions);
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		// now for code coverage, try an exception test
		subscriptions = [select Id from Subscription__c ];
		batchable.execute(null,subscriptions);
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		Test.stopTest();
	}

	@isTest
	static void finishTest() {
		Subscription_Batchable batchable = new Subscription_Batchable();
		Test.startTest();
		try {
			batchable.finish((Database.BatchableContext)null);
		}
		catch(Exception e) {}
		Test.stopTest();
	}

	@isTest
	static void sendErrorsTest() {
		Subscription_Batchable batchable = new Subscription_Batchable();
		batchable.errorList.add('anything');
		Test.startTest();
		System.assertNotEquals(null,batchable.sendErrors(null));
		Test.stopTest();
	}

	@isTest
	static void processErrorMapTest() {
		Database.SaveResult sr = Database.update(new User(Id=UserInfo.getUserId(),Email='DogAtHomeWork'),false);
		Map<Id,List<Database.Error>> errorMap = new Map<Id,List<Database.Error>>{sr.getId() => sr.getErrors()};
		errorMap.put(sr.getId(),sr.getErrors());
		Subscription_Batchable batchable = new Subscription_Batchable();
		batchable.processErrorMap(errorMap);
		System.assertNotEquals(0,batchable.errorList.size());
		Test.startTest();
		batchable.execute(null,new List<Subscription__c>{null});
		Test.stopTest();
		// the e-mail processing will be called, so the error list will be cleared
		System.assertEquals(0,batchable.errorList.size());
	}
}