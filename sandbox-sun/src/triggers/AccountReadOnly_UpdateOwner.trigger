trigger AccountReadOnly_UpdateOwner on AccountReadOnly__c (after update) {
    List<AccountReadOnly__c> accountReadOnlyList = new List<AccountReadOnly__c>();
    for(AccountReadOnly__c accountReadOnly : Trigger.new) {
        if(accountReadOnly.OwnerId != accountReadOnly.OwnerId__c) {
            AccountReadOnly__c a = accountReadOnly.clone();
            a.OwnerId = accountReadOnly.OwnerId__c;
            accountReadOnlyList.add(a);
        }
    }
    if(! accountReadOnlyList.isEmpty()) {
        Database.update(accountReadOnlyList,false);
    }
}