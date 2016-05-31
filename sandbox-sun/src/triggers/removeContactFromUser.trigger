trigger removeContactFromUser on Contact (before delete) 
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    List<User> userList = new List<User>();
    List<String> delConatctId = new List<String>();
    
    for(Integer i=0;i<trigger.old.size();i++)
    {
        delConatctId.add(trigger.old[i].id);
    }
    
    userList = [Select Id, Contact_Id__c, Associated_Contact__c from User where Contact_Id__c in : delConatctId];
    
    for(User usr : userList)
    {
        usr.Contact_Id__c = ' ';
        usr.Associated_Contact__c = ' ';
    }
    
    if(userList.size() > 0)
    {    
        update userList;
    }
}