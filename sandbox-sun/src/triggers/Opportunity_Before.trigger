trigger Opportunity_Before on Opportunity (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    OpportunityTriggerBefore2.processTrigger(Trigger.oldMap,Trigger.new);
}