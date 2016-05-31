trigger DuplicateLog_Before on DuplicateLog__c (before delete, before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    DuplicateLogTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}