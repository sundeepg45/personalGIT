trigger User_Before on User (before insert, before update) {
	UserTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}