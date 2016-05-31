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
 * @version 2012-03-05
 * 2011-09-01 - Created
 * 2011-12-08 - Modified insertLead method to by-pass non-GLM leads
 * 2012-03-05 - Split into a subclass
 * Bryan Bosely <bbosely@redhat.com>
 * 2011-09-17 - Added method to determine lead sub-region
 * 2011-11-?? - Added insertLead trigger method
 * 
 */
public virtual without sharing class LeadTriggerBeforePartner extends LeadTriggerBefore {
	/** BooleanSetting__c key to enable the leadPartnerUpdate trigger method. */
	public static final String LEAD_PARTNER_UPDATE_SETTING = 'Lead_Before.leadPartnerUpdate';
	/** BooleanSetting__c key to enable the partnerOptIn trigger method. */
	public static final String PARTNER_OPT_IN_SETTING = 'Lead_Before.partnerOptIn';
	/** Set of all the BooleanSetting__c keys used. */
	public static final Set<String> booleanSettingKeys = new Set<String> {
		LEAD_PARTNER_UPDATE_SETTING,
		PARTNER_OPT_IN_SETTING };

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerBeforePartner(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		super(xoldMap,xnewList);
	}

	/**
	 * This replacement for the LeadPartner_Update trigger calls the
	 * LeadPartnerUpdate class.
	 */
	public void leadPartnerUpdate() {
		new LeadPartnerUpdate().updateLeadPartnerWorked(newList);
	}

	/**
	 * This replacement to the LeadPartnerOptIn tigger will set the 
	 * Partner_Opt_In_Last_Modified_By__c and Partner_Opt_In_Last_Modified_Date__c 
	 * the first time the Partner_Opt_In__c value is changed.
	 */
	public void partnerOptIn() {
		if(isUpdate) {
			List<Lead> leads = new List<Lead>();
			DateTime n = null;
			Id userId = null;
			for(Lead lead : newList) {
				Lead oldLead = oldMap.get(lead.Id);
				// This looks like a bug to me.  The variable is called last modified, but this logic really makes it a
				// first modified value.  For now, we will leave it as we don't know if the code is wrong, or the variable name
				// is misleading.
				if(lead.Partner_Opt_In__c != oldLead.Partner_Opt_In__c && lead.Partner_Opt_In_Last_Modified_By__c == null) {
					if(n == null) {
						n = DateTime.now();
					}
					if(userId == null) {
						userId = UserInfo.getUserId();
					}
					lead.Partner_Opt_In_Last_Modified_By__c = userId;
					lead.Partner_Opt_In_Last_Modified_Date__c = n;
				}
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
		final LeadTriggerBeforePartner beforeTrigger = new LeadTriggerBeforePartner(xoldMap,xnewList);
		if(LeadTriggerBefore.booleanSettingMap.get(LEAD_PARTNER_UPDATE_SETTING) != false) {
			beforeTrigger.leadPartnerUpdate();
		}
		if(LeadTriggerBefore.booleanSettingMap.get(PARTNER_OPT_IN_SETTING) != false) {
			beforeTrigger.partnerOptIn();
		}
	}
}