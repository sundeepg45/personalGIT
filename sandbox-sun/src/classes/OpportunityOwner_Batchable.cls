/**
 * This class updates the Opportunity Owner Lookup field when it falls out of sync.
 *
 * @version 2015-11-18
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-11-18 - Correct lastProcessedDateTime to never be more than two days old...
 * 2014-09-18 - Added implements Database.Stateful as that was removed from the base class
 * 2014-04-21 - Update to use AbstractBatchable
 * 2013-11-18 - created
 */
global class OpportunityOwner_Batchable  extends AbstractBatchable implements Database.Stateful {
	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'OpportunityOwner.LastProcessed';

	/** 
	 * Keep track of the lastProcessedDateTime
	 */
	global DateTime lastProcessedDateTime {
		get {
			if(lastProcessedDateTime == null) {
				lastProcessedDateTime = DateTime.newInstance(0L);
				DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
				if(lastProcessed != null && lastProcessed.Value__c != null) {
					lastProcessedDateTime = lastProcessed.Value__c;
				}
			}
			return lastProcessedDateTime;
		}
		set;
	}

	/** Maximum value to use for lastProcessedDateTime */
	global DateTime lastProcessedDateTimeMax = DateTime.now().addDays(-2);

	/**
	 * Default constructor.
	 */
	global OpportunityOwner_Batchable() {
		super('OpportunityOwner_Batchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		DateTime minSystemModstamp = DateTime.now().addDays(-2);
		if(lastProcessedDateTime > minSystemModstamp) {
			minSystemModstamp = lastProcessedDateTime;
		}
		return (0 < [
			select count()
			from Opportunity
			where SystemModstamp >= :minSystemModstamp
				and IsOwnerLookupCurrent__c = false
			limit 1]);
	}

	/**
	 * Query the account records which have changed, and delete any orphaned
	 * OpportunityOwner__c objects.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		final DateTime lpt = lastProcessedDateTime;
		lastProcessedDateTimeMax = DateTime.now().addMinutes(-1);
		return Database.getQueryLocator([
			select 
				OwnerId,
				SystemModstamp
			from Opportunity
			where SystemModstamp >= :lpt
				and IsOwnerLookupCurrent__c = false
			order by SystemModstamp, LastModifiedDate ]);
	}

	/**
	 * Called to update the selected records.
	 * 
	 * @param bc the batchable context (not used)
	 * @param opps the list to update
	 */
	global void execute(Database.BatchableContext bc, List<Opportunity> opps) {
		Boolean triggerValue = AbstractTrigger.booleanSettingMap.get(OpportunityTriggerAfter2.REQUIRE_ENGAGEMENT_SA_SETTING);
		try {
			AbstractTrigger.booleanSettingMap.put(OpportunityTriggerAfter2.REQUIRE_ENGAGEMENT_SA_SETTING,false);
			for(Opportunity opp : opps) {
				if(opp.SystemModstamp > lastProcessedDateTime) {
					lastProcessedDateTime = opp.SystemModstamp;
				}
				Id ownerId = opp.OwnerId;
				if(! (ownerId+'xxx').startsWith('005')) {
					ownerId = null;
				}
				opp.Owner__c = ownerId;
			}
			Database.update(opps,false);
		}
		catch(Exception ex2) {
			errorList.add('Exception: '+ex2+'\n'+ex2.getStackTraceString());
		}
		finally {
			AbstractTrigger.booleanSettingMap.put(OpportunityTriggerAfter2.REQUIRE_ENGAGEMENT_SA_SETTING,triggerValue);
		}
	}

	/**
	 * finish method
	 *
	 * @param job the async apex job
	 */
	global override void finish(AsyncApexJob job) {
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed == null) {
			lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
		}
		if(lastProcessedDateTime > lastProcessedDateTimeMax) {
			lastProcessedDateTime = lastProcessedDateTimeMax;
		}
		lastProcessed.Value__c = lastProcessedDateTime;
		try {
			upsert lastProcessed;
		}
		catch(Exception e) {
			errorList.add('Failed to update lastProcessed '+e);
		}
		super.finish(job);
	}
}