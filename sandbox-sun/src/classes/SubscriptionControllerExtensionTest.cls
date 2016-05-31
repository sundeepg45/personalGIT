/**
 * This is a test class for SubscriptionControllerExtension methods.
 *
 * @version 2013-10-16
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-10-16 - Created
 */
@isTest
private class SubscriptionControllerExtensionTest {
	static Subscription__c subscription { get {
		if(subscription == null) {
			subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
			subscription.Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
			insert subscription;
		}
		return subscription;
	}}

	@isTest
	static void standardControllerTests() {
		ApexPages.StandardController stdController = new ApexPages.StandardController(subscription);
		SubscriptionControllerExtension extension = new SubscriptionControllerExtension(stdController);
		extension.subscription.Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
		System.assert(extension.getCanEdit(),'Expected editable');
		System.assertNotEquals(null,extension.edit());
		System.assert(extension.getCanCreateRenewalOpportunity(),'Not ready');
//		System.assertNotEquals(null,extension.createRenewalOpportunity());
		Test.setCurrentPage(new PageReference('/apex/Subscription_Edit?id='+stdController.getId()+'&Status__c='+SubscriptionControllerExtension.READY_STATUS));
		System.assert(extension.getCanEdit(),'Expected editable');
		System.assertNotEquals(null,extension.edit());
		extension = new SubscriptionControllerExtension(stdController);
		Test.setCurrentPage(new PageReference('/apex/Subscription_Edit?id='+stdController.getId()+'&Status__c='+SubscriptionControllerExtension.DO_NOT_LOAD_STATUS));
		extension.subscription.Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
		System.assert(extension.getCanEdit(),'Expected editable');
		System.assertNotEquals(null,extension.edit());
	}

	@isTest
	static void standardSetControllerTests() {
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Subscription__c>{subscription});
		stdSetController.setSelected(new List<Subscription__c>{subscription});
		SubscriptionControllerExtension extension = new SubscriptionControllerExtension(stdSetController);
		extension.subscriptionList[0].Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
		System.assertNotEquals(null,extension.changeStatusReadyForProcessing());
		extension.subscriptionList[0].Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
		System.assertNotEquals(null,extension.changeStatusReadyForSSI());
		extension.subscriptionList[0].Status__c = SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS;
		System.assertNotEquals(null,extension.changeStatusDoNotLoad());
	}

	@isTest
	static void standardSetControllerErrorTests() {
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Subscription__c>{});
		SubscriptionControllerExtension extension = new SubscriptionControllerExtension(stdSetController);
		extension.subscriptionList.add(new Subscription__c(Status__c=SubscriptionControllerExtension.HOLD_FOR_DECISION_STATUS));
		System.assertEquals(null,extension.changeStatusDoNotLoad());
	}

	@isTest
	static void downloadSSITest() {
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Subscription__c>{});
		SubscriptionControllerExtension extension = new SubscriptionControllerExtension(stdSetController);
		extension.subscriptionReportCriteria.StartDate__c = Date.today();
		extension.subscriptionReportCriteria.SuperRegion__c = 'APAC';
		subscription.Status__c = SubscriptionControllerExtension.READY_FOR_SSI_STATUS;
		subscription.SuperRegion__c = 'APAC';
		subscription.SSI_InScope__c = true;
		update subscription;
		extension.subscriptionReportCriteria.EndDate__c = Date.today();
		System.assertEquals(null,extension.downloadSSI());
		insert new Document(
			Body=Blob.valueOf('anything'),
			DeveloperName='subscriptions',
			Name='subscriptions',
			FolderId=UserInfo.getUserId());
		Test.startTest();
		System.assertNotEquals(null,extension.downloadSSI());
		Test.stopTest();
		Subscription__c sub = [select SSI_InScope__c, Status__c from Subscription__c where Id = :subscription.Id ];
		System.assertEquals(subscription.SSI_InScope__c,sub.SSI_InScope__c);
		System.assertEquals(SubscriptionControllerExtension.SUCCESS_STATUS,sub.Status__c);
	}
}