/**
 * This class is used to close renewal opportunities that have remained open for more than
 * 90 days, thereby making them new business opportunities
 *
 * The class is also responsible for sending email notifications to EMEA users when the renewal
 * opportunity is 30/15/1 days from being closed
 *
 * For more info see rally story US7514 or ticket RH-00078142
 *
 * @version 2012-12-17
 * @author		Bryan Bosely <bbosely@redhat.com>
 * @author		Bill Riemers <briemers@redhat.com>
 * 2013-12-11 - Ignore null close dates
 * 2011-11-17 - US14256 : Eliminated the aggregate query so we can use a query locator to scan more records.
 * 2012-06-12 - No longer send messages on success
 */
global class Renewal_AutoClosure implements Database.Batchable<sObject>, Database.Stateful
{
	/** query used to find Opportunities objects */	
	global String oppQuery = 
		'SELECT Name'
		+'	, OpportunityNumber__c'
		+'	, Owner.Email'
		+'	, Owner.EnterpriseServerUrl__c'
//		+'	, Owner.Profile.Name'
		+'	, Super_Region__c'
		+'	, CloseDate'
		+'	, (SELECT CloseDate' 
		+'		FROM OpportunityHistories'
		+'		ORDER BY CreatedDate LIMIT 1)'
		+'	FROM Opportunity'
		+'	WHERE Renewal_Opportunity__c = true'
		+'		AND isClosed = false'
		+'		AND Override_Auto_Close__c = false';

	global Set<Date> dateSet = new Set<Date>();

	//
	// calculate the dates for renewal closure
	//
	global Date dtCloseDate = null;

	//
	// query the email templates and map them according to the days offset and region.
	//
	global static Map<Integer,Map<String,EmailTemplate>> emailTemplateMaps {
		get {
			if(emailTemplateMaps == null) {
				emailTemplateMaps = new Map<Integer,Map<String,EmailTemplate>>();
				for(EmailTemplate et : [
					select Name, Body, Subject, Description
					from EmailTemplate
					where
						Folder.Type = 'Email'
						and Folder.Name = 'Alerts'
						and Name like 'Renewal Autoclose % Day %'
						and IsActive = true
					order by LastModifiedDate ] )
				{
					try {
						String s = et.Name.replaceAll('Renewal Autoclose ([0-9]+) Day .*','$1');
						Integer i = Integer.valueOf(s);
						String region = et.Name.replaceAll('Renewal Autoclose [0-9]+ Day (.*)','$1').toUpperCase();
						Map<String,EmailTemplate> emailTemplateMap = emailTemplateMaps.get(i);
						if(emailTemplateMap == null) {
							emailTemplateMap = new Map<String,EmailTemplate>();
							emailTemplateMaps.put(i,emailTemplateMap);
						}
						emailTemplateMap.put(region,et);
					}
					catch(Exception e) {
						System.debug(e);
					}
				}
			}
			return emailTemplateMaps;
		}
	}

	//
	// these are the super regions for sending notifications to
	//

	public static Set<String> superRegions {
		get {
			if(superRegions == null) {
				superRegions = new Set<String>();
				for(Map<String,EmailTemplate> m : emailTemplateMaps.values()) {
					superRegions.addAll(m.keySet());
				}
			}
			return superRegions;
		}
	}

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param 	bc batchable contents
	 * @return 	query locator for valid OpportunityHistories
	 *
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		List<Opportunity> renewalOpportunities = new List<Opportunity>();
		//
		// populate the date set we will use as a filter when looking for potential renewal opportunities
		//
		dateSet.clear();
		dtCloseDate = system.today().addDays( -91 );
		for ( Integer i : emailTemplateMaps.keySet() ) 
		{
			dateSet.add( dtCloseDate.addDays( i ) );
		}
		system.debug( '-- close date:' + dtCloseDate );
		system.debug( '-- date Set:'+ dateSet);
		return Database.getQueryLocator(oppQuery);
	}

	/**
	 * execute method impl for Database.Batchable interface
	 *
	 * @param 	bc batchable content
	 * @param 	renewals all mathing records
	 *
	 */
	global void execute(Database.BatchableContext bc, List<Opportunity> renewals) {
		//
		// query the opportunity history to get the potentials based on the dates we calculated
		//
		//
		// Find the actual matching opportunies.
		//
		List<Opportunity> expiredRenewals = new List<Opportunity>();
		Map<Integer,List<Opportunity>> notificationRenewalsMap = new Map<Integer,List<Opportunity>>();
		//
		// query the opportunities we identified as potentials
		//
		for(Opportunity renewal : renewals) {
			Date closeDate = renewal.CloseDate;
			for(OpportunityHistory oh : renewal.opportunityHistories) {
				if(oh.closeDate != null) {
					closeDate = oh.closeDate;
				}
			}
			if(closeDate != null) {
				//
				// identify which renewals have expired
				//
				if ( closeDate <= dtCloseDate ) {
					expiredRenewals.add( renewal );
				}
				else // identify which region specific renewal owners to notify
				{
					Integer i = dtCloseDate.daysBetween( closeDate );
					if ( emailTemplateMaps.containsKey( i ) ) 
					{
						List<Opportunity> oppList = notificationRenewalsMap.get( i );
						if( oppList == null ) 
						{
							oppList = new List<Opportunity>();
							notificationRenewalsMap.put( i, oppList );
						}
						oppList.add( renewal );
					}
				}
			}
		}
		system.debug( 'Expired renewal count: ' + expiredRenewals.size() );

		for ( Integer i : notificationRenewalsMap.keySet() ) {
			system.debug( 'Renewals for ' + i + ' day notification: ' + notificationRenewalsMap.get(i).size() );
		}

		//
		// close the expired renewals
		//
		closeRenewals( expiredRenewals );

		//
		// notify EMEA users
		//
		emailNotifications( notificationRenewalsMap );	
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param: DatabaseContext bc
	 * @return List<Opportunity>
	 **/
	 
	global void finish(Database.BatchableContext bc) {
		System.debug('Finish called');
		Id jobId = null;
		if(bc != null) {
			jobId = bc.getJobId();
		}
		// query the AsyncApexJob object to retrieve the current job's information.
		AsyncApexJob job = null;
		for(AsyncApexJob j : [SELECT Id
				, Status
				, NumberOfErrors
				, JobItemsProcessed
				, TotalJobItems
				, CreatedBy.Email
			FROM AsyncApexJob 
			WHERE Id = :jobId] )
		{
			job = j;
		}

		//
		// Send an email to notify me of the jobs status
		//
		if(job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0) {
			if(job == null) {
				job = new AsyncApexJob();
			}
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'Renewal Auto Closure ' + job.Status +' run as '+UserInfo.getUserName() );
			mail.setPlainTextBody( 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.' );
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
	}

	/**
	 * Bulk update opportunities.  A single failure will not fail the whole
	 * batch...
	 *
	 * @param: List<Opportunity> opportunities to close
	 */
	private static void updateOpportunities(List<Opportunity> opportunities) {
		if(!opportunities.isEmpty()) {
			for(Database.SaveResult r : Database.update(opportunities,false)) {
				Opportunity opp = opportunities.remove(0);
				for(Database.Error e : r.getErrors()) {
					System.debug('Failed to close '+opp+':'+e);
				}
			}
		}
	}	

	/**
	 * method for closing renewal opportunities
	 *
	 * @param: List<Opportunity> expiredRenewals
	 **/
	 
	private void closeRenewals(List<Opportunity> expiredRenewals)
	{	
		List<Opportunity> renewalBatches = new List<Opportunity>();
	
		//
		// close lost the renewal and set the reason code
		//
		
		for ( Opportunity renewal : expiredRenewals ) 
		{
			renewal.StageName = 'Closed Lost';
			renewal.ReasonWonLostSalesProcess__c = '90 Days Post Expiration';
			
			//
			// push the renewal updates in groups of 200 records
			//
			
			if ( renewalBatches.size() >= 200 ) 
			{
				updateOpportunities(renewalBatches);
			}
		
			renewalBatches.add( renewal );
		}
	
		//
		// push any remaining renewal updates
		//
		
		updateOpportunities(renewalBatches);
	}

	/**
	 * method for closing renewal opportunities
	 *
	 * @param: List<Opportunity> expiredRenewals
	 **/
	 
	public static String templateSubstitute(Opportunity opp,String value) {
		if(value != null) {
			value = value
				.replace('{!Opportunity.Link}',opp.Owner.EnterpriseServerUrl__c+opp.Id)
				.replace('{!Opportunity.Name}',opp.Name)
				.replace('{!Opportunity.OpportunityNumber__c}',opp.OpportunityNumber__c);
		}
		return value;
	}

	/**
	 * This method sends email notifications to EMEA users of opportunities that will
	 * be auto closed sometime in the future.  Each message is also stored in the Activity
	 * History.  The Activity History is checked to avoid duplicates.
	 *
	 * @param notificationRenewalsMap map of opportunities by number of days until autoclose
	 */
	public static void emailNotifications(Map<Integer,List<Opportunity>> notificationRenewalsMap)
	{
		// find the templates for each of the opportunities
		Map<Id,EmailTemplate> emailTemplateByOppId = new Map<Id,EmailTemplate>();
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
		for(Integer daysUntilAutoclose : notificationRenewalsMap.keySet()) {
			Map<String,EmailTemplate> emailTemplateMap = emailTemplateMaps.get(daysUntilAutoclose);
			if(emailTemplateMap != null) {
				for(Opportunity opp : notificationRenewalsMap.get(daysUntilAutoclose)) {
					String region = opp.Super_Region__c;
//					String region = opp.Owner.Profile.Name;
//					Integer i = region.indexOf(' ');
//					if(i > 0) {
//						region = region.substring(0,i).toUpperCase();
//					}
					EmailTemplate et = emailTemplateMap.get(region);
					if(et != null) {
						emailTemplateByOppId.put(opp.Id,et);
						oppMap.put(opp.Id,opp);
					}
				}
			}
		}
		final List <Messaging.SingleEmailMessage> allMail = new List<Messaging.SingleEmailMessage>();
		final List<Task> tasks = new List<Task>();
		if(! oppMap.isEmpty()) {
			Date dtToday = System.today();
			RecordType renewalTaskType = [
				SELECT Id 
				FROM RecordType 
				WHERE Name = 'Renewal Task'
					AND IsActive = true
					AND SObjectType = 'Task' ];
			// Exclude any opportunity which already has an
			// existing task.
			for(Task t : [
				select
					WhatId,
					OwnerId,
					Subject
				from Task
				where
					ActivityDate = :dtToday
					and RecordTypeId = :renewalTaskType.Id
					and Status = 'Sent'
					and Type = 'Email'
					and WhatId in : oppMap.keySet() ] )
			{
				Opportunity opp = oppMap.get(t.WhatId);
				if(opp.Owner.Id == t.OwnerId) {
					EmailTemplate et = emailTemplateByOppId.get(opp.Id);
					if(et != null) {
						String subject = templateSubstitute(opp,et.Subject);
						if(subject == t.Subject) {
							System.debug('Already mailed: '+subject);
							oppMap.remove(t.WhatId);
						}
					}
				}
			}
			if(! oppMap.isEmpty()) {
				// Prepare the lists of messages and tasks
				for(Opportunity opp : oppMap.values()) {
					EmailTemplate et = emailTemplateByOppId.get(opp.Id);
					if(et != null) {
						String body = templateSubstitute(opp,et.Body);
						String subject = templateSubstitute(opp,et.Subject);
						Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
						mail.setPlainTextBody(body);
						mail.setSubject(subject);
						mail.setToAddresses(new String []{opp.Owner.Email});
//						mail.setDescription(et.Description);
//						mail.setSaveAsActivity(true);
//						mail.setTargetObjectId(opp.Owner.Id);
//						mail.setTemplateID(et.Id);
//						mail.setWhatId(opp.Id);
						Task t = new Task(
							ActivityDate = dtToday,
							Description = et.Description,
							OwnerId = opp.Owner.Id,
							RecordTypeId = renewalTaskType.Id,
							Subject = subject,
							Status = 'Sent',
							Type = 'Email',
							WhatId = opp.Id);
						tasks.add(t);
						allMail.add(mail);
						System.debug('Subject: '+subject);
					}
				}
			}
		}
		System.debug('messages to send: '+allMail.size());
		if(! allMail.isEmpty()) {
			SavePoint pSavepoint = null;
			try {
				// We set a save point incase we failed to queue messages
				// and we are unable to remove the associated task.
				pSavepoint = Database.setSavepoint();
				// First we insert the tasks
				for(Database.Saveresult r : Database.insert(tasks,false)) {
					Task t = tasks.remove(0);
					Messaging.SingleEmailMessage mail = allMail.remove(0);
					for(Database.Error e : r.getErrors()) {
						System.debug('Failed to insert task:'+t+' :'+e);
					}
					if(r.isSuccess()) {
						tasks.add(t);
						allMail.add(mail);
					}
				}
				// Now we send a message for successful task
				if(! allMail.isEmpty()) {
					Set<Id> failedIds = new Set<Id>();
					for(Messaging.SendEmailResult r : Messaging.sendEmail(allMail,false)) {
						Task t = tasks.remove(0);
						Messaging.SingleEmailMessage mail = allMail.remove(0);
						for(Messaging.SendEmailError e : r.getErrors()) {
							System.debug('Failed send message:'+mail+'\nError Reported:'+e);
							failedIds.add(t.Id);
						}
					}
					// Finally we delete tasks for any failed messages
					if(! failedIds.isEmpty()) {
						Database.delete(new List<Id>(failedIds),true);
					}
				}
			}
			catch(Exception e) {
				// If all else fails, roll everything back
				if(pSavepoint != null) {
					Database.rollback(pSavepoint);
				}
				System.debug(e);
			}
		}
	}
}