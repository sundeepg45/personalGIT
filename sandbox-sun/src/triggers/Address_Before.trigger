trigger Address_Before on Address__c (before delete, before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    AddressTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}