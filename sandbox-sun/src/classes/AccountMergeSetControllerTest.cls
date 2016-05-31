/**
 * This is a test class for AccountMergeSetControllerTest.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2016-01-15
 * 2016-01-15 - created
 */
@isTest
private  class AccountMergeSetControllerTest {
	static List<Account> accounts {
		get {
			if(accounts == null) {
				CDH_Party__c p = new CDH_Party__c(
					Name = 'ACCOUNT-TEST',
					CDH_Party_Name__c = 'ACCOUNT-TEST',
					CDH_Party_Number_Ext__c = 'ACCOUNT-TEST',
					CDH_Party_Type__c = 'ORGANIZATION');
				insert p;
				Account a = new Account(
					Name='TestAccount',
					Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
					AccountClassification__c='EMEA - Hosting',
					BillingCity='Testville',
					BillingStreet='1 no where',
					BillingCountry='US',
					CDH_Party_Name__c = p.Id,
					Middleware_Supported__c='None',
					OwnerId = UserInfo.getUserId(),
					Ownership = 'Private',
					Total_of_Subsidiaries_if_Parent__c=5,
					VATNumber__c=null,
					What_Markets_are_Targeted__c='Vertical market');
				accounts = new List<Account>{a,a.clone(),a.clone()};
				accounts[1].Data_Status__c=AccountTriggerBeforeLock.PENDING_SALES_OPS;
				accounts[2].Data_Status__c=AccountTriggerBeforeLock.LOCKED;
			}
			return accounts;
		}
	}
	static ApexPages.StandardSetController stdSetController {
		get {
			if(stdSetController == null) {
				if((! accounts.isEmpty()) && accounts[0].Id == null) {
					insert accounts;
				}
				Set<Id> accountIds = new Map<Id,Account>(accounts).keySet();
				stdSetController = new ApexPages.StandardSetController(Database.getQueryLocator([select Id from Account where Id in :accountIds]));
				stdSetController.setPageSize(100);
//				System.assertEquals(accountIds.size(),stdSetController.getRecords().size());
				stdSetController.setSelected(stdSetController.getRecords());
			}
			return stdSetController;
		}
		set;
	}

	@IsTest
	static void constructAndQueryTest() {
		LongSetting__c accountMergeLimitSetting = LongSetting__c.getInstance(AccountMergeSetController.ACCOUNT_MERGE_LIMIT_SETTING);
		if(accountMergeLimitSetting == null) {
			accountMergeLimitSetting = new LongSetting__c(Name=AccountMergeSetController.ACCOUNT_MERGE_LIMIT_SETTING,Value__c=3);
		}
		accountMergeLimitSetting.Value__c = 2;
		upsert accountMergeLimitSetting;
		Test.startTest();
		// test with 3 accounts
		AccountMergeSetController controller = new AccountMergeSetController(stdSetController);
		System.assertEquals(1,ApexPages.getMessages().size());
		System.assertEquals(3,controller.accounts.size());
		// test with 2 accounts
		delete accounts.remove(0);
		stdSetController = null;
		controller = new AccountMergeSetController(stdSetController);
		System.assertEquals(1,ApexPages.getMessages().size());
		System.assertEquals(2,controller.accounts.size());
		// we might as well do the 2 account merge test here
		System.assertNotEquals(null,controller.mergeAccounts());
		System.assertEquals(1,ApexPages.getMessages().size());
		System.assertEquals(1,controller.accounts.size());
		accounts.remove(1);
		// test with 1 account
		stdSetController = null;
		controller = new AccountMergeSetController(stdSetController);
		System.assertEquals(2,ApexPages.getMessages().size());
		System.assertEquals(1,controller.accounts.size());
		// test with no accounts
		delete accounts.remove(0);
		stdSetController = null;
		controller = new AccountMergeSetController(stdSetController);
		// the same message can only be added once.
		//System.assertEquals(3,ApexPages.getMessages().size());
		System.assertEquals(null,controller.accounts);
		Test.stopTest();
	}

	@isTest
	static void selectAndMergeTest() {
		AccountMergeSetController controller = new AccountMergeSetController(stdSetController);
		System.assertEquals(0,ApexPages.getMessages().size());
		List<AccountMergeSetController.FieldSelect> fsList = controller.fieldSelectList;
		System.assertNotEquals(0,fsList.size());
		System.assertEquals(null,fsList[0].getFieldSetMember());
		System.assertEquals(accounts[0].Id,fsList[0].accountId);

		List<AccountMergeSetController.FieldSelect> fsList1 = fsList.clone();
		fsList1.remove(0);
		for(AccountMergeSetController.FieldSelect fs : fsList1 ) {
			System.assertNotEquals(null,fs.getFieldSetMember());
		}

		List<AccountMergeSetController.FieldSelect> fsList2 = new List<AccountMergeSetController.FieldSelect>();
		List<AccountMergeSetController.FieldSelect> fsList3 = new List<AccountMergeSetController.FieldSelect>();
		for(AccountMergeSetController.FieldSelect fs : controller.fieldSelectList ) {
			if(fs.accountId != null) {
				fsList2.add(fs);
			}
			else {
				fsList3.add(fs);
			}
		}

		for(Account a : accounts) {
			controller.defaultAccountId = a.Id;
			controller.selectAll();
			System.assertEquals(0,ApexPages.getMessages().size());
			for(AccountMergeSetController.FieldSelect fs : fsList2 ) {
				System.assertEquals(a.Id,fs.accountId);
			}
			for(AccountMergeSetController.FieldSelect fs : fsList3 ) {
				System.assertEquals(null,fs.accountId);
			}
		}
		System.assertNotEquals(null,controller.mergeAccounts());
		System.assertEquals(0,ApexPages.getMessages().size());
		System.assertEquals(1,controller.accounts.size());
		System.assertNotEquals(null,controller.cancel());
	}
}