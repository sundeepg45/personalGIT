/**
 * This class maintains the status value on Campaigns based on
 * each Campaign's Start Date and End Date values.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-05-17
 * 2013-05-17 - created
 */
global class CampaignStatus_Batchable implements Database.Batchable<SObject>, Database.Stateful {
	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();
	
	/**
	 * Query the campaign records which require a status update based on their start date or end data.
	 * Excluding campaigns with the legacy record type and those with inactive owners.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		Date currentDate = system.today();
		
		// return all campaign records that need a status update
		return Database.getQueryLocator([
			select 
				Id,
				EndDate,
				Name,
				StartDate,
				Status
			from Campaign
			where ((StartDate > :currentDate and Status != 'Planned')
				or (StartDate <= :currentDate and EndDate >= :currentDate and Status != 'In Progress')
				or (EndDate < :currentDate and Status != 'Completed'))
				and RecordTypeId <> null 
				and RecordTypeId <> '012600000004zfMAAQ'
				and Owner.IsActive = true
			order by StartDate, EndDate ]);
	}

	/**
	 * Called to execute a subset of updates.
	 * 
	 * @param bc the batchable context
	 * @param accounts the list to update
	 */
	global void execute(Database.BatchableContext bc, List<Campaign> campaigns) {
		List<Campaign> camps = campaigns.Clone();
		// touch all the campaign records that need a status update. relies on campaign 
		//   trigger to set the appropriate status value
		if(! camps.isEmpty()) {
			for(Database.SaveResult result : Database.update(camps,false)) {
				Campaign campaign = camps.remove(0);
				if(! result.isSuccess()) {
					errorList.add('Failed to update record for ' + campaign.Name + '(' + campaign.Id + ')');
				}
			}
		}
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param bc database context
	 */
	global void finish(Database.BatchableContext bc) {
		sendErrors([
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
			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'CampaignStatus_Batchable failures ' + job.Status +' run as '+UserInfo.getUserName() );
			String body = 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n';
			for(String e : errorList) {
				body += e+'\n';
			}
			mail.setPlainTextBody( body );
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
		return mail;
	}
}