/**
 * This trigger is used to default the country on Split based on
 * Country of Order on parent Opportunity
 *
 * @version 2014-11-08
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-11-08 - Created
 * 2015-02-26 - Modified (US64062)
 * 2015-03-03 - Modified (US64062 Defect)
 */
 
trigger OpportunitySplit_DefaultCountry_BI on OpportunitySplit (before Insert, before Update) {
    
   //Get list of countries in a set
    Set<String> setCountries = new Set<String>();
    
    set<Id>  setOpportunityIds = new set<Id>();
   
    //collect parent Opportunity Ids 
    for(OpportunitySplit oppSplitInst : trigger.new) {   
        setOpportunityIds.add(oppSplitInst.OpportunityId);
        setCountries.add(oppSplitInst.Country__c);
    }
    
    map<Id, String> mapOppIds_Country = new map<Id, String>();
       
    //map to store opportunity ids and country of order 
    for(Opportunity oppInst : [SELECT Country_of_Order__c 
                                FROM Opportunity 
                                WHERE Id IN: setOpportunityIds]){
                                
        mapOppIds_Country.put(oppInst.Id, oppInst.Country_of_Order__c);
        setCountries.add(oppInst.Country_of_Order__c);
    }
   
  //default values to Region, Super Region, Sub Region based on Country
    Map<String, Region__c> mapCountryAndRegion = new Map<String, Region__c>();
    
    for(Region__c regionInst : [SELECT 
                                    Region__c, Sub_Region__c, Super_Region__c, Country__c 
                                FROM 
                                    Region__c 
                                WHERE 
                                    Country__c in :setCountries]){
        
        mapCountryAndRegion.put(regionInst.Country__c, regionInst);
    }
    
    for(OpportunitySplit oppSplitInst : trigger.new){
        if(string.isBlank(oppSplitInst.Country__c) && trigger.isInsert) {
            oppSplitInst.Country__c = mapOppIds_Country.get(oppSplitInst.OpportunityId);
        }
        
        if (mapCountryAndRegion.get(oppSplitInst.Country__c) != NULL){
            oppSplitInst.Region__c = mapCountryAndRegion.get(oppSplitInst.Country__c).Region__c;
            oppSplitInst.Sub_Region__c = mapCountryAndRegion.get(oppSplitInst.Country__c).Sub_Region__c;
            oppSplitInst.Super_Region__c = mapCountryAndRegion.get(oppSplitInst.Country__c).Super_Region__c;
        } else {
            oppSplitInst.Region__c = '';
            oppSplitInst.Sub_Region__c = '';
            oppSplitInst.Super_Region__c = '';
        }       
    }
}