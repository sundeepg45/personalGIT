/**
 * This class replaces all after insert and after update case priority triggers.  The
 * processTrigger method is invoked by the CasePriority_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-14
 */
public without sharing class CasePriorityTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable upsertCasePriority */
	public static final String UPDATE_CASE = 'CasePriority_After.updateCase';

	private final Map<Id,CasePriority__c> oldMap = new Map<Id,CasePriority__c>();
	private final Map<Id,CasePriority__c> newMap = new Map<Id,CasePriority__c>();

	/**
	 * This our standard constructor for an after trigger.
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public CasePriorityTriggerAfter(Map<Id,CasePriority__c> xoldMap,Map<Id,CasePriority__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	public void updateCase() {
		if(isInsert && ! newMap.isEmpty()) {
			List<Case> caseList = new List<Case>();
			for(CasePriority__c cp : newMap.values()) {
				caseList.add(new Case(Id=cp.Case__c,CasePriority__c=cp.Id));
			}
			for(Database.SaveResult sr : Database.update(caseList,false)) {
				Case c = caseList.remove(0);
				if(! sr.isSuccess()) {
					newMap.get(c.CasePriority__c).addError('Failed to set CasePriority field on Case: '+sr.getErrors());
				}
			}
		}
	}

	/**
	 * This method is called from the CasePriority_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous CasePriority objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new CasePriority objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,CasePriority__c> xoldMap,Map<Id,CasePriority__c> xnewMap) {
		final CasePriorityTriggerAfter afterTrigger = new CasePriorityTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(UPDATE_CASE,true)) {
			afterTrigger.updateCase();
		}
	}
}