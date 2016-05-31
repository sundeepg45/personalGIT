trigger Contact_Before on Contact (before insert, before update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	ContactTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}