trigger Account_UpdateDependentTCs on Account (after update) {
    Set<Id> accountIds = new Set<Id>();
    
    for(Account account : Trigger.new) {
    	Account accountOld = Trigger.oldMap.get(account.Id);
    	
    	if (account.I_Agree_to_the_Terms_and_Conditions__c == accountOld.I_Agree_to_the_Terms_and_Conditions__c)
    	    continue;
        accountIds.add(account.Id);
    }

    if (accountIds.size() == 0)
        return;
    
    List<SFDC_Budget__c> mdfList = [
        select I_Agree_to_the_Terms_and_Conditions__c
             , Account_Master__c
          from SFDC_Budget__c
         where Account_Master__c in :accountIds
    ];

    if (mdfList.size() == 0)
        return;

    for(Account account : Trigger.new) {
        for(SFDC_Budget__c mdf : mdfList) {
        	if (account.Id != mdf.Account_Master__c)
        	    continue;
            mdf.I_Agree_to_the_Terms_and_Conditions__c = account.I_Agree_to_the_Terms_and_Conditions__c;
        }
    }
    
    update mdfList;
}