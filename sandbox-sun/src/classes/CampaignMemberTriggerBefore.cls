/**
 * Called by the before trigger on the CampaignMember object.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-30
 * 2013-04-30 - created
 */
public with sharing class CampaignMemberTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting active lead flag */
	public static final String SET_ACTIVE_LEAD = 'CampaignMember_Before.setActiveLead';
	/** Used for testing */
	public Boolean hasErrors = false;

	private final Map<Id,CampaignMember> oldMap = new Map<Id,CampaignMember>();
	private final List<CampaignMember> newList = new List<CampaignMember>();

	public CampaignMemberTriggerBefore(Map<Id,CampaignMember> xoldMap,List<CampaignMember> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Set the value of IsLeadActive__c
	 */
	public void setActiveLead() {
		Set<Id> leadIds = new Set<Id>();
		for(CampaignMember member : newList) {
			if(member.LeadId != null) {
				leadIds.add(member.LeadId);
			}
		}

		Map<Id,Lead> leadMap = new Map<Id,Lead>();
		List<Lead> leads = [
			select
				Rejected__c
			from Lead
			where Id in :leadIds ];
		for(Lead lead : leads) {
			leadMap.put(lead.Id, lead);			
		}

		for(CampaignMember member : newList) {
			if(member.LeadId != null && leadMap.keySet().contains(member.LeadId)) {
				member.IsLeadActive__c = (leadMap.get(member.LeadId).Rejected__c == 0);
			}
		}
	}

	public static void processTrigger(Map<Id,CampaignMember> xoldMap,List<CampaignMember> xnewList) {
		final CampaignMemberTriggerBefore beforeTrigger = new CampaignMemberTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(SET_ACTIVE_LEAD,true)) {
			beforeTrigger.setActiveLead();
		}
	}
}