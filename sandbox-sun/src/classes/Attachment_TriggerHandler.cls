/** Class Name      : Attachment_TriggerHandler
 *  Description     : Helper class which contains the business logic to run on trigger invocation on Attachment Object
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
public without sharing class Attachment_TriggerHandler{

    /**
     * Method name  : processRestrictDeletion
     * Description  : Method to restrict deletion of Attachment by Sales Users when corresponding opportunity is in Closed Won stage.
     *                Also, to restrict deletion of Attachment by any user (Except Admin) when corresponding opportunity is in Closed Booked stage.
     * @param       : xoldMap - the map containing Attachment records
     * @return      : void
     *
    **/
    public static void processRestrictDeletion(Map<Id,Attachment> xoldMap){

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

        for(Attachment obj : xoldMap.values()){
            opportunityIdSet.add(obj.ParentId);
        }

        //Querying Opportunity Object
        opportunityMap = new Map<Id, Opportunity>([Select
                                                        Id,
                                                        StageName
                                                    FROM Opportunity
                                                    WHERE Id IN: opportunityIdSet]);
        for(Attachment obj : xoldMap.values()){
            String sid = obj.ParentId;
            if (!sid.startsWith('006')) continue;

            String oppStage = opportunityMap.get(obj.ParentId).StageName;
            //Throw an error if Sales Users tries to delete Attachment when its Opportunity is in Closed Won stage.
            if( oppStage == Label.Closed_Won && (profile.Name == Label.Channel_Sales || profile.Name == Label.Direct_Sales_User || profile.Name == Label.Business_Affairs_User || profile.Name == Label.Global_Services_User || profile.Name == Label.Marketing || profile.Name == Label.SEAP_Compliance_User)){
               obj.addError(Label.Attachment_Cannot_Be_Deleted);
            }
            //Throw an error if any user(except admin) tries to delete Attachment when its Opportunity is in Closed Booked stage.
            else if(oppStage == Label.Closed_Booked_opportunity_Stage && (profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)){
                obj.addError(Label.Attachment_Cannot_Be_Deleted);
            }
        }
    }
}