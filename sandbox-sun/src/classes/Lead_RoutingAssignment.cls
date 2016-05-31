/**
 * This class is used to trigger lead routing based on the LeadCronRoutingRules__c table.
 * The whole table is mapped into a single query string, so it is important to keep the table small.
 *
 * @version 2015-12-18
 * @author	Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - Depreciated - refactored into Lead_Batchable
 * 2012-08-21 - created
 */
@isTest // depreciated
private class Lead_RoutingAssignment {} // depreciated
//depreciated global class Lead_RoutingAssignment implements Database.Batchable<sObject>, Database.Stateful {
//depreciated	global static final String GLR_ERROR_QUEUE_SETTING = 'LeadRouteAssign.ErrorQueueId';
//depreciated	/** Only change for test methods. */
//depreciated	global static Boolean routeToGLRErrorQUeue = false;
//depreciated
//depreciated	/** Map of error messages by lead Id */
//depreciated	global List<String> errorList = new List<String>();
//depreciated
//depreciated	/**
//depreciated	 * Start method impl for Database.Batchable interface.  Our
//depreciated	 * current method of writing the query limits us to around 300 to 600
//depreciated	 * records maximum in the LeadCronRoutingRule__c table.  This is fine 
//depreciated	 * since there are currently only 3 entries needed.   However, should 
//depreciated	 * we even need to exceed the upper limit this code would need to be 
//depreciated	 * rewritten.  A less efficent query that hard coded every REGION/RANKING
//depreciated	 * pair with a set of owner Id's would allow a virtually unlimited table
//depreciated	 * size.  However, it is unlikely that will ever be needed.
//depreciated	 *
//depreciated	 * @param 	bc batchable contents
//depreciated	 * @return 	query locator for valid Leads
//depreciated	 *
//depreciated	 */
//depreciated	global List<Lead> start(Database.BatchableContext bc)
//depreciated	//global Database.QueryLocator start(Database.BatchableContext bc)
//depreciated	{
//depreciated		errorList.clear();
//depreciated		final DateTime now = DateTime.now();
//depreciated		String query = 'select Id from Lead where ('
//depreciated			+'PenaltyBoxExpiration__c = null or PenaltyBoxExpiration__c <= :now )';
//depreciated		Integer i=0;
//depreciated		String sep = '';
//depreciated		String condition = '';
//depreciated		for(LeadCronRoutingRule__c lcrr : [
//depreciated			select OwnerId, Super_Region__c, Lead_Ranking__c
//depreciated			from LeadCronRoutingRule__c
//depreciated			order by OwnerId ] )
//depreciated		{
//depreciated			condition += sep+'(OwnerId=\''+lcrr.OwnerId+'\' and ';
//depreciated			String nextCondition = 'Super_Region__c = null and ';
//depreciated			if(lcrr.Super_Region__c != null) {
//depreciated				nextCondition='Super_Region__c in (\''+lcrr.Super_Region__c.replaceAll('\\s','').replaceAll(';','\',\'')+'\') and ';
//depreciated			}
//depreciated			condition += nextCondition;
//depreciated			nextCondition = 'Lead_Ranking__c = null)';
//depreciated			if(lcrr.Lead_Ranking__c != null) {
//depreciated				nextCondition = 'Lead_Ranking__c in (\''+lcrr.Lead_Ranking__c.replaceAll('\\s','').replaceAll(';','\',\'')+'\'))';
//depreciated			}
//depreciated			condition += nextCondition;
//depreciated			sep = ' or ';
//depreciated			i++;
//depreciated		}
//depreciated		if(i != 0) {
//depreciated			if(i != 1) {
//depreciated				condition = '('+condition+')';
//depreciated			}
//depreciated			query += ' and '+condition;
//depreciated		}
//depreciated		System.debug('query=['+query+']');
//depreciated		//return Database.getQueryLocator(query);
//depreciated		return Database.query(query+'order by LastModifiedDate limit 2000');
//depreciated	}
//depreciated
//depreciated	/**
//depreciated	 * execute method impl for Database.Batchable interface
//depreciated	 *
//depreciated	 * @param 	bc batchable content
//depreciated	 * @param 	leads all mathing records
//depreciated	 *
//depreciated	 */
//depreciated	global void execute(Database.BatchableContext bc, List<Lead> leads) {
//depreciated		Database.DMLOptions dmo = new Database.DMLOptions();
//depreciated		dmo.assignmentRuleHeader.useDefaultRule= true;
//depreciated		for(Lead ld : leads) {
//depreciated			ld.setOptions(dmo);
//depreciated		}
//depreciated		StringSetting__c glrErrorQueue = StringSetting__c.getInstance(GLR_ERROR_QUEUE_SETTING);
//depreciated		Id glrErrorQueueId = null;
//depreciated		if(glrErrorQueue != null) {
//depreciated			glrErrorQueueId = (Id)glrErrorQueue.Value__c;
//depreciated		}
//depreciated		List<Lead> failedLeads = new List<Lead>();
//depreciated		for(Database.SaveResult sr : Database.update(leads,false)) {
//depreciated			Lead ld = leads.remove(0);
//depreciated			Boolean inactiveOwner = routeToGLRErrorQUeue;
//depreciated			if(! sr.isSuccess()) {
//depreciated				for(Database.Error e : sr.getErrors()) {
//depreciated					inactiveOwner = inactiveOwner || (''+e.getStatusCode() == 'INACTIVE_OWNER_OR_USER');
//depreciated				}
//depreciated				errorList.add(ld.Id+': '+sr.getErrors()+'\ninactiveOwner='+inactiveOwner+',glrErrorQueueId='+glrErrorQueueId);
//depreciated			}
//depreciated			if(inactiveOwner && glrErrorQueueId != null) {
//depreciated				failedLeads.add(new Lead(Id=ld.Id,OwnerId=glrErrorQueueId,Assignment_Error__c='Routed to an Inactive User'));
//depreciated			}
//depreciated		}
//depreciated		Boolean triggerValue = AbstractTrigger.booleanSettingMap.get(LeadTriggerBefore.LEAD_ROUTING_SETTING);
//depreciated		try {
//depreciated			AbstractTrigger.booleanSettingMap.put(LeadTriggerBefore.LEAD_ROUTING_SETTING,false);
//depreciated			dmo.assignmentRuleHeader.useDefaultRule = false;
//depreciated			System.debug('failedLeads='+failedLeads);
//depreciated			for(Database.SaveResult sr : Database.update(failedLeads,dmo)) {
//depreciated				Lead ld = failedLeads.remove(0);
//depreciated				if(! sr.isSuccess()) {
//depreciated					errorList.add(ld.Id+': '+sr.getErrors());
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		finally {
//depreciated			AbstractTrigger.booleanSettingMap.put(LeadTriggerBefore.LEAD_ROUTING_SETTING,triggerValue);
//depreciated		}
//depreciated	}
//depreciated
//depreciated	/**
//depreciated	 * finish method impl for Database.Batchable interface
//depreciated	 *
//depreciated	 * @param: DatabaseContext bc
//depreciated	 *
//depreciated	 */
//depreciated	global void finish(Database.BatchableContext bc) {
//depreciated		System.debug('Finish called');
//depreciated		Id jobId = null;
//depreciated		if(bc != null) {
//depreciated			jobId = bc.getJobId();
//depreciated		}
//depreciated		// query the AsyncApexJob object to retrieve the current job's information.
//depreciated		AsyncApexJob job = null;
//depreciated		for(AsyncApexJob j : [SELECT Id
//depreciated				, Status
//depreciated				, NumberOfErrors
//depreciated				, JobItemsProcessed
//depreciated				, TotalJobItems
//depreciated				, CreatedBy.Email
//depreciated			FROM AsyncApexJob 
//depreciated			WHERE Id = :jobId] )
//depreciated		{
//depreciated			job = j;
//depreciated		}
//depreciated		sendErrors(job);
//depreciated	}
//depreciated
//depreciated	/**
//depreciated	 * Called to send error message by e-mail.
//depreciated	 */
//depreciated	global Messaging.SingleEmailMessage sendErrors(AsyncApexJob job) {
//depreciated		Messaging.SingleEmailMessage mail = null;
//depreciated		// Send an email to notify us of the jobs status
//depreciated		if(job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0 || ! errorList.isEmpty()) {
//depreciated			if(job == null) {
//depreciated				job = new AsyncApexJob();
//depreciated			}
//depreciated			mail = new Messaging.SingleEmailMessage();
//depreciated			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
//depreciated			mail.setToAddresses( toAddresses );
//depreciated			mail.setSubject( 'Lead Routing Assignment failures ' + job.Status +' run as '+UserInfo.getUserName() );
//depreciated			String body = 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n';
//depreciated			for(String e : errorList) {
//depreciated				body += e+'\n';
//depreciated			}
//depreciated			mail.setPlainTextBody( body );
//depreciated			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
//depreciated		}
//depreciated		return mail;
//depreciated	}
//depreciated }