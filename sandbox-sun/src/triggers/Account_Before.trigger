trigger Account_Before on Account (before insert, before update, before delete) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    if (trigger.isDelete)
        AccountTriggerBefore.processDeleteTrigger(Trigger.oldMap,Trigger.new);
    else
        AccountTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}