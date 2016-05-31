trigger SubscriptionLine_After on SubscriptionLine__c (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionLineTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}