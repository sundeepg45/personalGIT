public with sharing class RequalificationHomepageCompController {
	public Account MyAccount {
        set;
        get;
    }
        
    public RequalificationHomepageCompController() {
        User u = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        if (u.Contact.AccountId != null){
	        Account a = [select Id, RequalStatus__c, RequalificationDate__C from Account where Id = :u.Contact.AccountId];
    	    MyAccount = a;
        }
    }
        
}