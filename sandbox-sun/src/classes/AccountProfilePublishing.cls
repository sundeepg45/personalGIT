global class AccountProfilePublishing {

  WebService static void AccountProfilePublishing(String accountId) {
    if (accountId == null || accountId.length() == 0) {
        return;
    }
    Account acct = [select id, Is_Partner_Published__c from Account where Id = :accountId];
    if (acct.Is_Partner_Published__c == True) {
      acct.Is_Partner_Published__c = False;
      update acct;
    }
    else {
        acct.Is_Partner_Published__c = True;
        update acct;
    }
  }
  
}