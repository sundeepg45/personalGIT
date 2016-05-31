/**
 * The processTrigger method is invoked by the OpportunityTeamMember_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 *
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substitute values inside test methods.
 *
 * @version 2013-11-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-05 - Created
 */
public without sharing class OpportunityTeamMemberTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable method that requires a POC to have an engagement SA */
	public static final String REQUIRE_ENGAGEMENT_SA_SETTING = 'OppTeam_Before.requireEngagementSA';
    
    public static final String POC_REQUIRE_ENGAGEMENT_SA_ERROR = 'This Proof of Concept is required to have an Engagement SA. If you are editing the Opportunity Team directly, add the new Engagement SA before deleting this one.';
    public static final String POC_STATUS_SUBMIT_FOR_SCOPING = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_SUBMIT_FOR_SCOPING;
    public static final String POC_STATUS_SCOPING = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_SCOPING;
 	public static final String POC_STATUS_SUBMITTED = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_SUBMITTED;
    public static final String POC_STATUS_ACCEPTED = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_ACCEPTED;
    public static final String POC_STATUS_ENGAGED = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_ENGAGED;
    public static final String POC_STATUS_CLOSED = Opportunity_ProofOfConceptControllerExtn.POC_STATUS_CLOSED;
	public static final String POC_ENGAGEMENT_SA_ROLE = Opportunity_ProofOfConceptControllerExtn.POC_ENGAGEMENT_SA_ROLE;
	public static final Id pocRecordTypeId = Opportunity_ProofOfConceptControllerExtn.pocRecordTypeId;

	private final Map<Id,OpportunityTeamMember> oldMap = new Map<Id,OpportunityTeamMember>();
	private final List<OpportunityTeamMember> newList = new List<OpportunityTeamMember>();
    
	public OpportunityTeamMemberTriggerBefore(Map<Id,OpportunityTeamMember> xoldMap,List<OpportunityTeamMember> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

    /**
	 * Method that requires all POC opps of certain status values (Scoping and beyond) to have
	 *  at least one opp team member with team role Engagement SA.
	 */
    public String requireEngagementSA() {
        Set<Id> oppIds = new Set<Id>();
        Map<Id,Integer> removedCountMap = new Map<Id,Integer>();
        String errorMessage;

        //identify opportunities where an Engagement SA team member is being deleted
        if(isDelete) {
        	for(OpportunityTeamMember oldTeamMember : oldMap.values()) {
                if(oldTeamMember.TeamMemberRole == POC_ENGAGEMENT_SA_ROLE) {
                    oppIds.add(oldTeamMember.OpportunityId);
                    if(!removedCountMap.containsKey(oldTeamMember.OpportunityId)) {
                        removedCountMap.put(oldTeamMember.OpportunityId, 0);
                    }
                    removedCountMap.put(oldTeamMember.OpportunityId, removedCountMap.get(oldTeamMember.OpportunityId) + 1);
                }
            }
        }

        //identify opportunities where an Engagement SA team member is being edited to have a different role
        if(isUpdate) {
            for(OpportunityTeamMember newTeamMember : newList) {
                OpportunityTeamMember oldTeamMember = oldMap.get(newTeamMember.Id);
                if(oldTeamMember.TeamMemberRole == POC_ENGAGEMENT_SA_ROLE && newTeamMember.TeamMemberRole != POC_ENGAGEMENT_SA_ROLE) {
                    oppIds.add(oldTeamMember.OpportunityId);
					if(!removedCountMap.containsKey(oldTeamMember.OpportunityId)) {
                        removedCountMap.put(oldTeamMember.OpportunityId, 0);
                    }
                    removedCountMap.put(oldTeamMember.OpportunityId, removedCountMap.get(oldTeamMember.OpportunityId) + 1);                    
                }
            }
        }

        if(!oppIds.isEmpty()) {
            //get poc opps and their teammembers
            List<Opportunity> pocs = [
                SELECT
                    Id,
                    (SELECT Id FROM OpportunityTeamMembers WHERE TeamMemberRole = :POC_ENGAGEMENT_SA_ROLE)
                FROM Opportunity
                WHERE Id In :oppIds
                AND RecordTypeId = :pocRecordTypeId
            	AND POC_Status__c IN (:POC_STATUS_SCOPING,:POC_STATUS_SUBMITTED,:POC_STATUS_ACCEPTED,:POC_STATUS_ENGAGED,:POC_STATUS_CLOSED)];

            if(!pocs.isEmpty()) {
                Map<Id,Opportunity> pocMap = new Map<Id,Opportunity>();
                for(Opportunity poc : pocs) {
                    pocMap.put(poc.Id,poc);
                }

            	//look for cases where the last Engagement SA is being removed
                List<OpportunityTeamMember> teamMembers;
                if(isDelete) {
                    teamMembers = oldMap.values();
                }
                else {
                    teamMembers = newList;
                }
                for(OpportunityTeamMember teamMember : teamMembers) {
                    if(pocMap.containsKey(teamMember.OpportunityId)) {
                        Opportunity poc = pocMap.get(teamMember.OpportunityId);
                        Integer removedEngagementSaCount = removedCountMap.get(poc.Id);
                        Integer totalEngagementSaCount = poc.OpportunityTeamMembers.size();
                        system.debug('+++ removedEngagementSaCount: ' + removedEngagementSaCount);
                        system.debug('+++ totalEngagementSaCount: ' + totalEngagementSaCount);
                        if((totalEngagementSaCount - removedEngagementSaCount) <= 0) {
                            errorMessage = POC_REQUIRE_ENGAGEMENT_SA_ERROR;
                            teamMember.addError(errorMessage);
                        }
                    }
                }
            }
        }
        return errorMessage;
    }

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,OpportunityTeamMember> xoldMap,List<OpportunityTeamMember> xnewList) {
		final OpportunityTeamMemberTriggerBefore beforeTrigger = new OpportunityTeamMemberTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(REQUIRE_ENGAGEMENT_SA_SETTING,true)) {
			beforeTrigger.requireEngagementSA();
		}
        AbstractTrigger.processTriggerComplete();
    }
    
}