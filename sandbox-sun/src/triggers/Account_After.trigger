trigger Account_After on Account (after delete, after insert, after undelete, 
after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') == null || BooleanSetting__c.getInstance('DeactivateAll').Value__c != true) {
		AccountTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
	}
}