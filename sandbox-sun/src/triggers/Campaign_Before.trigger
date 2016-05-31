trigger Campaign_Before on Campaign (before delete, before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    CampaignTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}