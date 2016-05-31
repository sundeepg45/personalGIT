trigger SubscriptionLine_Before on SubscriptionLine__c (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    SubscriptionLineTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}