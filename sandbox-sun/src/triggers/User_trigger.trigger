trigger User_trigger on User (after insert, after update) {
    Profile p = [Select Id, Name From Profile Where Name = 'Direct Sales user'];
     // Map<String,User> userMap = new Map<String,User>(); 
    Map<Id, UserRole> userRoleMap = new Map<Id, UserRole>([Select Id, Name From UserRole Where Name Like '%EMEA%']);
    if ( Trigger.isInsert  || Trigger.isUpdate) {    
        if ( Trigger.isAfter){
        List<Id> Userids = New list<Id>();           
            for (user u: Trigger.new ){ 
                if(u.ProfileId == p.id && ((userRoleMap.get(u.UserRoleId)!=null) || u.Region__c == 'EMEA')){
                Userids.add(u.id);
                System.debug('User ID added to chatter group'+ Userids);    
                }            
            } 
            AddToChatter.AddUserToGroup(Userids);             
        }
    }
}