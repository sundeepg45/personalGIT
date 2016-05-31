/**
 * This is a test class for AccountMergeBatchable.
 * 
 * @version 2015-11-10
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-11-10 - Updated to include Merged address status.
 * 2015-10-01 - Expose more methods public
 * 2015-08-20 - Created
 */
@isTest
public class AccountMergeBatchableTest {
	static List<CDH_Party__c> cdhParties {
		get {
			return AccountTriggerAfterTest.cdhParties;
		}
	}
	static Map<Id,CDH_Party__c> cdhPartyMap {
		get {
			return AccountTriggerAfterTest.cdhPartyMap;
		}
	}
	public static List<Account> accounts {
		get {
			return AccountTriggerAfterTest.accounts;
		}
	}

	public static Map<Id,Account> accountMap {
		get {
			return AccountTriggerAfterTest.accountMap;
		}
	}

	public static List<EBS_Account__c> ebsAccounts {
		get {
			if(ebsAccounts == null) {
				ebsAccounts = new List<EBS_Account__c>();
				for(Account a : accountMap.values()) {
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

	public static List<Address__c> addresses {
		get {
			if(addresses == null) {
				addresses = new List<Address__c>();
				for(Account a : accountMap.values()) {
					for(CDH_Party__c cdhParty : cdhPartyMap.values()) {
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
							CDH_Party__c = a.CDH_Party_Name__c,
							CDH_Party_Site_Number__c = 's:'+cdhParty.Name,
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

	public static List<Contact> contacts {
		get {
			if(contacts == null) {
				contacts = new List<Contact>();
				for(Account a : accountMap.values()) {
					for(CDH_Party__c cdhParty : cdhPartyMap.values()) {
						if(cdhParty.CDH_Party_Type__c == 'PERSON') {
							Contact c = new Contact(
								AccountId = a.Id,
								CDH_Party__c = cdhParty.Id,
								Email='test@redhat.com',
								FirstName='John',
								Status__c = 'Active',
								LastName=''+a.Id+' '+cdhParty.Id,
								Phone='9055551212', 
								Title='Dr');
							contacts.add(c);
							contacts.add(c.clone());
							contacts.add(c.clone());
						}
					}
				}
			}
			return contacts;
		}
		set;
	}

	@IsTest
	static void hasWorkTest() {
		// start off with no data
		AccountMergeBatchable amb = new AccountMergeBatchable();
		Test.startTest();
		System.assert(amb.accountIds.isEmpty(),'Unexpected migrated accounts: '+amb.accountIds);
		System.assert(! amb.hasWork(),'No work expected');
		// now create the accounts
		Set<Id> accountIds = accountMap.keySet();
		System.assert(amb.accountIds.isEmpty(),'Unexpected migrated accounts: '+amb.accountIds);
		System.assert(! amb.hasWork(),'No work expected');
		// add the accounts to the accountIds set
		amb.accountIds.addAll(accountIds);
		System.assert(! amb.hasWork(),'No work expected');
		// insert contacts with duplicates
		AbstractTrigger.setBooleanSettings('Contact_Before.',false);
		AbstractTrigger.setBooleanSettings('Contact_After.',false);
		insert contacts;
		AbstractTrigger.setBooleanSettings('Contact_Before.',true);
		AbstractTrigger.setBooleanSettings('Contact_After.',true);
		System.assertNotEquals(0,amb.getContactResults(1).size(),'Failed getContactResults test');
		System.assert(amb.hasWork(),'Expected work');
		// insert addresses with duplicates
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		insert addresses;
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		AbstractTrigger.setBooleanSettings('Address_After.',true);
		System.assertNotEquals(0,amb.getAddressResults(1).size(),'Failed getAddressResults test');
		System.assert(amb.hasWork(),'Expected work');
		// insert ebsAccounts with duplicates
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
		insert ebsAccounts;
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
		System.assertNotEquals(0,amb.getEBSAccountResults(1).size(),'Failed getEBSAccountResults test');
		System.assert(amb.hasWork(),'Expected work');
		// clear the accountIds
		amb.accountIds = null;
		System.assert(amb.accountIds.isEmpty(),'Unexpected migrated accounts: '+accountIds);
		System.assert(! amb.hasWork(),'No work expected');
		// add the accountIds back
		amb.accountIds.addAll(accountIds);
		// delete the contacts
		AbstractTrigger.setBooleanSettings('Contact_Before.',false);
		AbstractTrigger.setBooleanSettings('Contact_After.',false);
		delete contacts;
		AbstractTrigger.setBooleanSettings('Contact_Before.',true);
		AbstractTrigger.setBooleanSettings('Contact_After.',true);
		System.assertEquals(0,amb.getContactResults(1).size(),'Failed getContactResults test');
		System.assert(amb.hasWork(),'Expected work');
		// delete addresses
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		delete addresses;
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		AbstractTrigger.setBooleanSettings('Address_After.',true);
		System.assertEquals(0,amb.getAddressResults(1).size(),'Failed getAddressResults test');
		System.assert(amb.hasWork(),'Expected work');
		// delete ebsAccounts
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
		delete ebsAccounts;
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
		System.assertEquals(0,amb.getEBSAccountResults(1).size(),'Failed getEBSAccountResults test');
		System.assert(! amb.hasWork(),'No work expected');
		Test.stopTest();
	}

	@IsTest
	static void startAndExecuteTest() {
		AbstractTrigger.setBooleanSettings('Contact_Before.',false);
		AbstractTrigger.setBooleanSettings('Contact_After.',false);
		insert contacts;
		AbstractTrigger.setBooleanSettings('Contact_Before.',true);
		AbstractTrigger.setBooleanSettings('Contact_After.',true);
		AbstractTrigger.setBooleanSettings('Address_Before.',false);
		AbstractTrigger.setBooleanSettings('Address_After.',false);
		insert addresses;
		AbstractTrigger.setBooleanSettings('Address_Before.',true);
		AbstractTrigger.setBooleanSettings('Address_After.',true);
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
		insert ebsAccounts;
		AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
		AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
		Map<Id,Contact> contactMap = new Map<Id,Contact>(contacts);
		Map<Id,Address__c> addressMap = new Map<Id,Address__c>(addresses);
		Map<Id,EBS_Account__c> ebsAccountMap = new Map<Id,EBS_Account__c>(ebsAccounts);
		AccountMergeBatchable amb = new AccountMergeBatchable();
		amb.accountIds.addAll(accountMap.keySet());
		Test.startTest();
		List<SObject> records = amb.start(null);
		for(SObject o : records) {
			if(o instanceof Contact) {
				System.assertNotEquals(null,contactMap.remove(o.Id),'Unexpected contact '+o);
			}
			else if(o instanceof Address__c) {
				System.assertNotEquals(null,addressMap.remove(o.Id),'Unexpected address '+o);
			}
			else {
				
				System.assert(o instanceof EBS_Account__c,'Unexpected object type: '+o);
				System.assertNotEquals(null,ebsAccountMap.remove(o.Id),'Unexpected ebsAccount '+o);
			}
		}
		System.assert(contactMap.isEmpty(),'Missing contacts: '+contactMap.values());
		System.assert(addressMap.isEmpty(),'Missing addresses: '+addressMap.values());
		System.assert(ebsAccountMap.isEmpty(),'Missing ebsAccounts: '+ebsAccountMap.values());
		amb.execute(null,records);
		Test.stopTest();
		System.assert(amb.errorList.isEmpty(),'Unexpected errors: '+amb.errorList);

		Map<Id,DuplicateLog__c> duplicateLogMap = new Map<Id,DuplicateLog__c>();
		for(DuplicateLog__c dl : [
			select
				DuplicateRecordId__c,
				MasterRecordId__c,
				ObjectType__c 
			from DuplicateLog__c ] )
		{
			System.assert(! duplicateLogMap.containsKey(dl.DuplicateRecordId__c),'Duplicate entry: '+dl);
			duplicateLogMap.put(dl.DuplicateRecordId__c,dl);
		}

		// check the address results
		List<Address__c> addresses2 = [
			select 
				Id,
				Sales_Account__c,
				CDH_Party__c,
				CDH_Party_Site_Number__c,
				IsDuplicate__c,
				MasterRecord__c,
				Status__c 
			from Address__c
			order by MasterRecord__c nulls first ];
		System.assertEquals(addresses.size(),addresses2.size());
		Map<String,Address__c> masterAddressMap = new Map<String,Address__c>();
		for(Address__c a : addresses2) {
			String key = a.Sales_Account__c+':'+a.CDH_Party_Site_Number__c;
			Address__c masterRecord = masterAddressMap.get(key);
			DuplicateLog__c dl = duplicateLogMap.get(a.Id);
			if(! a.IsDuplicate__c) {
				System.assertEquals(null,masterRecord,'Duplicate active address: '+a);
				System.assertEquals(null,a.MasterRecord__c);
				masterAddressMap.put(key,a);
				System.assertEquals(null,dl);
			}
			else {
				System.assertNotEquals(null,masterRecord,'Missing active address for: '+a);
				System.assertEquals(masterRecord.Id,a.MasterRecord__c);
				System.assertEquals(masterRecord.Id,dl.MasterRecordId__c);
			}
		}
		// check the ebsAccounts results
		List<EBS_Account__c> ebsAccounts2 = [
			select 
				Id,
				Sales_Account__c,
				Name,
				MasterRecord__c,
				Status__c
			from EBS_Account__c
			order by MasterRecord__c nulls first ];
		System.assertEquals(ebsAccounts.size(),ebsAccounts2.size());
		Map<String,EBS_Account__c> masterEBSAccountMap = new Map<String,EBS_Account__c>();
		for(EBS_Account__c e : ebsAccounts2) {
			String key = e.Sales_Account__c+':'+e.Name;
			EBS_Account__c masterRecord = masterEBSAccountMap.get(key);
			DuplicateLog__c dl = duplicateLogMap.get(e.Id);
			if(e.Status__c == 'Active') {
				System.assertEquals(null,masterRecord,'Duplicate active EBS Account: '+e);
				System.assertEquals(null,e.MasterRecord__c);
				masterEBSAccountMap.put(key,e);
				System.assertEquals(null,dl);
			}
			else {
				System.assertEquals('INACTIVE',(''+e.Status__c).toUpperCase(),'Unexpected status for: '+e);
				System.assertNotEquals(null,masterRecord,'Missing active EBS Account for: '+e);
				System.assertEquals(masterRecord.Id,e.MasterRecord__c);
				System.assertEquals(masterRecord.Id,dl.MasterRecordId__c);
			}
		}
		// check the contact results
		List<Contact> contacts2 = [
			select 
				Id,
				AccountId,
				CDH_Party__c,
				MasterRecord__c,
				Status__c 
			from Contact
			order by MasterRecord__c nulls first ];
		System.assertEquals(contacts.size(),contacts2.size());
		Map<String,Contact> masterContactMap = new Map<String,Contact>();
		for(Contact c : contacts2) {
			String key = c.AccountId+':'+c.CDH_Party__c;
			Contact masterRecord = masterContactMap.get(key);
			DuplicateLog__c dl = duplicateLogMap.get(c.Id);
			if(c.Status__c == 'Active') {
				System.assertEquals(null,masterRecord,'Duplicate active contact: '+c);
				System.assertEquals(null,c.MasterRecord__c);
				masterContactMap.put(key,c);
				System.assertEquals(null,dl);
			}
			else {
				System.assertEquals('INACTIVE',(''+c.Status__c).toUpperCase(),'Unexpected status for: '+c);
				System.assertNotEquals(null,masterRecord,'Missing active contact for: '+c);
				System.assertEquals(masterRecord.Id,c.MasterRecord__c);
				System.assertEquals(masterRecord.Id,dl.MasterRecordId__c);
			}
		}
		System.assert(! amb.hasWork(),'No work expected');
	}
}