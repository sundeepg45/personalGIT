trigger OpportunityPartner_Before on OpportunityPartner__c (before delete, before insert, before update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
	OpportunityPartnerTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}