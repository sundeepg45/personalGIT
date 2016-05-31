public with sharing class ManageSSOUsers_Controller {
   public ManageSSOUsers_Controller() {
   }
   
   public User me {
	   	get {
	   		return [
	    		  select Id,
	    		  		 FederationIdentifier,
	    		  		 Contact.AccountId,
	    		  		 IsPartnerAdmin__c	
	    		    from User
	    		   where Id = :UserInfo.getUserId()
	    		   limit 1];
	   	}
   }

   public List<User> users {
    	get {  		
    		User me = [
    		  select Id,
    		  		 ContactId,
    		  		 Contact.AccountId,
    		  		 IsPartnerAdmin__c,
    		  		 IsActive
    		    from User
    		   where Id = :UserInfo.getUserId()
    		   limit 1
    	    ];
    		
    		if (me.Contact.AccountId != null){
	    		return [
	    		  select Id
	    		       , FederationIdentifier 
	    		       , ContactId
	    		  	   , Name
	    		       , Email
	    		       , IsPartnerAdmin__c
	    		       , IsActive	
	    		    from User
	    		   where User.Contact.AccountId = :me.Contact.AccountId
	    		   limit 300
	    	    ];
    		} else {
    			return new List<User>();
    		}
    	}
    }

}