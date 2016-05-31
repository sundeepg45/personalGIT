/**
 * This batch apex class examines detailed data in the TrackingEventLog object
 * and populates summary data in TrackingEventSummary. It depends on an instance
 * of the StringSetting__c custom setting, TrackingEventLog.LastProcessedDate, to
 * determine which records have not yet been processed.
 *
 * TrackingEventLog and TrackingEventSummary allow users to report on and
 * analyze system usage.
 *
 * Use the DailyScheduler class to schedule this class to run.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2012-05-03
 * 2012-05-03 - Created
 * 2012-06-12 - No longer send error messages on success.
 */
global class TrackingEventLog_CalculateSummary implements Database.Batchable<SObject>, Database.Stateful {

	/** the query that determines the scope of the batch job */
	global static String query;

	/** setting that determines where the last run finished processing */
	global StringSetting__c lastProcessed;

	/** string representation of the datetime in GMT where we should begin processing (exclusive) */
	global String timeRangeStart;

	/** datetime timestamp in GMT of the last TrackingEventLog__c record processed */
	global DateTime timeRangeEnd;

	/** a list of error messages encountered during run */
	global List<String> errorMessages = new List<String>();

	/** a count of the records processed */
	global Integer recordCount = 0;

	/** a switch to specify whether execute() should process future batches */
	global boolean processBatch = true;

	/**
	 * Required by Database.Batchable - runs once when this batch apex is kicked off. Here the
	 * query on TrackingEventLog__c that sets the scope of this run is defined.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		// initialize timeRangeStart as the end time from the last run (stored in custom setting)
		lastProcessed = StringSetting__c.getInstance('TrackingEventLog.LastProcessedDate');
		timeRangeStart = lastProcessed.Value__c;

		// set query
		query = 'select Name,Timestamp__c,TrackingEvent__c,UserRoleId__c'
			+ ' from TrackingEventLog__c'
			+ ' where Timestamp__c > ' + timeRangeStart
			+ ' order by Timestamp__c asc';

		return Database.getQueryLocator(query);
	}

	/**
	 * Required by Database.Batchable - runs for each batch. Here a batch of detail records from
	 * TrackingEventLog__c are examined and counts on the corresponding TrackingEventSummary__c
	 * records are created are incremented.
	 */
	global void execute(Database.BatchableContext bc, List<SObject> trackingEventLogObjects) {
		if (processBatch) {
			// declare nested Maps - the hierarchy looks like this:
			// 	Level 1 - Map keyed by event date
			//		Level 2 - Map keyed by event Id
			//			Level 3 - Map keyed by user role
			//				Level 4 - TrackingEventSummary__c object
			// the result is a tree structure for storing and indexing summary records
			Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate = new Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>>();

			// get roles and store them in the map
			Map<Id, UserRole> roleMap = new Map<Id, UserRole>([
				select
					Name
				from UserRole
				limit 40000 ]);

			// iterate through TrackingEventLog entries
			for(SObject eventLogObject : trackingEventLogObjects) {
				TrackingEventLog__c eventLog = (TrackingEventLog__c)eventLogObject;
				DateTime eventDateTime = eventLog.Timestamp__c;
				Date eventDate = eventDateTime.dateGMT();
				Id eventId = eventLog.TrackingEvent__c;
				String eventRole = roleMap.get(eventLog.UserRoleId__c).Name;
				TrackingEventSummary__c summary;


				recordCount++;

				// if we haven't seen this date yet, attempt to populate the map tree
				//   with existing summary records for that date
				if (!summaryMapKeyedByDate.containsKey(eventDate)) {
					populateSummaryMap(eventDate,summaryMapKeyedByDate);
				}

				// find the summary object in the map tree (or create a new one if needed)
				summary = getSummary(eventDate, eventId, eventRole, summaryMapKeyedByDate);

				// increment the count
				summary.Count__c = summary.Count__c + 1;
				timeRangeEnd = eventDateTime;
			}

			// update database
			if(upsertSummary(summaryMapKeyedByDate)) {
				// update last run time setting
				lastProcessed.Value__c = timeRangeEnd.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
				lastProcessed.CurrencyIsoCode = 'USD';
				update lastProcessed;
			}
			else {
				processBatch = false;
			}
		}
	}

	/**
	 * Required by Database.Batchable - runs once when this batch apex is completed. Here we send an email notification
	 * of any errors.
	 */
	global void finish(Database.BatchableContext bc) {
		Id jobId = null;
		if(bc != null) {
			jobId = bc.getJobId();
		}
		// query the AsyncApexJob object to retrieve the current job's information.
		AsyncApexJob job = null;
		for(AsyncApexJob j : [
			select
				Status,
				NumberOfErrors,
				JobItemsProcessed,
				TotalJobItems,
				CreatedBy.Email
			from AsyncApexJob
			where Id = :jobId ] )
		{
			job = j;
		}

		if(! errorMessages.isEmpty() || job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0) {
			if(job == null) {
				job = new AsyncApexJob();
			}
			// Send an email to notify me of the jobs status
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			//String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			String[] toAddresses = new String[] { 'scoleman@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'TrackingEventLog_CalculateSummary ' +job.Status+' processed '+recordCount+' records running as '+UserInfo.getUserName());
			String body = 'The batch Apex job run as '+UserInfo.getUserName()+ ' processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n\n';
			if(! errorMessages.isEmpty()) {
				for(String e : errorMessages) {
					body += e + '\n\n';
				}
			}
			mail.setPlainTextBody(body);
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
	}

	/**
	 * Retrieve existing TrackingEventSummary__c records by date and store them in a tree-like
	 * data structure for easy indexing.
	 *
	 * @param eventDate the date for which to retrieve summary records
	 * @param summaryMapKeyedByDate a tree data structure implemented with nested maps that contains TrackingEventSummary__c objects at the leaf
	 */
	private void populateSummaryMap(Date eventDate, Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate) {
		List<TrackingEventSummary__c> summaryList = new List<TrackingEventSummary__c>();
		Map<Id, Map<String, TrackingEventSummary__c>> summaryMapKeyedByEvent;

		summaryList = [
			select
				Name,
				Count__c,
				Date__c,
				TrackingEvent__c,
				UserRole__c
			from TrackingEventSummary__c
			where Date__c = :eventDate ];

		for (TrackingEventSummary__c summary : summaryList) {
			putSummary(summary, summaryMapKeyedByDate);
		}
	}

	/**
	 * Commit TrackingEventSummary__c records to the database.
	 *
	 * @param summaryMapKeyedByDate a tree data structure implemented with nested maps that contains TrackingEventSummary__c objects at the leaf
	 * @returns a boolean value that indicates success or failure of the upsert
	 */
	private boolean upsertSummary(Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate) {
		List<TrackingEventSummary__c> summaryList = new List<TrackingEventSummary__c>();
		boolean success;

		try {
			// traverse the summary tree to generate a list of summary records for upsert
			for (Map<Id, Map<String, TrackingEventSummary__c>> summaryMapKeyedByEvent : summaryMapKeyedByDate.values()) {
				for (Map<String, TrackingEventSummary__c> summaryMapKeyedByRole : summaryMapKeyedByEvent.values()) {
					for (TrackingEventSummary__c summary : summaryMapKeyedByRole.values()) {
						summaryList.add(summary);
					}
				}
			}
			upsert summaryList;
			success = true;
		}
		catch (Exception e) {
			String errorMessage = e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage();
			System.debug(errorMessage);
			errorMessages.add(errorMessage);
			success = false;
		}

		return success;
	}

	/**
	 * Find a TrackingEventSummary__c in the tree. If it doesn't exist, create it.
	 *
	 * @param eventDate the Date__c value of the desired TrackingEventSummary__c object
	 * @param eventId the TrackingEvent__c value of the desired TrackingEventSummary__c object
	 * @param eventRole the UserRole__c value of the desired TrackingEventSummary__c object
	 * @param summaryMapKeyedByDate a tree data structure implemented with nested maps that contains TrackingEventSummary__c objects at the leaf
	 * @returns the requested TrackingEventSummary__c object
	 */
	private TrackingEventSummary__c getSummary(Date eventDate, Id eventId, String eventRole, Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate) {
		Map<String,TrackingEventSummary__c> summaryMapKeyedByRole;
		TrackingEventSummary__c summary;

		summaryMapKeyedByRole = getSummaryMap(eventDate,eventId,eventRole,summaryMapKeyedByDate);

		// if map contains the role get the TrackingEventSummary__c object
		if (summaryMapKeyedByRole.containsKey(eventRole)) {
			summary = summaryMapKeyedByRole.get(eventRole);
		}
		// otherwise create a new one
		else {
			summary = new TrackingEventSummary__c(Count__c = 0, Date__c = eventDate, TrackingEvent__c = eventId, UserRole__c = eventRole);
			summaryMapKeyedByRole.put(eventRole,summary);
		}

		return summary;
	}

	/**
	 * Put an TrackingEventSummary__c object in the tree.
	 *
	 * @param summary an existing TrackingEventSummary__c object
	 * @param summaryMapKeyedByDate a tree data structure implemented with nested maps that contains TrackingEventSummary__c objects at the leaf
	 */
	private void putSummary(TrackingEventSummary__c summary, Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate) {
		Map<String,TrackingEventSummary__c> summaryMapKeyedByRole;
		Date eventDate = summary.Date__c;
		Id eventId = summary.TrackingEvent__c;
		String eventRole = summary.UserRole__c;
		Decimal eventCount = summary.Count__c;
		Id summaryId = summary.Id;

		summaryMapKeyedByRole = getSummaryMap(eventDate,eventId,eventRole,summaryMapKeyedByDate);

		summaryMapKeyedByRole.put(eventRole,summary);
	}

	/**
	 * Utility method to help locate and create TrackingEventSummary__c objects in the tree.
	 * Navigates the tree, creating missing nodes as they are encountered, and returns the
	 * last nested Map - the one that actually contains TrackingEventSummary__c.
	 *
	 * @param eventDate the Date__c value of the desired TrackingEventSummary__c object
	 * @param eventId the TrackingEvent__c value of the desired TrackingEventSummary__c object
	 * @param eventRole the UserRole__c value of the desired TrackingEventSummary__c object
	 * @param summaryMapKeyedByDate a tree data structure implemented with nested maps that contains TrackingEventSummary__c objects at the leaf
	 * @returns the requested TrackingEventSummary__c object
	 */
	private Map<String,TrackingEventSummary__c> getSummaryMap(Date eventDate, Id eventId, String eventRole, Map<Date, Map<Id, Map<String, TrackingEventSummary__c>>> summaryMapKeyedByDate)  {
		Map<Id, Map<String, TrackingEventSummary__c>> summaryMapKeyedByEvent;
		Map<String,TrackingEventSummary__c> summaryMapKeyedByRole;
		TrackingEventSummary__c summary;

		// if the first level map contains the event date get the second level map
		if (summaryMapKeyedByDate.containsKey(eventDate)) {
			summaryMapKeyedByEvent = summaryMapKeyedByDate.get(eventDate);
		}
		// otherwise add it
		else {
			summaryMapKeyedByEvent = new Map<Id, Map<String, TrackingEventSummary__c>>();
			summaryMapKeyedByDate.put(eventDate,summaryMapKeyedByEvent);
		}

		// if the second level map contains the event id get the third level map
		if (summaryMapKeyedByEvent.containsKey(eventId)) {
			summaryMapKeyedByRole = summaryMapKeyedByEvent.get(eventId);
		}
		// otherwise add it
		else {
			summaryMapKeyedByRole = new Map<String,TrackingEventSummary__c>();
			summaryMapKeyedByEvent.put(eventId,summaryMapKeyedByRole);
		}

		return summaryMapKeyedByRole;
	}
}