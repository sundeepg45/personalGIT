/**
 * This class implements the batch apex job CreditCheck_Expiration.  Use the DailyScheduler
 * class to schedule this class to run.
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-06-12
 * 2011-07-27 - Created
 * 2011-10-17 - Removed Schedulable implimentation
 * 2012-06-12 - No longer send success messages
 */
global class CreditCheck_Expiration  implements Database.Batchable<SObject>, Database.Stateful {
	//
	// calculate the dates for renewal closure
	//
	public static final String CLOSED_LOST = 'Closed Lost';
	public static final Set<String> REJECTED_CREDIT_STAGES = new Set<String> {
		'Rejected', 'Rejected - Manual', 'Closed' };
	public static final String EXPIRE_MESSAGE = 'Closed as a stale date.\n--\n';
	public static final String DAYS_WARNING_SETTING = 'CreditCheck.DaysWarning';
	public static final String MAX_DAYS_OLD_SETTING = 'CreditCheck.MaxDaysOld';
	public static Map<String,LongSetting__c> longSettingMap = new Map<String,LongSetting__c>{
		DAYS_WARNING_SETTING => LongSetting__c.getInstance(DAYS_WARNING_SETTING),
		MAX_DAYS_OLD_SETTING => LongSetting__c.getInstance(MAX_DAYS_OLD_SETTING) };
	public static DateTime expirationDateTime = DateTime.newInstanceGMT(System.Now().dateGMT(),Time.newInstance(0,0,0,0)).addDays( -getIntegerValue(MAX_DAYS_OLD_SETTING,100));
	public static DateTime newestNoticeDateTime = expirationDateTime.addDays( getIntegerValue(DAYS_WARNING_SETTING,5) );
	public static DateTime oldestNoticeDateTime = newestNoticeDateTime.addDays(-1);
	public static String query = 'select LastModifiedDate, Opportunity__c'
		+ ' from Credit__c where LastModifiedDate < :newestNoticeDateTime'
			+ ' and ( not Credit_Stage__c in :REJECTED_CREDIT_STAGES )'
			+ ' and (( LastModifiedDate < :expirationDateTime'
					+ ' and ( Opportunity__r.IsClosed = false or Opportunity__r.StageName = :CLOSED_LOST))'
				+ ' or ( LastModifiedDate >= :oldestNoticeDateTime'
					+ ' and Opportunity__r.IsClosed = false ))';

	global static Integer getIntegerValue(String key,Integer retval) {
		LongSetting__c ls = longSettingMap.get(key);
		if(ls != null && ls.Value__c != null) {
			retval = ls.Value__c.intValue();
		}
		return retval;
	}

	global List<String> errorMessages = new List<String>();

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @return	List<SObject> list of credit objects to expire
	 */
//	global List<SObject> start(Database.BatchableContext bc)
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
//		return Database.query(query);
		return Database.getQueryLocator(query);
	}

	/**
	 * Query the Enterprise Server Url from any user.
	 */
	global static String ENTERPRISE_SERVER_URL {
		get {
			if(ENTERPRISE_SERVER_URL == null) {
				User u = [select EnterpriseServerUrl__c from User limit 1];
				ENTERPRISE_SERVER_URL = u.EnterpriseServerUrl__c;
			}
			return ENTERPRISE_SERVER_URL;
		}
		set;
	}

	global static EmailTemplate REMINDER_EMAIL_TEMPLATE {
		get {
			if(REMINDER_EMAIL_TEMPLATE == null) {
				for(EmailTemplate et : [
					select Name, Body, Subject, Description
					from EmailTemplate
					where
						Folder.Type = 'Email'
						and Folder.Name = 'Alerts' 
						and Name like 'Credit Check Expiration Reminder'
						and IsActive = true
					order by LastModifiedDate ] )
				{
					REMINDER_EMAIL_TEMPLATE = et;
				}
			}
			return REMINDER_EMAIL_TEMPLATE;
		}
		set;
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @param	List<SObject> credit objects
	 */
	global void execute(Database.BatchableContext bc, List<SObject> creditObjects) {
		List<Credit__c> expiredList = new List<Credit__c>();
		Set<Id> creditIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		final Long expirationTime = expirationDateTime.getTime();
		for(SObject o : creditObjects) {
			final Credit__c credit = (Credit__c)o;
			if(credit.LastModifiedDate.getTime() < expirationTime) {
				expiredList.add(credit);
			}
			else {
				creditIds.add(credit.Id);
				oppIds.add(credit.Opportunity__c);
			}
		}
		List<Credit__c> notificationList = new List<Credit__c>();
		if(REMINDER_EMAIL_TEMPLATE != null && ! oppIds.isEmpty()) {
			for(Credit__c credit : [
				select 
					Opportunity__r.Id,
					Opportunity__r.Name, 
					Opportunity__r.OpportunityNumber__c,
					Opportunity__r.Owner.Email
				from Credit__c
				where Opportunity__c in :oppIds
					and Opportunity__r.Owner.IsActive = true
				order by CreatedDate desc ])
			{
				if(oppIds.remove(credit.Opportunity__c)) {
					if(creditIds.contains(credit.Id)) {
						notificationList.add(credit);
					}
				}
			}
			sendReminders(notificationList);
		}
		closeCreditChecks(expiredList);
	}

	/**	
	 * close expired credit checks
	 *
	 * @param	List<Credit__c> credit checks to close
	 */
	global void closeCreditChecks(List<Credit__c> credits) {
		// update the credit checks
		if(! credits.isEmpty()) {
			for(Credit__c credit : credits) {
				credit.Credit_Stage__c = 'Closed';
				credit.isFinal__c = false;
				String message = EXPIRE_MESSAGE;
				if(credit.Comments__c != null) {
					message += credit.Comments__c;
					if(message.length() > 32000) {
						message = message.substring(0,32000);
					}
				}
				credit.Comments__c = message;
			}
			for(Database.SaveResult r : Database.Update(credits)) {
				final Credit__c credit = credits.remove(0);
				for(Database.Error e : r.getErrors()) {
					final String errorMessage = ENTERPRISE_SERVER_URL+credit.Id+'\nMessage: '+e.getMessage();
					System.debug(errorMessage);
					errorMessages.add(errorMessage);
				}
			}
			System.debug('Records updated');
		}
	}

	/**	
	 * remind user of expired credit checks
	 *
	 * @param	List<Credit__c> credit checks to send reminders for
	 */
	global void sendReminders(List<Credit__c> credits) {
		if( ! credits.isEmpty()) {
			final List <Messaging.SingleEmailMessage> allMail = new List<Messaging.SingleEmailMessage>();
			EmailTemplate et = REMINDER_EMAIL_TEMPLATE;
			for(Credit__c credit : credits) {
				String body = templateSubstitute(credit,et.Body);
				String subject = templateSubstitute(credit,et.Subject);
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setPlainTextBody(body);
				mail.setSubject(subject);
				mail.setToAddresses(new String []{credit.Opportunity__r.Owner.Email});
				allMail.add(mail);
				System.debug('Subject: '+subject);
			}
			for(Messaging.SendEmailResult r : Messaging.sendEmail(allMail,false)) {
				Messaging.SingleEmailMessage mail = allMail.remove(0);
				Credit__c credit = credits.remove(0);
				for(Messaging.SendEmailError e : r.getErrors()) {
					final String errorMessage = ENTERPRISE_SERVER_URL+credit.Id+'\nFailed to send:'+mail+'\nCause: '+e;
					System.debug(errorMessage);
					errorMessages.add(errorMessage);
				}
			}
		}
	}

	public static String templateSubstitute(Credit__c credit,String value) {
		if(value != null) {
			Opportunity opp = credit.Opportunity__r;
			value = value
				.replace('{!Opportunity.Link}',ENTERPRISE_SERVER_URL+opp.Id)
				.replace('{!Opportunity.Name}',opp.Name)
				.replace('{!Opportunity.OpportunityNumber__c}',opp.OpportunityNumber__c);
		}
		return value;
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 */
	global void finish(Database.BatchableContext bc) {
		System.debug('Finish called');
		AsyncApexJob job = null;
		// query the AsyncApexJob object to retrieve the current job's information.
		try {
			job = [
				select
					Status,
					NumberOfErrors,
					JobItemsProcessed,
					TotalJobItems,
					CreatedBy.Email
				from AsyncApexJob 
				where Id = :bc.getJobId() ];
		}
		catch(NullPointerException e) {
			// this error is expected in our test method
			errorMessages.add('Failed to load job: '+e);
		}

		if(! errorMessages.isEmpty() || job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0) {
			if(job == null) {
				job = new AsyncApexJob();
			}
			// Send an email to notify me of the jobs status
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'Credit Check Expiration ' + job.Status +' ran as '+UserInfo.getUserName());
			String body = 'The batch Apex job run as processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n\n';
			for(String e : errorMessages) {
				body += e + '\n\n';
			}
			mail.setPlainTextBody(body);
			System.debug('sending message '+mail);
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
	}
}