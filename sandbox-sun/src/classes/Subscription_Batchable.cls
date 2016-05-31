/**
 * This class is used to convert ready subscription into opportunities.
 *
 * @version 2015-03-16
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-03-16 - Include stack trace when reporting an exception
 * 2015-03-15 - Handle delete and limit the maximum age to one day
 * 2015-02-19 - Changed age in minutes to a value that can be overridden by test methods
 * 2015-02-04 - Only process records which where last modified more than 1 minute ago to help avoid locking errors
 * 2015-01-15 - Added processErrorMap method
 * 2014-04-21 - Update to use AbstractBatchable
 * 2012-08-21 - created
 */
global class Subscription_Batchable extends AbstractBatchable {
	global static Integer MIN_AGE_IN_MINUTES = 1;
	global static Integer MAX_AGE_IN_MINUTES = 1440;
	/**
	 * Default constructor.
	 */
	global Subscription_Batchable() {
		super('Subscription_Batchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		final DateTime recentTime = DateTime.now().addMinutes(-MIN_AGE_IN_MINUTES);
		final DateTime oldestTime = DateTime.now().addMinutes(-MAX_AGE_IN_MINUTES);
		return (0 < [
			select count()
			from Subscription__c
			where LastModifiedDate >= :oldestTime
				and LastModifiedDate <= :recentTime
				and ( Status__c = :SubscriptionControllerExtension.READY_STATUS
					or (Status__c = :SubscriptionControllerExtension.READY_FOR_SSI_STATUS
						and (SuperRegion__c = 'NA' or SuperRegion__c = 'LATAM' or Opportunity__c != null) )
					or (Status__c = :SubscriptionControllerExtension.ERROR_STATUS
						and Opportunity__c != null) )
			limit 1]);
	}

	/**
	 * Start method impl for Database.Batchable interface.  A fairly small
	 * scope value will need to be used for the current implementation.
	 *
	 * @param 	bc batchable contents
	 * @return 	query locator for ready subscriptions
	 *
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		errorList.clear();
		final DateTime recentTime = DateTime.now().addMinutes(-MIN_AGE_IN_MINUTES);
		final DateTime oldestTime = DateTime.now().addMinutes(-MAX_AGE_IN_MINUTES);
		// attempt to do opportunity deletes in advance
		Database.delete ( [
			select Id
			from Opportunity
			where Id in (
				select Opportunity__c
				from Subscription__c
				where LastModifiedDate >= :oldestTime 
					and LastModifiedDate <= :recentTime
					and Opportunity__c != null
					and ( Status__c = :SubscriptionControllerExtension.READY_STATUS
						or Status__c = :SubscriptionControllerExtension.READY_FOR_SSI_STATUS
						or Status__c = :SubscriptionControllerExtension.ERROR_STATUS ) )
			limit 200 FOR UPDATE ], false);
		// query ready opportunities and ones that need a delete
		return Database.getQueryLocator([
			select Id, Opportunity__c, Status__c
			from Subscription__c
			where LastModifiedDate >= :oldestTime
				and LastModifiedDate <= :recentTime
				and ( Status__c = :SubscriptionControllerExtension.READY_STATUS
					or (Status__c = :SubscriptionControllerExtension.READY_FOR_SSI_STATUS
						and (SuperRegion__c = 'NA' or SuperRegion__c = 'LATAM' or Opportunity__c != null) )
					or (Status__c = :SubscriptionControllerExtension.ERROR_STATUS
						and Opportunity__c != null) )
			order by LastModifiedDate ]);
	}

	/**
	 * execute method impl for Database.Batchable interface
	 *
	 * @param 	bc batchable content
	 * @param 	leads all mathing records
	 *
	 */
	global void execute(Database.BatchableContext bc, List<Subscription__c> subscriptions) {
		//Database.update(subscriptions,false);
		try {
			List<Opportunity> opps = new List<Opportunity>();
			for(Subscription__c s : subscriptions) {
				if(s.Opportunity__c != null) {
					opps.add(new Opportunity(Id=s.Opportunity__c));
				}
			}
			if(! opps.isEmpty()) {
				// if we are deleting opportunities, do no other processing
				// this should rarely happen as we try to do in the createRenewalOpportunities 
				// call and in the start call
				for(Database.DeleteResult dr : Database.delete(opps,false)) {
					Opportunity opp = opps.remove(0);
					if(! dr.isSuccess()) {
						errorList.add('Failed to delete '+opp.Id+' : '+dr.getErrors());
					}
				}
			}
			else {
				Set<Id> subscriptionIds = new Map<Id,Subscription__c>(subscriptions).keySet();
				processErrorMap(Opportunity_Subscription.createRenewalOpportunities( subscriptionIds, false ));
			}
		}
		catch(Exception ex) {
			String message = ex.getMessage() + ':\n' + ex.getStackTraceString();
			system.debug(Logginglevel.ERROR, 'Exception: ' + message );
			errorList.add(message);
		}
		// email any errors that resulted in an uncaught exception
		if(! errorList.isEmpty()) {
			super.finish(lookupJob(bc));
		}
	}

	global void processErrorMap(Map<Id,List<Database.Error>> errorMap) {
		for(Id i : errorMap.keySet()) {
			for(Database.Error e : errorMap.get(i)) {
				errorList.add(i+': '+e.getMessage());
			}
		}
	}
}