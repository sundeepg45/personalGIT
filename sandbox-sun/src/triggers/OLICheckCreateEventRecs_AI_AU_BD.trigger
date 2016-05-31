/**
 * This trigger is used to create an entry in Event__c if there is an entry
 * is not present already
 *
 * @version 2015-11-26
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-10-06 - Created
 * Bill C Riemers
 * 2015-11-26 - Depreciated - moved into OpportunityLineItemTriggerAfter2
 */
trigger OLICheckCreateEventRecs_AI_AU_BD on OpportunityLineItem (after Insert, after Update, before Delete) {
//depreciated    
//depreciated    set<Id> setParentOppIds = new set<Id>();
//depreciated    map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
//depreciated    list<Event__c> listNewEventRecs = new list<Event__c>();
//depreciated    Event__c newEventInst = new Event__c();
//depreciated    
//depreciated   //collect all the parent opportunity ids
//depreciated    if(trigger.isInsert || trigger.isUpdate){
//depreciated        for(OpportunityLineItem oppLineItmInst : trigger.New){
//depreciated            
//depreciated            setParentOppIds.add(oppLineItmInst.OpportunityId);
//depreciated        }
//depreciated    }else if(trigger.isDelete){
//depreciated        for(OpportunityLineItem oppLineItmInst : trigger.Old){
//depreciated            
//depreciated            setParentOppIds.add(oppLineItmInst.OpportunityId);
//depreciated        }
//depreciated    }
//depreciated    
//depreciated   //fetch all the event records, if already present, for the corresponding parent opportunity
//depreciated    list<Event__c> listEventRecs = new list<Event__c>([SELECT Opportunity__c FROM Event__c WHERE Opportunity__c IN: setParentOppIds AND Processed__c = FALSE]);
//depreciated    
//depreciated    setParentOppIds = new set<Id>();
//depreciated    
//depreciated   //create map opportunity id and corresponding event record 
//depreciated    for(Event__c eventInst : listEventRecs){
//depreciated        
//depreciated        mapParentOppId_Event.put(eventInst.Opportunity__c, eventInst);
//depreciated    }
//depreciated   
//depreciated   //collect all the opportunity ids for which there is no record present in Event object 
//depreciated    if(trigger.isInsert || trigger.isUpdate){
//depreciated        for(OpportunityLineItem oppLineItmInst : trigger.New){
//depreciated            
//depreciated            if(mapParentOppId_Event.get(oppLineItmInst.OpportunityId) == NULL)
//depreciated                setParentOppIds.add(oppLineItmInst.OpportunityId);
//depreciated        }
//depreciated    }else if(trigger.isDelete){
//depreciated        for(OpportunityLineItem oppLineItmInst : trigger.Old){
//depreciated            
//depreciated            if(mapParentOppId_Event.get(oppLineItmInst.OpportunityId) == NULL)
//depreciated                setParentOppIds.add(oppLineItmInst.OpportunityId);
//depreciated        }
//depreciated    }
//depreciated   
//depreciated   //create new records in Event
//depreciated    for(Id parentOppId : setParentOppIds){
//depreciated        
//depreciated        newEventInst = new Event__c();
//depreciated        newEventInst.Opportunity__c = parentOppId;
//depreciated        listNewEventRecs.add(newEventInst);
//depreciated    }
//depreciated    
//depreciated    Database.Insert(listNewEventRecs, FALSE);
}