/**
 * In the future this class can replace all before insert and before update Case triggers.	
 * The processTrigger method is invoked by the Case_Before trigger and in turn invokes
 * all the methods of this class.	This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * NOTE: Some other existing triggers have not yet been incorporated into this class (future).
 *
 * @version 2014-05-29
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-05-29 - added assignContact() and setRegion() to replace trigger UpdateRegionAndContactOnCase
 * 2012-11-20 - Added protectFields() method to prevent edit of some fields by unauthorized users
 * 2012-06-01 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-05-28 - Updated protected fields to recursively check queues, exclude admins, and use GroupSettings__c.
 */
public with sharing class CaseTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable assignment of case contact */
	public static final String ASSIGN_CONTACT_SETTING = 'Case_Before.assignContact';
	/** BooleanSetting__c key to enable setting region and NA business unit */
	public static final String SET_REGION_SETTING = 'Case_Before.setRegion';
	/** BooleanSetting__c key to enable setting legacy values */
	public static final String ASSIGN_LEGACY_SETTING = 'Case_Before.assignLegacy';
	/** BooleanSetting__c key to enable protecting fields */
	public static final String PROTECT_FIELDS_SETTING = 'Case_Before.protectFields';
	/** Error message displayed when protected fields are edited by unauthorized users */
	public static final String PROTECTED_FIELD_ERROR = 'Only a Case Owner or a member of the owning queue can edit this field. Add a new Case Comment instead.';
	/** Used for testing */
	public Boolean hasErrors = false;

	private final Map<Id,Case> oldMap = new Map<Id,Case>();
	private final List<Case> newList = new List<Case>();


	public CaseTriggerBefore(Map<Id,Case> xoldMap,List<Case> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	public static Id currentUserId {
		get {
			if(currentUserId == null) {
				currentUserId = UserInfo.getUserId();
			}
			return currentUserId;
		}
		set;
	}

	/**
	 * Assigns the current user's internal contact record as the default contact for a new case.
	 */
	public void assignContact() {

		if(isInsert) {
			// get custom setting value that contains the internal account name
			Util__c utilSetting = Util__c.getInstance('RedhatIntAccountName');

			if(utilSetting != null) {
				// get details of current user
				User currentUser = [
					SELECT Contact_Id__c 
					FROM User 
					WHERE Id = :UserInfo.getUserId() 
					LIMIT 1 ];

				if(currentUser.Contact_Id__c != null) {
					// fetch related contact - can't join in the user query above because Contact_Id__c is 
					//  not a relationship field. relies on user triggers to associate the correct contact
					//  to the user record on user creation/activation.
					List<Contact> contacts = [
						SELECT Id 
						FROM Contact 
						WHERE Id = :currentUser.Contact_Id__c 
						AND Account.Name = :utilSetting.Variable_Value__c 
						LIMIT 1 ];

					if(!contacts.isEmpty()) {
						Contact contact = contacts[0];

						for(Case newCase : newList) {

							if(newCase.ContactId == null) {
								// assign contact
								newCase.ContactId = contact.Id;
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Sets the Region and NA Business Unit field on the case based on the assigned contact.
	 */
	public void setRegion() {

		if(isInsert || isUpdate) {
			Set<Id> contactIds = new Set<Id>();

			// build set of contact Ids so we can fetch associated users in bulk
			for(Case newCase : newList) {

				if(newCase.ContactId != null && !contactIds.contains(newCase.ContactId)) {
					contactIds.add(newCase.ContactId);
				}
			}
			
			if(!contactIds.isEmpty()) {
				// fetch users related to case contacts and then build a map of users by contact Id.
				//  relies on user triggers to associate the correct contact to the user record on user 
				//  creation/activation.
				Map<Id, User> userMap = new Map<Id, User>();				
				List<User> users = [
					SELECT 
						Contact_Id__c,
						Region__c,
						Business_Unit__c
					FROM User
					WHERE IsActive = True 
					AND UserType = 'Standard' 
					AND Contact_Id__c IN :contactIds ];

				for(User user : users) {
					userMap.put(user.Contact_Id__c, user);
				}

				// build a set of record type ids for which we should set the region based on custom
				//  setting CaseRecordType__c.
				Set<Id> recordTypeIdSet = new Set<Id>();

				for(CaseRecordType__c recTypeId : CaseRecordType__c.getall().values()) {
					recordTypeIdSet.add(recTypeId.RecordTypeId__c);
				}		

				if(!userMap.isEmpty()) {

					for(Case newCase : newList) {

						if(newCase.ContactId != null && userMap.containsKey(newCase.ContactId)) {
							User user = userMap.get(newCase.ContactId);

							// set region based on user value (only for certain record types).
							if(recordTypeIdSet.contains(newCase.RecordTypeId)) {
								newCase.Region__c = user.Region__c;
							}

							// set NA business unit based on user vale (for all record types - 
							//  not sure why this is different than region logic, but carrying 
							//  this over from the trigger this replaces).
							newCase.NA_Business_Unit__c = user.Business_Unit__c;
						}
					}
				}
			}
		}
	}

	/**
	 * Prevents editing of certain fields by anyone but the case owner or members of the owning queue.
	 */
	public void protectFields() {
		if (isUpdate && AdminByPass__c.getInstance().IsCaseAdmin__c != true) {
			Set<Id> groupIds = new Set<Id>();
			String userIdPrefix = ((String)currentUserId).substring(0,3);
			Set<Id> allowedIds = new Set<Id>{currentUserId};
			// Of course we accept changes the old user can make, because that is standard salesforce
			// We also accept changes the new user can make, since there is no reason not to allow an
			// update than can be done in two steps to be done in one step.
			List<Case> cases = new List<Case>();
			for(Case newCase : newList) {
				Case oldCase = oldMap.get(newCase.Id);
				if (newCase.Status != oldCase.Status || newCase.Case_Notes__c != oldCase.Case_Notes__c || newCase.Case_Resolution__c != oldCase.Case_Resolution__c) {
					cases.add(newCase);
					if(! ((String)newCase.OwnerId).startsWith(userIdPrefix) ) {
						groupIds.add(newCase.OwnerId);
					}
					if(! ((String)oldCase.OwnerId).startsWith(userIdPrefix) ) {
						groupIds.add(oldCase.OwnerId);
					}
				}
			}
			// Now check the group settings and see if any if the groups do not use protected case fields
			for(Id ownerId : groupIds) {
				GroupSetting__c gs = GroupSetting__c.getInstance(ownerId);
				if(gs != null && gs.ProtectedCaseFields__c == false) {
					allowedIds.add(ownerId);
					System.debug('Allowed: '+ownerId);
				}
			}
			groupIds.removeAll(allowedIds);
			if(! groupIds.isEmpty()) {
				// prune empty groups
				List<AggregateResult> aggregateResults = [
					select GroupId
					from GroupMember
					where GroupId in :groupIds
					group by GroupId ];
				allowedIds.addAll(groupIds);
				groupIds.clear();
				if(! aggregateResults.isEmpty()) {
					for(AggregateResult ar : aggregateResults) {
						groupIds.add((Id)ar.get('GroupId'));
					}
					allowedIds.removeAll(groupIds);
					System.debug('Allowed Ids: '+allowedIds);
					// recurse to find all the child groups this user is a member of until we find all
					// the groups of interest
					for(Set<Id> newlyAllowedIds = allowedIds.clone();
						! (groupIds.isEmpty() || newlyAllowedIds.isEmpty());
						allowedIds.addAll(newlyAllowedIds) )
					{
						List<GroupMember> groupMembers = [
							select GroupId, UserOrGroupId
							from GroupMember
							where UserOrGroupId in :newlyAllowedIds 
								and (not GroupId in :allowedIds) ];
						newlyAllowedIds.clear();
						for(GroupMember gm : groupMembers) {
							newlyAllowedIds.add(gm.GroupId);
							System.debug('Allowed: '+gm.GroupId);
						}
						groupIds.removeAll(newlyAllowedIds);
					}
				}
			}
			for(Case newCase : cases) {
				Case oldCase = oldMap.get(newCase.Id);
				if (! (allowedIds.contains(newCase.OwnerId)||allowedIds.contains(oldCase.OwnerId))) {
					System.debug('Not allowed: '+newCase.OwnerId+', '+oldCase.OwnerId);
					if (newCase.Status != oldCase.Status) {
						newCase.Status.addError(PROTECTED_FIELD_ERROR);
						hasErrors = true;
					}
					if (newCase.Case_Notes__c != oldCase.Case_Notes__c) {
						newCase.Case_Notes__c.addError(PROTECTED_FIELD_ERROR);
						hasErrors = true;
					}
					if (newCase.Case_Resolution__c != oldCase.Case_Resolution__c) {
						newCase.Case_Resolution__c.addError(PROTECTED_FIELD_ERROR);
						hasErrors = true;
					}
				}			
			}
		}
	}

	/**
	 * Set the value used for owner lookups and queue name.
	 */
	public override void assignLegacy() {
		Boolean needsQuery = false;
		Set<Id> queueIds = new Set<Id>();
		Map<Id,String> queueMap = new Map<Id,String>();
		for(Case c :newList) {
			if(c.OwnerId != null && ! (''+c.OwnerId).startsWith('005')) {
				queueMap.put(c.ownerId,c.Queue_Name__c);
				needsQuery = needsQuery || isInsert || oldMap.get(c.Id).OwnerId != c.OwnerId;
			}
		}
		if(needsQuery) {
			for(Group g : [
				select Name 
				from Group 
				where Id in :queueMap.keySet() ])
			{
				queueMap.put(g.Id,g.Name);
			}
		}
		for(Case c :newList) {
			String queueName = null;
			Id ownerId = null;
			if(c.OwnerId != null) {
				 if((''+c.OwnerId).startsWith('005')) {
					ownerId = c.OwnerId;
				 }
				 else {
					queueName = queueMap.get(c.OwnerId);
				}
			}
			if(queueName != c.Queue_Name__c) {
				c.Queue_Name__c = queueName;
			}
			if(c.Owner__c != ownerId) {
				c.Owner__c = ownerId;
			}
		}
	}
	
	public static void processTrigger(Map<Id,Case> xoldMap,List<Case> xnewList) {
		final CaseTriggerBefore beforeTrigger = new CaseTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_CONTACT_SETTING,true)) {
			beforeTrigger.assignContact();
		}
		if(AbstractTrigger.isActive(SET_REGION_SETTING,true)) {
			beforeTrigger.setRegion();
		}		
		if(AbstractTrigger.isActive(PROTECT_FIELDS_SETTING,true)) {
			beforeTrigger.protectFields();
		}
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
		AbstractTrigger.processTriggerComplete();
	}
}