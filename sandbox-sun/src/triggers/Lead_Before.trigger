trigger Lead_Before on Lead (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    LeadTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}