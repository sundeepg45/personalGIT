/**
 * Test class created for EBSAccountTriggerAfter class.
 *
 * @version 2015-09-22
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-09-22 - created
 */
@isTest
public class EBSAccountTriggerAfterTest {
	static CDH_Party__c cdhEntitleParty {
		get {
			if(cdhEntitleParty == null) {
				cdhEntitleParty = new CDH_Party__c(
					Name = '-23336778',
					CDH_Party_Type__c = 'Entitle',
					CDH_Party_Name__c = 'ContactTriggerAfterTest.entitlePartyName',
					CDH_Party_Number_Ext__c = '-23336778');
			}
			return cdhEntitleParty;
		}
		set;
	}

	static Id getCDHEntitlePartyId() {
		if(cdhEntitleParty.Id == null) {
			insert cdhEntitleParty;
		}
		return cdhEntitleParty.Id;
	}

	static Account entitleAccount {
		get {
			if(entitleAccount == null) {
				Id cdhEntitlePartyId = getCDHEntitlePartyId();
				entitleAccount = new Account(
					CDH_Party_Name__c = cdhEntitlePartyId,
					CDH_Party_Name__r = cdhEntitleParty,
					Name = 'ContactTriggerAfterTest.entitleAccount',
					RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId() );
			}
			return entitleAccount;
		}
		set;
	}

	static Id getEntitleAccountId() {
		if(entitleAccount.Id == null) {
			insert entitleAccount;
		}
		return entitleAccount.Id;
	}

	static List<EBS_Account__c> ebsAccounts {
		get {
			if(ebsAccounts == null) {
				Id accountId = getEntitleAccountId();
				ebsAccounts = new List<EBS_Account__c>{
					new EBS_Account__c(Name = '1231', 
						Primary_EBS_Account__c = false, 
						Sales_Account__c = accountId),
					new EBS_Account__c(Name = '1232', 
						Primary_EBS_Account__c = false, 
						Sales_Account__c = accountId),
					new EBS_Account__c(Name = '1233', 
						Primary_EBS_Account__c = true, 
						Sales_Account__c = accountId),
					new EBS_Account__c(Name = '1231', 
						Primary_EBS_Account__c = false, 
						Sales_Account__c = accountId) };
			}
			return ebsAccounts;
		}
	}

	@isTest
	static void updateEBSAccountNumbersTest(){
		Id accountId = getEntitleAccountId();
		Account a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals(null,a.EBS_Account_Numbers__c);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);

		Test.startTest();

		insert ebsAccounts[0];
		EBSAccountTriggerAfter afterTrigger = new EBSAccountTriggerAfter(null,new Map<Id,EBS_Account__c>{ebsAccounts[0].Id=>ebsAccounts[0]},false);
		afterTrigger.updateEBSAccountNumbers();
		a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals('1231',a.EBS_Account_Numbers__c);

		insert ebsAccounts[1];
		afterTrigger = new EBSAccountTriggerAfter(null,new Map<Id,EBS_Account__c>{ebsAccounts[1].Id=>ebsAccounts[1]},false);
		afterTrigger.updateEBSAccountNumbers();
		a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals('1231, 1232',a.EBS_Account_Numbers__c);

		insert ebsAccounts[2];
		afterTrigger = new EBSAccountTriggerAfter(null,new Map<Id,EBS_Account__c>{ebsAccounts[2].Id=>ebsAccounts[2]},false);
		afterTrigger.updateEBSAccountNumbers();
		a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals('1233*, 1231, 1232',a.EBS_Account_Numbers__c);

		insert ebsAccounts[3];
		afterTrigger = new EBSAccountTriggerAfter(null,new Map<Id,EBS_Account__c>{ebsAccounts[3].Id=>ebsAccounts[3]},false);
		afterTrigger.updateEBSAccountNumbers();
		a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals('1233*, 1231, 1232',a.EBS_Account_Numbers__c);

		Map<Id,EBS_Account__c> ebsAccountMap = new Map<Id,EBS_Account__c>(ebsAccounts);
		delete ebsAccounts;
		afterTrigger = new EBSAccountTriggerAfter(ebsAccountMap,null,false);
		afterTrigger.updateEBSAccountNumbers();
		a = [select EBS_Account_Numbers__c from Account where Id = :accountId];
		System.assertEquals(null,a.EBS_Account_Numbers__c);

		Test.stopTest();
	}

	@isTest // (SeeAllData=true) no longer needed 
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
		AbstractTrigger.insertMissing = 100;
		EBS_Account__c ebsAccount0 = ebsAccounts[0];
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		EBSAccountTriggerAfter.processTrigger(null,new Map<Id,EBS_Account__c>{null=>ebsAccount0},false);
		// insert the ebsAccount, again with the triggers off
		insert ebsAccounts;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
		EBS_Account__c ebsAccount1 = ebsAccount0.clone(true);
		EBS_Account__c ebsAccount2 = ebsAccount0.clone(true);
		Test.startTest();
		// insert test
		EBSAccountTriggerAfter.processTrigger(null,new Map<Id,EBS_Account__c>{ebsAccount2.Id=>ebsAccount2},false);
		// update test
		EBSAccountTriggerAfter.processTrigger(new Map<Id,EBS_Account__c>{ebsAccount1.Id=>ebsAccount0},new Map<Id,EBS_Account__c>{ebsAccount2.Id=>ebsAccount2},false);
		// delete test
		EBSAccountTriggerAfter.processTrigger(new Map<Id,EBS_Account__c>{ebsAccount1.Id=>ebsAccount1},null,false);
		// undelete test
		EBSAccountTriggerAfter.processTrigger(null,new Map<Id,EBS_Account__c>{ebsAccount2.Id=>ebsAccount2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('EBSAccount_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		AbstractTriggerTest.deployTest('EBSAccount_After.',ebsAccounts);
	}
}