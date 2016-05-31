/**
 * This class contains unit tests for validating the behavior of 
 * AddressTriggerBefore.cls
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2015-08-27
 * 2015-08-27 - Created
 */
@isTest
private class AddressTriggerBeforeTest {

	static List<Address__c> addresses {
		get {
			if(addresses == null) {
				addresses = new List<Address__c>();
				for(Account a : AccountTriggerAfterTest.accountMap.values()) {
					for(CDH_Party__c cdhParty : AccountTriggerAfterTest.cdhPartyMap.values()) {
						Address__c addr = new Address__c(
							Address_Line1__c = 'Line 1',
							Address_Line2__c = 'Line 2',
							Address_Line3__c = 'Line 3',
							Address_Line4__c = 'Line 4',
							City__c = 'City',
							State__c = 'ON',
							County__c = 'county',
							Zip_Postal_Code__c = 'L8J 3S8',
							Country__c = 'CA',
							Identifying_Address__c = false,
							CDH_Party__c = cdhParty.Id,
							Sales_Account__c = a.Id,
							Status__c = 'Active' );
						addresses.add(addr);
						addresses.add(addr.clone());
						addresses.add(addr.clone());
					}
				}
			}
			return addresses;
		}
		set;
	}

	@isTest
	static void inactivateDuplicateTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		addresses[0].CDH_Party_Site_Number__c = '-1';
		insert addresses[0];
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		Address__c address = addresses[1];
		address.MasterRecord__c = addresses[0].Id;
		address.Status__c = 'Active';
		address.IsDuplicate__c = false;
		address.CDH_Party_Site_Number__c = '-1';
		Test.startTest();
		AddressTriggerBefore beforeTrigger = new AddressTriggerBefore(new Map<Id,Address__c>{null=>address},new List<Address__c>{address});
		beforeTrigger.inactivateDuplicates();
		Test.stopTest();
		System.assert(address.IsDuplicate__c);
	}

	@isTest
	static void changedCDHPartySiteNumbersTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		addresses[0].Status__c = 'Active';
		Address__c addressBefore = addresses[0];
		Address__c addressAfter = addresses[0].clone(true);
		addressBefore.CDH_Party_Site_Number__c = '-1';
		addressAfter.CDH_Party_Site_Number__c = '-2';
		Test.startTest();
		AddressTriggerBefore beforeTrigger = new AddressTriggerBefore(new Map<Id,Address__c>{null=>addressBefore},new List<Address__c>{addressAfter});
		beforeTrigger.changedCDHPartySiteNumbers();
		Test.stopTest();
		System.assertEquals(addressBefore.CDH_Party_Site_Number__c,addressAfter.CDH_Party_Site_Number_Previous__c);
	}

	@isTest
	static void updateCDHPartySiteNumbersTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		addresses[0].Status__c = 'Merged';
		addresses[0].IsDuplicate__c = true;
		addresses[0].CDH_Party_Site_Number__c = '-1';
		addresses[0].CDH_Party_Site_Number_Previous__c = '-2';
		insert addresses[0];
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		Address__c addressBefore = addresses[1].clone(true);
		addressBefore.Status__c = 'Active';
		Address__c addressAfter = addresses[1];
		addressAfter.Status__c = 'Active';
		addressAfter.CDH_Party_Site_Number__c = addresses[0].CDH_Party_Site_Number_Previous__c;
		Test.startTest();
		AddressTriggerBefore beforeTrigger = new AddressTriggerBefore(new Map<Id,Address__c>{null=>addressBefore},new List<Address__c>{addressAfter});
		beforeTrigger.updateCDHPartySiteNumbers();
		Test.stopTest();
		System.assertEquals(addresses[0].CDH_Party_Site_Number__c,addressAfter.CDH_Party_Site_Number__c);
	}

	@isTest // (SeeAllData=true) no longer needed
	static void processTriggerTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		Address__c a = addresses[0];
		insert a;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		AbstractTrigger.setBooleanSettings('Address_After.',true);
		Test.startTest();
		// insert
		AddressTriggerBefore.processTrigger(null,new List<Address__c>{a});
		// update
		AddressTriggerBefore.processTrigger(new Map<Id,Address__c>{a.Id=>a.clone(true)},new List<Address__c>{a});
		// delete
		AddressTriggerBefore.processTrigger(new Map<Id,Address__c>{a.Id=>a},null);
		Test.stopTest();
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Address_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Address_Before.',addresses);
	}
}