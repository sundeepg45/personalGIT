/**
 * This class replaces all after insert and after update lead triggers.  The
 * processTrigger method is invoked by the Lead_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2013-08-07
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-07 - Added AbstractTrigger.processTriggerComplete call, and update query
 * 2012-03-05 - split into multiple subclasses.
 * 2011-09-01 - Created
 */
public abstract without sharing class LeadTriggerAfter {
	/** Map of all the BooleanSetting__c values used.  (Not used)*/
	public static Map<String,Boolean> booleanSettingMap {
		get {
			if(booleanSettingMap == null) {
				booleanSettingMap = new Map<String,Boolean>();
				for(String key : LeadTriggerAfterPartner.booleanSettingKeys) {
					booleanSettingMap.put(key,getBooleanSettingValue(key));
				}
			}
			return booleanSettingMap;
		}
	}
	/** Normally populated as a copy of Trigger.oldMap */
	protected final Map<Id,Lead> oldMap;
	/** Normally populated as Trigger.new */
	protected final Map<Id,Lead> newMap;
	/** Logically equivalent to Trigger.IsDelete */
	protected final Boolean isDelete;
	/** Logically equivalent to Trigger.IsInsert */
	protected final Boolean isInsert;
	/** Logically equivalent to Trigger.IsUpdate */
	protected final Boolean isUpdate;
	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	protected LeadTriggerAfter(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		oldMap = xoldMap;
		isDelete = (xnewMap == null);
		isInsert = (xoldMap == null);
		isUpdate = !(isDelete || isInsert);
		if(isDelete) {
			xnewMap = new Map<Id,Lead>();
		}
		newMap = new Map<Id,Lead>(xnewMap);
	}

	/**
	 * Query a Boolean value from BooleanSetting__c constants.
	 */
	public static Boolean getBooleanSettingValue(String key) {
		Boolean retval = null;
		BooleanSetting__c bs = BooleanSetting__c.getInstance(key);
		if(bs != null) {
			retval = bs.Value__c;
		}
		return retval;
	}

	/**
	 * Called to add error messages to the lead and remove the map entry.
	 *
	 * @param leadId the Id of the lead to add the error to
	 * @param newMap the updatable map of leads base on Id
	 * @param message the error message to report
	 * @param errors the Database.Errors object
	 * @param retval the current error status (e.g. hasErrors)
	 * @returns the new error status
	 */
	public static Boolean addErrorsToLead(Id leadId, Map<Id,Lead> newMap, String message,List<Database.Error> errors,Boolean retval) {
		if(! errors.isEmpty()) {
			Lead newLead = newMap.remove(leadId);
			if(newLead != null) {
				newLead.addError(message+': '+errors);
			}
			retval = true;
		}
		return retval;
	}

	/**
	 * A mapping of users.
	 */
	public Map<Id,User> userMap {
		get {
			if(userMap == null) {
				userMap = AbstractTrigger.getUserMap(newMap.values());
			}
			return userMap;
		}
		set;
	}

	/**
	 * The current user.
	 */
	public User currentUser {
		get {
			// no need to do another query, we can simply reuse the userMap query above...
			if(currentUser == null) {
				currentUser = userMap.get(UserInfo.getUserId());
			}
			return currentUser;
		}
		set;
	}

	/**
	 * This method is called from the Lead_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual after triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new Lead objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		LeadTriggerAfterPartner.processTrigger(xoldMap,xnewMap);
		LeadTriggerAfterGLM.processTrigger(xoldMap,xnewMap);
		AbstractTrigger.processTriggerComplete();
	}
}