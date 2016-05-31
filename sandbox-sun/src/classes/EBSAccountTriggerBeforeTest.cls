/**
 * This class contains unit tests for validating the behavior of 
 * EBSAccountTriggerBefore.cls
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2015-08-27
 * 2015-08-27 - Created
 */
@isTest
private class EBSAccountTriggerBeforeTest {
	static List<EBS_Account__c> ebsAccounts {
		get {
			if(ebsAccounts == null) {
				ebsAccounts = new List<EBS_Account__c>();
				for(Account a : AccountTriggerAfterTest.accountMap.values()) {
					EBS_Account__c e = new EBS_Account__c(
						Name = '-'+a.CDH_Party_Name__c,
						Sales_Account__c=a.Id,
						Account_Type__c = 'R',
						Status__c = 'Active');
					ebsAccounts.add(e);
					ebsAccounts.add(e.clone());
					ebsAccounts.add(e.clone());
				}
			}
			return ebsAccounts;
		}
		set;
	}

	@isTest
	static void inactivateDuplicate() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
		insert ebsAccounts[0];
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
		EBS_Account__c ebsAccount = ebsAccounts[1];
		ebsAccount.MasterRecord__c = ebsAccounts[0].Id;
		ebsAccount.Status__c = 'Active';
		Test.startTest();
		EBSAccountTriggerBefore beforeTrigger = new EBSAccountTriggerBefore(new Map<Id,EBS_Account__c>{null=>ebsAccount},new List<EBS_Account__c>{ebsAccount});
		beforeTrigger.inactivateDuplicates();
		Test.stopTest();
		System.assertEquals('INACTIVE',ebsAccount.Status__c.toUpperCase());
	}

	@isTest // (SeeAllData=true) no longer needed
	static void processTriggerTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
		EBS_Account__c e = ebsAccounts[0];
		insert e;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
		Test.startTest();
		// insert
		EBSAccountTriggerBefore.processTrigger(null,new List<EBS_Account__c>{e});
		// update
		EBSAccountTriggerBefore.processTrigger(new Map<Id,EBS_Account__c>{e.Id=>e.clone(true)},new List<EBS_Account__c>{e});
		// delete
		EBSAccountTriggerBefore.processTrigger(new Map<Id,EBS_Account__c>{e.Id=>e},null);
		Test.stopTest();
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('EBSAccount_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('EBSAccount_Before.',ebsAccounts);
	}
}