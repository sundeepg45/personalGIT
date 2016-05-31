trigger AccountHierarchy_AssignAccountId on AccountHierarchy__c (before insert) {
    for(AccountHierarchy__c ah : Trigger.new) {
        ah.AccountId__c = ah.Account__c;
    }
}