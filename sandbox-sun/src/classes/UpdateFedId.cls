global class UpdateFedId {
    @future
    public static void updateIdFuture(Set<Id> userIds, Map<Id,String> oldFedIdMap, Map<Id,String> newFedIdMap)
    {
    	updateId(userIds, oldFedIdMap, newFedIdMap);
	}

    public static void updateId(Set<Id> userIds, Map<Id,String> oldFedIdMap, Map<Id,String> newFedIdMap)
    {
        List<User> userList = new List<User>();

        userList = [Select Id, FederationIdentifier, Federation_ID__c from User where Id in : userIds];
        for(User usr : userList)
        {
            if(usr.Federation_ID__c == null || (usr.FederationIdentifier  != oldFedIdMap.get(usr.Id) && usr.Federation_ID__c != null && oldFedIdMap.get(usr.Id) != null))
            {
            	if (usr.Federation_ID__c == null && !oldFedIdMap.containsKey(usr.Id)){
            		// Federation_ID__c was intentionally cleared out, clear out FederationIdentifier
            		usr.FederationIdentifier = null;
            	} else {
            		// Federation_ID__c is unitiated, populate it with the field from fed id
                	usr.Federation_ID__c = usr.FederationIdentifier;
            	}
            }
            else if((usr.Federation_ID__c != newFedIdMap.get(usr.Id) || usr.FederationIdentifier == null) && usr.Federation_ID__c != null)
            {
                usr.FederationIdentifier = usr.Federation_ID__c;
            }
        }
        Util.fedidUpdateInprogress = true;
        if (!System.Test.isRunningTest())
        {
            update userList;
        }
        Util.fedidUpdateInprogress = false;
    }
}