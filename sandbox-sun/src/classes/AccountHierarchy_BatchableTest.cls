/**
 * This is the test class for AccountHierarchy_Batchable.
 *
 * @version 2013-09-03
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-29 - created
 */
@IsTest
private class AccountHierarchy_BatchableTest {
	static Account parent { get {
		if(parent == null) {
			RecordType recordType = [
				select Id,name
				from RecordType
				where name = 'Strategic'
					and SObjectType = 'Account'
					and IsActive = true
				limit 1 ];
			parent = new Account(
				name='parent account',
				RecordTypeId=recordType.Id,
				AccountClassification__c='Strategic',
				CurrencyIsoCode='USD');
			insert parent;
			parent.RecordType = recordType;
		}
		return parent;
	}}

	static Account account { get {
		if(account == null) {
			// create an account
			account = new Account(
				ParentId = parent.Id,
				CurrencyIsoCode='USD',
				name='Test Account',
				RecordTypeId=parent.RecordTypeId,
				AccountClassification__c=parent.RecordType.Name,
				BillingCity = 'Raleigh',
				BillingCountry = 'US',
				BillingPostalCode = '27606',
				BillingState = 'North Carolina',
				BillingStreet = '1801 Varsity Drive',
				OracleAccountNumber__c = '12345',
				ShippingCity = 'Raleigh',
				ShippingCountry = 'US',
				ShippingPostalCode = '27606',
				ShippingState = 'North Carolina',
				ShippingStreet = '1801 Varsity Drive',
				VATNumber__c = '67890');
			insert account;
			account.RecordType = parent.RecordType;
		}
		return account;
	}}

	@IsTest
	static void startAndExecuteTest() {
		AccountHierarchy_Batchable.CATCHUP_COUNT=0;
		Set<Id> accountIds = new Set<Id>{parent.Id,account.Id};
		AccountHierarchy_Batchable batchable = new AccountHierarchy_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		ssc.setPageSize(100);
		List<Account> accounts = ssc.getRecords();
		System.assertEquals(1,accounts.size());
		System.assertEquals(account.Id,accounts[0].Id);
		AccountHierarchy_Batchable.CATCHUP_COUNT=200;
		Test.startTest();
		ssc = new ApexPages.StandardSetController(batchable.start(null));
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		List<AccountHierarchy__c> accountHierarchies = [
			select
				Account__c
			from AccountHierarchy__c ];
		System.assertEquals(1,accountHierarchies.size());
		System.assertEquals(account.Id,accountHierarchies[0].Account__c);
		ssc.setPageSize(100);
		accountHierarchies = ssc.getRecords();
		System.assertEquals(1,accountHierarchies.size());
		System.assertEquals(account.Id,accountHierarchies[0].Account__c);
		batchable.execute(null,accountHierarchies);
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		Test.stopTest();
		accountHierarchies = [
			select
				Account__c,
				Account__r.ParentId,
				Parent__r.Account__c
			from AccountHierarchy__c ];
		System.assertEquals(2,accountHierarchies.size());
		for(AccountHierarchy__c ah : accountHierarchies) {
			System.assert(accountIds.contains(ah.Account__c),'Unexpected Account Id '+ah.Account__c);
			System.assertEquals(ah.Account__r.ParentId,(ah.Parent__r != null)?ah.Parent__r.Account__c:null);
		}
	}

	@IsTest
	static void executeDeleteTest() {
		List<AccountHierarchy__c> accountHierarchies = new List<AccountHierarchy__c>{
			new AccountHierarchy__c(Account__c=parent.Id,AccountId__c=parent.Id),
			new AccountHierarchy__c(Account__c=account.Id,AccountId__c=account.Id)};
		insert accountHierarchies;
		accountHierarchies[0].AccountId__c=account.Id;
		accountHierarchies[1].AccountId__c=parent.Id;
		AccountHierarchy_Batchable batchable = new AccountHierarchy_Batchable();
		Test.startTest();
		batchable.execute(null,accountHierarchies);
		System.assertEquals(0,batchable.errorList.size(),batchable.errorList);
		Test.stopTest();
		System.assertEquals(0,[select count() from AccountHierarchy__c]);
	}

	@isTest
	static void finishTest() {
		AccountHierarchy_Batchable batchable = new AccountHierarchy_Batchable();
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
		AccountHierarchy_Batchable batchable = new AccountHierarchy_Batchable();
		batchable.errorList.add('anything');
		Test.startTest();
		System.assertNotEquals(null,batchable.sendErrors(null));
		Test.stopTest();
	}
}