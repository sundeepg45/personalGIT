/**
 * This batch job processes inbound events from the bus. Intended to be scheduled using
 * custom DailyScheduler feature using the Scheduled Apex custom setting. If you add this
 * to the schedule, make sure InboundEvent.trigger is DISABLED first.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2014-07-15
 * 2014-07-15 - created
 */
global class InboundEvent_Batchable implements Database.Batchable<SObject> {

    /**
     * Query the campaign records which require a status update based on their start date or end data.
     * Excluding campaigns with the legacy record type and those with inactive owners.
     */
    global Database.QueryLocator start(Database.BatchableContext bc)
    {      
        // return all campaign records that need a status update
        return Database.getQueryLocator([
            SELECT 
                Id,
                Event_Type__c,
                Message__c,
                Operation__c,
                Retries__c,
                Status__c
            FROM Inbound_Event__c
            WHERE Status__c IN ('New','Retried')
            ORDER BY Name]);
    }

    global void execute(Database.BatchableContext bc, List<Inbound_Event__c> inboundEvents) {
        List<Inbound_Event__c> deleteEvents = new List<Inbound_Event__c>();

        // the downstream code is not bulkified - it was built to handle one
        //  record at a time. we'll need to keep batch size low to avoid limits.
        for(Inbound_Event__c inboundEvent : inboundEvents) {
            try {
                // pass event message to service broker
                InboundServiceBroker.processMessage(
                    inboundEvent.Id,
                    inboundEvent.Event_Type__c,
                    inboundEvent.Message__c,
                    inboundEvent.Operation__c,
                    inboundEvent.Retries__c,
                    inboundEvent.Status__c);
            }
            catch(Exception ex) {
                // if there's an error queue an error message. this should be rare - the service broker will handle and queue most errors.
                OutboundService.queueErrorMessage(inboundEvent.Message__c, ex.getTypeName(), ex.getMessage());
            }
            finally {
                deleteEvents.add(new Inbound_Event__c(Id = inboundEvent.Id));
            }
        }

        delete deleteEvents;
    }

    global void finish(Database.BatchableContext bc) {}    
}