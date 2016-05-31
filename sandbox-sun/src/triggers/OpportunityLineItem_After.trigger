trigger OpportunityLineItem_After on OpportunityLineItem (after delete, after insert, after undelete, 
after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') == null || BooleanSetting__c.getInstance('DeactivateAll').Value__c != true) {
		OpportunityLineItemTriggerAfter2.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
	}
}