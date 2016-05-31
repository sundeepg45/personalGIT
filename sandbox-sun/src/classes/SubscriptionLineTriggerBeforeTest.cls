/**
 * Test the SubscriptionLineTriggerBefore class.
 *
 * @version 2015-01-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - commenting out assigned batch tests
 * 2013-09-19 - created
 */
@isTest
private class SubscriptionLineTriggerBeforeTest {
//depreciated	@isTest
//depreciated	static void assignBatchTest1() {
//depreciated		List<SubscriptionLine__c> subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,subscriptionLines);
//depreciated		Test.startTest();
//depreciated		triggerBefore.assignBatch();
//depreciated		Test.stopTest();
//depreciated		for(SubscriptionLine__c subLine : subscriptionLines) {
//depreciated			System.assertEquals(batchId,subLine.Batch__c);
//depreciated		}
//depreciated	}

//depreciated	@isTest
//depreciated	static void assignBatchTest2() {
//depreciated		List<SubscriptionLine__c> subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
//depreciated		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,subscriptionLines);
//depreciated		Test.startTest();
//depreciated		triggerBefore.assignBatch();
//depreciated		Test.stopTest();
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		for(SubscriptionLine__c subLine : subscriptionLines) {
//depreciated			System.assertEquals(batchId,subLine.Batch__c);
//depreciated		}
//depreciated	}

	@isTest
	static void calcRenewalValuesTest() {
		SubscriptionLine__c subLine = SubscriptionBatchTriggerAfterTest.subscriptionLines.get(0);
		subLine.OrderedQuantity__c = 2.0;
		subLine.SubstituteQuantity__c = 4.0;
		subLine.UnitSellingPrice__c = 90.0;
		subLine.UnitListPrice__c = 100.0;
		subLine.SubstituteItemListPrice__c = 30.0;
		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,new List<SubscriptionLine__c>{subLine});
		Test.startTest();
		triggerBefore.calcRenewalValues();
		Test.stopTest();
		// Since the calculations are not 100% correct, for now we'll just 
		// check that a calculation was performed, not that it is correct.
		System.assertNotEquals(null,subLine.RenewalUnitPrice__c);
		System.assertNotEquals(0.0,subLine.RenewalUnitPrice__c);
		System.assertNotEquals(null,subLine.RenewalTotalPrice__c);
		System.assertNotEquals(0.0,subLine.RenewalTotalPrice__c);
	}

	@isTest
	static void assignCompositeKeyTest() {
		List<SubscriptionLine__c> subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,subscriptionLines);
		triggerBefore.assignCompositeKey();
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00,subscriptionLines[0].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00,subscriptionLines[1].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01,subscriptionLines[2].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01,subscriptionLines[3].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10,subscriptionLines[4].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10,subscriptionLines[5].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11,subscriptionLines[6].OriginalCompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11,subscriptionLines[7].OriginalCompositeKey__c);
	}

	@isTest
	static void syncAccountFieldsTest() {
		Id accountId = SubscriptionTriggerBeforeTest.getAccountId();
		List<SubscriptionLine__c> subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
		// assign only Account__c
		subscriptionLines[0].EntitleToSalesAccount__c = accountId;
		subscriptionLines[0].EntitleToSfAccountId__c = null;
		// assign only AccountId__c
		subscriptionLines[1].EntitleToSalesAccount__c = null;
		subscriptionLines[1].EntitleToSfAccountId__c = accountId;
		// assign only AccountId__c an invalid campaign Id
		Id dummyAccountId = (''+accountId).substring(0,4)+'00000000000';
		subscriptionLines[2].EntitleToSalesAccount__c = null;
		subscriptionLines[2].EntitleToSfAccountId__c = dummyAccountId;
		// assign a completely bogus value to AccountId__c
		subscriptionLines[3].EntitleToSalesAccount__c = null;
		subscriptionLines[3].EntitleToSfAccountId__c = 'DOG FOOD';
		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,subscriptionLines);
		Test.startTest();
		triggerBefore.syncAccountFields();

		System.assertEquals(accountId,subscriptionLines[0].EntitleToSalesAccount__c,'EntitleToSalesAccount__c assignment from EntitleToSalesAccountId__c failed.');

		System.assertEquals(''+accountId,subscriptionLines[0].EntitleToSfAccountId__c,'EntitleToSfAccountId__c changed on EntitleToSfAccount__c assignment from EntitleToSfAccountId__c.');

		System.assertEquals(accountId,subscriptionLines[1].EntitleToSalesAccount__c,'EntitleToSalesAccount__c changed on EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c.');

		System.assertEquals(''+accountId,subscriptionLines[1].EntitleToSfAccountId__c,'EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c failed.');

		System.assertEquals(null,subscriptionLines[2].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c assignment from '+dummyAccountId);

		System.assertEquals(null,subscriptionLines[2].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		System.assertEquals(null,subscriptionLines[3].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c assignment from DOG FOOD');

		System.assertEquals('DOG FOOD',subscriptionLines[3].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptionLines[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptionLines[1].EntitleToSfAccountId__c = accountId;

		triggerBefore = new SubscriptionLineTriggerBefore(new Map<Id,SubscriptionLine__c>{subscriptionLines[1].Id=>subscriptionLines[0]},new List<SubscriptionLine__c>{subscriptionLines[1]});
		triggerBefore.syncAccountFields();

		System.assertEquals(dummyAccountId,subscriptionLines[1].EntitleToSalesAccount__c,'EntitleToSalesAccount__c changed on EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c.');

		System.assertEquals(''+dummyAccountId,subscriptionLines[1].EntitleToSfAccountId__c,'EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c failed.');

		subscriptionLines[1].EntitleToSalesAccount__c = accountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptionLines[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptionLines[1].EntitleToSfAccountId__c,'Expect EntitleToSfAccountId__c to change from '+dummyAccountId);

		subscriptionLines[0].EntitleToSalesAccount__c = dummyAccountId;
		subscriptionLines[0].EntitleToSfAccountId__c = dummyAccountId;
		subscriptionLines[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptionLines[1].EntitleToSfAccountId__c = accountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(accountId,subscriptionLines[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(accountId,subscriptionLines[1].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptionLines[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptionLines[1].EntitleToSfAccountId__c = null;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptionLines[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptionLines[1].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptionLines[1].EntitleToSfAccountId__c = dummyAccountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptionLines[1].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptionLines[1].EntitleToSfAccountId__c,'Expect EntitleToSfAccountId__c to change');

		Test.stopTest();
	}

	@isTest
	static void assignSubscriptionTest() {
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		subscriptions[0].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptions[1].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptions[2].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptions[3].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		Map<Id,Subscription__c> subscriptionMap = SubscriptionBatchTriggerAfterTest.subscriptionMap;
		List<SubscriptionLine__c> subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
		subscriptionLines[0].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptionLines[1].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptionLines[2].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptionLines[3].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptionLines[4].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptionLines[5].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptionLines[6].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		subscriptionLines[7].OriginalCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(null,subscriptionLines);
		Test.startTest();
		triggerBefore.assignSubscription();
		Test.stopTest();
		for(SubscriptionLine__c subLine : subscriptionLines) {
			System.assertNotEquals(null,subLine.OriginalSubscription__c);
			Subscription__c sub = subscriptionMap.get(subLine.OriginalSubscription__c);
			System.assertEquals(sub.CompositeKey__c,subLine.OriginalCompositeKey__c);
			System.assertNotEquals(null,subLine.Subscription__c);
			sub = subscriptionMap.get(subLine.Subscription__c);
			System.assertEquals(sub.CompositeKey__c,subLine.SubscriptionCompositeKey__c);
		}
	}

	@isTest
	static void assignOwnerTest() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		subscription.CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		User u = [
			select Id from User
			where IsActive = true
				and ProfileId = :UserInfo.getProfileId()
				and Id != :UserInfo.getUserId()
			limit 1 ];
		subscription.OwnerId = u.Id;
		AbstractTrigger.setBooleanSettings('Sub_Before.',false);
		AbstractTrigger.setBooleanSettings('Sub_After.',false);
		insert subscription;
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		subscriptionLine.SubscriptionCompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptionLine.Subscription__c = subscription.Id;
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		List<SubscriptionLine__c> subLines = [
			select
				OwnerId,
				SubscriptionOwnerId__c
			from SubscriptionLine__c
			where Id = :subscriptionLine.Id ];
		SubscriptionLineTriggerBefore triggerBefore = new SubscriptionLineTriggerBefore(
			new Map<Id,SubscriptionLine__c>(subLines),
			subLines);
		Test.startTest();
		triggerBefore.assignOwner();
		Test.stopTest();
		System.assertEquals(u.Id,subLines[0].OwnerId);
	}

	@isTest
	static void processTriggerTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<SubscriptionLine__c> subscriptionLines = new List<SubscriptionLine__c>{subscriptionLine};
		Map<Id,SubscriptionLine__c> oldMap = new Map<Id,SubscriptionLine__c>{ subscriptionLine.Id => subscriptionLine };
		List<SubscriptionLine__c> newList = subscriptionLines.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('SubLine_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		SubscriptionLineTriggerBefore.processTrigger(null,newList);
		// update
		newList = subscriptionLines.deepClone(true);
		SubscriptionLineTriggerBefore.processTrigger(oldMap,newList);
		// delete
		SubscriptionLineTriggerBefore.processTrigger(oldMap,null);
	}

	@isTest
	static void deployTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		AbstractTriggerTest.deployTest('SubLine_Before.',new List<SubscriptionLine__c>{subscriptionLine});
	}
}