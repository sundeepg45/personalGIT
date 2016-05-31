trigger Subscription_After on Subscription__c (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}