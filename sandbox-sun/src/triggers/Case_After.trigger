trigger Case_After on Case (after insert,after update) {
    CaseTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}