/**
 * This class replaces all after insert and after update case triggers.  The
 * processTrigger method is invoked by the Case_After trigger and in turn invokes
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
public without sharing class CaseTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable upsertCasePriority */
	public static final String UPSERT_CASE_PRIORITY = 'Case_After.upsertCasePriority';

	/** Query the key used to keep track of the CasePriorityTotals__c instance Id */
	public static final String CASE_PRIORITY_TOTALS_ID_KEY = 'CasePriorityTotals.Id';

	private final Map<Id,Case> oldMap = new Map<Id,Case>();
	private final Map<Id,Case> newMap = new Map<Id,Case>();

	/**
	 * This our standard constructor for an after trigger.
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public CaseTriggerAfter(Map<Id,Case> xoldMap,Map<Id,Case> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * There is only one instace of CasePriorityTotals__c and this is the Id
	 * of that instance.
	 */
	public static Id getCasePriorityTotalsId() {
		StringSetting__c totalsSetting = StringSetting__c.getInstance(CASE_PRIORITY_TOTALS_ID_KEY);
		if(totalsSetting == null) {
			totalsSetting = new StringSetting__c(Name=CASE_PRIORITY_TOTALS_ID_KEY);
		}
		if(totalsSetting.Value__c == null) {
			for(CasePriorityTotals__c cpt : [
				select Id 
				from CasePriorityTotals__c 
				limit 1])
			{
				totalsSetting.Value__c=cpt.Id;
			}
			if(totalsSetting.Value__c == null) {
				CasePriorityTotals__c cpt = new CasePriorityTotals__c();
				insert cpt;
				totalsSetting.Value__c=cpt.Id;
			}
			upsert totalsSetting;
		}
		return totalsSetting.Value__c;
	}

	public void upsertCasePriority() {
		List<CasePriority__c> upsertList = new List<CasePriority__c>();
		for(Case newCase : newMap.values()) {
			if(newCase.RelativeBenefit__c > 0.0 || newCase.RelativePenalty__c > 0.0 || newCase.RelativeCost__c > 0.0) {
				Case oldCase = oldMap.get(newCase.Id);
				if( oldCase == null ||
					newCase.CasePriority__c == null ||
					newCase.RelativeBenefit__c != oldCase.RelativeBenefit__c ||
					newCase.RelativePenalty__c != oldCase.RelativePenalty__c ||
					newCase.RelativeCost__c != oldCase.RelativeCost__c ||
					newCase.IsClosed != oldCase.IsClosed )
				{
					upsertList.add(new CasePriority__c(Id=newCase.CasePriority__c,Case__c=newCase.Id,Totals__c=getCasePriorityTotalsId(),ExternalId__c=''+newCase.Id+getCasePriorityTotalsId()));
				}
			}
		}
		if(! upsertList.isEmpty()) {
			for(Database.UpsertResult result : Database.upsert(upsertList,CasePriority__c.Fields.ExternalId__c,false)) {
				CasePriority__c cp = upsertList.remove(0);
				if(!result.isSuccess()) {
					newMap.get(cp.Case__c).addError(''+result.getErrors());
				}
			}
		}
	}

	/**
	 * This method is called from the Case_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Case objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new Case objects as in Trigger.newMAp
	 */
	public static void processTrigger(Map<Id,Case> xoldMap,Map<Id,Case> xnewMap) {
		final CaseTriggerAfter afterTrigger = new CaseTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(UPSERT_CASE_PRIORITY,true)) {
			afterTrigger.upsertCasePriority();
		}
	}

}