/**
 * This trigger is used to create an entry in Event__c if there is an entry
 * is not present already
 *
 * @version 2015-11-26
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-10-06 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2016-01-06 - Revert event creation
 * 2015-11-26 - Updated to call OpportunityTriggerAfter2
 */
trigger OSCheckCreateEventRecs_AI_AU_BD on OpportunitySplit (after Insert, after Update, before Delete) {
    /** BooleanSetting__c key to enable the createEventRecords2 method. */
    static final String CREATE_EVENT_RECORDS_SETTING = 'OppSplit.CreateEventRecords';
    if(AbstractTrigger.isActive(CREATE_EVENT_RECORDS_SETTING,true)) {
//US80608(rollback DE7583)        if(Opportunity_Split_Batchable2.scheduledApex == null) {
            set<Id> setParentOppIds = new set<Id>();
            map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
            list<Event__c> listNewEventRecs = new list<Event__c>();
            Event__c newEventInst = new Event__c();
            //collect all the parent opportunity ids 
            if(trigger.isInsert || trigger.isUpdate){
                for(OpportunitySplit oppSlitInst : trigger.New){
                    
                    setParentOppIds.add(oppSlitInst.OpportunityId);
                }
            }else if(trigger.isDelete){
                for(OpportunitySplit oppSlitInst : trigger.Old){
                    
                    setParentOppIds.add(oppSlitInst.OpportunityId);
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
                for(OpportunitySplit oppSlitInst : trigger.New){
                    
                    if(mapParentOppId_Event.get(oppSlitInst.OpportunityId) == NULL)
                        setParentOppIds.add(oppSlitInst.OpportunityId);
                }
            }else if(trigger.isDelete){
                for(OpportunitySplit oppSlitInst : trigger.Old){
                    
                    if(mapParentOppId_Event.get(oppSlitInst.OpportunityId) == NULL)
                        setParentOppIds.add(oppSlitInst.OpportunityId);
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
//US80608(rollback DE7583)            List<OpportunitySplit> oppSplits = trigger.new;
//US80608(rollback DE7583)            if( trigger.isDelete) {
//US80608(rollback DE7583)                oppSplits = trigger.old;
//US80608(rollback DE7583)            }
//US80608(rollback DE7583)            //collect all the parent opportunity ids 
//US80608(rollback DE7583)            for(OpportunitySplit oppSlitInst : oppSplits){
//US80608(rollback DE7583)                oppIds.add(oppSlitInst.OpportunityId);
//US80608(rollback DE7583)            }
//US80608(rollback DE7583)            OpportunityTriggerAfter2.createEventRecords(oppIds,false);
//US80608(rollback DE7583)        }
    }
}