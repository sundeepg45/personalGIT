/**
 * This class contains unit tests for validating the AccountTriggerBefore class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-05-18
 * 2012-05-18 - refactored into sub classes
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-22 - Added a few fields to createAcccount
 */
@isTest
public class AccountTriggerBeforeTest extends AccountTriggerBefore {
	public AccountTriggerBeforeTest(Map<Id,Account> oldMap,List<Account> newList) {
		super(oldMap,newList);
	}

	public static Map<Id,RecordTypeInfo> accountRecordTypeByIdMap {
		get {
			if(accountRecordTypeByIdMap == null) {
				accountRecordTypeByIdMap = Schema.SObjectType.Account.getRecordTypeInfosById();
			}
			return accountRecordTypeByIdMap;
		}
	}

	public static Account createAccount(Id recordTypeId) {
		return new Account(
			Name='TestAccount '+recordTypeId,
			Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
			RecordTypeId=recordTypeId,
			AccountClassification__c='EMEA - Hosting',
			BillingCity='Testville',
			BillingStreet='1 no where',
			Middleware_Supported__c='None',
			Named_Account__c = false,
			OwnerId = UserInfo.getUserId(),
			Ownership = 'Private',
			Subregion__c = null,
			Total_of_Subsidiaries_if_Parent__c=5,
			VATNumber__c=null,
			What_Markets_are_Targeted__c='Vertical market');
	}

	public static Account createAccount() {
		Account retval = null;
		for(Id recordTypeId : accountRecordTypeByIdMap.keySet()) {
			retval = createAccount(recordTypeId);
			break;
		}
		return retval;
	}

	Map<Id,Account> getNewMap() {
		return accountMap;
	}

	@isTest
	static void newMapTest() {
		List<Account> accounts = new List<Account>();
		for(Id recordTypeId : accountRecordTypeByIdMap.keySet()) {
			accounts.add(createAccount(recordTypeId));
		}
		// Turn off all the triggers, as we are not testing the insert here.
		AbstractTrigger.setBooleanSettings('',false);
		for(Database.SaveResult sr : Database.insert(accounts,false) ) {
			Account a = accounts.remove(0);
			if(sr.isSuccess()) {
				accounts.add(a);
			}
		}
		AbstractTrigger.booleanSettingMap.clear();
		AccountTriggerBeforeTest triggerBefore = new AccountTriggerBeforeTest(new Map<Id,Account>(accounts),accounts);
		System.assertEquals(accounts.size(),triggerBefore.getNewMap().size());
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		Account account = createAccount();
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Account_Before.',true);
		// insert
		AccountTriggerBefore.processTrigger(null,new List<Account>{account});
		// update
		AccountTriggerBefore.processTrigger(new Map<Id,Account>{account.Id=>account.clone(true)},new List<Account>{account});
		// delete
		AccountTriggerBefore.processTrigger(new Map<Id,Account>{account.Id=>account},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Account_Before.');
	}

	@isTest
	static void deployTest() {
		List<Account> accounts = new List<Account>();
		for(Id recordTypeId : accountRecordTypeByIdMap.keySet()) {
			accounts.add(createAccount(recordTypeId));
		}
		AbstractTriggerTest.deployTest('Account_Before.',accounts);
	}
}