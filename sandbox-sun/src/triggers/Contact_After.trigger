trigger Contact_After on Contact (after delete, after insert, after undelete, after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') == null || BooleanSetting__c.getInstance('DeactivateAll').Value__c != true) {
		ContactTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
	}
}