/**
 * This class is used to process inbound and outbound integration events.
 * 
 * @version 2015-12-09
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2014-09-25 - Created
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2015-12-09 - Do not allow inbound messages to override the embedded
 * @since 2015-12-09 - Techdebt - implemented hasWork, bulkified attachment query, bulkified DML error handling
 * @since 2015-11-27 - avoid negative limits
 */
global class Integration_Batchable extends AbstractBatchable  {
	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'Integration.LastProcessed';

	/** Must run in minutes. */
	global static final Integer MUST_RUN_IN_MINUTES = 60; 

	/** Controls the oldest record we consider. */
	global static final Integer MAX_AGE_IN_DAYS = 2;

	/** 
	 * Keep track of the lastProcessedDateTime
	 */
	global DateTimeSetting__c lastProcessed {
		get {
			if(lastProcessed == null) {
				lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY,Value__c=DateTime.newInstance(0L).addDays(MAX_AGE_IN_DAYS));
				DateTimeSetting__c xlastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
				if(xlastProcessed != null && xlastProcessed.Value__c != null) {
					lastProcessed = xlastProcessed;
				}
			}
			return lastProcessed;
		}
		set;
	}

	/**
	 * Default constructor.
	 */
	global Integration_Batchable() {
		super('Integration_Batchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		DateTime oldestDateTime = lastProcessed.Value__c.addDays(-MAX_AGE_IN_DAYS);
		return (DateTime.now() >= lastProcessed.Value__c.addMinutes(MUST_RUN_IN_MINUTES))
			|| ([
				SELECT count()
				FROM Inbound_Event__c
				WHERE Status__c IN ('New','Retried') AND LastModifiedDate >= :oldestDateTime
				LIMIT 1 ] > 0) 
			|| ([
				SELECT count() 
				FROM Outbound_Event__c
				WHERE LastModifiedDate >= :oldestDateTime
				LIMIT 1 ] > 0)
			|| ([
				SELECT count()
				FROM Outbound_Error__c 
				WHERE Status__c = 'New' AND LastModifiedDate >= :oldestDateTime
				LIMIT 1 ] > 0);
	}

	/**
	 * Start method impl for Database.Batchable interface.  A fairly small
	 * scope value will need to be used for the current implementation.
	 * 
	 * @param   bc batchable contents
	 * @return  query locator for ready Inbound_Event__c records
	 *
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) {
		lastProcessed.Value__c = DateTime.now();
		errorList.clear();

		Database.QueryLocator retval = Database.getQueryLocator([
			SELECT
				Id,
				Event_Type__c,
				Full_Message_In_Attachment__c,
				Message__c,
				Operation__c,
				Retries__c,
				Status__c,
				(SELECT Id FROM Attachments WHERE Name = 'FullMessage' LIMIT 1)
			FROM Inbound_Event__c
			WHERE Status__c IN ('New','Retried')
			ORDER BY Name]);

		try {
			Integer outboundLimit = getOutboundLimit();
			checkOutboundEventLoad();
			processOutboundEvents(getOutboundEvents(outboundLimit), getOutboundErrors(outboundLimit), outboundLimit);
		}
		finally {
			Database.upsert(lastProcessed,false);
		}
		return retval;
	}

	/**
	 * execute method impl for Database.Batchable interface
	 *
	 * @param   bc batchable content
	 * @param   inboundEvents all matching records
	 */
	global void execute(Database.BatchableContext bc, List<Inbound_Event__c> inboundEvents) {
		try {
			processInboundEvents(inboundEvents);
			Integer outboundLimit = getOutboundLimit();
			processOutboundEvents(getOutboundEvents(outboundLimit), getOutboundErrors(outboundLimit), outboundLimit);
		}
		catch(Exception ex) {
			errorList.add('execute error: ' + ex.getMessage()+'\n'+ex.getStackTraceString());
		}
		finally {
			// email any errors that resulted in an uncaught exception
			if(! errorList.isEmpty()) {
				super.finish(lookupJob(bc));
			}
		}
	}

	/**
	 * finish method
	 *
	 * @param job the async apex job
	 */
	global override void finish(AsyncApexJob job) {
		try {
			Integer outboundLimit = getOutboundLimit();
			checkOutboundEventLoad();
			processOutboundEvents(getOutboundEvents(outboundLimit), getOutboundErrors(outboundLimit), outboundLimit);
		}
		catch(Exception ex) {
			errorList.add('Outbound Processing Error: ' + ex.getMessage()+'\n'+ex.getStackTraceString());
		}
		finally {
			super.finish(job);
		}
	}

	public void processInboundEvents(List<Inbound_Event__c> inboundEvents) {
		// don't allow messages from the bus to override the embedded flag
		OpportunityTriggerBefore2.embedded.OverrideAllowed__c = false;

		List<Inbound_Event__c> deleteEvents = new List<Inbound_Event__c>();
		Map<Id,Attachment> attachmentMap = null;

		// the downstream code is not bulkified - it was built to handle one
		//  record at a time. we'll need to keep batch size low to avoid limits.
		for(Inbound_Event__c inboundEvent : inboundEvents) {
			String message = inboundEvent.Message__c;
			try {
				// get full message text
				if(inboundEvent.Full_Message_In_Attachment__c && inboundEvent.Attachments != null && ! inboundEvent.Attachments.isEmpty()) {
					message = null;
					if(attachmentMap == null) {
						Set<Id> ids = new Set<Id>();
						for(Inbound_Event__c ie : inboundEvents) {
							if(ie.Full_Message_In_Attachment__c && ie.Attachments != null) {
								for(Attachment a : ie.Attachments) {
									ids.add(a.Id);
								}
							}
						}
						attachmentMap = new Map<Id,Attachment>([SELECT Id,Body FROM Attachment WHERE Id in :ids]);
					}
					Attachment attach = attachmentMap.get(inboundEvent.Attachments[0].Id);
					if(attach != null) {
						message = attach.Body.toString();
					}
				}

				// pass event message to service broker
				InboundServiceBroker.processMessage(
					inboundEvent.Id,
					inboundEvent.Event_Type__c,
					message,
					inboundEvent.Operation__c,
					inboundEvent.Retries__c,
					inboundEvent.Status__c);
			}
			catch(Exception ex) {
				// if there's an error queue an error message.
				OutboundService.queueErrorMessage(message, ex.getTypeName(), ex.getMessage());
			}
			finally {
				deleteEvents.add(new Inbound_Event__c(Id = inboundEvent.Id));
			}
		}
		for(Database.DeleteResult dr : Database.delete(deleteEvents,false) ) {
			if(! dr.isSuccess()) {
				errorList.add('Failed to update event: '+dr.getErrors());
			}
		}
	}

	public void checkOutboundEventLoad() {
		try {
			Integer alertThreshold = 1000;
			LongSetting__c alertThresholdSetting = LongSetting__c.getInstance('Integration.alertThresholdOutbound');
			if(alertThresholdSetting != null && alertThresholdSetting.Value__c != null) {
				alertThreshold = Integer.valueOf(alertThresholdSetting.Value__c);
			}

			Integer eventCount = [SELECT count() FROM Outbound_Event__c];

			if(eventCount > alertThreshold) {
				List<Outbound_Event__c> recentAlertEvents = [
					SELECT Id, LastModifiedDate
					FROM Outbound_Event__c
					WHERE Send_Load_Alert__c = True
					ORDER BY Priority__c ASC, CreatedDate DESC
					LIMIT 1];

				if(recentAlertEvents.isEmpty() || DateTime.now() > recentAlertEvents[0].LastModifiedDate.addHours(1)) {
					List<Outbound_Event__c> alertEvents = [
						SELECT Id, Send_Load_Alert__c
						FROM Outbound_Event__c
						ORDER BY Priority__c ASC, CreatedDate DESC
						LIMIT 1];

					alertEvents[0].Send_Load_Alert__c = True;
					for(Database.SaveResult sr : Database.update(alertEvents,false)) {
						if(!sr.isSuccess()) {
							errorList.add('Event load monitoring failed to complete: ' + sr.getErrors());
						}
					}
				}
			}
		}
		catch(Exception ex) {
			errorList.add('Event load monitoring failed to complete: ' + ex.getMessage()+'\n'+ex.getStackTraceString());
		}
	}

	public void processOutboundEvents(List<Outbound_Event__c> outboundEvents, List<Outbound_Error__c> outboundErrors, Integer outboundLimit) {
		if(outboundLimit > 0) {
			List<OutboundWrapper> events = new List<OutboundWrapper>();

			// get candidate events
			for(Outbound_Event__c outboundEvent : outboundEvents) {
				events.add(new OutboundWrapper(outboundEvent, null));
			}

			// get candidate errors
			for(Outbound_Error__c outboundError : outboundErrors) {
				events.add(new OutboundWrapper(null, outboundError));
			}

			// prioritize the combines list of events and errors
			events.sort();
 
			// create lists of sObjects to update
			List<SObject> updatedEvents = new List<SObject>();
			Integer outboundUpdated = 0;
			for(OutboundWrapper event : events) {
				System.debug('*** event: ' + event.Priority + ' / ' + event.CreatedDate);
				if(outboundUpdated < outboundLimit) {
					if(event.SObjectType == 'Outbound_Event__c') {
						event.OutboundEvent.Status__c = 'Pending';
						updatedEvents.add(event.OutboundEvent);
						outboundUpdated = outboundUpdated + 1;
					}
					else if(event.SObjectType == 'Outbound_Error__c') {
						event.OutboundError.Status__c = 'Pending';
						updatedEvents.add(event.OutboundError);
						outboundUpdated = outboundUpdated + 1;
					}
				}
				else {
					break;
				}
			}

			for(Database.SaveResult sr : Database.update(updatedEvents,false) ) {
				if(! sr.isSuccess()) {
					errorList.add('Failed to update event: '+sr.getErrors());
				}
			}
		}
	}

	public Integer getOutboundLimit() {
		Integer pendingLimit = 100;

		LongSetting__c pendingLimitSetting = LongSetting__c.getInstance('Integration.maxPendingOutbound');
		if(pendingLimitSetting != null && pendingLimitSetting.Value__c != null) {
			pendingLimit = Integer.valueOf(pendingLimitSetting.Value__c);
		}

		Integer pendingEventCount = [SELECT count() FROM Outbound_Event__c WHERE Status__c = 'Pending'];
		Integer pendingErrorCount = [SELECT count() FROM Outbound_Error__c WHERE Status__c = 'Pending'];

		return pendingLimit - pendingEventCount - pendingErrorCount;
	}

	public static Integer largestInteger(Integer v1,Integer v2) {
		if(v2 != null && (v1 == null || v1 < v2)) {
			v1 = v2;
		}
		return v1;
	}

	public List<Outbound_Event__c> getOutboundEvents(Integer outboundLimit) {
		return [SELECT 
					Id, 
					Status__c,
					Priority__c,
					CreatedDate
				FROM Outbound_Event__c 
				WHERE Status__c = 'New' 
				ORDER BY 
					Priority__c DESC, 
					CreatedDate ASC 
				LIMIT :largestInteger(outboundLimit,0)];
	}

	public List<Outbound_Error__c> getOutboundErrors(Integer outboundLimit) {
		return [SELECT 
					Id, 
					Status__c,
					Priority__c,
					CreatedDate
				FROM Outbound_Error__c 
				WHERE Status__c = 'New' 
				ORDER BY 
					Priority__c DESC, 
					CreatedDate ASC 
				LIMIT :largestInteger(outboundLimit,0)];
	}

	class OutboundWrapper implements Comparable {
		public Outbound_Event__c OutboundEvent;
		public Outbound_Error__c OutboundError;

		public String SObjectType {
			get {
				String returnValue;
				if(OutboundEvent != null) {
					returnValue = 'Outbound_Event__c';
				}
				else if(OutboundError != null) {
					returnValue = 'Outbound_Error__c';
				}
				return returnValue;
			}
		}

		public Decimal Priority {
			get {
				Decimal returnValue;
				if(OutboundEvent != null) {
					returnValue = OutboundEvent.Priority__c;
				}
				else if(OutboundError != null) {
					returnValue = OutboundError.Priority__c;
				}
				return returnValue;
			}
		}

		public Datetime CreatedDate {
			get {
				Datetime returnValue;
				if(OutboundEvent != null) {
					returnValue = OutboundEvent.CreatedDate;
				}
				else if(OutboundError != null) {
					returnValue = OutboundError.CreatedDate;
				}
				return returnValue;
			}
		}

		public OutboundWrapper(Outbound_Event__c outboundEvent, Outbound_Error__c outboundError) {
			this.OutboundEvent = outboundEvent;
			this.OutboundError = outboundError;
		}

		public Integer compareTo(Object compareTo) {
			OutboundWrapper compareToEvent = (OutboundWrapper)compareTo;

			// The return value of 0 indicates that both elements are equal.
			Integer returnValue = 0;
			if(this.Priority != compareToEvent.Priority) {
				returnValue = -1;
				if(this.Priority < compareToEvent.Priority) {
					returnValue = 1;
				} 
			}
			else if(this.CreatedDate != compareToEvent.CreatedDate) {
				returnValue = -1;
				if(this.CreatedDate > compareToEvent.CreatedDate) {
					returnValue = 1;
				}
			}
			return returnValue;
		}
	}
}