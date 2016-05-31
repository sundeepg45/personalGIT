/**
 * Test the SubscriptionLineTriggerAfter class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2013-09-19
 * 2013-09-19 - created
 */
@isTest
private class SubscriptionLineTriggerAfterTest {
	@isTest
	static void updateSubscriptionTest() {
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
		subscriptionLine.RenewalTotalPrice__c = 1000.00;
		SubscriptionLineTriggerAfter triggerAfter = new SubscriptionLineTriggerAfter(null,new Map<Id,SubscriptionLine__c>{null=>subscriptionLine});
		Test.startTest();
		System.runAs(u) {
			triggerAfter.updateSubscriptions();
		}
		Test.stopTest();
		Subscription__c sub = [
			select LastModifiedById
			from Subscription__c
			where Id = :subscription.Id ];
		System.assertEquals(u.Id,sub.LastModifiedById);
	}

	@isTest
	static void updateEntitlementsTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[1];
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[1];
		subscriptionLine.OriginalCompositeKey__c = subscription.CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscription.EntitleToAccountNumber__c = subscriptionLine.EntitleToAccountNumber__c = '-1';
		subscription.EntitleToCDHPartyNumber__c = subscriptionLine.EntitleToCDHPartyNumber__c = '-1';
		subscription.EntitleToCDHPartySiteNumber__c = subscriptionLine.EntitleToCDHPartySiteNumber__c = '-2';
		subscription.EntitleToContCDHPartyNumber__c = subscriptionLine.EntitleToContCDHPartyNumber__c = '-3';
		subscription.EntitleToAddress1__c = null;
		subscription.EntitleToAddress2__c = null;
		subscription.EntitleToCity__c = null;
		subscription.EntitleToContactEmail__c = null;
		subscription.EntitleToContactFirstName__c = null;
		subscription.EntitleToContactLastName__c = null;
		subscription.EntitleToContactName__c = null;
		subscription.EntitleToContactPhone__c = null;
		subscription.EntitleToCountry__c = null;
		subscription.EntitleToPostalCode__c = null;
		subscription.EntitleToState__c = null;
		subscriptionLine.EntitleToAddress1__c = 'address 1';
		subscriptionLine.EntitleToAddress2__c = 'address 2';
		subscriptionLine.EntitleToCity__c = 'city';
		subscriptionLine.EntitleToContactEmail__c = 'test@nowhere.com';
		subscriptionLine.EntitleToContactFirstName__c = 'firstname';
		subscriptionLine.EntitleToContactLastName__c = 'lastname';
		subscriptionLine.EntitleToContactName__c = 'firsname lastname';
		subscriptionLine.EntitleToContactPhone__c = '1-800-555-1212';
		subscriptionLine.EntitleToCountry__c = 'US';
		subscriptionLine.EntitleToPostalCode__c = '49001';
		subscriptionLine.EntitleToState__c = 'MI';
		AbstractTrigger.setBooleanSettings('Sub_Before.',false);
		AbstractTrigger.setBooleanSettings('Sub_After.',false);
		insert subscription;
		subscriptionLine.OriginalSubscription__c = subscription.Id;
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		SubscriptionLineTriggerAfter triggerAfter = new SubscriptionLineTriggerAfter(new Map<Id,SubscriptionLine__c>{subscriptionLine.Id=>subscriptionLine},new Map<Id,SubscriptionLine__c>{subscriptionLine.Id=>subscriptionLine});
		Test.startTest();
		triggerAfter.updateSubscriptions();
		Test.stopTest();
		Subscription__c sub = [
			select
				Id,
				EntitleToAddress1__c,
				EntitleToAddress2__c,
				EntitleToCity__c,
				EntitleToContactEmail__c,
				EntitleToContactFirstName__c,
				EntitleToContactLastName__c,
				EntitleToContactName__c,
				EntitleToContactPhone__c,
				EntitleToCountry__c,
				EntitleToPostalCode__c,
				EntitleToState__c
			from Subscription__c
			where Id = :subscription.Id ];
		System.assertEquals(subscriptionLine.EntitleToAddress1__c,sub.EntitleToAddress1__c);
		System.assertEquals(subscriptionLine.EntitleToAddress2__c,sub.EntitleToAddress2__c);
		System.assertEquals(subscriptionLine.EntitleToCity__c,sub.EntitleToCity__c);
		System.assertEquals(subscriptionLine.EntitleToState__c,sub.EntitleToState__c);
		System.assertEquals(subscriptionLine.EntitleToPostalCode__c,sub.EntitleToPostalCode__c);
		System.assertEquals(subscriptionLine.EntitleToContactEmail__c,sub.EntitleToContactEmail__c);
		System.assertEquals(subscriptionLine.EntitleToContactFirstName__c,sub.EntitleToContactFirstName__c);
		System.assertEquals(subscriptionLine.EntitleToContactLastName__c,sub.EntitleToContactLastName__c);
		System.assertEquals(subscriptionLine.EntitleToContactName__c,sub.EntitleToContactName__c);
		System.assertEquals(subscriptionLine.EntitleToContactPhone__c,sub.EntitleToContactPhone__c);
	}

	@isTest
	static void processTriggerTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		SubscriptionLineTriggerAfter.processTrigger(null,new Map<Id,SubscriptionLine__c>{null=>subscriptionLine});
		// insert the subscriptionLine, again with the triggers off
		insert subscriptionLine;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('SubLine_After.',true);
		SubscriptionLine__c subscriptionLine2 = subscriptionLine.clone(true);
		Test.startTest();
		// insert test
		SubscriptionLineTriggerAfter.processTrigger(null,new Map<Id,SubscriptionLine__c>{subscriptionLine2.Id=>subscriptionLine2});
		// update test
		SubscriptionLineTriggerAfter.processTrigger(new Map<Id,SubscriptionLine__c>{subscriptionLine.Id=>subscriptionLine},new Map<Id,SubscriptionLine__c>{subscriptionLine2.Id=>subscriptionLine2});
		// delete test
		SubscriptionLineTriggerAfter.processTrigger(new Map<Id,SubscriptionLine__c>{subscriptionLine.Id=>subscriptionLine},null);
		Test.stopTest();
	}

	@isTest
	static void deployTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		AbstractTriggerTest.deployTest('SubLine_After.',new List<SubscriptionLine__c>{subscriptionLine});
	}
}