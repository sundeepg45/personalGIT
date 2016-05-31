trigger OpportunityLineItem_Before on OpportunityLineItem (before delete, before insert, before update) {
	OpportunityLineItemTriggerBefore2.processTrigger(Trigger.oldMap,Trigger.new);
}