trigger Task_Before on Task (before delete, before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    TaskTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}