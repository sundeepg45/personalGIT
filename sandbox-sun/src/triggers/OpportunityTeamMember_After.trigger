/**
 * After trigger on OpportunityTeamMember
 *
 * @version 2013-10-01
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-10-01 - Migrated functionality to OpportunityTeamMemberTriggerAfter
 * 2013-06-17 - Created
 */
 trigger OpportunityTeamMember_After on OpportunityTeamMember (after insert, after update, after delete) {
	OpportunityTeamMemberTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}