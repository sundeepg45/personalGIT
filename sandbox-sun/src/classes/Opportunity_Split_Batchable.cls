/**
 * This class processes batches of opportunities whose opportunity split details
 * need to be rebuilt.
 *
 * @version 2015-02-07
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-02-07 - added boolean setting that suppresses per-batch error email
 * 2014-10-06 - Created
 */
global class Opportunity_Split_Batchable extends AbstractBatchable {

    private static Boolean getBooleanSetting(String key, Boolean defaultValue) {
        BooleanSetting__c b = BooleanSetting__c.getInstance(key);
        if(b != null) {
            defaultValue = b.Value__c;
        }
        return defaultValue;
    }

    /**
     * This is an external entry point for processing the staging opportunities.  This can be 
     * called by other classes or for debugging.
     *
     * @param currentOrders list of Event__c records to process.
     */
    global static void processEvents(List<Event__c> events) {
        new Opportunity_Split_Batchable().executeNoEmail(events);
    }

    /**
     * Default constructor.
     */
    global Opportunity_Split_Batchable() {
        super('Opportunity_Split_Batchable');
    }

    /**
     * Check if there is work for this job to do.
     *
     * @return false if there is no work to do.
     */
    global override Boolean hasWork() {
        return true;
    }

    /**
     * Start method impl for Database.Batchable interface.
     *
     * @param   bc batchable context
     * @return  query locator for ready Orders
     *
     */
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        errorList.clear();
        return Database.getQueryLocator([
            select
                Opportunity__c 
            from Event__c
            where Processed__c = False
            order by CreatedDate asc]);
    }

    /**
     * Execute method impl for Database.Batchable interface
     *
     * @param   bc batchable context
     * @param   events
     */
    global void execute(Database.BatchableContext bc, List<Event__c> events) {
        executeNoEmail(events);

        // email any errors that resulted in an uncaught exception
        if(!errorList.isEmpty() && getBooleanSetting('OppSplitBatch.errorEmailPerBatch', False)) {
            super.finish(lookupJob(bc));
        }
    }

    /**
     * Execute but don't send error emails
     *
     * @param   events
     */
    global void executeNoEmail(List<Event__c> events) {
        try {
            Set<Id> opportunityIds = new Set<Id>();

            for (Event__c event : events) {
                opportunityIds.add(event.Opportunity__c);
                event.Processed__c = True;
            }

            if(!Test.isRunningTest()) {
                Process_Opportnity_Split_Detail posd = new Process_Opportnity_Split_Detail();
                List<String> errors = posd.rebuildSplitDetails(opportunityIds);
                errorList.addAll(errors);
            }
        }
        catch(Exception ex) {
            errorList.add('Caught Exception: '+ex);
        }
        finally {
            update events;
        }
    }
}