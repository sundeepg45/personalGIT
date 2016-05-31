public class opportunitySubmittedupdateOwner{

       public void updateOwnerRole(Map<String,String> OppIdOwner, Opportunity [] opps)
        {

                Map<String,String> userroleIdMap= new Map<String,String>();
                Map<String,String> ownerroleIdMap= new Map<String,String>();
                Map<String,String> ownerLegacyRoleMap= new Map<String,String>();
                        try{
                        User[] users = [select UserRoleId,Id,Legacy_Role__c from User where Id IN:OppIdOwner.Values()];

                        for(User obj_user :users)
                                {
                                ownerroleIdMap.put(obj_user.Id,obj_user.UserRoleId);
                                ownerLegacyRoleMap.put(obj_user.Id,obj_user.Legacy_Role__c);
                                }

                UserRole [] userroles= [Select Id,Name from UserRole where Id IN :ownerroleIdMap.Values()];


                for(UserRole obj_userrole:userroles)
                                {
                              userroleIdMap.put(obj_userrole.Id,obj_userrole.Name);
                                }

                for(Opportunity obj_opp:opps)
                                {

                                String roleName;
                                String roleId=ownerroleIdMap.get(obj_opp.OwnerId);
                                String legacyRoleName=ownerLegacyRoleMap.get(obj_opp.OwnerId);
                                
                                if(roleId !=null)roleName=userroleIdMap.get(roleId);
                                System.debug(roleName);
                                if(roleName!=null)obj_opp.Owner_Role_at_Close__c =roleName;
                        		if(legacyRoleName!=null)obj_opp.Legacy_Owner_Role_at_Close_Value__c =legacyRoleName;
                                }

                        }
                                catch(Exception e){}
                }
}