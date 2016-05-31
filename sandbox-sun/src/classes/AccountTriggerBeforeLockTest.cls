/**
 * This class contains unit tests for validating the AccountTriggerBeforeLock class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-05-18
 * 2012-05-18 - refactored into sub classes
 */
@isTest
private class AccountTriggerBeforeLockTest {
	static List<Account> queryAccounts(Set<Id> ids) {
		return [
			select
				Name,
				Data_Status__c,
				RecordTypeId,
				AccountClassification__c,
				BillingCity,
				BillingStreet,
				CreatedDate,
				Hours_to_Review__c,
				Middleware_Supported__c,
				OwnerId,
				Ownership,
				Total_of_Subsidiaries_if_Parent__c,
				VATNumber__c,
				What_Markets_are_Targeted__c
			from Account
			where Id in :ids ];
	}

	static List<Account> accounts {
		get {
			if(accounts == null) {
				List<Account> accountList = new List<Account>();
				for(Id id : AccountTriggerBeforeTest.accountRecordTypeByIdMap.keySet()) {
					accountList.add(AccountTriggerBeforeTest.createAccount(id));
				}
				accounts = new List<Account>();
				AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = false;
				for(Database.SaveResult r : Database.insert(accountList,false)) {
					Account a = accountList.remove(0);
					if(r.isSuccess()) {
						accountList.add(a);
					}
				}
				AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = null;
				accounts = queryAccounts(new Map<Id,Account>(accountList).keySet());
			}
			return accounts;
		}
	}

	static List<Account> updatedAccounts1 {
		get {
			if(updatedAccounts1 == null) {
				updatedAccounts1 = queryAccounts(new Map<Id,Account>(accounts).keySet());
				for(Account a : updatedAccounts1) {
					if(true) {
						System.assertNotEquals(null,a.CreatedDate);
					}
					a.Name = 'TestAccount2 '+a.recordTypeId;
					a.BillingStreet='2 no where';
					a.Ownership = 'Public';
					a.Total_of_Subsidiaries_if_Parent__c = null;
					a.What_Markets_are_Targeted__c='Education Market';
				}
			}
			return updatedAccounts1;
		}
	}

	static User testUser {
		get {
			if(testUser == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				testUser = [select Id from User where ProfileId = :salesUserProfileTesting.Id__c and IsActive = true limit 1];
			}
			return testUser;
		}
	}

	static List<Account> updatedAccounts2 {
		get {
			if(updatedAccounts2 == null) {
				updatedAccounts2 = updatedAccounts1.deepClone(true);
				Id recordTypeId = null;
				for(Id id : AccountTriggerBeforeTest.accountRecordTypeByIdMap.keySet()) {
					recordTypeId = id;
				}
				for(Account a : updatedAccounts2) {
					Id id = a.recordTypeId;
					a.recordTypeId = recordTypeId;
					a.OwnerId = testUser.Id;
					recordTypeId = id;
				}
			}
			return updatedAccounts2;
		}
	}

	static List<AccountChangeRequest__c> getAccountChangeRequests(Set<Id> accountIds) {
		List<AccountChangeRequest__c> retval = [
			select 
				Account__c
			from AccountChangeRequest__c
			where Account__c in :accountIds ];
		return retval;
	}

	static Map<Id,Map<String,AccountChangeRequestField__c>> getAccountChangeRequestFieldMaps(Set<Id> accountChangeRequestIds) {
		Map<Id,Map<String,AccountChangeRequestField__c>> retval = new Map<Id,Map<String,AccountChangeRequestField__c>>();
		for(AccountChangeRequestField__c acrf : [
			select
				Approved__c,
				ChangeRequest__c,
				BooleanValue__c,
				DateTimeValue__c,
				DateValue__c,
				FieldName__c,
				TextValue__c
			from AccountChangeRequestField__c
			where ChangeRequest__c in :accountChangeRequestIds ]
		) {
			Map<String,AccountChangeRequestField__c> acrfMap = retval.get(acrf.ChangeRequest__c);
			if(acrfMap == null) {
				acrfMap = new Map<String,AccountChangeRequestField__c>();
				retval.put(acrf.ChangeRequest__c,acrfMap);
			}
			acrfMap.put(acrf.FieldName__c.toLowerCase(),acrf);
		}
		return retval;
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void pendingDataReviewTest() {
		System.assertNotEquals(0,accounts.size());
		System.assertNotEquals(1,accounts.size());
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts);
		List<AccountChangeRequest__c> acrs = getAccountChangeRequests(oldMap.keySet());
		System.assertEquals(0,acrs.size());
		List<Account> newList = accounts.deepClone(true);
		//System.runAs(testUser) {
			AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = false;
			AccountTriggerBeforeLock beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(0,acrs.size());
			System.assertEquals(accounts.size(),beforeTrigger.accountMap.size());
			for(Account a : accounts) {
				Account x = newList.remove(0);
				System.assertEquals(a.Name,x.Name);
				System.assertEquals(a.Data_Status__c,x.Data_Status__c);
				System.assertEquals(a.RecordTypeId,x.RecordTypeId);
				System.assertEquals(a.AccountClassification__c,x.AccountClassification__c);
				System.assertEquals(a.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,x.BillingStreet);
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assertEquals(a.OwnerId,x.OwnerId);
				System.assertEquals(a.Ownership,x.Ownership);
				System.assertEquals(a.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assertEquals(a.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
			AccountTriggerBeforeLock.lockedFields = new Set<String>{
				'name',
				'recordtypeid',
				'accountclassification__c',
				'billingcity',
				'billingstreet',
				'ownerid',
				'ownership',
				'total_of_subsidiaries_if_parent__c',
				'vatnumber__c' };
			newList = updatedAccounts1.deepClone(true);
			beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(0,acrs.size());
			for(Account a : updatedAccounts1) {
				Account x = newList.remove(0);
				System.assertEquals(a.Name,x.Name);
				System.assertEquals(a.Data_Status__c,x.Data_Status__c);
				System.assertEquals(a.RecordTypeId,x.RecordTypeId);
				System.assertEquals(a.AccountClassification__c,x.AccountClassification__c);
				System.assertEquals(a.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,x.BillingStreet);
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assertEquals(a.OwnerId,x.OwnerId);
				System.assertEquals(a.Ownership,x.Ownership);
				System.assertEquals(a.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assertEquals(a.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
			newList = updatedAccounts2.deepClone(true);
			beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(0,acrs.size());
			for(Account a : updatedAccounts2) {
				Account x = newList.remove(0);
				System.assertEquals(a.Name,x.Name);
				System.assertEquals(a.Data_Status__c,x.Data_Status__c);
				System.assertEquals(a.RecordTypeId,x.RecordTypeId);
				System.assertEquals(a.AccountClassification__c,x.AccountClassification__c);
				System.assertEquals(a.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,x.BillingStreet);
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assertEquals(a.OwnerId,x.OwnerId);
				System.assertEquals(a.Ownership,x.Ownership);
				System.assertEquals(a.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assertEquals(a.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
		//}
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void lockedTest() {
		for(Account a : accounts) {
			a.Data_Status__c = AccountTriggerBeforeLock.LOCKED;
		}
		for(Account a : updatedAccounts1) {
			a.Data_Status__c = AccountTriggerBeforeLock.LOCKED;
		}
		for(Account a : updatedAccounts2) {
			a.Data_Status__c = AccountTriggerBeforeLock.LOCKED;
		}
		System.assertNotEquals(0,accounts.size());
		System.assertNotEquals(1,accounts.size());
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts);
		List<AccountChangeRequest__c> acrs = getAccountChangeRequests(oldMap.keySet());
		System.assertEquals(0,acrs.size());
		Map<Id,AccountChangeRequest__c> acrMap;
		Map<Id,Map<String,AccountChangeRequestField__c>> acrfMaps;
		//System.runAs(testUser) {
			AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = false;
			List<Account> newList = accounts.deepClone(true);
			AccountTriggerBeforeLock beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(0,acrs.size());
			System.assertEquals(accounts.size(),beforeTrigger.accountMap.size());
			for(Account a : accounts) {
				Account x = newList.remove(0);
				System.assertEquals(a.Name,x.Name);
				System.assertEquals(a.Data_Status__c,x.Data_Status__c);
				System.assertEquals(a.RecordTypeId,x.RecordTypeId);
				System.assertEquals(a.AccountClassification__c,x.AccountClassification__c);
				System.assertEquals(a.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,x.BillingStreet);
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assertEquals(a.OwnerId,x.OwnerId);
				System.assertEquals(a.Ownership,x.Ownership);
				System.assertEquals(a.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assertEquals(a.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
			AccountTriggerBeforeLock.lockedFields = new Set<String>{
				'name',
				'recordtypeid',
				'accountclassification__c',
				'billingcity',
				'billingstreet',
				'ownerid',
				'ownership',
				'total_of_subsidiaries_if_parent__c',
				'vatnumber__c' };
			newList = updatedAccounts1.deepClone(true);
			beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(accounts.size(),acrs.size());
			acrMap = new Map<Id,AccountChangeRequest__c>(acrs);
			acrfMaps = getAccountChangeRequestFieldMaps(acrMap.keySet());
			for(AccountChangeRequest__c acr : acrs) {
				acrMap.put(acr.Account__c,acr);
			}
			List<Account> oldList = accounts.clone();
			for(Account a : updatedAccounts1) {
				Account x = newList.remove(0);
				Account o = oldList.remove(0);
				AccountChangeRequest__c acr = acrMap.remove(a.Id);
				System.assertNotEquals(null,acr);
				Map<String,AccountChangeRequestField__c> acrfMap = acrfMaps.get(acr.Id);
				System.assertNotEquals(null,acrfMap);
				System.assertEquals(AccountTriggerBeforeLock.PENDING_UPDATE,x.Data_Status__c);
				System.assertEquals(a.Name,acrfMap.get('name').TextValue__c);
				System.assertEquals(o.Name,x.Name);
				System.assert(! acrfMap.containsKey('recordtypeid'));
				System.assertEquals(o.RecordTypeId,x.RecordTypeId);
				System.assert(! acrfMap.containsKey('accountclassification__c'));
				System.assertEquals(o.AccountClassification__c,x.AccountClassification__c);
				System.assert(! acrfMap.containsKey('billingcity'));
				System.assertEquals(o.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,acrfMap.get('billingstreet').TextValue__c);
				System.assertEquals(o.BillingStreet,x.BillingStreet);
				System.assert(! acrfMap.containsKey('middleware_supported__c'));
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assert(! acrfMap.containsKey('ownerid'));
				System.assertEquals(o.OwnerId,x.OwnerId);
				System.assertEquals((String)a.Ownership,acrfMap.get('ownership').TextValue__c);
				System.assertEquals(o.Ownership,x.Ownership);
				System.assertEquals(String.valueof(a.Total_of_Subsidiaries_if_Parent__c),acrfMap.get('total_of_subsidiaries_if_parent__c').TextValue__c);
				System.assertEquals(o.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assert(! acrfMap.containsKey('vatnumber__c'));
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assert(! acrfMap.containsKey('what_markets_are_targeted__c'));
				System.assertEquals(a.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
			delete acrs;
			newList = updatedAccounts2.deepClone(true);
			beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.createAccountRelatedChanges();
			acrs = getAccountChangeRequests(oldMap.keySet());
			System.assertEquals(accounts.size(),acrs.size());
			acrMap = new Map<Id,AccountChangeRequest__c>(acrs);
			acrfMaps = getAccountChangeRequestFieldMaps(acrMap.keySet());
			for(AccountChangeRequest__c acr : acrs) {
				acrMap.put(acr.Account__c,acr);
			}
			oldList = accounts.clone();
			for(Account a : updatedAccounts2) {
				Account x = newList.remove(0);
				Account o = oldList.remove(0);
				AccountChangeRequest__c acr = acrMap.remove(a.Id);
				System.assertNotEquals(null,acr);
				Map<String,AccountChangeRequestField__c> acrfMap = acrfMaps.get(acr.Id);
				System.assertNotEquals(null,acrfMap);
				System.assertEquals(AccountTriggerBeforeLock.PENDING_UPDATE,x.Data_Status__c);
				System.assertEquals(a.Name,acrfMap.get('name').TextValue__c);
				System.assertEquals(o.Name,x.Name);
				System.assertEquals(a.RecordTypeId,acrfMap.get('recordtypeid').TextValue__c);
				System.assertEquals(o.RecordTypeId,x.RecordTypeId);
				System.assert(! acrfMap.containsKey('accountclassification__c'));
				System.assertEquals(o.AccountClassification__c,x.AccountClassification__c);
				System.assert(! acrfMap.containsKey('billingcity'));
				System.assertEquals(o.BillingCity,x.BillingCity);
				System.assertEquals(a.BillingStreet,acrfMap.get('billingstreet').TextValue__c);
				System.assertEquals(o.BillingStreet,x.BillingStreet);
				System.assert(! acrfMap.containsKey('middleware_supported__c'));
				System.assertEquals(a.Middleware_Supported__c,x.Middleware_Supported__c);
				System.assertEquals((String)a.OwnerId,acrfMap.get('ownerid').TextValue__c);
				System.assertEquals(o.OwnerId,x.OwnerId);
				System.assertEquals((String)a.Ownership,acrfMap.get('ownership').TextValue__c);
				System.assertEquals(o.Ownership,x.Ownership);
				System.assertEquals(String.valueof(a.Total_of_Subsidiaries_if_Parent__c),acrfMap.get('total_of_subsidiaries_if_parent__c').TextValue__c);
				System.assertEquals(o.Total_of_Subsidiaries_if_Parent__c,x.Total_of_Subsidiaries_if_Parent__c);
				System.assert(! acrfMap.containsKey('vatnumber__c'));
				System.assertEquals(a.VATNumber__c,x.VATNumber__c);
				System.assertEquals(a.What_Markets_are_Targeted__c,acrfMap.get('what_markets_are_targeted__c').TextValue__c);
				System.assertEquals(o.What_Markets_are_Targeted__c,x.What_Markets_are_Targeted__c);
			}
		//}
	}

	@isTest
	static void changeDataStatusTest() {
		for(Account a : updatedAccounts1) {
			a.Data_Status__c = AccountTriggerBeforeLock.LOCKED;
		}
		System.assertNotEquals(0,accounts.size());
		System.assertNotEquals(1,accounts.size());
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts);
		List<Account> newList = updatedAccounts1.deepClone(true);
		//System.runAs(testUser) {
			AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = false;
			AccountTriggerBeforeLock beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.changeDataStatus();
			for(Account a : newList) {
				System.assertEquals(AccountTriggerBeforeLock.LOCKED,a.Data_Status__c);
			}
			beforeTrigger.createAccountRelatedChanges();
			newList = updatedAccounts1.deepClone(true);
			beforeTrigger = new AccountTriggerBeforeLock(oldMap,newList);
			beforeTrigger.changeDataStatus();
			for(Account a : newList) {
				System.assertEquals(AccountTriggerBeforeLock.PENDING_UPDATE,a.Data_Status__c);
			}
		//}
	}

	@isTest
	static void assignHoursToReviewTest() {
		for(Account a : updatedAccounts1) {
			a.Data_Status__c = AccountTriggerBeforeLock.LOCKED;
		}
		System.assertNotEquals(0,accounts.size());
		System.assertNotEquals(1,accounts.size());
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts);
		AccountTriggerBeforeLock beforeTrigger = new AccountTriggerBeforeLock(oldMap,updatedAccounts1);
		for(Account a : updatedAccounts1) {
			System.assertNotEquals(null,a.CreatedDate);
			System.assertNotEquals(null,a.CreatedDate.getTime());
		}
		for(Account a : accounts) {
			System.assertNotEquals(null,a.CreatedDate);
			System.assertNotEquals(null,a.CreatedDate.getTime());
		}
		beforeTrigger.assignHoursToReview();
		for(Account a : updatedAccounts1) {
			System.assertNotEquals(null,a.Hours_to_Review__c);
		}
	}
}