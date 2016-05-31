trigger Subscription_Before on Subscription__c (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}