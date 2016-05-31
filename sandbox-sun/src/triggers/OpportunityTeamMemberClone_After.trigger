trigger OpportunityTeamMemberClone_After on OpportunityTeamMemberClone__c (after insert, after update, after delete) {
    OpportunityTeamMemberCloneTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}