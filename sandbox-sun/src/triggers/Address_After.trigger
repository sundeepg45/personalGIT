trigger Address_After on Address__c (after delete, after insert, after undelete, 
after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') == null || BooleanSetting__c.getInstance('DeactivateAll').Value__c != true) {
		AddressTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
	}
}