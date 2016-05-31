/**
 * This is a test class for AccountReadOnly_Batchable.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
@isTest
private class AccountReadOnly_BatchableTest {
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
	static void startTest() {
		Account acc = createAccount();
		insert acc;
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Account> accounts = ssc.getRecords();
		System.assertEquals(1,accounts.size());
		System.assertEquals(acc.Id,accounts[0].Id);
	}

	@isTest
	static void executeTest1() {
		Account acc = createAccount();
		insert acc;
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		Test.startTest();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Account> accounts = ssc.getRecords();
		System.assertEquals(1,accounts.size());
		System.assertEquals(acc.Id,accounts[0].Id);
		batchable.execute(null,accounts);
		System.assertEquals(1,[select Count() from AccountReadOnly__c where ExternalId__c = :''+acc.Id]);
		delete acc;
		ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		accounts = ssc.getRecords();
		System.assertEquals(1,accounts.size());
		System.assertEquals(acc.Id,accounts[0].Id);
		System.assertEquals(0,[select Count() from AccountReadOnly__c where ExternalId__c = :''+acc.Id]);
		batchable.execute(null,accounts);
		System.assertEquals(0,[select Count() from AccountReadOnly__c where ExternalId__c = :''+acc.Id]);
	}

	@isTest
	static void executeTest2() {
		Account acc = createAccount();
		insert acc;
		Account acc2 = createAccount();
		acc2.ParentId = acc.Id;
		insert acc2;
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		Test.startTest();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Account> accounts = ssc.getRecords();
		System.assertEquals(2,accounts.size());
		batchable.execute(null,accounts);
		System.assertEquals(2,[select Count() from AccountReadOnly__c]);
		delete acc;
		accounts = [select IsDeleted, LastModifiedDate from Account where Id = :acc.Id All Rows];
		batchable.execute(null,accounts);
		System.assertEquals(1,[select Count() from AccountReadOnly__c]);
		ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		accounts = ssc.getRecords();
		System.assertEquals(2,accounts.size());
		System.assertEquals(acc.Id,accounts[0].Id);
		System.assertEquals(1,[select Count() from AccountReadOnly__c]);
		batchable.execute(null,accounts);
		Test.stopTest();
		System.assertEquals(1,[select Count() from AccountReadOnly__c]);
	}

	@isTest
	static void exceptionTest1() {
		Account acc = createAccount();
		insert acc;
		List<Account> accounts = [select IsDeleted, LastModifiedDate from Account where Id = :acc.Id All Rows];
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		Test.startTest();
		batchable.execute(null,null);
		System.assert(! batchable.errorList.isEmpty(),'Expected an exception');
		batchable = new AccountReadOnly_Batchable();
		batchable.execute(null,accounts);
		Test.stopTest();
		System.assert(! batchable.errorList.isEmpty(),'Expected a field reference error');
	}

	@isTest
	static void finishTest() {
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
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
		AccountReadOnly_Batchable batchable = new AccountReadOnly_Batchable();
		batchable.errorList.add('anything');
		Test.startTest();
		System.assertNotEquals(null,batchable.sendErrors(null));
		Test.stopTest();
	}
}