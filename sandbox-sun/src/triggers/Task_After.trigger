trigger Task_After on Task (after delete, after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    TaskTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}