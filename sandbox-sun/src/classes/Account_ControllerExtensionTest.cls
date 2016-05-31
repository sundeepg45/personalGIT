/**
 * This is a test class for Account_ControllerExtension.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
@isTest
private class Account_ControllerExtensionTest {
	static Account createAccount() {
		return new Account(
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
	}

	@isTest
	static void coverageTest() {
		Account acc = createAccount();
		insert acc;
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Account> accounts = ssc.getRecords();
		System.assertEquals(1,accounts.size());
		System.assertEquals(acc.Id,accounts[0].Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(acc);
		Account_ControllerExtension controller = new Account_ControllerExtension(sc);
		batchable.execute(null,accounts);
		System.assertNotEquals(null,controller.getAccountReadOnlyId());
	}
}