/**
 * This trigger is used to create an entry in Event__c if there is an entry
 * is not present already
 *
 * @version 2014-11-08
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-11-08 - Created
 */
trigger Opportunity_UpdateCountryOppSplit_AU on Opportunity (after Update) {
//depreciated	    
//depreciated	  //fetch all the child split records  
//depreciated	    list<OpportunitySplit> listChildSplits = new list<OpportunitySplit>([SELECT Country__c, OpportunityId
//depreciated	                                                                            FROM OpportunitySplit
//depreciated	                                                                            WHERE OpportunityId IN: trigger.newMap.keySet()]);
//depreciated	    
//depreciated	    map<Id, list<OpportunitySplit>> mapOppId_childSplits = new map<Id, list<OpportunitySplit>>();
//depreciated	  
//depreciated	  //populate the map of parent Opportunities and Split records  
//depreciated	    for(OpportunitySplit oppSplitInst : listChildSplits){
//depreciated	        if(!mapOppId_childSplits.containsKey(oppSplitInst.OpportunityId))
//depreciated	            mapOppId_childSplits.put(oppSplitInst.OpportunityId, new list<OpportunitySplit>());
//depreciated	        if(mapOppId_childSplits.containsKey(oppSplitInst.OpportunityId))
//depreciated	            mapOppId_childSplits.get(oppSplitInst.OpportunityId).add(oppSplitInst);
//depreciated	    }
//depreciated	    
//depreciated	    listChildSplits = new list<OpportunitySplit>();
//depreciated	  
//depreciated	  //check if the Country in split is not manually changes, change it to new value in Country of Order  
//depreciated	    for(Opportunity oppInst : trigger.new){
//depreciated	        if(mapOppId_childSplits.get(oppInst.Id) != NULL){
//depreciated	            for(OpportunitySplit oppSplitInst : mapOppId_childSplits.get(oppInst.Id)){
//depreciated	                if(oppSplitInst.Country__c == trigger.oldMap.get(oppInst.Id).Country_of_Order__c
//depreciated	                    && trigger.oldMap.get(oppInst.Id).Country_of_Order__c != oppInst.Country_of_Order__c){
//depreciated	                    oppSplitInst.Country__c = oppInst.Country_of_Order__c;
//depreciated	                    listChildSplits.add(oppSplitInst);
//depreciated	                }
//depreciated	            }
//depreciated	        }
//depreciated	    }
//depreciated	    
//depreciated	  //update split records
//depreciated	    if(!listChildSplits.isEmpty())
//depreciated	        database.update(listChildSplits, FALSE);
//depreciated	    
}