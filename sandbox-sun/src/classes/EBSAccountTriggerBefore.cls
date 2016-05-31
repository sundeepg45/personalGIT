/**
 * This class replaces all before insert and before update ebsAccount triggers.  The
 * processTrigger method is invoked by the EBSAccount_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-08-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-08-27 - Created
 */
public without sharing class EBSAccountTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable inactivateDuplicates method. */
	public static final String INACTIVATE_DUPLICATES_SETTING = 'EBSAccount_Before.inactivateDuplicates';

	private final Map<Id,EBS_Account__c> oldMap = new Map<Id,EBS_Account__c>();
	private final List<EBS_Account__c> newList = new List<EBS_Account__c>();

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewList the mapping of new values
	 */
	public EBSAccountTriggerBefore(Map<Id,EBS_Account__c> xoldMap,List<EBS_Account__c> xnewList) {
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
			for(EBS_Account__c ebsAccount : newList) {
				if(ebsAccount.MasterRecord__c != null && ebsAccount.Status__c != 'Inactive') {
					ebsAccount.Status__c = 'Inactive';
				}
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,EBS_Account__c> xoldMap,List<EBS_Account__c> xnewList) {
		final EBSAccountTriggerBefore beforeTrigger = new EBSAccountTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(INACTIVATE_DUPLICATES_SETTING,true)) {
			beforeTrigger.inactivateDuplicates();
		}
		AbstractTrigger.processTriggerComplete();
	}
}