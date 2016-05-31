trigger User_UnsetAccountPrimaryPartnerUser on User (after update) {
    //
    // Build a list of deactivated users
    //
    
    Set<Id> userIds = new Set<Id>();
    
    for(User user : Trigger.new) {
        if (true == user.IsActive)
            continue;
        if (true != Trigger.oldMap.get(user.Id).IsActive)
            continue;
        userIds.add(user.Id);
    }
    
    //
    // Find all accounts with that user designation
    //
    
    List<Account> accountList = [
        select PrimaryPartnerUser__c
          from Account
         where PrimaryPartnerUser__c in :userIds
    ];
    
    for(Account account : accountList)
        account.PrimaryPartnerUser__c = null;
    
    update accountList;
}