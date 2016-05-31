trigger LeadManagementHistory_LFR on LeadManagementHistory__c (before insert,before update) {
    LMH_TriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}