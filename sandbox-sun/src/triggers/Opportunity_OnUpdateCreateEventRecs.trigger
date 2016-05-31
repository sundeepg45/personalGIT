//depreciated - 2015-11-26 - moved into OpportunityTriggerAfter2
trigger Opportunity_OnUpdateCreateEventRecs on Opportunity (after Update) {
//depreciated    
//depreciated    set<Id> setParentOppIds = new set<Id>();
//depreciated    map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
//depreciated    list<Event__c> listNewEventRecs = new list<Event__c>();
//depreciated    Event__c newEventInst = new Event__c();
//depreciated    
//depreciated    for(Opportunity oppInst : trigger.new){
//depreciated        
//depreciated        if(oppInst.CloseDate != trigger.oldMap.get(oppInst.Id).CloseDate ||
//depreciated           oppInst.StageName != trigger.oldMap.get(oppInst.Id).StageName){
//depreciated            
//depreciated            setParentOppIds.add(oppInst.Id);
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
//depreciated    setParentOppIds = new set<Id>();
//depreciated    
//depreciated    for(Opportunity oppInst : trigger.new){
//depreciated        
//depreciated        if((oppInst.CloseDate != trigger.oldMap.get(oppInst.Id).CloseDate ||
//depreciated            oppInst.StageName != trigger.oldMap.get(oppInst.Id).StageName) &&
//depreciated           mapParentOppId_Event.get(oppInst.Id) == NULL){
//depreciated            
//depreciated            setParentOppIds.add(oppInst.Id);
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