/**
 * Test class created for ContactTriggerAfter class.
 *
 * @version 2016-02-12
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2016-02-12 - Added test for update external ids method
 * @since 2015-10-01 - added test for logDuplicates
 * @since 2015-08-27 - expose the getContactId method
 * @since 2015-08-19 - corrected test error with insert missing boolean settings
 * @since 2015-08-12 - created
 */
@isTest
public class ContactTriggerAfterTest {
	private static CDH_Party__c cdhPersonParty {
		get {
			if(cdhPersonParty == null) {
				cdhPersonParty = new CDH_Party__c(
					Name = '-12341341',
					CDH_Party_Type__c = 'PERSON',
					CDH_Party_Name__c = 'ContactTriggerAfterTest.personPartyName',
					CDH_Party_Number_Ext__c = '-12341341');
			}
			return cdhPersonParty;
		}
		set;
	}

	private static CDH_Party__c cdhEntitleParty {
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

	private static Id getCDHPersonPartyId() {
		if(cdhPersonParty.Id == null) {
			insert new List<CDH_Party__c>{cdhPersonParty,cdhEntitleParty};
		}
		return cdhPersonParty.Id;
	}

	private static Id getCDHEntitlePartyId() {
		if(cdhEntitleParty.Id == null) {
			insert new List<CDH_Party__c>{cdhPersonParty,cdhEntitleParty};
		}
		return cdhEntitleParty.Id;
	}

	private static Account entitleAccount {
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

	private static Id getEntitleAccountId() {
		if(entitleAccount.Id == null) {
			insert entitleAccount;
		}
		return entitleAccount.Id;
	}

	private static Contact contact { get {
		if(contact == null) {
			Id cdhPersonPartyId = getCDHPersonPartyId();
			Id entitleAccountId = getEntitleAccountId();
			contact = new Contact(
				Account = entitleAccount,
				AccountId = entitleAccountId,
				CDH_Party__r = cdhPersonParty,
				CDH_Party__c = cdhPersonPartyId,
				OwnerId = UserInfo.getUserId(),
				FirstName = 'first name',
				LastName = 'last name',
				Email = 'test@nowhere.com',
				Phone = '1-800-555-1212');
		}
		return contact;
	} }

	/**
	 * Insert the contact and return the contact id.
	 * 
	 * @return contact id
	 */
	public static Id getContactId() {
		if(contact.Id == null) {
			// Turn off all triggers, as we are going to test those next
			AbstractTrigger.setBooleanSettings('Contact_After.',false);
			insert contact;
			// Turn on all the triggers, and make sure everything is tested.
			AbstractTrigger.setBooleanSettings('Contact_After.',true);
		}
		return contact.Id;
	}

	/**
	 * Test the sendOutboundMessage method.
	 */
	@isTest
	static void sendOutboundMessage() {
		// since we can't update labels, we just clear this set before our test runs
		ContactTriggerAfter.excludeAccountRecordTypeDeveloperNames.clear();
		Id contactId = getContactId();
		Contact contact1 = contact.clone(true);
		ContactTriggerAfter afterTrigger = new ContactTriggerAfter(null,new Map<Id,Contact>{contactId=>contact1},false);
		// test insert
		List<IntegrationObjects.Contact> ioContacts = afterTrigger.sendOutboundMessage();
		System.assertEquals(1,ioContacts.size());
		Contact contact2 = contact1.clone(true);
		// test update that does not change a relevant field
		afterTrigger = new ContactTriggerAfter(new Map<Id,Contact>{contactId=>contact1},new Map<Id,Contact>{contactId=>contact2},false);
		ioContacts = afterTrigger.sendOutboundMessage();
		System.assertEquals(0,ioContacts.size());
		// test an undelete
		afterTrigger = new ContactTriggerAfter(null,new Map<Id,Contact>{contactId=>contact2},true);
		ioContacts = afterTrigger.sendOutboundMessage();
		System.assertEquals(1,ioContacts.size());
		// test update that changes a relevant field
		contact2.FirstName = contact2.FirstName+'.';
		afterTrigger = new ContactTriggerAfter(new Map<Id,Contact>{contactId=>contact1},new Map<Id,Contact>{contactId=>contact2},false);
		ioContacts = afterTrigger.sendOutboundMessage();
		System.assertEquals(1,ioContacts.size());
	}

	/**
	 * Test the logDuplicates method.
	 */
	@isTest
	static void logDuplicatesTest() {
		List<Account> accounts = new List<Account> {entitleAccount,entitleAccount.clone()};
		insert accounts;
		List<Contact> contacts = new List<Contact>{contact,contact.clone()};
		insert contacts;
		List<Contact> contactsOld = contacts.deepClone(true,true,true);
		Id accountId = accounts[1].Id;
		for(Contact c : contactsOld) {
			c.AccountId = accountId;
		}
		ContactTriggerAfter triggerAfter = new ContactTriggerAfter(new Map<Id,Contact>(contactsOld),new Map<Id,Contact>(contacts),false);
		Test.startTest();
		triggerAfter.logDuplicates();
		Test.stopTest();
		System.assertEquals(1,[select count() from DuplicateLog__c]);
	}

	/**
	 * Test the updateExternalIds method.
	 */
	@isTest
	static void updateExternalIds() {
		contact.Hash__c = null;
		Id contactId = getContactId();
		Contact contact1 = contact.clone(true);
		String hash = ContactTriggerBefore.hash(contact1);
		ContactTriggerAfter afterTrigger = new ContactTriggerAfter(null,new Map<Id,Contact>{contactId=>contact1},false);
		Test.startTest();
		afterTrigger.updateExternalIds();
		Test.stopTest();
		Contact contact2 = [select Hash__c from Contact where Id = :contactId];
		System.assertEquals(hash,contact2.Hash__c);
	}

	/**
	 * Test the processTrigger method.
	 */
	@isTest 
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Contact_After.',false);
		AbstractTrigger.insertMissing = 100;
		Contact contact0 = contact;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		ContactTriggerAfter.processTrigger(null,new Map<Id,Contact>{null=>contact0},false);
		// insert the contact, again with the triggers off
		getContactId();
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contact_After.',true);
		Contact contact1 = contact0.clone(true);
		Contact contact2 = contact0.clone(true);
		Test.startTest();
		// insert test
		ContactTriggerAfter.processTrigger(null,new Map<Id,Contact>{contact2.Id=>contact2},false);
		// update test
		ContactTriggerAfter.processTrigger(new Map<Id,Contact>{contact1.Id=>contact0},new Map<Id,Contact>{contact2.Id=>contact2},false);
		// delete test
		ContactTriggerAfter.processTrigger(new Map<Id,Contact>{contact1.Id=>contact1},null,false);
		// undelete test
		ContactTriggerAfter.processTrigger(null,new Map<Id,Contact>{contact2.Id=>contact2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('Contact_After.');
	}

	/**
	 * Test that just invoke the trigger.  We already tested the results in the above
	 * methods.  If we check it here then we can have deployment problems
	 *  as the trigger may be deployed after the class, or could be inactive.
	 */
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		AbstractTriggerTest.deployTest('Contact_After.',new List<Contact>{contact});
	}
}