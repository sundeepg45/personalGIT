public with sharing class Lead_DealRegistrationRedirect {
	
    public Account account;
    public boolean isNADealRegistration {get; private set; }

    public Lead_DealRegistrationRedirect(ApexPages.StandardController std)
    {
    	Id accountId = null;
		    User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
    	    accountId = me.Contact.AccountId;
        loadAccount(accountId);
    }
    
    private void loadAccount(String accountId) {

        account = [
        	select	Id
        	     ,  Name
        	     ,  Global_Region__c
         	  from	account
        	 where  Id = :accountId
       	];

		if (account.Global_Region__c == 'NA'){
			isNADealRegistration = TRUE;
			
		} 
		else { 
			isNADealRegistration = FALSE;
		}
     }


}