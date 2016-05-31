/**
 * Test the SubscriptionTriggerAfter class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2013-09-19
 * 2013-09-19 - created
 */
@isTest
private class SubscriptionTriggerAfterTest {
	@isTest
	static void matchAccounts() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		AbstractTrigger.setBooleanSettings('Sub_Before.',false);
		AbstractTrigger.setBooleanSettings('Sub_After.',false);
		insert subscription;
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		subscriptionLine.Subscription__c = subscription.Id;
		subscriptionLine.OriginalSubscription__c = subscription.Id;
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		subscriptionLine.ErrorMessage__c = 'TESTING';
		SubscriptionTriggerBefore.updatedLines = new List<SubscriptionLine__c>{ subscriptionLine };
		SubscriptionError__c subErr = new SubscriptionError__c(
			Reason__c = 'TESTING',
			Details__c = 'MORE TESTING',
			Subscription__c = subscription.Id );
		SubscriptionTriggerBefore.errorList = new List<SubscriptionError__c>{ subErr };
		SubscriptionTriggerAfter triggerAfter = new SubscriptionTriggerAfter(null,new Map<Id,Subscription__c>{subscription.Id=>subscription});

		Test.startTest();
		triggerAfter.matchAccounts();
		Test.stopTest();

		System.assertEquals(null,SubscriptionTriggerBefore.errorList);
		SubscriptionError__c subErr2 = [
			select Id 
			from SubscriptionError__c
			where Subscription__c = :subscription.Id ];

		System.assertEquals(null,SubscriptionTriggerBefore.updatedLines);
		SubscriptionLine__c subLine2 = [
			select ErrorMessage__c
			from SubscriptionLine__c
			where Id = :subscriptionLine.Id ];
		System.assertEquals(subscriptionLine.ErrorMessage__c, subLine2.ErrorMessage__c );
	}

	@isTest
	static void updateSubscriptionLinesTest() {
		User u = [
			select Id from User
			where ProfileId = :UserInfo.getProfileId()
				and IsActive = true
				and Id != :UserInfo.getUserId()
			limit 1 ];
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		subscription.CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscription.OwnerId = UserInfo.getUserId();
		subscriptionLine.SubscriptionCompositeKey__c = subscription.CompositeKey__c;
		subscriptionLine.OwnerId = u.Id;
		subscriptionLine.CurrencyIsoCode='USD';
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		AbstractTrigger.setBooleanSettings('Sub_After.',false);
		insert subscription;
		SubscriptionTriggerAfter triggerAfter = new SubscriptionTriggerAfter(null,new Map<Id,Subscription__c>{subscription.Id=>subscription});
		Test.startTest();
		triggerAfter.updateSubscriptionLines();
		Test.stopTest();
		SubscriptionLine__c subLine = [
			select
				CurrencyIsoCode,
				OwnerId,
				Subscription__c,
				SubscriptionCompositeKey__c
			from SubscriptionLine__c
			where Id = :subscriptionLine.Id ];
		System.assertEquals(subscription.CurrencyIsoCode,subLine.CurrencyIsoCode);
		System.assertEquals(UserInfo.getUserId(),subLine.OwnerId);
		System.assertEquals(subscription.Id,subLine.Subscription__c);
		System.assertEquals(subscription.CompositeKey__c,subLine.SubscriptionCompositeKey__c);
	}

	@isTest
	static void updateSubscriptionPartnerRelationshipTest() {
		Map<Id,SubscriptionPartner__c> subscriptionPartnerMap = SubscriptionBatchTriggerAfterTest.subscriptionPartnerMap;
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		subscriptions[0].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptions[1].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptions[2].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptions[3].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		Map<Id,Subscription__c> subscriptionMap = SubscriptionBatchTriggerAfterTest.subscriptionMap;
		SubscriptionTriggerAfter triggerAfter = new SubscriptionTriggerAfter(null,subscriptionMap);
		Test.startTest();
		triggerAfter.updateSubscriptionPartnerRelationship();
		Test.stopTest();
		List<SubscriptionPartnerRelationship__c> relationships = [
			select
				Subscription__c,
				SubscriptionPartner__c
			from SubscriptionPartnerRelationship__c
			where Subscription__c in : subscriptionMap.keySet()
				and SubscriptionPartner__c in : subscriptionPartnerMap.keySet() ];
		for(SubscriptionPartnerRelationship__c relationship : relationships) {
			subscriptionMap.keySet().remove(relationship.Subscription__c);
			subscriptionPartnerMap.keySet().remove(relationship.SubscriptionPartner__c);
		}
		System.assert(subscriptionMap.isEmpty(),'Failed to map all subscriptions');
		System.assert(subscriptionPartnerMap.isEmpty(),'Failed to map all subscription partners');
	}

	@isTest
	static void processTriggerTest() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Sub_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		SubscriptionTriggerAfter.processTrigger(null,new Map<Id,Subscription__c>{null=>subscription});
		// insert the subscription, again with the triggers off
		insert subscription;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Sub_After.',true);
		Subscription__c subscription2 = subscription.clone(true);
		Test.startTest();
		// insert test
		SubscriptionTriggerAfter.processTrigger(null,new Map<Id,Subscription__c>{subscription2.Id=>subscription2});
		// update test
		SubscriptionTriggerAfter.processTrigger(new Map<Id,Subscription__c>{subscription.Id=>subscription},new Map<Id,Subscription__c>{subscription2.Id=>subscription2});
		// delete test
		SubscriptionTriggerAfter.processTrigger(new Map<Id,Subscription__c>{subscription.Id=>subscription},null);
		Test.stopTest();
	}

	@isTest
	static void deployTest() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		AbstractTriggerTest.deployTest('Sub_After.',new List<Subscription__c>{subscription});
	}
}