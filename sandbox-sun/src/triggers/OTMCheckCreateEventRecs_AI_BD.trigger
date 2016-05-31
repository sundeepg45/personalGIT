/**
 * This trigger is used to create an entry in Event__c if there is an entry
 * is not present already
 *
 * @version 2014-11-26
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-10-06 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-11-26 - Updated to call OpportunityTriggerAfter2
 */
trigger OTMCheckCreateEventRecs_AI_BD on OpportunityTeamMember (after Insert, before Delete) {
    /** BooleanSetting__c key to enable the createEventRecords2 method. */
    static final String CREATE_EVENT_RECORDS_SETTING = 'OTM.CreateEventRecords';
    if(AbstractTrigger.isActive(CREATE_EVENT_RECORDS_SETTING,true)) {
//US80608(rollback DE7583)        if(Opportunity_Split_Batchable2.scheduledApex == null) {
            set<Id> setParentOppIds = new set<Id>();
            map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
            list<Event__c> listNewEventRecs = new list<Event__c>();
            Event__c newEventInst = new Event__c();
            
            //collect all the parent opportunity ids  
            if(trigger.isInsert || trigger.isUpdate){
                for(OpportunityTeamMember oppTeamMemInst : trigger.New){
                    
                    setParentOppIds.add(oppTeamMemInst.OpportunityId);
                }
            }else if(trigger.isDelete){
                for(OpportunityTeamMember oppTeamMemInst : trigger.Old){
                    
                    setParentOppIds.add(oppTeamMemInst.OpportunityId);
                }
            }
            
            //fetch all the event records, if already present, for the corresponding parent opportunity  
            list<Event__c> listEventRecs = new list<Event__c>([SELECT Opportunity__c FROM Event__c WHERE Opportunity__c IN: setParentOppIds AND Processed__c = FALSE]);
            
            setParentOppIds = new set<Id>();
            
            //create map opportunity id and corresponding event record 
            for(Event__c eventInst : listEventRecs){
                
                mapParentOppId_Event.put(eventInst.Opportunity__c, eventInst);
            }
            
            //collect all the opportunity ids for which there is no record present in Event object  
            if(trigger.isInsert || trigger.isUpdate){
                for(OpportunityTeamMember oppTeamMemInst : trigger.New){
                    
                    if(mapParentOppId_Event.get(oppTeamMemInst.OpportunityId) == NULL)
                        setParentOppIds.add(oppTeamMemInst.OpportunityId);
                }
            }else if(trigger.isDelete){
                for(OpportunityTeamMember oppTeamMemInst : trigger.Old){
                    
                    if(mapParentOppId_Event.get(oppTeamMemInst.OpportunityId) == NULL)
                        setParentOppIds.add(oppTeamMemInst.OpportunityId);
                }
            }
            
            //create new records in Event  
            for(Id parentOppId : setParentOppIds){
                
                newEventInst = new Event__c();
                newEventInst.Opportunity__c = parentOppId;
                listNewEventRecs.add(newEventInst);
            }
            
            Database.Insert(listNewEventRecs, FALSE);
//US80608(rollback DE7583)        }
//US80608(rollback DE7583)        else {
//US80608(rollback DE7583)            Set<Id> oppIds = new Set<Id>();
//US80608(rollback DE7583)            List<OpportunityTeamMember> otmList = trigger.new;
//US80608(rollback DE7583)            if(trigger.isDelete) {
//US80608(rollback DE7583)                otmList = trigger.old;
//US80608(rollback DE7583)            }
//US80608(rollback DE7583)            for(OpportunityTeamMember oppTeamMemInst : otmList) {
//US80608(rollback DE7583)                oppIds.add(oppTeamMemInst.OpportunityId);
//US80608(rollback DE7583)            }
//US80608(rollback DE7583)            OpportunityTriggerAfter2.createEventRecords(oppIds,false);
//US80608(rollback DE7583)        }
    }
}