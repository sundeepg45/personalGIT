/**
 * In the future this class can replace all before insert and before update contact triggers.  
 * The processTrigger method is invoked by the Contact_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * NOTE: Some other existing triggers have not yet been incorporated into this class (future).
 *
 * @version 2016-02-11
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2012-06-01 - Created
 * Bill C Riemers <briemers@redhat.com>
 * @since 2016-02-11 - Added update extrenal ids method
 * @since 2015-10-01 - add assignment of the reparent flag
 * @since 2015-08-27 - add method to inactivate duplicates
 */
public with sharing class ContactTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting legacy values */
	public static final String ASSIGN_LEGACY_SETTING = 'Contact_Before.assignLegacy';
	/** BooleanSetting__c key to enable inactivateDuplicates method. */
	public static final String INACTIVATE_DUPLICATES_SETTING = 'EBSAccount_Before.inactivateDuplicates';
	/** BooleanSetting__c key to enable update external Ids method. */
	public static final String UPDATE_EXTERNAL_IDS_SETTING = 'Contact_Before.updateExternalIds';

	private final Map<Id,Contact> oldMap = new Map<Id,Contact>();
	private final List<Contact> newList = new List<Contact>();

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewList the mapping of new values
	 */
	public ContactTriggerBefore(Map<Id,Contact> xoldMap,List<Contact> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Inactivate duplicates.
	 */
	public void inactivateDuplicates() {
		if(isUpdate) {
			for(Contact contact : newList) {
				Boolean isDuplicate = (contact.MasterRecord__c != null);
				if(isDuplicate && contact.Status__c != 'Inactive') {
					contact.Status__c = 'Inactive';
				}
				Boolean isReparented = (contact.Reparented__c == true) && ! isDuplicate;
				if(! (isInsert || isDuplicate)) {
					if(! isReparented) {
						Contact old = oldMap.get(contact.Id);
						isReparented = (old != null && old.AccountId != contact.AccountId);
					}
					if(isReparented) {
						ContactTriggerAfter.reparentedContactIds.add(contact.Id);
						// once a contact id is added to the set we can set isReparented to false
						isReparented = false; 
					}
				}
				if(contact.Reparented__c != isReparented) {
					contact.Reparented__c = isReparented;
				}
			}
		}
	}

	private static String blankValue(String value,String defaultValue) {
		if(value == '' || value == null) {
			value = defaultValue;
		}
		return value;
	}

	/**
	 * Generate a hash for a contact based on account id, firstname, lastname, email, and phone
	 * @param c contact to hash
	 * @return the generated hash string
	 */
	public static String hash(Contact c) {
		return c.AccountId + EncodingUtil.base64Encode( Crypto.generateDigest(
			'SHA-512',
			Blob.valueOf(
				( blankValue(c.FirstName,'')+'\n'
					+blankValue(c.LastName,'')+'\n'
					+blankValue(c.Email,'')+'\n'
					+blankValue(c.Phone,'') ).toLowerCase() ) ));
	}

	/**
	 * This is a before trigger that clears the Hash__c value when it is no longer valid...
	 * As a to-do item we should clear the Contract_External_Id__c value when it is no longer valid.
	 */
	public void updateExternalIds() {
//to-do		// For now, lets not do this, as it could cause regression.
//to-do		for(Contact c : newList) {
//to-do			if(c.Contact_External_Id__c != null) {
//to-do				String contactExternalId = c.Contact_External_Id__c;
//to-do				final String lockString = 'ContactTriggerAfter.Lock';
//to-do				if(isUpdate && c.CDH_Party__c != null && ThreadLock.lock(lockString)) {
//to-do					try {
//to-do						contactExternalId = c.Cdh_Party_Number__c + c.AccountId;
//to-do					}
//to-do					catch(Exception ignored) {}
//to-do					finally {
//to-do						ThreadLock.unlock(lockString);
//to-do					}
//to-do				}
//to-do				if(c.MasterRecord__c != null) {
//to-do					contactExternalId = null;
//to-do				}
//to-do				if(contactExternalId != c.Contact_External_Id__c) {
//to-do					c.Contact_External_Id__c = null;
//to-do				}
//to-do			}
//to-do		}
		for(Contact c : newList) {
			if(c.Hash__c != hash(c) || c.MasterRecord__c != null) {
				c.Hash__c = null;
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,Contact> xoldMap,List<Contact> xnewList) {
		final ContactTriggerBefore beforeTrigger = new ContactTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
		if(AbstractTrigger.isActive(INACTIVATE_DUPLICATES_SETTING,true)) {
			beforeTrigger.inactivateDuplicates();
		}
		if(AbstractTrigger.isActive(UPDATE_EXTERNAL_IDS_SETTING,true)) {
			beforeTrigger.updateExternalIds();
		}
		AbstractTrigger.processTriggerComplete();
	}
}