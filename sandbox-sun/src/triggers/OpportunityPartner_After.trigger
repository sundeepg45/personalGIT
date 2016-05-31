trigger OpportunityPartner_After on OpportunityPartner__c (after delete, after insert, after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
	OpportunityPartnerTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}