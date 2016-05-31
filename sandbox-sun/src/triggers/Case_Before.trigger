trigger Case_Before on Case (before insert, before update) {
	CaseTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}