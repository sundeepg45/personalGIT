/**
 * The processTrigger method is invoked by the OpportunityTeamMember_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 *
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substitute values inside test methods.
 *
 * @version 2013-12-09
 * Bill Riemers <briemers@redhat.com>
 * 2013-12-09 - Reorder methods
 * 2013-11-14 - Created by refactoring OpportTeamMemberTriggerAfter
 */
public without sharing class OpportunityTeamMemberCloneTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting of POC status */
	public static final String SET_POC_STATUS_SETTING = 'OppTeamClone_After.setPOCStatus';
	/** BooleanSetting__c key to enable setting of engagement SA */
	public static final String SET_ENGAGEMENT_SA_SETTING = 'OppTeamClone_After.setEngagementSA';

	public static final String POC_STATUS_SCOPING = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_SCOPING;
	public static final String POC_STATUS_SUBMIT_FOR_SCOPING = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_SUBMIT_FOR_SCOPING;
	public static final String POC_ENGAGEMENT_SA_ROLE = Opportunity_ProofOfConceptControllerExtn.POC_ENGAGEMENT_SA_ROLE;
	public static final Id pocRecordTypeId = Opportunity_ProofOfConceptControllerExtn.pocRecordTypeId;  

	/** Normally populated as a copy of Trigger.oldMap */
	public final Map<Id,OpportunityTeamMemberClone__c> oldMap = new Map<Id,OpportunityTeamMemberClone__c>();
	/** Normally populated as Trigger.new */
	public final Map<Id,OpportunityTeamMemberClone__c> newMap = new Map<Id,OpportunityTeamMemberClone__c>();
	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;   

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public OpportunityTeamMemberCloneTriggerAfter(Map<Id,OpportunityTeamMemberClone__c> xoldMap,Map<Id,OpportunityTeamMemberClone__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/** This is to allow us to pass in query values from other triggers. */
	public static Map<Id,Opportunity> staticOpportunityMap = null;

	/**
	 * Query the selected list of opportunity ids.  The results are limited to
	 * just POC's.
	 */
	public static Map<Id,Opportunity> queryOpportunities(Set<Id> oppIds) {
		return new Map<Id,Opportunity>([
			select
				RecordTypeId,
				Engagement_SA__c,
				POC_Status__c,
				(select 
					CreatedDate,
					OpportunityId,
					TeamMemberRole,
					UserId
					from OpportunityTeamMembers)	
			from Opportunity
			where Id in :oppIds 
				and RecordType.Name = 'Proof of Concept' ]);
	}

	public Map<Id,Opportunity> opportunityMap {
		get {
			if(opportunityMap == null) {
				opportunityMap = new Map<Id,Opportunity>();
				List<OpportunityTeamMemberClone__c> teamMembers = newMap.values();
				Set<Id> oppIds = new Set<Id>();
				if(isDelete) {
					teamMembers = oldMap.values();
				}
				for(OpportunityTeamMemberClone__c teamMember : teamMembers) {
					oppIds.add(teamMember.Opportunity__c);
				}
				if(staticOpportunityMap != null) {
					opportunityMap.putAll(staticOpportunityMap);
					opportunityMap.keySet().retainAll(oppIds);
					oppIds.removeAll(opportunityMap.keySet());
				}
				if(! oppIds.isEmpty()) {
					opportunityMap.putAll( queryOpportunities( oppIds ) );
				}
			}
			return opportunityMap;
		}
		set;
	}

	/**
	 * Update the POC status as a result of opp team changes
	 */
	public void setPOCStatus() {
		if(! hasErrors) {
			Set<Id> opportunityIds = new Set<Id>();
			for(OpportunityTeamMemberClone__c teamMember : newMap.values()) {
				if(teamMember.TeamMemberRole__c == POC_ENGAGEMENT_SA_ROLE
					&& (isInsert || oldMap.get(teamMember.Id).TeamMemberRole__c != POC_ENGAGEMENT_SA_ROLE)) {
					opportunityIds.add(teamMember.Opportunity__c);
				}
			}

			if(!opportunityIds.IsEmpty()) {
				Set<Id> pocIds = new Set<Id>();
				for(Opportunity opportunity : opportunityMap.values()) {
					if(opportunityIds.contains(opportunity.Id) && opportunity.RecordTypeId == pocRecordTypeId && opportunity.POC_Status__c == POC_STATUS_SUBMIT_FOR_SCOPING) {
						pocIds.add(opportunity.Id);
					}
				}
				if(!pocIds.IsEmpty()) {
					//find pending scoping assignment processes
					List<ProcessInstance> assignmentProcesses = [
						SELECT
							Id,
							TargetObjectId,
							(SELECT Id, ActorId FROM Workitems)
						FROM ProcessInstance
						WHERE Status = 'Pending'
							AND TargetObjectId IN :pocIds];
					//approve them
					for(ProcessInstance assignmentProcess : assignmentProcesses) {
						boolean approved = false;
						for(ProcessInstanceWorkitem workItem : assignmentProcess.Workitems) {
							if(workItem.ActorId == UserInfo.getUserId()) {
								// create a ProcessWorkitemRequest
								Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
								approveRequest.setComments('Scoping assignment completed');
								approveRequest.setAction('Approve');
								approveRequest.setWorkitemId(workItem.Id);
								// complete the approval 
								Approval.ProcessResult result =  Approval.process(approveRequest);
								approved = true;
							}
						}
						//if we found pending approval steps but none of them were for the current user, approve on behalf of
						// first approver. useful when an administrator assigns the Engagement SA instead of one of the assigned approvers.
						if(!assignmentProcess.Workitems.isEmpty() && !approved) {
							Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
							approveRequest.setComments('Scoping assignment completed by proxy or administrator');
							approveRequest.setAction('Approve');
							approveRequest.setWorkitemId(assignmentProcess.Workitems[0].Id);
							// complete the approval 
							Approval.ProcessResult result =  Approval.process(approveRequest);
						}
					}
				}
			}
		}
	}

	private Id suggestEngagementSA(List<OpportunityTeamMember> teamMembers) {
		OpportunityTeamMember engagementSA = null;
		DateTime teamMemberCreatedDate = null;
		for(OpportunityTeamMember teamMember : teamMembers) {
			if(teamMember.TeamMemberRole == POC_ENGAGEMENT_SA_ROLE 
				&& (teamMemberCreatedDate == null || teamMember.CreatedDate < teamMemberCreatedDate))
			{
				engagementSA = teamMember;
				teamMemberCreatedDate = teamMember.CreatedDate;
			}
		}
		Id retval = null;
		if(engagementSA != null) {
			system.debug('suggested engagement SA:' + engagementSA);
			retval = engagementSA.UserId;
		}
		return retval;
	}

	static void addTeamMember(Map<Id,List<OpportunityTeamMemberClone__c>> teamMembersMap,OpportunityTeamMemberClone__c teamMember) {
		List<OpportunityTeamMemberClone__c> teamMembers = teamMembersMap.get(teamMember.Opportunity__c);
		if(teamMembers == null) {
			teamMembers = new List<OpportunityTeamMemberClone__c>();
			teamMembersMap.put(teamMember.Opportunity__c,teamMembers);
		}
		teamMembers.add(teamMember);
	}

	/**
	 * Reflects changes to the Engagement SA on the opp team back to the POC record.
	 *
	 */
	public void setEngagementSA() {
		if(! hasErrors) {
			Boolean triggerValue = booleanSettingMap.get(SET_ENGAGEMENT_SA_SETTING);
			Boolean triggerValue2 = booleanSettingMap.get(OpportunityTriggerAfter2.SET_ENGAGEMENT_SA_SETTING);
			try {
				// turn off set engagement sa setting trigger to avoid recursion
				booleanSettingMap.put(SET_ENGAGEMENT_SA_SETTING,false);
				booleanSettingMap.put(OpportunityTriggerAfter2.SET_ENGAGEMENT_SA_SETTING,false);
				Map<Id,List<OpportunityTeamMemberClone__c>> removedEngagementSAs = new Map<Id,List<OpportunityTeamMemberClone__c>>();
				Map<Id,List<OpportunityTeamMemberClone__c>> addedEngagementSAs = new Map<Id,List<OpportunityTeamMemberClone__c>>();
				Map<Id,List<OpportunityTeamMemberClone__c>> teamMembersByOppId = new Map<Id,List<OpportunityTeamMemberClone__c>>();

				List<OpportunityTeamMemberClone__c> values = newMap.values();
				if(isDelete) {
					values = oldMap.values();
				}
				for(OpportunityTeamMemberClone__c xteamMember : values) {
					OpportunityTeamMemberClone__c newTeamMember = newMap.get(xteamMember.Id);
					OpportunityTeamMemberClone__c oldTeamMember = oldMap.get(xteamMember.Id);
					//find updated Engagement SAs and add them to either the added list or removed list
					if(oldTeamMember == null || newTeamMember == null || newTeamMember.TeamMemberRole__c != oldTeamMember.TeamMemberRole__c) {
						if(newTeamMember != null && newTeamMember.TeamMemberRole__c == POC_ENGAGEMENT_SA_ROLE) {
							addTeamMember(addedEngagementSAs,newTeamMember);
							addTeamMember(teamMembersByOppId,newTeamMember);
						}
						else if(oldTeamMember != null && oldTeamMember.TeamMemberRole__c == POC_ENGAGEMENT_SA_ROLE) {
							addTeamMember(removedEngagementSAs,oldTeamMember);
							addTeamMember(teamMembersByOppId,oldTeamMember);
						}
					}
				}
				if(! teamMembersByOppId.isEmpty()) {
					removedEngagementSAs.keySet().removeAll(addedEngagementSAs.keySet());
					List<Opportunity> updatedpocs = new List<Opportunity>();
					//get list of potentially impacted POCs and opp team members
					for(Opportunity poc : opportunityMap.values()) {
						if(poc.RecordTypeId == pocRecordTypeId) {
							//if one of the removed SAs is the engagement SA on the poc record try to replace them on the poc
							if(poc.Engagement_SA__c != null) {
								List<OpportunityTeamMemberClone__c> teamMembers = removedEngagementSAs.get(poc.Id);
								if(teamMembers != null) {
									for(OpportunityTeamMemberClone__c teamMember : teamMembers ) {
										if(poc.Engagement_SA__c == teamMember.User__c) {
											//attempt replace the removed SA with the suggested replacement (null if there are no other engagement SAs on the team)
											poc.Engagement_SA__c = suggestEngagementSA(poc.OpportunityTeamMembers);
											updatedpocs.add(poc);
										}
									}
								}
							}
							//if a SA was added to the team and there isn't an engagement SA on the poc make them it 
							else {
								List<OpportunityTeamMemberClone__c> teamMembers = addedEngagementSAs.get(poc.Id);
								if(teamMembers != null) {
									poc.Engagement_SA__c = teamMembers[0].User__c;
									updatedpocs.add(poc);
								}
							}
						}
					}
					if(!updatedpocs.isEmpty()) {
						for(Database.SaveResult r : Database.update(updatedpocs,false)) {
							Opportunity opp = updatedpocs.remove(0);
							if(! r.isSuccess()) {
								for(OpportunityTeamMemberClone__c teamMember : teamMembersByOppId.get(opp.Id)) {
									teamMember.addError('Failed to update opportunity: '+r.getErrors());
									hasErrors = true;
								}
							}
						}
					}
				}
			}
			finally {
				booleanSettingMap.put(SET_ENGAGEMENT_SA_SETTING,triggerValue);
				booleanSettingMap.put(OpportunityTriggerAfter2.SET_ENGAGEMENT_SA_SETTING,triggerValue2);
			}
		}
	}

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,OpportunityTeamMemberClone__c> xoldMap,Map<Id,OpportunityTeamMemberClone__c> xnewMap) {
		final OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(SET_ENGAGEMENT_SA_SETTING,true)) {
			afterTrigger.setEngagementSA();
		}
		if(AbstractTrigger.isActive(SET_POC_STATUS_SETTING,true)) {
			afterTrigger.setPOCStatus();
		}
		AbstractTrigger.processTriggerComplete();
	}

}