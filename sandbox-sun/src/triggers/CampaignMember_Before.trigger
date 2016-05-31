trigger CampaignMember_Before on CampaignMember (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    CampaignMemberTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}