/** Class Name      : Event_TriggerHandler
 *  Description     : Helper class which contains the business logic to run on trigger invocation on Event Object
 *  @author         : Niti Bansal <nibansal@redhat.com>
 *  @version        : 17-12-2015
 *
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                  Date            Modification ID             Description
 *   Niti Bansal                10-12-2014                                  Initial Version 
 *   Bill C Riemers             17-12-2015                                  Resolve null pointer exception
 *  ---------------------------------------------------------------------------------------------------------------------------------------
 *                                                                                    
**/
public without sharing class Event_TriggerHandler{
    
    /**
     * Method name  : processRestrictDeletion
     * Description  : Method to restrict deletion of Event by Sales Users when corresponding opportunity is in Closed Won stage.
     *                Also, to restrict deletion of Event by any user (Except Admin) when corresponding opportunity is in Closed Booked stage.
     * @param       : xoldMap - the map containing Event records
     * @return      : void
     * 
    **/     
    public static void processRestrictDeletion(Map<Id,Event> xoldMap){
        Profile profile = new EventTriggerBefore(null,null).currentUser.Profile;
        
        //Set of Opportunity Ids                    
        Set<Id> opportunityIdSet = new Set<Id>();  
        
        //Map of Opportunity Ids=>Opportunity   
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        for(Event eventObj : xoldMap.values()){
            if((eventObj.whatId+'xxx').startsWith('006')) {
                opportunityIdSet.add(eventObj.whatid);
            }  
        }
        
        //Querying Opportunity Object
        if(! opportunityIdSet.isEmpty()) {
            opportunityMap.putAll([Select
                                                        Id,
                                                        StageName
                                                    FROM Opportunity
                                                    WHERE Id IN: opportunityIdSet]);
        }
        for(Event eventObj : xoldMap.values()){
            Opportunity opp = opportunityMap.get(eventObj.whatid);
            if(opp != null) {
                String oppStage = opp.StageName;
                //Throw an error if Sales Users tries to delete Event when its Opportunity is in Closed Won stage.
                if(oppStage == Label.Closed_Won && (profile.Name == Label.Channel_Sales || profile.Name == Label.Direct_Sales_User || profile.Name == Label.Business_Affairs_User || profile.Name == Label.Global_Services_User || profile.Name == Label.Marketing || profile.Name == Label.SEAP_Compliance_User)){
                   eventObj.addError(Label.Event_Cannot_Be_Deleted);
                }
                //Throw an error if any user(except admin) tries to delete Event when its Opportunity is in Closed Booked stage.
                else if(oppStage == Label.Closed_Booked_opportunity_Stage && (profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)){
                    eventObj.addError(Label.Event_Cannot_Be_Deleted);
                }
            }
        }

    }    
}