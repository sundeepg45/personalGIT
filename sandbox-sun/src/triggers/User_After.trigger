trigger User_After on User (after insert, after update) {
	UserTriggerAfter.processTrigger(Trigger.oldMap,Trigger.new);
}