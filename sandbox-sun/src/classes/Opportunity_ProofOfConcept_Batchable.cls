/**
 * This class schedules the a check for updating proof of concept status on opportunities.
 *
 * This job is scheduled with the Daily Scheduler.
 *
 * @version 2013-08-08
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-08 - Removed reference to OpportunityTriggerBefore
 * 2013-07-05 - Created
 */
global class Opportunity_ProofOfConcept_Batchable  implements Database.Batchable<SObject>, Database.Stateful {
	public static final String POC_STATUS_ACCEPTED = 'Accepted';

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @return	List<SObject> opportunities that need the POC status updated
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) {
		Date todayDate = System.today();
		return Database.getQueryLocator([
			select Id
			from Opportunity
			where POC_Status__c = :POC_STATUS_ACCEPTED
				and EngagementStartDate__c <= :todayDate 
				and LastModifiedDate < :todayDate ]);
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @param	List<SObject> opportunity objects
	 */
	global void execute(Database.BatchableContext bc, List<SObject> opportunityObjects) {
		// The trigger does the work, we'll just ignore errors
		Database.update(opportunityObjects,false);
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 */
	global void finish(Database.BatchableContext bc) {
		// really nothing to do here either, since we are ignoring errors
	}
}