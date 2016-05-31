trigger Opportunity_After on Opportunity (after insert, after update, after delete, after undelete) {
	OpportunityTriggerAfter2.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUndelete);
}