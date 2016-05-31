/*****************************************************************************************
    Name    : OpportunitySplit_BU
    Desc    : Based on Opportunity Stage restricting users of various profile to edit 
              Percentage on Revenue/Overlay split
                       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer                 Date            Description
---------------------------------------------------------------------------
    Anshul Kumar             23 SEP 2014      Created  (User Story  US55247)         
******************************************************************************************/
trigger OpportunitySplit_BU on OpportunitySplit (before Update) {
    
    //variable declaration
    map<Id, String> mapOppSplitId_OppStage = new map<Id, String>();
    set<Id> setOppIds = new set<Id>();
    map<Id, list<Id>> mapOppId_OppSplitId = new map<Id, list<Id>>();
    
    //populate the set of parent opportunities and map of opportunity ids -> list of child opportunity splits
    for(OpportunitySplit oppSplitInst : trigger.new){
    
        setOppIds.add(oppSplitInst.OpportunityId);
        if(!mapOppId_OppSplitId.containsKey(oppSplitInst.OpportunityId)){
        
            mapOppId_OppSplitId.put(oppSplitInst.OpportunityId, new list<Id>());
        }
        if(mapOppId_OppSplitId.containsKey(oppSplitInst.OpportunityId)){
        
            mapOppId_OppSplitId.get(oppSplitInst.OpportunityId).add(oppSplitInst.Id);
        }
    }
    
    //retrieve parent opportunity
    list<Opportunity> listOpp = new list<Opportunity>([SELECT StageName FROM Opportunity WHERE Id IN: setOppIds]);
    
    //populate the map of opportunity split ids -> parent opportunity stage
    for(Opportunity oppInst : listOpp){
        
        for(Id oppSplitId : mapOppId_OppSplitId.get(oppInst.Id)){
        
            mapOppSplitId_OppStage.put(oppSplitId, oppInst.StageName);
        }
    }
    
    //current user's profile name
    String currentUserProfileName = [SELECT Name FROM Profile WHERE Id =: USerInfo.getProfileId()].Name;
    
    for(OpportunitySplit oppSplitInst : trigger.new){
        
        //check if the revenue/overlay split percentage is changed by user
        if(oppSplitInst.SplitPercentage != trigger.oldMap.get(oppSplitInst.Id).SplitPercentage){
            
            //NULL check on custom setting record retrieval
            if(OpportunitySplitUserProfiles__c.getValues(currentUserProfileName) != NULL){
                
                //check whether the current user is sales user
                if(OpportunitySplitUserProfiles__c.getValues(currentUserProfileName).Sales_User__c == TRUE){
                    
                    if(mapOppSplitId_OppStage.get(oppSplitInst.Id) != NULL){
                        
                        //check if the parent opportunity is Closed Booked
                        if(mapOppSplitId_OppStage.get(oppSplitInst.Id) == system.Label.Closed_Booked_opportunity_Stage){
                            
                            //display error to user
                            oppSplitInst.SplitPercentage.addError(system.Label.Closed_Booked_stage_edit_error);
                        }
                    }
                }
            }else{
                
                //display error to user
                oppSplitInst.SplitPercentage.addError(system.Label.Non_Sales_Operations_User);
            }
        }
    }
}