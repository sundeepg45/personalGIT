/**
 * This class replaces all before insert and before update case priority triggers.  The
 * processTrigger method is invoked by the CasePriority_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-16
 * 2012-11-16 - Created
 */
public without sharing class CasePriorityTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable the assignRelative trigger method. */
	public static final String ASSIGN_RELATIVE_SETTING = 'CasePriority_Before.assignRelative';

	private final Map<Id,CasePriority__c> oldMap = new Map<Id,CasePriority__c>();
	private final List<CasePriority__c> newList = new List<CasePriority__c>();

	/** 
	 * Standard trigger before constructor.
	 * @param xoldMap the mapping of old values
	 * @param xnewList the list of new values
	 */
	public CasePriorityTriggerBefore(Map<Id,CasePriority__c> xoldMap,List<CasePriority__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Assign the CasePriority's RecordTypeId when the default value was used.
	 */
	public void assignRelative() {
		for(CasePriority__c cp : newList) {
			cp.RelativeCost__c = cp.RelativeCostFormula__c;
			cp.RelativeValue__c = cp.RelativeValueFormula__c;
		}
	}

	/**
	 * This method is called from the CasePriority_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Case Priority objects as in Trigger.oldMap.
	 * @param xnewList the list of new Case Priority objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,CasePriority__c> xoldMap,List<CasePriority__c> xnewList) {
		final CasePriorityTriggerBefore beforeTrigger = new CasePriorityTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_RELATIVE_SETTING,true)) {
			beforeTrigger.assignRelative();
		}
	}
}