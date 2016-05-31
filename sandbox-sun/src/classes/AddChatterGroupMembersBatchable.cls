/**
 * This class maintains the All Sales & Marketing chatter group and would be scheduled utilizing the Daily Scheduler.
 * This class is also supposed to replace AddChatterGroupMembers_Schedulable class.
 * Created as part of Case # RH-00189365, October 2012 AM Release.
 *
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * @version 2012-09-27
 * 2012-09-27 - created
 */
global class AddChatterGroupMembersBatchable implements Database.Batchable<SObject>, Database.Stateful {
	
	/** Name of a custom setting key. */
	global static final String GROUP_KEY = 'All Sales & Marketing';
	
	/** Variable to hold group's Id. */
	global Id groupId;
	
	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();
	
	/** QueryLocator used by Start method */
	global String Query;
	
	/**
	 * start() method implemented for Database.Batchable interface 
	 *  Get QueryLocator for all active User records which are tied to Salesforce, Salesforce Platform or Chatter Free User License Types
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		Set<String> licenseTypes = new Set<String> {'Salesforce','Salesforce Platform','Chatter Free'};
		Map<Id, UserLicense> licenses = new Map<Id, UserLicense>([SELECT Id, Name FROM UserLicense WHERE Name IN :licenseTypes]);
		Map<Id, Profile> profiles = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE UserLicenseId IN :licenses.keyset()]);
		Set<Id> profileIds = profiles.keyset(); //created as paranthesis '()' is not allowed in QueryLocator. 
		CollaborationGroup allSalesMarketing = [SELECT Id FROM CollaborationGroup WHERE Name = :GROUP_KEY LIMIT 1];
		if(allSalesMarketing != NULL){
			groupId = allSalesMarketing.Id;	
		}		
		Query = 'SELECT Id FROM User WHERE isActive = TRUE AND ProfileId IN :profileIds';
		if(System.Test.isRunningTest())
	    {
        	Query = 'SELECT Id FROM User WHERE isActive = TRUE AND ProfileId IN :profileIds ORDER BY CreatedDate DESC LIMIT 10';
    	}
		return Database.getQueryLocator(Query);
	}
	
	/**
	 * execute() method implemented for Database.Batchable interface 
	 * Called to insert new collaboration (chatter) group members
	 * 
	 * @param bc the batchable context
	 * @param list of user records meeting a certain criteria
	 */
	global void execute(Database.BatchableContext bc, List<User> userList) 
	{
		if(groupId != NULL)
		{
			Set<Id> userIdsInput = new Set<Id>(); //holds all users passed in the executing batch
			Set<Id> usersExisting = new Set<Id>(); //holds users who are already members
			
			List<CollaborationGroupMember> membersNew = new List<CollaborationGroupMember>(); //holds all Chatter Group Member records that need to be inserted
			List<CollaborationGroupMember> membersExisting = new List<CollaborationGroupMember>(); //holds all Chatter Group Member records that already exist
			
			for(User u : userList)
			{
				userIdsInput.add(u.Id);
			}
			
			membersExisting = [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :groupId AND MemberId IN :userIdsInput];
			
			for(CollaborationGroupMember cgm : membersExisting)
			{
				usersExisting.add(cgm.MemberId);
			}
						
			userIdsInput.removeAll(usersExisting);
			
			if(!userIdsInput.isEmpty())
			{
				for(Id userId : userIdsInput)
				{
					CollaborationGroupMember cgm = new CollaborationGroupMember
		  											(MemberId = userId, CollaborationGroupId = groupId, NotificationFrequency = 'W');
		  			membersNew.add(cgm);					
				}
				
				for(Database.SaveResult sr : Database.Insert(membersNew, FALSE))
	            {
	            	CollaborationGroupMember cgm = membersNew.remove(0);
	            	if(! sr.isSuccess())
	            	{            			
	            		errorList.add('Failed to insert user: '+ cgm.MemberId + ' as member of All Sales & Marketing chatter group - ' + sr.getErrors());
					}
				}								
			}
		}		
	}
		
	/**
	 * finish method implemented for Database.Batchable interface
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
			mail.setSubject('AddChatterGroupMembersBatchable failures ' + job.Status + ' ran as '+ UserInfo.getUserName());
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