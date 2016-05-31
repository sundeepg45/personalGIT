/**
 * This class replaces all after insert and after update case comment triggers.  The
 * processTrigger method is invoked by the CaseComment_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-12-06
 */
public with sharing class CaseCommentTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable upsertData */
	public static final String UPSERT_DATA = 'CaseComment_After.upsertData';

	private final Map<Id,CaseComment> oldMap = new Map<Id,CaseComment>();
	private final Map<Id,CaseComment> newMap = new Map<Id,CaseComment>();

	/**
	 * This our standard constructor for an after trigger.
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public CaseCommentTriggerAfter(Map<Id,CaseComment> xoldMap,Map<Id,CaseComment> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Called to insert and update the CaseCommentData__c object foreach CaseComment.
	 */
	public void upsertData() {
		List<CaseCommentData__c> ccdList = new List<CaseCommentData__c>();
		DateTime n = DateTime.now();
		for(CaseComment cc : newMap.values()) {
			ccdList.add(new CaseCommentData__c(Case__c=cc.ParentId,CaseCommentId__c=cc.Id,CreatedBy__c=cc.CreatedById,LastModifiedDate__c=n));
		}
		if(! ccdList.isEmpty()) {
			for(Database.UpsertResult r : Database.upsert(ccdList,CaseCommentData__c.Fields.CaseCommentId__c,false)) {
				CaseCommentData__c ccd = ccdList.remove(0);
				if(! r.isSuccess()) {
					Trigger.newMap.get(ccd.Case__c).addError('Failed to update comment: '+r.getErrors());
				}
			}
		}
	}

	/**
	 * This method is called from the CaseComment_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous CaseComment objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new CaseComment objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,CaseComment> xoldMap,Map<Id,CaseComment> xnewMap) {
		final CaseCommentTriggerAfter afterTrigger = new CaseCommentTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(UPSERT_DATA,true)) {
			afterTrigger.upsertData();
		}
	}

}