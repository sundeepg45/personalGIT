/**
 * This trigger kicks off the batch job that runs validation and matching logic 
 *  on Opportunity Staging records created by the Order Loader tool.
 *
 * @version 2015-07-10
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-07-10 - Now using OrderLoaderBatchable contructor that supports querying staging records by a unique batch id
 * 2015-02-25 - Created
 */
trigger OrderLoaderTrigger on Order_Loader_Batch__c (after insert) {
    Integer count = 0;
    for(Order_Loader_Batch__c batch : Trigger.new) {
        if(count == 0) {
            OrderLoaderBatchable orderLoader = new OrderLoaderBatchable(batch.Batch_ID__c);
            Id batchProcessId = Database.executeBatch(orderLoader,5);
        }
        else {
            batch.addError('This object does not support batch inserts. Please insert only one record at a time.');
        }
        count ++;
    }
}