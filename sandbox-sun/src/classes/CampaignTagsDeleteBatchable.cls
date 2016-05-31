/**
 * This class maintains the CampaignTag__c object that replicates the standard tagged records for Campaigns which may be used in analytics.
 * Created as part of Case # RH-00149359, October 2012 AM Release.
 *
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * @version 2012-10-01
 * 2012-10-01 - created
 */
global class CampaignTagsDeleteBatchable implements Database.Batchable<sObject>, Database.Stateful {
	
	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();
	
	/** QueryLocator used by Start method */
	global String Query;

    /**
	 * start() method implemented for Database.Batchable interface 
	 * Query all CampaignTag__c records that exist
	 *
	 * @param bc the batchable context
	 */
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
    	Query = 'SELECT Campaign_Tag_Id__c FROM CampaignTag__c'; //fetch all CampaignTag__c records
		if(System.Test.isRunningTest())
	    {
        	Query = 'SELECT Campaign_Tag_Id__c FROM CampaignTag__c LIMIT 10'; //query to be used while running tests
    	}
		return Database.getQueryLocator(Query);
    }

	/**
	 * execute() method implemented for Database.Batchable interface 
	 * Determine which CampaignTag records have been deleted and delete corresponding CampaignTag__c records
	 * 
	 * @param bc the batchable context (not used)
	 * @param list of CampaignTag__c records
	 */
    global void execute(Database.BatchableContext bc, List<CampaignTag__c> CTList)
    {
    	Map<String, CampaignTag__c> CampaignTagIds = new Map<String, CampaignTag__c>();    	
    	List<CampaignTag__c> deleteList = new List<CampaignTag__c>(); 
    	
    	for(CampaignTag__c ct : CTList)
    	{
    		CampaignTagIds.put(ct.Campaign_Tag_Id__c, ct);
    	}
    	
    	//check which CampaignTag records that have a corresponding record in CampaignTag__c still exists
    	Map<String, CampaignTag> existList = new Map<String, CampaignTag>([SELECT Id FROM CampaignTag WHERE Id IN: CampaignTagIds.keyset()]);

		//delete CampaignTag__c records that do not have a corresponding record in CampaignTag any more
		for(String s : CampaignTagIds.keyset())
		{
			if(! existList.containsKey(s))
			deleteList.add(CampaignTagIds.get(s));
		}

    	if(! deleteList.isEmpty())
        {
        	for(Database.DeleteResult dr : Database.Delete(deleteList, false))
            {
            	CampaignTag__c ct = deleteList.remove(0);
            	if(! dr.isSuccess())
            	{            			
            		errorList.add('Failed to delete CampaignTag__c.Id = ' + ct.Id + ' : ' + dr.getErrors());
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
	 */
	global void finish(AsyncApexJob job) {
		// method call to send email if required
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
			mail.setSubject('CampaignTagsDeleteBatchable failures ' + job.Status + ' ran as '+ UserInfo.getUserName());
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