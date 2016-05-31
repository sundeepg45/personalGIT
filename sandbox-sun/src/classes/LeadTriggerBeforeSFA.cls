/**
 * This class replaces all before insert and before update lead triggers.  The
 * processTrigger method is invoked by the Lead_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-07-19
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-05-15 - New class for assigning variables used for reporting purposes.
 */
public without sharing class LeadTriggerBeforeSFA extends LeadTriggerBefore {
	/** BooleanSetting__c key to enable a trigger for assigning the owner lookup. */
	public static final String ASSIGN_LEGACY_SETTING = 'Lead_Before.assignLegacy';

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerBeforeSFA(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		super(xoldMap,xnewList);
	}

	/**
	 * Set the value used for owner lookups and queue name.
	 */
	public override void assignLegacy() {
		Boolean needsQuery = false;
		Set<Id> queueIds = new Set<Id>();
		Map<Id,String> queueMap = new Map<Id,String>();
		for(Lead ld :newList) {
			if(ld.OwnerId != null && ! (''+ld.OwnerId).startsWith('005')) {
				queueMap.put(ld.ownerId,ld.Queue_Name__c);
				needsQuery = needsQuery || isInsert || oldMap.get(ld.Id).OwnerId != ld.OwnerId;
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
		for(Lead ld :newList) {
			String queueName = null;
			Id ownerId = null;
			if(ld.OwnerId != null) {
 				if((''+ld.OwnerId).startsWith('005')) {
					ownerId = ld.OwnerId;
 				}
 				else {
					queueName = queueMap.get(ld.OwnerId);
				}
			}
			if(queueName != ld.Queue_Name__c) {
				ld.Queue_Name__c = queueName;
			}
			if(ld.Owner__c != ownerId) {
				ld.Owner__c = ownerId;
			}
		}
	}

	/**
	 * This method is called from the Lead_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewList the list of new Lead objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		final LeadTriggerBeforeSFA beforeTrigger = new LeadTriggerBeforeSFA(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
	}
}