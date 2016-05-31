/** Class Name      : ProcessBookedOpportunityProducts
 *  Description     : Helper class which contains the business logic to run on trigger invocation on OpportunityLineItem
 *  @author         : Sagar Mehta <smehta@redhat.com>
 *  @version        : 09-12-2014
 *
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                  Date            Modification ID             Description
 *   Sagar Mehta                09-12-2014                                  Initial Version 
 *  ---------------------------------------------------------------------------------------------------------------------------------------
 *                                                                                    
**/

public without sharing class ProcessBookedOpportunityProducts{
    
    /**
     * Method name  : processOpportunityProducts
     * Description  : Method to validate that Opportunity Products are not deleted by Sales Users when corresponding opportunity is in Closed Won stage.
     *                Also, to validate that Opportunity Products are not deleted by any user (Except Admin) when corresponding opportunity is in Closed Booked stage.
     * @param       : xoldMap - the map containing OpportunityLineItem records
     * @return      : void
     * 
    **/
    public static void processOpportunityProducts(Map<Id,OpportunityLineItem> xoldMap){
        
        //Fetch profile of logged in user.       
        Profile profile = new Profile();
        User user = [Select 
                            Id,
                            ProfileId
                        FROM User
                        WHERE Id =: UserInfo.getUserId()];
                        
        profile = [Select 
                        Id,
                        Name
                    FROM Profile
                    WHERE Id =: user.ProfileId];
        
        //Set of Opportunity Ids        
        Set<Id> opportunityIdSet = new Set<Id>(); 
        
        //Map of Opportunity Ids=>Opportunity 
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        for(OpportunityLineItem li : xoldMap.values()){
            opportunityIdSet.add(li.OpportunityId);  
        }
        
        //Querying Opportunity Object
        opportunityMap = new Map<Id, Opportunity>([Select
                                                        Id,
                                                        StageName
                                                    FROM Opportunity
                                                    WHERE Id IN: opportunityIdSet]);
                
        for(OpportunityLineItem li : xoldMap.values()){
            String oppStage = opportunityMap.get(li.OpportunityId).StageName;
            
            system.debug('Profile in class-------->'+profile.name);
            system.debug('oppStage in class-------->'+oppStage);
            //Throw an error if Sales Users tries to delete Opportunity Product when its Opportunity is in Closed Won stage.
            if(oppStage == Label.Closed_Won  && (profile.Name == Label.Channel_Sales || profile.Name == Label.Direct_Sales_User || profile.Name == Label.Business_Affairs_User || profile.Name == Label.Global_Services_User || profile.Name == Label.Marketing || profile.Name == Label.SEAP_Compliance_User)){
               li.addError(Label.OppProducts_Cannot_Be_Deleted);
            }
            //Throw an error if any user(except admin) tries to delete Opportunity Product when its Opportunity is in Closed Booked stage.       
            else if(oppStage == Label.Closed_Booked_opportunity_Stage && (profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)){
               li.addError(Label.OppProducts_Cannot_Be_Deleted);
            }
        }
    }    
}