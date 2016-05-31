/**
 * This class maintains the CampaignTag__c object that replicates the standard tagged records for Campaigns which may be used in analytics.
 * Created as part of Case # RH-00149359, October 2012 AM Release.
 *
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * @version 2012-09-14
 * 2012-09-14 - created
 */
global class CampaignTagsBatchable implements Database.Batchable<sObject>, Database.Stateful {

	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'CampaignTags.LastProcessed';

	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();

	/** Keep track of the lastProcessedDateTime */
	global DateTime lastProcessedDateTime = DateTime.newInstance(0L);
	
	/** QueryLocator used by Start method */
	global String Query;

	/**
	 * start() method implemented for Database.Batchable interface 
	 * Query the CampaignTag records which have been created/deleted since the batch job last ran
	 *
	 * @param bc the batchable context
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null) {
			lastProcessedDateTime = lastProcessed.Value__c;
		}

		final DateTime lpt = lastProcessedDateTime;
		lastProcessedDateTime = DateTime.Now();
		Query = 'SELECT Id, Type, Name, ItemId FROM CampaignTag WHERE Type = \'Public\' AND SystemModstamp >= :lpt ORDER BY SystemModstamp';
		if(System.Test.isRunningTest())
	    {
        	Query = 'SELECT Id, Type, Name, ItemId FROM CampaignTag WHERE Type = \'Public\' ORDER BY SystemModstamp DESC LIMIT 10';
    	}
		return Database.getQueryLocator(Query);
	}

	/**
	 * execute() method implemented for Database.Batchable interface 
	 * Called to upsert CampaignTag__c records
	 * 
	 * @param bc the batchable context (not used)
	 * @param list of standard CampaignTag records
	 */
	global void execute(Database.BatchableContext bc, List<CampaignTag> CTList) {

        List<CampaignTag__c> upsertList = new List<CampaignTag__c>(); //list of records to be upserted
              
        for(CampaignTag c : CTList)
        {
            CampaignTag__c ct = new CampaignTag__c (
                    								Name = c.Name,
                    								Campaign__c = c.ItemId,
                    								Campaign_Tag_Id__c = c.Id
                    								); //one CampaignTag__c record corresponding to each CampaignTag record
            upsertList.add(ct);            	            	
		}
        
        if(! upsertList.isEmpty())
        {
        	Schema.SObjectField f = CampaignTag__c.Fields.Campaign_Tag_Id__c; //external id field for upsert, contains Id of corresponding CampaignTag record 
        	for(Database.UpsertResult ur : Database.Upsert(upsertList, f, false))
            {
            	if(! ur.isSuccess()) {
            			if(ur.isCreated())
            			errorList.add('Failed to insert CampaignTag__c.Id = ' + ur.getId() + ' : ' + ur.getErrors());
            			else
            			errorList.add('Failed to update CampaignTag__c.Id = ' + ur.getId() + ' : ' + ur.getErrors());
					}
			}
        }    
	}

	/**
	 * finish() method implemented for Database.Batchable interface
	 *
	 * @param bc batchable context
	 */
	global void finish(Database.BatchableContext bc) {
		finish([
			SELECT
				Status,
				NumberOfErrors,
				JobItemsProcessed,
				TotalJobItems,
				CreatedBy.Email
			FROM AsyncApexJob 
			WHERE Id = :bc.getJobId()] );
	}

	/**
	 * overloaded finish method
	 *
	 * @param job the async apex job
	 *
	 */
	global void finish(AsyncApexJob job) {
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed == null) {
			lastProcessed = new DateTimeSetting__c(Name = LAST_PROCESSED_KEY);
		}
		lastProcessed.Value__c = lastProcessedDateTime;
		try {
			upsert lastProcessed;
		}
		catch(Exception e) {
			errorList.add('Failed to update DateTime Setting CampaignTags.lastProcessed - ' + e);
		}
		sendErrors(job);
	}

	/**
	 * Called to send error message by e-mail.
	 *
	 * @param job the async apex job
	 * @return the message which was sent
	 */
	global Messaging.SingleEmailMessage sendErrors(AsyncApexJob job) {
		Messaging.SingleEmailMessage mail = null;
		// Send an email to notify us of the jobs status
		if(job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0 || ! errorList.isEmpty()) {
			if(job == null) {
				job = new AsyncApexJob();
			}
			mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {'sf-error-list@redhat.com'};
			mail.setToAddresses(toAddresses);
			mail.setSubject('CampaignTagsBatchable failures ' + job.Status + ' ran as '+ UserInfo.getUserName());
			String body = 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n';
			for(String e : errorList) {
				body += e + '\n';
			}
			mail.setPlainTextBody(body);
			mail.setHtmlBody(body);
			mail.setUseSignature(false);
			mail.setSaveAsActivity(false);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
		}
		return mail;
	}
}