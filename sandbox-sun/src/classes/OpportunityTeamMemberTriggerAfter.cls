/**
 * The processTrigger method is invoked by the OpportunityTeamMember_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 *
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substitute values inside test methods.
 *
 * @version 2013-11-03
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-03 - Implemented scoping assignment approval process
 * 2013-10-01 - Implemented POC Engagement SA trigger
 * 2013-10-01 - Moved from trigger to trigger class
 * 2013-06-17 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-11-14 - Added syncClones method and moved processing into that method
 */
public without sharing class OpportunityTeamMemberTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable syncClones method */
	public static final String SYNC_CLONES_SETTING = 'OppTeam_After.syncClones';

	/** Normally populated as a copy of Trigger.oldMap */
	public final Map<Id,OpportunityTeamMember> oldMap = new Map<Id,OpportunityTeamMember>();
	/** Normally populated as Trigger.new */
	public final Map<Id,OpportunityTeamMember> newMap = new Map<Id,OpportunityTeamMember>();
	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;	

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public OpportunityTeamMemberTriggerAfter(Map<Id,OpportunityTeamMember> xoldMap,Map<Id,OpportunityTeamMember> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Syncronize the OpportunityTeamMemberClone__c records
	 */
	public void syncClones() {
		if(isDelete) {
			Set<String> teamMemberIds = new Set<String>();
			for(Id teamMemberId : oldMap.keySet()) {
				teamMemberIds.add(''+teamMemberId);
			}
			List<OpportunityTeamMemberClone__c> clones = [
				select
					OpportunityTeamMemberId__c
				from OpportunityTeamMemberClone__c
				where OpportunityTeamMemberId__c in :teamMemberIds ];
			if(! clones.isEmpty()) {
				for(Database.DeleteResult r : Database.delete(clones,false)) {
					OpportunityTeamMemberClone__c teamMemberClone = clones.remove(0);
					if(! r.isSuccess()) {
						OpportunityTeamMember teamMember = oldMap.get((Id)teamMemberClone.OpportunityTeamMemberId__c);
						teamMember.addError('Failed to delete clone: '+r.getErrors());
					}
				}
			}
		}
		else {
			Set<Id> oppIds = new Set<Id>();
			for(OpportunityTeamMember teamMember : newMap.values()) {
				oppIds.add(teamMember.OpportunityId);
			}
			Map<Id,Opportunity> oppMap = OpportunityTeamMemberCloneTriggerAfter.queryOpportunities(oppIds);
			if(! oppMap.isEmpty() ) {
				List<OpportunityTeamMemberClone__c> clones = new List<OpportunityTeamMemberClone__c>();
				for(OpportunityTeamMember teamMember : newMap.values()) {
					if ( oppMap.containsKey(teamMember.OpportunityId) ) {
						clones.add( new OpportunityTeamMemberClone__c(
							Opportunity__c = teamMember.OpportunityId,
							OpportunityAccessLevel__c = teamMember.OpportunityAccessLevel,
							OpportunityTeamMemberId__c = teamMember.Id,
							TeamMemberRole__c = teamMember.TeamMemberRole,
							User__c = teamMember.UserId) );
					}
				}
				try {
					// avoid the duplicate query
					OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = oppMap;
					for(Database.UpsertResult r : Database.upsert(clones,OpportunityTeamMemberClone__c.Fields.OpportunityTeamMemberId__c,false)) {
						OpportunityTeamMemberClone__c teamMemberClone = clones.remove(0);
						if(! r.isSuccess()) {
							OpportunityTeamMember teamMember = newMap.get((Id)teamMemberClone.OpportunityTeamMemberId__c);
							teamMember.addError('Failed to upsert clone: '+r.getErrors());
						}
					}
				}
				finally {
					// do not retain query results
					OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = null;
				}
			}
		}
	}

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,OpportunityTeamMember> xoldMap,Map<Id,OpportunityTeamMember> xnewMap) {
		final OpportunityTeamMemberTriggerAfter afterTrigger = new OpportunityTeamMemberTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(SYNC_CLONES_SETTING,true)) {
			afterTrigger.syncClones();
		}
		AbstractTrigger.processTriggerComplete();
	}
}