/**
 * Before trigger on OpportunityTeamMember
 *
 * @version 2013-11-05
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-05 - Created
 */
trigger OpportunityTeamMember_Before on OpportunityTeamMember (before insert, before update, before delete) {
	OpportunityTeamMemberTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}