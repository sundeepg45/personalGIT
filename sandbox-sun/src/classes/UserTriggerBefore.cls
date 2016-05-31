/**
 * This class will eventually replace all before insert and before update user triggers.  
 * The processTrigger method is invoked by the User_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-06-02
 * 2012-06-02 - Created to support SMR
 */
public without sharing class UserTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting legacy copy values */
	public static final String COPY_LEGACY_SETTING = 'User_Before.copyLegacy';

	private final Map<Id,User> oldMap;
	private final List<User> newList;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public UserTriggerBefore(Map<Id,User> xoldMap,List<User> xnewList) {
		super(xoldMap,xnewList,null);
		oldMap = (Map<Id,User>)oldSObjectMap;
		newList = (List<User>)newSObjectList;
	}

	/**
	 * This method copies Legacy_Role__c and Legacy_Profile__c picklist values
	 * into text fields.
	 */
	public void copyLegacy() {
		for(User u : newList) {
			// check before assigning to avoid extra field tracking
			if(u.Legacy_Profile_Copy__c != u.Legacy_Profile__c) {
				u.Legacy_Profile_Copy__c = u.Legacy_Profile__c;
			}
			// check before assigning to avoid extra field tracking
			if(u.Legacy_Role_Copy__c != u.Legacy_Role__c) {
				u.Legacy_Role_Copy__c = u.Legacy_Role__c;
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 */
	public static void processTrigger(Map<Id,User> xoldMap,List<User> xnewList) {
		final UserTriggerBefore beforeTrigger = new UserTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(COPY_LEGACY_SETTING,true)) {
			beforeTrigger.copyLegacy();
		}
	}
}