trigger Lead_After on Lead (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    LeadTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}