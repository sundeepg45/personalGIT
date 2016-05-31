trigger CasePriority_After on CasePriority__c (after insert, after update) {
   CasePriorityTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}