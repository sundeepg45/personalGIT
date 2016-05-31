trigger SubscriptionPartner_After on SubscriptionPartner__c (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionPartnerTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}