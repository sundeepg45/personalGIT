trigger Campaign_After on Campaign (after delete, after insert, after update, after undelete) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    CampaignTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap,Trigger.isUnDelete);
}