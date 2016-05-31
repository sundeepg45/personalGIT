trigger CasePriority_Before on CasePriority__c (before insert, before update) {
    CasePriorityTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}