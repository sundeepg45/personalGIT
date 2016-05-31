trigger EBSAccount_After on EBS_Account__c (after delete, after insert, after undelete, after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') == null || BooleanSetting__c.getInstance('DeactivateAll').Value__c != true) {
		EBSAccountTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
	}
}