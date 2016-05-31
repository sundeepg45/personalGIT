trigger SubscriptionPartner_Before on SubscriptionPartner__c (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionPartnerTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}