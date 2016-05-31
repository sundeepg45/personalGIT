trigger EBSAccount_Before on EBS_Account__c (before delete, before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    EBSAccountTriggerBefore.processTrigger(Trigger.oldMap,Trigger.new);
}