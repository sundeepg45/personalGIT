/**
 * This class is used to convert Opportunity_Header_Staging__c records into opportunities
 * when reprocessing.
 *
 * @version 2015-02-07
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-11-04 - Use the job creation date for the last processing date
 * 2014-09-22 - Corrected test method failures
 * 2014-09-18 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2015-02-07 - added boolean setting that suppresses per-batch error email
 */
global class Order_Opportunity_Batchable extends AbstractBatchable  {
	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'Order_Opportunity.LastProcessed';
	global static final String READY_STATUS = 'Ready For Reprocessing';
	/** A limit in number of days to avoid querying too many old records. */
	global static final Integer MAX_AGE_IN_DAYS = 2;
	/** A sufficent number of minutes allow reprocessing in batch failures. */
	global static final Integer OVERLAP_TIME_IN_MINUTES = 30;

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
	 * @param currentOrders list of Opportunity_Header_Staging__c records to process.
	 */
	global static void processOrders(List<Opportunity_Header_Staging__c> currentOrders) {
		new Order_Opportunity_Batchable().executeNoEmail(currentOrders);
	}

	/**
	 * Default constructor.
	 */
	global Order_Opportunity_Batchable() {
		super('Order_Opportunity_Batchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		DateTime lastProcessedDateTime = DateTime.now().addDays(-MAX_AGE_IN_DAYS);
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null && lastProcessed.Value__c != null) {
			lastProcessedDateTime = lastProcessed.Value__c.addMinutes(-OVERLAP_TIME_IN_MINUTES);
		}
		return (0 < [
			select count()
			from Opportunity_Header_Staging__c
			where Status__c = :READY_STATUS
				and LastModifiedDate >= :lastProcessedDateTime
			limit 1]);
	}

	/**
	 * Start method impl for Database.Batchable interface.  A fairly small
	 * scope value will need to be used for the current implementation.
	 *
	 * @param 	bc batchable contents
	 * @return 	query locator for ready Orders
	 *
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTime lastProcessedDateTime = DateTime.now().addDays(-MAX_AGE_IN_DAYS);
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null && lastProcessed.Value__c != null) {
			lastProcessedDateTime = lastProcessed.Value__c.addMinutes(-OVERLAP_TIME_IN_MINUTES);
		}
		final DateTime lpt = lastProcessedDateTime;
		errorList.clear();
		return Database.getQueryLocator([
			select
				LastModifiedDate,
				Name,
				Status__c
			from Opportunity_Header_Staging__c
			where Status__c = :READY_STATUS
				and LastModifiedDate >= :lastProcessedDateTime
			order by LastModifiedDate ]);
	}

	/**
	 * execute method impl for Database.Batchable interface
	 *
	 * @param 	bc batchable content
	 * @param 	currentOrders all matching records
	 */
	global void execute(Database.BatchableContext bc, List<Opportunity_Header_Staging__c> currentOrders) {
		executeNoEmail(currentOrders);
		// email any errors that resulted in an uncaught exception
		if(!errorList.isEmpty() && getBooleanSetting('OrderOppBatch.errorEmailPerBatch', False)) {
			super.finish(lookupJob(bc));
		}
	}

	/**
	 * Called from execute without sending error emails
	 *
	 * @param 	currentOrders all matching records
	 */
	global void executeNoEmail(List<Opportunity_Header_Staging__c> currentOrders) {
		try {
			errorList.addAll(
				new Order_Opportunity_Matching().processOrders(
					Order_Opportunity_Matching.queryOrders(new Map<Id,Opportunity_Header_Staging__c>(currentOrders).keySet())));
		}
		catch(Exception ex) {
			errorList.add('Caught Exception: '+ex);
		}
	}

	/**
	 * update the last processed DateTime
	 */
	global void updateLastProcessedDateTime(DateTime lastProcessedDateTimeMax) {
		if(lastProcessedDateTimeMax != null) {
			DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
			Boolean needsInsert = (lastProcessed == null);
			if(needsInsert) {
				lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
			}
			if(needsInsert || lastProcessed.Value__c == null || lastProcessed.Value__c < lastProcessedDateTimeMax) {
				lastProcessed.Value__c = lastProcessedDateTimeMax;
				try {
					upsert lastProcessed;
				}
				catch(Exception e) {
					errorList.add('Failed to update lastProcessed '+e);
				}
			}
		}
	}

	/**
	 * finish method
	 *
	 * @param job the async apex job
	 */
	global override void finish(AsyncApexJob job) {
		DateTime lastProcessedDateTime = DateTime.now().addDays(-MAX_AGE_IN_DAYS);
		if(job != null && job.CreatedDate != null) {
			lastProcessedDateTime = job.CreatedDate;
		}
		updateLastProcessedDateTime(lastProcessedDateTime);
		super.finish(job);
	}
}