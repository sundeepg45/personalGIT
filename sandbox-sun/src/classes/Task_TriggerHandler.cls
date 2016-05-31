/** Class Name      : Task_TriggerHandler
 *  Description     : Helper class which contains the business logic to run on trigger invocation on Task Object
 *  @author         : Niti Bansal <nibansal@redhat.com>
 *  @version        : 10-12-2014
 *
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                  Date            Modification ID             Description
 *   Niti Bansal                10-12-2014                                  Initial Version 
 *  ---------------------------------------------------------------------------------------------------------------------------------------
 *                                                                                    
**/
public without sharing class Task_TriggerHandler{
    
    /**
     * Method name  : processRestrictDeletion
     * Description  : Method to restrict deletion of Task by Sales Users when corresponding opportunity is in Closed Won stage.
     *                Also, to restrict deletion of Task by any user (Except Admin) when corresponding opportunity is in Closed Booked stage.
     * @param       : xoldMap - the map containing Task records
     * @return      : void
     * 
    **/    
    public static void processRestrictDeletion(Map<Id,Task> xoldMap){                    
        
        //Fetch profile of logged in user. 
        Profile profile = new Profile();
        User user = [Select Id,
                            ProfileId
                        FROM User
                        WHERE Id =: UserInfo.getUserId()];
                        
        profile = [Select Id,
                            Name
                    FROM Profile
                    WHERE Id =: user.ProfileId];
        
        //Set of Opportunity Ids                    
        Set<Id> opportunityIdSet = new Set<Id>();  
        
        //Map of Opportunity Ids=>Opportunity   
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        for(Task taskObj : xoldMap.values()){
            opportunityIdSet.add(taskObj.whatid);  
        }
        
        //Querying Opportunity Object
        opportunityMap = new Map<Id, Opportunity>([Select
                                                        Id,
                                                        StageName
                                                    FROM Opportunity
                                                    WHERE Id IN: opportunityIdSet]);
                                                            
        for(Task taskObj : xoldMap.values()){
            if(opportunityMap.containsKey(taskObj.whatid)){
               String oppStage = opportunityMap.get(taskObj.whatid).StageName;            
               //Throw an error if Sales Users tries to delete Task when its Opportunity is in Closed Won stage.
               if(oppStage == Label.Closed_Won && (profile.Name == Label.Channel_Sales || profile.Name == Label.Direct_Sales_User || profile.Name == Label.Business_Affairs_User || profile.Name == Label.Global_Services_User || profile.Name == Label.Marketing || profile.Name == Label.SEAP_Compliance_User)){
                taskObj.addError(Label.Task_Cannot_Be_Deleted);
               }
               //Throw an error if any user(except admin) tries to delete Task when its Opportunity is in Closed Booked stage.
               else if(oppStage == Label.Closed_Booked_opportunity_Stage && (profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)){
                taskObj.addError(Label.Task_Cannot_Be_Deleted);
            }
            }   
        }

    }    
}