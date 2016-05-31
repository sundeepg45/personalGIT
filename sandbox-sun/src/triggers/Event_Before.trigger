trigger Event_Before on Event (before insert, before update) {
	EventTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}