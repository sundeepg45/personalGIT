/**
 * This class contains unit tests for validating the behavior of 
 * ContactTriggerBefore.cls
 *
 * @version 2016-02-11
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2012-06-01 - Created
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2016-02-12 - Added test for update external ids method
 */
@isTest
private class ContactTriggerBeforeTest {
	private static Contact contact {
		get {
			if (contact == null) {
				contact = new Contact(
					LastName='Foo',
					OwnerId = UserInfo.getUserId(),
					Owner__c = null);
			}
			return contact;
		}
		set;
	}

	/**
	 * Test inactiveDuplicate method.
	 */
	@isTest
	static void inactivateDuplicate() {
		contact.MasterRecord__c = ContactTriggerAfterTest.getContactId();
		contact.Status__c = 'Active';
		Test.startTest();
		ContactTriggerBefore beforeTrigger = new ContactTriggerBefore(new Map<Id,Contact>{null=>contact},new List<Contact>{contact});
		beforeTrigger.inactivateDuplicates();
		Test.stopTest();
		System.assertEquals('INACTIVE',contact.Status__c.toUpperCase());
	}

	/**
	 * Test updateExternalIds method.
	 */
	@isTest
	static void updateExternalIds() {
		contact.Hash__c = 'Fudge';
		ContactTriggerBefore beforeTrigger = new ContactTriggerBefore(new Map<Id,Contact>{null=>contact},new List<Contact>{contact});
		beforeTrigger.updateExternalIds();
		System.assertEquals(null,contact.Hash__c);
		String hash = ContactTriggerBefore.hash(contact);
		contact.Hash__c = hash;
		beforeTrigger.updateExternalIds();
		System.assertEquals(hash,contact.Hash__c);
	}

	/**
	 * Test processTrigger method.
	 */
	@isTest
	static void processTriggerTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Contact_Before.',false);
		AbstractTrigger.setBooleanSettings('Contact_After.',false);
		insert contact;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contact_Before.',true);
		AbstractTrigger.setBooleanSettings('Contact_After.',true);
		Test.startTest();
		// insert
		ContactTriggerBefore.processTrigger(null,new List<Contact>{contact});
		// update
		ContactTriggerBefore.processTrigger(new Map<Id,Contact>{contact.Id=>contact.clone(true)},new List<Contact>{contact});
		// delete
		ContactTriggerBefore.processTrigger(new Map<Id,Contact>{contact.Id=>contact},null);
		Test.stopTest();
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Contact_Before.');
	}

	/**
	 * Perform a test call the the trigger.
	 */
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Contact_Before.',new List<Contact>{contact});
	}
}