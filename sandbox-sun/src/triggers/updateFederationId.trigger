trigger updateFederationId on User (after insert,after update,before insert) 
{    
    Set<Id> usrIdSet = new Set<Id>();
    Map<Id,String> oldFedIdMap = new Map<Id,String>();
    Map<Id,String> newFedIdMap = new Map<Id,String>();
        
    if (!Util.fedidUpdateInprogress){
        if(trigger.isUpdate)
        {
            for(User usr : Trigger.new)
            {
                usrIdSet.add(usr.Id);
            
                if(usr.Federation_ID__c == null || (usr.FederationIdentifier  != trigger.oldMap.get(usr.Id).FederationIdentifier && usr.Federation_ID__c != null))
                {
                    if (usr.Federation_ID__c == null && trigger.oldMap.get(usr.Id).Federation_ID__c == null){
                        oldFedIdMap.put(usr.Id,trigger.oldMap.get(usr.Id).FederationIdentifier);
                    }
                }
                else if(usr.Federation_ID__c != trigger.oldMap.get(usr.Id).Federation_ID__c)
                {
                    newFedIdMap.put(usr.Id,trigger.oldMap.get(usr.Id).Federation_ID__c);
                }
            }
            if(oldFedIdMap != null || newFedIdMap != null)
            if (System.isFuture()){
                UpdateFedId.updateId(usrIdSet,oldFedIdMap,newFedIdMap);
            } else {
                UpdateFedId.updateIdFuture(usrIdSet,oldFedIdMap,newFedIdMap);
            }
        }
        if(trigger.isInsert)
        {       
            for(User usr : Trigger.new)
            {
                usrIdSet.add(usr.Id);
                if(usr.FederationIdentifier != null && trigger.isBefore)
                {
                    System.debug('inside before');
                    usr.Federation_ID__c = usr.FederationIdentifier;
                }
                if(usr.Federation_ID__c != null && usr.FederationIdentifier == null && trigger.isAfter)
                {
                    System.debug('inside after');
                    newFedIdMap.put(usr.Id,usr.Federation_ID__c);
                }
            }
            if(newFedIdMap != null && newFedIdMap.size() > 0 && trigger.isAfter)
            {
                System.debug('inside insert new'+newFedIdMap);
                if (System.isFuture()){
                    System.debug('inside not future');
                    UpdateFedId.updateId(usrIdSet,oldFedIdMap,newFedIdMap);
                } else {
                    System.debug('inside future');
                    UpdateFedId.updateIdFuture(usrIdSet,oldFedIdMap,newFedIdMap);
                }
            }
        }
    }
}