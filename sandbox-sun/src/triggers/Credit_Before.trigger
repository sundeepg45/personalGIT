trigger Credit_Before on Credit__c (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    CreditTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}