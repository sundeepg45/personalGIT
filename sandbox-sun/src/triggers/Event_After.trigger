trigger Event_After on Event (after delete, after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    EventTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}