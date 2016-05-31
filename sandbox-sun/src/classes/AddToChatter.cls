global class AddToChatter {
   public static void AddUserToGroup(list<ID> Users) {      
     if(System.isFuture() || System.isBatch()){
           regularSyncCall(Users);
        } else {
                doFutureCall(Users);
     }      
    }   
    @future
    public static void doFutureCall(list<ID> Users){
        regularSyncCall(Users);
    } 
    public static void regularSyncCall(list<ID> Users){
     try {
                List<CollaborationGroupMember> cgm = new List<CollaborationGroupMember>();
                Id cgID = [Select Id FROM CollaborationGroup Where Name='EMEA Sales All' LIMIT 1].ID;            
                System.debug('+++Chatter Group+++'+cgID);
                for(ID TEMP: Users){                          
                   cgm.add(new CollaborationGroupMember(CollaborationGroupId = cgID, MemberId =TEMP));   
                }
                if(cgm !=null){
                   insert cgm;
                }
            }
            catch (QueryException qe) {
                System.debug('QueryException in AddToChatter.AddUserToGroup is :' + qe);  
            } 
            catch (Exception ex) {
                System.debug('Exception in AddToChatter.AddUserToGroup is :' + ex);
            }   
    }
}