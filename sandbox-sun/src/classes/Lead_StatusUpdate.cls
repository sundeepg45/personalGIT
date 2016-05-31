/**
 * This class schedules the a check for updating statuses on leads.
 *
 * This job is scheduled with the Daily Scheduler.
 *
 * @version 2015-12-18
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - Depreciated - Merged with Lead_RoutingAssignment into Lead_Batchable
 * 2012-06-12 - Nolonger send success messages
 * 2011-09-23 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-04 - Including leads that just left the penalty box in the status update
 */
@isTest //depreciated
private class Lead_StatusUpdate {} //depreciated
//depreciated global class Lead_StatusUpdate implements Database.Batchable<SObject>, Database.Stateful {
//depreciated	global static String query = 'select Id, PenaltyBoxExpiration__c'
//depreciated		+ '	from Lead'
//depreciated		+ '	where (Next_Status_Update__c <= :now or PenaltyBoxExpiration__c <= :now)'
//depreciated		+ '	and IsConverted <> true'
//depreciated		+ '	order by Next_Status_Update__c desc';
//depreciated	global List<String> errorMessages = new List<String>();
//depreciated	global Integer recordCount = 0;
//depreciated	global Integer failureCount = 0;
//depreciated	global DateTime now = DateTime.now();
//depreciated
//depreciated	/**
//depreciated	 * start method impl for Database.Batchable interface
//depreciated	 *
//depreciated	 * @param	Database.BatchableContext bc
//depreciated	 * @return	List<SObject> list of credit objects to expire
//depreciated	 */
//depreciated	global Database.QueryLocator start(Database.BatchableContext bc)
//depreciated	{
//depreciated		System.debug('query='+query);
//depreciated		return Database.getQueryLocator(query);
//depreciated	}
//depreciated
//depreciated	/**	
//depreciated	 * execute method impl for Database.Batchable interface
//depreciated	 *
//depreciated	 * @param	Database.BatchableContext bc
//depreciated	 * @param	List<SObject> credit objects
//depreciated	 */
//depreciated	global void execute(Database.BatchableContext bc, List<SObject> leadObjects) {
//depreciated		List<Lead> leads = new List<Lead>();
//depreciated		for(SObject o : leadObjects) {
//depreciated			Lead ld = (Lead)o;
//depreciated			ld.Next_Status_Update__c = null;
//depreciated			if (ld.PenaltyBoxExpiration__c <= now) {
//depreciated				ld.PenaltyBoxExpiration__c = null;
//depreciated			}
//depreciated			leads.add(ld);
//depreciated		}
//depreciated		for(Database.SaveResult s : Database.update(leads,false)) {
//depreciated			Lead ld = leads.remove(0);
//depreciated			recordCount++;
//depreciated			if(! s.isSuccess()) {
//depreciated				failureCount++;
//depreciated				for(Database.Error e : s.getErrors()) {
//depreciated					errorMessages.add('Failed to update '+ld+': '+e);
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * finish method impl for Database.Batchable interface
//depreciated	 *
//depreciated	 * @param	Database.BatchableContext bc
//depreciated	 */
//depreciated	global void finish(Database.BatchableContext bc) {
//depreciated		System.debug('Finish called');
//depreciated		Id jobId = null;
//depreciated		if(bc != null) {
//depreciated			jobId = bc.getJobId();
//depreciated		}
//depreciated		// query the AsyncApexJob object to retrieve the current job's information.
//depreciated		AsyncApexJob job = null;
//depreciated		for(AsyncApexJob j : [
//depreciated			select
//depreciated				Status,
//depreciated				NumberOfErrors,
//depreciated				JobItemsProcessed,
//depreciated				TotalJobItems,
//depreciated				CreatedBy.Email
//depreciated			from AsyncApexJob 
//depreciated			where Id = :jobId ] )
//depreciated		{
//depreciated			job = j;
//depreciated		}
//depreciated		if(! errorMessages.isEmpty() || job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0) {
//depreciated			if(job == null) {
//depreciated				job = new AsyncApexJob();
//depreciated			}
//depreciated			// Send an email to notify me of the jobs status
//depreciated			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//depreciated			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
//depreciated			mail.setToAddresses( toAddresses );
//depreciated			mail.setSubject( 'Lead Status Update ' + job.Status +' processed '+recordCount+'records with '+failureCount+' failures running as '+UserInfo.getUserName());
//depreciated			String body = 'The batch Apex job run as processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n\n';
//depreciated			for(String e : errorMessages) {
//depreciated				body += e + '\n\n';
//depreciated			}
//depreciated			mail.setPlainTextBody(body);
//depreciated			System.debug('sending message '+mail);
//depreciated			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
//depreciated		}
//depreciated	}
//depreciated }