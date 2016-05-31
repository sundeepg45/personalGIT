/**
 * This class replaces all after insert and after update contact triggers.  The
 * processTrigger method is invoked by the Contact_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-02-11
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2016-02-12 - Added update external ids method
 * @since 2015-10-01 - Added logDuplicates method
 * @since 2015-08-12 - Created by refactoring from the Contact_Trigger_After class and outbound messages limited to events that update relevant fields
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2015-08-13 - Suppressing publishing of test records per US71693
 */
public without sharing class ContactTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable sendOutboundMessage method. */
	public static final String SEND_OUTBOUND_MESSAGE_SETTING = 'Contact_After.sendOutboundMessage';
	/** BooleanSetting__c key to enable logDuplicates method. */
	public static final String LOG_DUPLICATES_SETTING = 'Contact_After.logDuplicates';
	/** BooleanSetting__c key to enable update external Ids method. */
	public static final String UPDATE_EXTERNAL_IDS_SETTING = 'Contact_After.updateExternalIds';

	public static final Id INTEGRATION_ADMIN_ID = '00530000000f8Sv';

	/** Used to keep track of the contact ids of reparented records. */
	public static Set<Id> reparentedContactIds = new Set<Id>();

	private final Map<Id,Contact> oldMap = new Map<Id,Contact>();
	private final Map<Id,Contact> newMap = new Map<Id,Contact>();
//	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public ContactTriggerAfter(Map<Id,Contact> xoldMap,Map<Id,Contact> xnewMap, Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	@TestVisible
	private static Set<String> excludeAccountRecordTypeDeveloperNames {
		get {
			if( excludeAccountRecordTypeDeveloperNames == null) {
				excludeAccountRecordTypeDeveloperNames = new Set<String>();
				try {
					// todo: this is an inappropriate use of labels
					for(String recordTypeDeveloperName : Label.AccountPartnerRecordType.split(',')){
						excludeAccountRecordTypeDeveloperNames.add(recordTypeDeveloperName);
					}
				}
				catch(Exception ignore1) {}
				excludeAccountRecordTypeDeveloperNames.remove(null);
				excludeAccountRecordTypeDeveloperNames.remove('');
			}
			return excludeAccountrecordTypeDeveloperNames;
		}
		set;
	}

	/**
	 * Send an outbound message when a contact is created, undelete, or one of the relevant
	 * fields have been update.
	 */
	public List<IntegrationObjects.Contact> sendOutboundMessage() {
		List<IntegrationObjects.Contact> ioContacts = new List<IntegrationObjects.Contact>();
		if(isInsert || isUndelete || INTEGRATION_ADMIN_ID != UserInfo.getUserId() || Test.isRunningTest() ) {
			Set<Id> contactIds = new Set<Id>();
			for(Contact contact : newMap.values()) {
				Contact oldContact = oldMap.get(contact.Id);
				if(isInsert
					|| isUndelete
					|| oldContact == null
					|| oldContact.Name != contact.Name
					|| oldContact.AccountId != contact.AccountId
					|| oldContact.CDH_Party__c != contact.CDH_Party__c
					|| oldContact.FirstName != contact.FirstName
					|| oldContact.LastName != contact.LastName
					|| oldContact.Salutation != contact.Salutation
					|| oldContact.Email != contact.Email
					|| oldContact.Phone != contact.Phone
					|| oldContact.MobilePhone != contact.MobilePhone
					|| oldContact.Fax != contact.Fax
					|| oldContact.LoginName__c != contact.LoginName__c
					|| oldContact.CDH_Party_Number__c != contact.CDH_Party_Number__c
					|| oldContact.Account_Record_Type__c != contact.Account_Record_Type__c)
				{
					// we'll also do this comparison in the query, as we might not have set
					// this field in test methods
					if(! excludeAccountRecordTypeDeveloperNames.contains(contact.Account_Record_Type__c)) {
						contactIds.add(contact.Id);
					}
				}
			}
			if(!contactIds.isEmpty()) {
				// iterating on the list of contacts created/updated.
				for(Contact contact:[
					select 
						Name,
						AccountId,
						MasterRecord__r.Status__c,
						Status__c,
						Account.CDH_Party_Name__r.Name,
						CDH_Party__c,
						CDH_Party__r.Name,
						FirstName,
						LastName,
						Salutation,
						Email,
						Phone,
						MobilePhone,
						Fax,
						LoginName__c,
						CDH_Party_Number__c,
						Account_Record_Type__c,
						Do_Not_Publish_To_Bus__c,
						Do_Not_Publish_To_Bus_Account__c
					from Contact 
					where Id IN :contactIds
						and Account.RecordType.DeveloperName not in :excludeAccountRecordTypeDeveloperNames ] )
				{
					// US71693
					OutboundService.DoNotPublish = (OutboundService.DoNotPublish || contact.Do_Not_Publish_To_Bus__c || contact.Do_Not_Publish_To_Bus_Account__c);

					// Generating the Integration object of contact
					IntegrationObjects.Contact  ioContact  = new IntegrationObjects.Contact();
					ioContact = IntegrationObjectConverter.convertContact(contact);

					// setting reference related attribute because those would not be set in integration object converter method.
					ioContact.SalesAccount_CDH_Party_Number = contact.Account.CDH_Party_Name__r.Name;
					ioContact.CDH_Party_Number = contact.CDH_Party__r.Name;
	
					ioContacts.add(ioContact);
				}
				if(! ioContacts.isEmpty()) {
					String operation = 'Create';
					if(isUpdate || isUndelete) {
						operation = 'Update';
					}
					//This logic is for defining the priority of the outbound message
					String piorityStatus = 'BulkInsertUpdate';
					if(ioContacts.size() == 1) {
						piorityStatus = 'SingleInsertUpdate';
					}
					system.debug('Create events ---->'+ioContacts);
					OutboundService.queueContactMessages(ioContacts,operation,piorityStatus);
				}
			}
		}
		return ioContacts;
	}

	/**
	 * Used to create the duplicate log entries.
	 */
	public void logDuplicates() {
		if(! isInsert) {
			Set<Id> accountIds = new Set<Id>();
			for(Contact contact : newMap.values()) {
				if(contact.MasterRecord__c == null) {
					Contact old = oldMap.get(contact.Id);
					if((old != null && old.AccountId != contact.AccountId)
						|| reparentedContactIds.contains(contact.Id) )
					{
						accountIds.add(contact.AccountId);
					}
				}
			}
			if(! accountIds.isEmpty()) {
				AccountMergeBatchable amb = new AccountMergeBatchable();
				amb.accountIds = accountIds;
				List<SObject> contacts = amb.getContacts(new List<SObject>(), 0);
				if(!contacts.isEmpty()) {
					amb.discoveredBy = 'Reparent';
					amb.execute(null,contacts);
				}
			}
		}
	}

	public void updateExternalIds() {
		Set<String> hashSet = new Set<String>();
		Map<String,Contact> hashMap = new Map<String,Contact>();
		for(Contact c : newMap.values()) {
			if(c.Hash__c != null) {
				hashSet.add(c.Hash__c);
			}
			else if(c.MasterRecord__c == null) {
				String key = ContactTriggerBefore.hash(c);
				hashMap.put(key,new Contact(Id=c.Id,Hash__c=key));
			}
		}
		hashMap.keySet().removeAll(hashSet);
		if(! hashMap.isEmpty()) {
			for(AggregateResult ar : [
				select Hash__c 
				from Contact 
				where Hash__c in :hashMap.keySet()
				group by Hash__c ])
			{
				hashMap.remove(String.valueOf(ar.get('Hash__c')));
			}
			if(! hashMap.isEmpty()) {
				// we are already locked from recursive triggers
				Database.update(hashMap.values(),false);
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 * @param isUndelete true if being restored from the recycle bin
	 */
	public static void processTrigger(Map<Id,Contact> xoldMap,Map<Id,Contact> xnewMap ,Boolean isUndelete) {
		// We use a locking variable to avoid unintended recursion.
		final String lockString = 'ContactTriggerAfter.Lock';
		if(ThreadLock.lock(lockString)) {
			try {
				final ContactTriggerAfter afterTrigger = new ContactTriggerAfter(xoldMap,xnewMap, isUndelete);
				if(AbstractTrigger.isActive(UPDATE_EXTERNAL_IDS_SETTING,true)) {
					afterTrigger.updateExternalIds();
				}
				if(AbstractTrigger.isActive(SEND_OUTBOUND_MESSAGE_SETTING,true)) {
					afterTrigger.sendOutboundMessage();
				}
				if(AbstractTrigger.isActive(LOG_DUPLICATES_SETTING,true)) {
					afterTrigger.logDuplicates();
				}
			}
			finally {
				try {
					AbstractTrigger.processTriggerComplete();
				}
				finally {
					ThreadLock.unlock(lockString);
				}
			}
		}
	}
}