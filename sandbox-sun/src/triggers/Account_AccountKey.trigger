trigger Account_AccountKey on Account (before insert,before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    for(Account a : Trigger.new)
    {
        a.AccountKey__c = null;
        if(a.OracleAccountNumber__c != null)
        {
            String accountNumber = a.OracleAccountNumber__c.trim();
            if(accountNumber != '')
            {
                a.AccountKey__c = accountNumber;
            }
        }
        if(a.AccountKey__c == null && a.OraclePartyNumber__c != null)
        {
            String partyNumber = a.OraclePartyNumber__c.trim();
            if(partyNumber != '')
            {
                a.AccountKey__c = ':'+partyNumber;
            }
        }
    }
}