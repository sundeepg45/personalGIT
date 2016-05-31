/**
 * Test class created for ContactTriggerAfter class.
 *
 * @version 2015-08-19
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-08-19 - created
 */
@isTest
public class AccountTriggerAfterTest {
	public static List<CDH_Party__c> cdhParties {
		get {
			if(cdhParties == null) {
				cdhParties = new List<CDH_Party__c>{
					new CDH_Party__c(
						Name = '-23336778',
						CDH_Party_Type__c = 'Entitle',
						CDH_Party_Name__c = 'ContactTriggerAfterTest.entitlePartyName0',
						CDH_Party_Number_Ext__c = '-23336778'),
					new CDH_Party__c(
						Name = '-83336778',
						CDH_Party_Type__c = 'Entitle',
						CDH_Party_Name__c = 'ContactTriggerAfterTest.entitlePartyName1',
						CDH_Party_Number_Ext__c = '-83336778'),
					new CDH_Party__c(
						Name = '-12341341',
						CDH_Party_Type__c = 'PERSON',
						CDH_Party_Name__c = 'AccountTriggerAfterTest.personPartyName2',
						CDH_Party_Number_Ext__c = '-12341341'),
					new CDH_Party__c(
						Name = '-92341341',
						CDH_Party_Type__c = 'PERSON',
						CDH_Party_Name__c = 'AccountTriggerAfterTest.personPartyName3',
						CDH_Party_Number_Ext__c = '-92341341') };
			}
			return cdhParties;
		}
		set;
	}

	public static Map<Id,CDH_Party__c> cdhPartyMap {
		get {
			if(cdhPartyMap == null) {
				insert cdhParties;
				cdhPartyMap = new Map<Id,CDH_Party__c>(cdhParties);
			}
			return cdhPartyMap;
		}
		set;
	}

	public static List<Account> accounts {
		get {
			if(accounts == null && ! cdhPartyMap.isEmpty()) {
				Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
				accounts = new List<Account>{
					new Account(
						CDH_Party_Name__c = cdhParties[0].Id,
						CDH_Party_Name__r = cdhParties[0],
						Name = 'AccountTriggerAfterTest.account0A',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[0].Id,
						CDH_Party_Name__r = cdhParties[0],
						Name = 'AccountTriggerAfterTest.account0B',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[1].Id,
						CDH_Party_Name__r = cdhParties[1],
						Name = 'AccountTriggerAfterTest.account1A',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[1].Id,
						CDH_Party_Name__r = cdhParties[1],
						Name = 'AccountTriggerAfterTest.account1B',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[2].Id,
						CDH_Party_Name__r = cdhParties[2],
						Name = 'AccountTriggerAfterTest.account2A',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[2].Id,
						CDH_Party_Name__r = cdhParties[2],
						Name = 'AccountTriggerAfterTest.account2B',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[3].Id,
						CDH_Party_Name__r = cdhParties[3],
						Name = 'AccountTriggerAfterTest.account3A',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = cdhParties[3].Id,
						CDH_Party_Name__r = cdhParties[3],
						Name = 'AccountTriggerAfterTest.account3B',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = null,
						Name = 'AccountTriggerAfterTest.account4A',
						RecordTypeId = recordTypeId ),
					new Account(
						CDH_Party_Name__c = null,
						Name = 'AccountTriggerAfterTest.account4B',
						RecordTypeId = recordTypeId ) };
			}
			return accounts;
		}
		set;
	}

	public static Map<Id,Account> accountMap {
		get {
			if(accountMap == null) {
				// Turn off all triggers, as we are going to test those next
				AbstractTrigger.setBooleanSettings('Account_After.',false);
				insert accounts;
				// Turn on all the triggers, and make sure everything is tested.
				AbstractTrigger.setBooleanSettings('Account_After.',true);
				accountMap = new Map<Id,Account>(accounts);
			}
			return accountMap;
		}
		set;
	}

	@isTest
	static void blockAccountMergesTest() {
		Map<Id,Account> oldMap = accountMap.clone();
		oldMap.keySet().retainAll(new Set<Id>{accounts[0].Id,accounts[2].Id,accounts[4].Id,accounts[6].Id,accounts[8].Id});
		AccountTriggerAfter afterTrigger = new AccountTriggerAfter(oldMap,null,false);
		oldMap = afterTrigger.oldMap;
		System.assertEquals(5,oldMap.size());

		Map<Id,Id> masterRecordIdMap = afterTrigger.masterRecordIdMap;
		masterRecordIdMap.put(accounts[0].Id,accounts[1].Id);
		masterRecordIdMap.put(accounts[2].Id,accounts[3].Id);
		masterRecordIdMap.put(accounts[4].Id,accounts[5].Id);
		masterRecordIdMap.put(accounts[6].Id,accounts[7].Id);
		masterRecordIdMap.put(accounts[8].Id,accounts[9].Id);
		// test with both the master record and the deleted account have a null cdh party name value.
		afterTrigger.blockAccountMerges();
		System.assert(afterTrigger.hasErrors,'Expected block of merge to a record with matching a null CDH Party Name values.');
		System.assert(! oldMap.containsKey(accounts[8].Id),'The account with an error should have been removed from the oldMap');
		System.assertEquals(4,oldMap.size());

		// test complete success
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(! afterTrigger.hasErrors,'None of the merges should have been blocked.');
		System.assertEquals(4,oldMap.size());

		// test with one of the master record accounts with a null cdh party name value
		masterRecordIdMap.put(accounts[6].Id,accounts[9].Id);
		afterTrigger.blockAccountMerges();
		System.assert(afterTrigger.hasErrors,'Expected block of merge to a record with a null CDH Party Name value.');
		System.assert(! oldMap.containsKey(accounts[6].Id),'The account with an error should have been removed from the oldMap');
		System.assertEquals(3,oldMap.size());

		// test complete success again
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(! afterTrigger.hasErrors,'None of the merges should have been blocked.');
		System.assertEquals(3,oldMap.size());

		// test with one of the master record accounts mapped to a different cdh party name value
		masterRecordIdMap.put(accounts[4].Id,accounts[7].Id);
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(afterTrigger.hasErrors,'Expected block of merge to a record with a non-matching CDH Party Name value.');
		System.assert(! oldMap.containsKey(accounts[4].Id),'The account with an error should have been removed from the oldMap');
		System.assertEquals(2,oldMap.size());

		// test complete success again
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(! afterTrigger.hasErrors,'None of the merges should have been blocked.');
		System.assertEquals(2,oldMap.size());

		// test with a missing master record account... this scenario should never really happen
		masterRecordIdMap.put(accounts[2].Id,null);
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(afterTrigger.hasErrors,'Expected block of merge to a non-existant master record id.');
		System.assert(! oldMap.containsKey(accounts[2].Id),'The account with an error should have been removed from the oldMap');
		System.assertEquals(1,oldMap.size());

		// test complete success again
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(! afterTrigger.hasErrors,'None of the merges should have been blocked.');
		System.assertEquals(1,oldMap.size());

		// test when the deleted account has a null cdh party name value
		Account a = afterTrigger.oldMap.values()[0];
		a.CDH_Party_Name__c = null;
		a.CDH_Party_Name__r = null;
		afterTrigger.hasErrors = false;
		afterTrigger.blockAccountMerges();
		System.assert(afterTrigger.hasErrors,'Expected block of merge to a record when child has a null cdh party name value.');
		System.assert(! oldMap.containsKey(accounts[0].Id),'The account with an error should have been removed from the oldMap');
		System.assertEquals(0,oldMap.size());

	}

	@isTest // (SeeAllData=true) no longer needed 
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.insertMissing = 1000;
		AbstractTrigger.setBooleanSettings('Account_After.',false);
		Account account0 = accounts[0];
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		AccountTriggerAfter.processTrigger(null,new Map<Id,Account>{null=>account0},false);
		// insert the opportunity, again with the triggers off
		Map<Id,Account> xaccountMap = accountMap;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Account_After.',true);
		Account account1 = account0.clone(true);
		Account account2 = account0.clone(true);
		Test.startTest();
		// insert test
		AccountTriggerAfter.processTrigger(null,new Map<Id,Account>{account2.Id=>account2},false);
		// update test
		AccountTriggerAfter.processTrigger(new Map<Id,Account>{account1.Id=>account0},new Map<Id,Account>{account2.Id=>account2},false);
		// delete test
		AccountTriggerAfter.processTrigger(new Map<Id,Account>{account1.Id=>account1},null,false);
		// undelete test
		AccountTriggerAfter.processTrigger(null,new Map<Id,Account>{account2.Id=>account2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('Account_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		AbstractTriggerTest.deployTest('Account_After.',accounts);
	}
}