trigger UserContact on User (after insert, after update) {
    
    List<String> usrId = new List<String>();
    List<String> usrEmail = new List<String>();
    
    if(Trigger.isInsert)
    {
        for(Integer i = 0;i<trigger.new.size();i++)
        {
            if(trigger.new[i].ContactId == null && trigger.new[i].UserType == 'Standard')
            {
                usrId.add(trigger.new[i].Id);    
                usrEmail.add(trigger.new[i].Email);
            }
        }
        
        if(usrId.size() > 0 && usrEmail.size() > 0)
        {
            User_Contact.associatedContact(usrId,usrEmail); 
        }
    }
    else if(Trigger.isUpdate)
    {
        for(Integer i = 0;i<trigger.new.size();i++)
        {
            if(trigger.new[i].isActive == true && trigger.new[i].isActive != trigger.old[i].isActive && trigger.new[i].UserType == 'Standard' && trigger.new[i].ContactId == null)
            {
                usrId.add(trigger.new[i].Id);
                usrEmail.add(trigger.new[i].Email);
            }
        }
        
        if(usrId.size() > 0 && usrEmail.size() > 0)
        {
            User_Contact.associatedContact(usrId,usrEmail);
        }
    }
}