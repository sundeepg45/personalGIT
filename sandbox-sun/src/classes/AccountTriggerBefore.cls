/**
 * This class will eventually replace all before insert and before update account triggers.
 * The processTrigger method is invoked by the Account_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control
 * the order in which the code logic is invoked, as well as allowing other class features
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-05-18
 * 2011-05-18 - refactored with new top level class similar to Lead triggers
 *
 */
public abstract without sharing class AccountTriggerBefore extends AbstractTrigger {
	public static final String LOCKED = 'Locked';
	public static final String PENDING_UPDATE = 'Pending Update';

	/** BooleanSetting__c key to enable the accountPartnerUpdate trigger method. */
	public static Map<String,Boolean> booleanSettingMap {
		get { return AbstractTrigger.booleanSettingMap; }
	}

	/** Normally populated as Trigger.oldMap */
	protected final Map<Id,Account> oldMap = new Map<Id,Account>();
	/** Normally populated as Trigger.new */
	protected final List<Account> newList = new List<Account>();

	/**
	 * This constructor is normally called via the child super methods.
	 */
	public AccountTriggerBefore(Map<Id,Account> xoldMap,List<Account> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Create a mutable account map.
	 * @return a mutable account map.
	 */
	public Map<Id,Account> accountMap {
		get {
			if(accountMap == null && ! isInsert) {
				accountMap = new Map<Id,Account>(newList);
			}
			return accountMap;
		}
		set;
	}

	/**
	 * This method is called from the Account_Before trigger to invoke all the methods
	 * of this class related to delete, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Account objects as in Trigger.oldMap.
	 * @param xnewList the list of new Account objects as in Trigger.new
	 */
	public static void processDeleteTrigger(Map<Id,Account> xoldMap,List<Account> xnewList) {
		// Need to go delete any active partner programs on the account to allow the events to go out to CDH
		List<Partner_Program__c> programs = [Select Id from Partner_Program__c where Account__c in :xoldMap.keySet() and Status__c = 'Active'];
		delete programs;
	}

	/**
	 * This method is called from the Account_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Account objects as in Trigger.oldMap.
	 * @param xnewList the list of new Account objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Account> xoldMap,List<Account> xnewList) {
		AccountTriggerBeforeLock.processTrigger(xoldMap,xnewList);
		AccountTriggerBeforeSFA.processTrigger(xoldMap,xnewList);
	}
}