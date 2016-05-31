/**
 * Test the SubscriptionPartnerTriggerAfter class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2013-09-19
 * 2013-09-19 - created
 */
@isTest
private class SubscriptionPartnerTriggerAfterTest {

	@isTest
	static void updateSubscriptionPartnerRelationshipTest() {
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		subscriptions[0].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptions[1].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptions[2].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptions[3].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		Map<Id,Subscription__c> subscriptionMap = SubscriptionBatchTriggerAfterTest.subscriptionMap;
		Map<Id,SubscriptionPartner__c> subscriptionPartnerMap = SubscriptionBatchTriggerAfterTest.subscriptionPartnerMap;
		SubscriptionPartnerTriggerBefore.assignCompositeKey(subscriptionPartnerMap.values());
		SubscriptionPartnerTriggerAfter triggerAfter = new SubscriptionPartnerTriggerAfter(null,subscriptionPartnerMap);
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
		SubscriptionPartner__c subscriptionPartner = SubscriptionBatchTriggerAfterTest.subscriptionPartners[0];
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('SubPart_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		SubscriptionPartnerTriggerAfter.processTrigger(null,new Map<Id,SubscriptionPartner__c>{null=>subscriptionPartner});
		// insert the subscriptionPartner, again with the triggers off
		insert subscriptionPartner;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('SubPart_After.',true);
		SubscriptionPartner__c subscriptionPartner2 = subscriptionPartner.clone(true);
		Test.startTest();
		// insert test
		SubscriptionPartnerTriggerAfter.processTrigger(null,new Map<Id,SubscriptionPartner__c>{subscriptionPartner2.Id=>subscriptionPartner2});
		// update test
		SubscriptionPartnerTriggerAfter.processTrigger(new Map<Id,SubscriptionPartner__c>{subscriptionPartner.Id=>subscriptionPartner},new Map<Id,SubscriptionPartner__c>{subscriptionPartner2.Id=>subscriptionPartner2});
		// delete test
		SubscriptionPartnerTriggerAfter.processTrigger(new Map<Id,SubscriptionPartner__c>{subscriptionPartner.Id=>subscriptionPartner},null);
		Test.stopTest();
	}

	@isTest
	static void deployTest() {
		SubscriptionPartner__c subscriptionPartner = SubscriptionBatchTriggerAfterTest.subscriptionPartners[0];
		AbstractTriggerTest.deployTest('SubPart_After.',new List<SubscriptionPartner__c>{subscriptionPartner});
	}
}