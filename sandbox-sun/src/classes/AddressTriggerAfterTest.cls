/**
 * Test class created for AddressTriggerAfter class.
 *
 *
 * @version 2015-11-18
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-11-18 - New tests
 * 2015-10-01 - Created
 */
@isTest
public class AddressTriggerAfterTest {

	static List<Account> accounts {
		get {
			if(accounts == null) {
				Map<Id,Account> accountMap = AccountMergeBatchableTest.accountMap.clone();
				accounts = AccountMergeBatchableTest.accounts.clone();
				AccountMergeBatchableTest.accounts.clear();
				AccountMergeBatchableTest.accounts.add(accounts[0]);
				AccountMergeBatchableTest.accountMap.clear();
				AccountMergeBatchableTest.accountMap.put(accounts[0].Id,accounts[0]);
			}
			return accounts;
		}
		set;
	}

	static List<Address__c> addresses {
		get {
			if(addresses == null) {
				accounts.isEmpty();
				addresses = AccountMergeBatchableTest.addresses;
			}
			return addresses;
		}
		set;
	}

	@isTest
	static void logDuplicatesTest() {
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		insert addresses;
		List<Address__c> addressesOld = addresses.deepClone(true,true,true);
		Map<Id,Address__c> oldMap = new Map<Id,Address__c>(addressesOld);
		Map<Id,Address__c> newMap = new Map<Id,Address__c>(addresses);
		AddressTriggerAfter triggerAfter = new AddressTriggerAfter(oldMap,newMap,false);

		Test.startTest();
		triggerAfter.logDuplicates();
		// we haven't tagged anything to find duplicates...
		System.assertEquals(0,[select count() from DuplicateLog__c]);
		// still not tagged as reparented
		Id accountId = accounts[1].Id;
		for(Address__c address : addressesOld) {
			address.Sales_Account__c = accountId;
		}
		// we still haven't tagged anything to find duplicates...
		triggerAfter.logDuplicates();
		System.assertEquals(0,[select count() from DuplicateLog__c]);

		for(Address__c address : addresses) {
			AddressTriggerAfter.reparentedAddressMap.put(address.Id,address.Sales_Account__c);
		}
		Savepoint sp = Database.setSavePoint();
		triggerAfter.logDuplicates();
		System.assertEquals(2*(addressesOld.size()/3),[select count() from DuplicateLog__c]);
		Database.rollback(sp);

		// make sure we reinitialized
		AddressTriggerAfter.reparentedAddressMap.clear();
		triggerAfter.logDuplicates();
		System.assertEquals(0,[select count() from DuplicateLog__c]);

		// should only have an effect on inserts
		addresses[0].Reparented__c = true;
		triggerAfter.logDuplicates();
		System.assertEquals(0,[select count() from DuplicateLog__c]);
		triggerAfter = new AddressTriggerAfter(null,newMap,false);
		triggerAfter.logDuplicates();
		Test.stopTest();

		System.assertEquals(2*(addressesOld.size()/3),[select count() from DuplicateLog__c]);
	}

	@isTest
	static void correctExternalIds() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		addresses[0].Status__c = 'Active';
		addresses[0].IsDuplicate__c = false;
		addresses[0].CDH_Party_Site_Number__c = '-1';
		addresses[0].Address_External_Id__c = 'CATDOG';
		insert addresses[0];
		Address__c addressAfter = addresses[0].clone(true);
		addressAfter.CDH_Party_Site_Number__c = '-2';
		AddressTriggerAfter triggerAfter = new AddressTriggerAfter(new Map<Id,Address__c>{addresses[0].Id => addresses[0]},new Map<Id,Address__c>{addressAfter.Id => addressAfter},false);
		Test.startTest();
		triggerAfter.correctExternalIds();
		Test.stopTest();
		Address__c a = [select Address_External_Id__c from Address__c where Id = :addresses[0].Id ];
		System.assertNotEquals(null,a.Address_External_Id__c);
		System.assertNotEquals(addresses[0].Address_External_Id__c,a.Address_External_Id__c);
	}

	@isTest
	static void updateDuplicatesTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		addresses[0].Status__c = addresses[1].Status__c = 'Active';
		addresses[0].CDH_Party_Site_Number__c = addresses[1].CDH_Party_Site_Number__c = '-1';
		insert new List<Address__c>{addresses[0],addresses[1]};
		Address__c addressAfter = addresses[1].clone(true);
		addressAfter.CDH_Party_Site_Number_Previous__c = addressAfter.CDH_Party_Site_Number__c;
		addressAfter.CDH_Party_Site_Number__c = '-2';
		addressAfter.Status__c = 'Merged';
		addressAfter.IsDuplicate__c = true;
		AddressTriggerAfter triggerAfter = new AddressTriggerAfter(new Map<Id,Address__c>{addresses[1].Id => addresses[1]},new Map<Id,Address__c>{addressAfter.Id => addressAfter},false);
		Test.startTest();
		triggerAfter.updateDuplicates();
		Test.stopTest();
		Address__c a = [select CDH_Party_Site_Number__c from Address__c where Id = :addresses[0].Id ];
		System.assertEquals(addressAfter.CDH_Party_Site_Number__c,a.CDH_Party_Site_Number__c);
	}

	@isTest
	static void outboundMessagesTest() {
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		insert addresses;
		Map<Id,Address__c> addressMap = new Map<Id,Address__c>(addresses);
		AddressTriggerAfter triggerAfter = new AddressTriggerAfter(null,addressMap,false);
		Test.startTest();
		triggerAfter.outboundMessages();
		Test.stopTest();
		System.assertNotEquals(0,[select count() from Outbound_Event__c]);
	}

	@isTest
	static void setIdentifyingTest() {
		addresses[0].Identifying_Address__c = true;
		Address__c address1 = addresses[0].clone();
		addresses[0].CDH_Party_Site_Number__c = '-1';
		address1.CDH_Party_Site_Number__c = '-2';
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		insert new List<Address__c>{addresses[0],address1};
		AddressTriggerAfter triggerAfter = new AddressTriggerAfter(null,new Map<Id,Address__c>{address1.Id=>address1},false);
		Test.startTest();
		triggerAfter.setIdentifying();
		Test.stopTest();
		Address__c a = [select Id from Address__c where (Id=:addresses[0].Id or Id=:address1.Id) and Identifying_Address__c = true];
		System.assertEquals(address1.Id,a.Id);
	}

	@isTest // (SeeAllData=true) no longer needed 
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		AbstractTrigger.insertMissing = 100;
		Address__c address0 = addresses[0];
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		AddressTriggerAfter.processTrigger(null,new Map<Id,Address__c>{null=>address0},false);
		// insert the address, again with the triggers off
		insert addresses;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Address_After.',true);
		Address__c address1 = address0.clone(true);
		Address__c address2 = address0.clone(true);
		address2.Sales_Account__c = accounts[1].Id;
		Test.startTest();
		// insert test
		AddressTriggerAfter.processTrigger(null,new Map<Id,Address__c>{address2.Id=>address2},false);
		// update test
		AddressTriggerAfter.processTrigger(new Map<Id,Address__c>{address1.Id=>address0},new Map<Id,Address__c>{address2.Id=>address2},false);
		// delete test
		AddressTriggerAfter.processTrigger(new Map<Id,Address__c>{address1.Id=>address1},null,false);
		// undelete test
		AddressTriggerAfter.processTrigger(null,new Map<Id,Address__c>{address2.Id=>address2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('Address_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		AbstractTriggerTest.deployTest('Address_After.',addresses);
	}
}