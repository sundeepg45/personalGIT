trigger SubscriptionBatch_After on SubscriptionBatch__c (after insert, after update) {
//depreciated	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
//depreciated	SubscriptionBatchTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}