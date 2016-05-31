trigger EmailMessage_After on EmailMessage (after insert) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    EmailMessageTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,false);
}