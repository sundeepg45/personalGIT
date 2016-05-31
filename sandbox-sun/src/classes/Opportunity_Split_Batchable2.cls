/**
 * This class processes batches of opportunities whose opportunity split details
 * need to be rebuilt.
 *
 * @version 2016-01-06
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-02-07 - added boolean setting that suppresses per-batch error email
 * 2014-10-06 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2016-01-06 - rollback
 * 2016-01-04 - Allow the same user to have multiple split detail records per product
 * 2015-11-23 - Merged in Process_Opportnity_Split_Detail class and rewrote to do processing per line item...
 */
@IsTest //US80608(rollback DE7583) 
private class Opportunity_Split_Batchable2 {} //US80608(rollback DE7583) 
//US80608(rollback DE7583) global class Opportunity_Split_Batchable2 extends AbstractBatchable {
//US80608(rollback DE7583) 	global static final String JOB_NAME = 'Opportunity_Split_Batchable2';
//US80608(rollback DE7583) 	/** Maximum event rows per batch call. */
//US80608(rollback DE7583) 	global static final Long MAX_EVENT_ROWS = 8000L;
//US80608(rollback DE7583) 	/** Maximum event age in days. */
//US80608(rollback DE7583) 	global static final Integer MAX_EVENT_AGE = 7;
//US80608(rollback DE7583) 	/** Custom setting key to keep track of re-entry processing. */
//US80608(rollback DE7583) 	global static final String PROCESSING_KEY = 'OppSplit.Processing';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the number of events for re-entry processing. */
//US80608(rollback DE7583) 	global static final String PROCESSING_SIZE_KEY = 'OppSplit.SizeProcessing';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the lower limit last modified date in the event query. */
//US80608(rollback DE7583) 	global static final String MIN_PROCESSING_KEY = 'OppSplit.MinProcessing';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the upper limit last modified date in the event query. */
//US80608(rollback DE7583) 	global static final String MAX_PROCESSING_KEY = 'OppSplit.MaxProcessing';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the lower limit name in the event query. */
//US80608(rollback DE7583) 	global static final String MIN_NAME_KEY = 'OppSplit.MinName';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the upper limit name in the event query. */
//US80608(rollback DE7583) 	global static final String MAX_NAME_KEY = 'OppSplit.MaxName';
//US80608(rollback DE7583) 	/** Custom setting key to keep track of the lower last modified date in the line item query. */
//US80608(rollback DE7583) 	global static final String LINE_PROCESSING_KEY = 'OppSplit.LineProcessing';
//US80608(rollback DE7583) 	/** Custom setting key to disable part of the error handling. */
//US80608(rollback DE7583) 	global static final String EMAIL_PER_BATCH_KEY = 'OppSplit.errorEmailPerBatch';

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Default constructor.
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global Opportunity_Split_Batchable2() {
//US80608(rollback DE7583) 		super(JOB_NAME);
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static ScheduledApex__c scheduledApex {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(scheduledApex == null) {
//US80608(rollback DE7583) 				scheduledApex = ScheduledApex__c.getInstance(JOB_NAME);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return scheduledApex;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/** 
//US80608(rollback DE7583) 	 * Keep track of the processing flag
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global static BooleanSetting__c processingSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(processingSetting == null) {
//US80608(rollback DE7583) 				processingSetting = BooleanSetting__c.getInstance(PROCESSING_KEY);
//US80608(rollback DE7583) 				if(processingSetting == null) {
//US80608(rollback DE7583) 					processingSetting = new BooleanSetting__c(Name=PROCESSING_KEY,Value__c=false);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return processingSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static DateTimeSetting__c minProcessingSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(minProcessingSetting == null) {
//US80608(rollback DE7583) 				minProcessingSetting = DateTimeSetting__c.getInstance(MIN_PROCESSING_KEY);
//US80608(rollback DE7583) 				if(minProcessingSetting == null) {
//US80608(rollback DE7583) 					minProcessingSetting = new DateTimeSetting__c(Name=MIN_PROCESSING_KEY,Value__c=DateTime.now().addDays(-MAX_EVENT_AGE));
//US80608(rollback DE7583) 					minNameSetting.Value__c='E-000000000000000000';
//US80608(rollback DE7583) 					maxNameSetting.Value__c='E-999999999999999999';
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return minProcessingSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static DateTimeSetting__c maxProcessingSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(maxProcessingSetting == null) {
//US80608(rollback DE7583) 				maxProcessingSetting = DateTimeSetting__c.getInstance(MAX_PROCESSING_KEY);
//US80608(rollback DE7583) 				if(maxProcessingSetting == null) {
//US80608(rollback DE7583) 					maxProcessingSetting = new DateTimeSetting__c(Name=MAX_PROCESSING_KEY,Value__c=minProcessingSetting.Value__c);
//US80608(rollback DE7583) 					minNameSetting.Value__c='E-000000000000000000';
//US80608(rollback DE7583) 					maxNameSetting.Value__c='E-999999999999999999';
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return maxProcessingSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static StringSetting__c minNameSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(minNameSetting == null) {
//US80608(rollback DE7583) 				minNameSetting = StringSetting__c.getInstance(MIN_NAME_KEY);
//US80608(rollback DE7583) 				if(minNameSetting == null) {
//US80608(rollback DE7583) 					minNameSetting = new StringSetting__c(Name=MIN_NAME_KEY,Value__c='E-000000000000000000');
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return minNameSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static StringSetting__c maxNameSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(maxNameSetting == null) {
//US80608(rollback DE7583) 				maxNameSetting = StringSetting__c.getInstance(MAX_NAME_KEY);
//US80608(rollback DE7583) 				if(maxNameSetting == null) {
//US80608(rollback DE7583) 					maxNameSetting = new StringSetting__c(Name=MAX_NAME_KEY,Value__c='E-999999999999999999');
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return maxNameSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static LongSetting__c processingSizeSetting {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(processingSizeSetting == null) {
//US80608(rollback DE7583) 				processingSizeSetting = LongSetting__c.getInstance(PROCESSING_SIZE_KEY);
//US80608(rollback DE7583) 				if(processingSizeSetting == null) {
//US80608(rollback DE7583) 					processingSizeSetting = new LongSetting__c(Name=PROCESSING_SIZE_KEY);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			if(processingSizeSetting.Value__c == null || processingSizeSetting.Value__c <= 0L) {
//US80608(rollback DE7583) 				processingSizeSetting.Value__c = MAX_EVENT_ROWS;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return processingSizeSetting;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Check if there is work for this job to do.  This will return true if 
//US80608(rollback DE7583) 	 * the processing setting is true, the job has not run in more than an hour,
//US80608(rollback DE7583) 	 * or there is new work to process.
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @return false when the job does not need to run.
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global override Boolean hasWork() {
//US80608(rollback DE7583) 		return processingSetting.Value__c == true
//US80608(rollback DE7583) 			|| minProcessingSetting.Value__c < DateTime.now().addHours(-1)
//US80608(rollback DE7583) 			|| (0 < [
//US80608(rollback DE7583) 				select count()
//US80608(rollback DE7583) 				from Event__c
//US80608(rollback DE7583) 				where Processed__c = false
//US80608(rollback DE7583) 					and LastModifiedDate >= :minProcessingSetting.Value__c
//US80608(rollback DE7583) 				limit 1] );
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static Integer largestInteger(Integer v1,Integer v2) {
//US80608(rollback DE7583) 		if(v2 != null && (v1 == null || v1 < v2) ){
//US80608(rollback DE7583) 			v1 = v2;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		return v1;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Compute the number of query rows left.  A value may be assigned to fake a lower limit.
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global static Integer queryRows {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			Integer retval = queryRows;
//US80608(rollback DE7583) 			if(retval == null || retval > 0) {
//US80608(rollback DE7583) 				retval = 0;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return largestInteger(retval + Limits.getLimitQueryRows() - Limits.getQueryRows(),0);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set {
//US80608(rollback DE7583) 			if(value != null) {
//US80608(rollback DE7583) 				value -= Limits.getLimitQueryRows() - Limits.getQueryRows();
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			queryRows = value;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Compute the number of dml rows left.  A value may be assigned to fake a lower limit.
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global static Integer dmlRows {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			Integer retval = dmlRows;
//US80608(rollback DE7583) 			if(retval == null || retval > 0) {
//US80608(rollback DE7583) 				retval = 0;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return largestInteger(retval + Limits.getLimitDMLRows() - Limits.getDMLRows(),0);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set {
//US80608(rollback DE7583) 			if(value != null) {
//US80608(rollback DE7583) 				value -= Limits.getLimitDMLRows() - Limits.getDMLRows();
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			dmlRows = value;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global List<Event__c> events {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(events == null) {
//US80608(rollback DE7583) 				Integer qlimits = queryRows;
//US80608(rollback DE7583) 				if(qlimits > Limits.getLimitQueryRows()/5) {
//US80608(rollback DE7583) 					qlimits = Limits.getLimitQueryRows()/5;
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				if(qlimits > ((Limits.getLimitDMLRows() * 4) / 5)) {
//US80608(rollback DE7583) 					qlimits = (Limits.getLimitDMLRows() * 4) / 5;
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				if(processingSizeSetting.Value__c != null && qlimits > processingSizeSetting.Value__c) {
//US80608(rollback DE7583) 					qlimits = largestInteger(processingSizeSetting.Value__c.intValue(),0);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				events = [
//US80608(rollback DE7583) 					select Id,
//US80608(rollback DE7583) 						LastModifiedDate,
//US80608(rollback DE7583) 						Name,
//US80608(rollback DE7583) 						Opportunity__c,
//US80608(rollback DE7583) 						Processed__c
//US80608(rollback DE7583) 					from Event__c
//US80608(rollback DE7583) 					where Processed__c = false 
//US80608(rollback DE7583) 						and LastModifiedDate >= :minProcessingSetting.Value__c
//US80608(rollback DE7583) 						and LastModifiedDate <= :maxProcessingSetting.Value__c
//US80608(rollback DE7583) 						and Name >= :minNameSetting.Value__c
//US80608(rollback DE7583) 						and Name <= :maxNameSetting.Value__c
//US80608(rollback DE7583) 					order by LastModifiedDate, Name
//US80608(rollback DE7583) 					limit :qlimits ];
//US80608(rollback DE7583) 				processingSizeSetting.Value__c = events.size();
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return events;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global Map<Id,Id> eventIdByOppId {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(eventIdByOppId == null) {
//US80608(rollback DE7583) 				eventIdByOppId = new Map<Id,Id>();
//US80608(rollback DE7583) 				for(Event__c ev : events) {
//US80608(rollback DE7583) 					eventIdByOppId.put(ev.Opportunity__c,ev.Id);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return eventIdByOppId;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static void retryEvents(Boolean doRetry) {
//US80608(rollback DE7583) 		if(doRetry && queryRows > 0 && dmlRows > 0) {
//US80608(rollback DE7583) 			// retry logic
//US80608(rollback DE7583) 			Integer qlimit = queryRows;
//US80608(rollback DE7583) 			if(qlimit > dmlRows) {
//US80608(rollback DE7583) 				qlimit = dmlRows;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			List<Event__c> xevents = [
//US80608(rollback DE7583) 				select Id
//US80608(rollback DE7583) 				from Event__c 
//US80608(rollback DE7583) 				where Processed__c = false 
//US80608(rollback DE7583) 					and CreatedDate >= :DateTime.now().addDays(-1) 
//US80608(rollback DE7583) 					and LastModifiedDate < :minProcessingSetting.Value__c.addHours(-1)
//US80608(rollback DE7583) 				order by LastModifiedDate
//US80608(rollback DE7583) 				limit :qlimit ];
//US80608(rollback DE7583) 			Database.update(xevents,false);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Start method impl for Database.Batchable interface.
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @param   bc batchable context
//US80608(rollback DE7583) 	 * @return  list of line items and events
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global List<SObject> start(Database.BatchableContext bc)
//US80608(rollback DE7583) 	{
//US80608(rollback DE7583) 		errorList.clear();
//US80608(rollback DE7583) 		// initialize all the settings
//US80608(rollback DE7583) 		DateTime startTime = DateTime.newInstance(0L);
//US80608(rollback DE7583) 		DateTime endTime = DateTime.now();
//US80608(rollback DE7583) 		DateTimeSetting__c lineProcessingSetting = DateTimeSetting__c.getInstance(LINE_PROCESSING_KEY);
//US80608(rollback DE7583) 		if(lineProcessingSetting == null) {
//US80608(rollback DE7583) 			lineProcessingSetting = new DateTimeSetting__c(Name=LINE_PROCESSING_KEY,Value__c=startTime);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		if(maxProcessingSetting.Value__c > endTime) {
//US80608(rollback DE7583) 			maxProcessingSetting.Value__c = endTime;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		// if there are no events the reset some of the variables and try again
//US80608(rollback DE7583) 		if(events.isEmpty()) {
//US80608(rollback DE7583) 			minNameSetting.Value__c = 'E-000000000000000000';
//US80608(rollback DE7583) 			maxNameSetting.Value__c = 'E-999999999999999999';
//US80608(rollback DE7583) 			lineProcessingSetting.Value__c = startTime;
//US80608(rollback DE7583) 			processingSizeSetting.Value__c = MAX_EVENT_ROWS;
//US80608(rollback DE7583) 			minProcessingSetting.Value__c = maxProcessingSetting.Value__c;
//US80608(rollback DE7583) 			maxProcessingSetting.Value__c = endTime;
//US80608(rollback DE7583) 			events = null;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		List<SObject> queue = new List<SObject>();
//US80608(rollback DE7583) 		if(! events.isEmpty()) {
//US80608(rollback DE7583) 			// adjust the settings so each job will query the same records...
//US80608(rollback DE7583) 			minNameSetting.Value__c = events[0].Name;
//US80608(rollback DE7583) 			minProcessingSetting.Value__c = events[0].LastModifiedDate;
//US80608(rollback DE7583) 			maxNameSetting.Value__c = events[events.size()-1].Name;
//US80608(rollback DE7583) 			maxProcessingSetting.Value__c = events[events.size()-1].LastModifiedDate;
//US80608(rollback DE7583) 			for(Event__c ev : events) {
//US80608(rollback DE7583) 				if(ev.Name < minNameSetting.Value__c) {
//US80608(rollback DE7583) 					minNameSetting.Value__c = ev.Name;
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				if(ev.Name > maxNameSetting.Value__c) {
//US80608(rollback DE7583) 					maxNameSetting.Value__c = ev.Name;
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			// it would be a serious bug not to be able to query at least one row...
//US80608(rollback DE7583) 			System.assert(queryRows > 0,'Limit exception: Unable to complete batch job');
//US80608(rollback DE7583) 			// find the opportunity split detail records that need to be deleted
//US80608(rollback DE7583) 			Set<Id> eventIds = new Set<Id>();
//US80608(rollback DE7583) 			for(Event__c event : events) {
//US80608(rollback DE7583) 				if(event.Opportunity__c != null) {
//US80608(rollback DE7583) 					eventIds.add(event.Id);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			List<SObject> oppSplitDetails = [
//US80608(rollback DE7583) 				SELECT Id
//US80608(rollback DE7583) 				FROM Opportunity_Split_Detail__c
//US80608(rollback DE7583) 				WHERE Opportunity__c IN :eventIdByOppId.keySet()
//US80608(rollback DE7583) 					AND Event__c NOT IN :eventIds
//US80608(rollback DE7583) 				LIMIT :queryRows ];
//US80608(rollback DE7583) 			// add the records to the queue so they may be deleted...
//US80608(rollback DE7583) 			queue.addAll(oppSplitDetails);
//US80608(rollback DE7583) 			if(queryRows > 0) {
//US80608(rollback DE7583) 				// find the next set of opportunity line items we should process
//US80608(rollback DE7583) 				List<OpportunityLineItem> lineItems = [
//US80608(rollback DE7583) 					SELECT
//US80608(rollback DE7583) 						OpportunityId,
//US80608(rollback DE7583) 						Opportunity.CurrencyIsoCode,
//US80608(rollback DE7583) 						Opportunity.StageName,
//US80608(rollback DE7583) 						Opportunity.CloseDate,
//US80608(rollback DE7583) 						TotalPrice,
//US80608(rollback DE7583) 						Entitle_To_Address__r.Country__c,
//US80608(rollback DE7583) 						Year1Amount__c,
//US80608(rollback DE7583) 						Year2Amount__c,
//US80608(rollback DE7583) 						Year3Amount__c,
//US80608(rollback DE7583) 						Year4Amount__c,
//US80608(rollback DE7583) 						Year5Amount__c,
//US80608(rollback DE7583) 						Year6Amount__c,
//US80608(rollback DE7583) 						Configured_SKU__c,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Id,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Primary_BU__c,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Secondary_BU__c,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Tertiary__c,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Quaternary_BU__c,
//US80608(rollback DE7583) 						PricebookEntry.Product2.Quinary_BU__c,
//US80608(rollback DE7583) 						LastModifiedDate
//US80608(rollback DE7583) 					FROM OpportunityLineItem
//US80608(rollback DE7583) 					WHERE OpportunityId in :eventIdByOppId.keySet()
//US80608(rollback DE7583) 						AND LastModifiedDate > :lineProcessingSetting.Value__c
//US80608(rollback DE7583) 						AND LastModifiedDate < :endTime
//US80608(rollback DE7583) 					ORDER BY LastModifiedDate
//US80608(rollback DE7583) 					LIMIT :queryRows ];
//US80608(rollback DE7583) 				lineProcessingSetting.Value__c = startTime;
//US80608(rollback DE7583) 				if(! lineItems.isEmpty()) {
//US80608(rollback DE7583) 					if(queryRows <= 0) {
//US80608(rollback DE7583) 						lineProcessingSetting.Value__c=lineItems.get(lineItems.size()-1).LastModifiedDate;
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 					for(OpportunityLineItem lineItem : lineItems) {
//US80608(rollback DE7583) 						// don't add the lines with the latest last modified date, as we
//US80608(rollback DE7583) 						// do not want to process those lines more than once.
//US80608(rollback DE7583) 						if(lineItem.LastModifiedDate != lineProcessingSetting.Value__c) {
//US80608(rollback DE7583) 							// Believe it or not, it is not problematic if no line items get added
//US80608(rollback DE7583) 							// at this point, because the batch job will get called in that case.
//US80608(rollback DE7583) 							queue.add(lineItem);
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			// Only add events being processed when no lineitems are being processed
//US80608(rollback DE7583) 			// as the records may be processed out of order.  If neccessary these
//US80608(rollback DE7583) 			// event updates will be completed in the finish method.
//US80608(rollback DE7583) 			if(queue.isEmpty()) {
//US80608(rollback DE7583) 				queue.addAll((List<SObject>)events);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		// we will need to re-enter if the query limit was exhausted
//US80608(rollback DE7583) 		processingSetting.Value__c = (queryRows <= 0);
//US80608(rollback DE7583) 		// otherwise use the remaining query rows to find old event records that can 
//US80608(rollback DE7583) 		// safely be deleted.
//US80608(rollback DE7583) 		if(! processingSetting.Value__c) {
//US80608(rollback DE7583) 			List<SObject> oevents = [
//US80608(rollback DE7583) 				select Id,
//US80608(rollback DE7583) 					Opportunity__c,
//US80608(rollback DE7583) 					Processed__c
//US80608(rollback DE7583) 				from Event__c
//US80608(rollback DE7583) 				where LastModifiedDate < :minProcessingSetting.Value__c.addDays(-7)
//US80608(rollback DE7583) 					and (Processed__c = true OR Opportunity__c = null)
//US80608(rollback DE7583) 				order by LastModifiedDate
//US80608(rollback DE7583) 				limit :queryRows ];
//US80608(rollback DE7583) 			queue.addAll(oevents);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		// we will always update the custom settings.  This has a disadvantage in that if
//US80608(rollback DE7583) 		// a record errors out there is no logic to retry.  However, the advantage is this 
//US80608(rollback DE7583) 		// makes sure we do not get stuck in reprocessing loops.
//US80608(rollback DE7583) 		Database.upsert(new List<DateTimeSetting__c>{minProcessingSetting,maxProcessingSetting,lineProcessingSetting},DateTimeSetting__c.Fields.Name,true);
//US80608(rollback DE7583) 		Database.upsert(new List<StringSetting__c>{minNameSetting,maxNameSetting},StringSetting__c.Fields.Name,true);
//US80608(rollback DE7583) 		Database.upsert(processingSizeSetting,LongSetting__c.Fields.Name,true);
//US80608(rollback DE7583) 		Database.upsert(processingSetting,BooleanSetting__c.Fields.Name,true);
//US80608(rollback DE7583) 		retryEvents(queue.isEmpty());
//US80608(rollback DE7583) 		return queue;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Execute method impl for Database.Batchable interface
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @param   bc batchable context
//US80608(rollback DE7583) 	 * @param   SObjects including opportunity line items, events, and opportunity split details
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global void execute(Database.BatchableContext bc, List<SObject> objects) {
//US80608(rollback DE7583) 		executeNoEmail(objects);

//US80608(rollback DE7583) 		// email any errors that resulted in an uncaught exception
//US80608(rollback DE7583) 		if(!errorList.isEmpty() && AbstractTrigger.isActive(EMAIL_PER_BATCH_KEY,true)) {
//US80608(rollback DE7583) 			super.finish(lookupJob(bc));
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}


//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Execute but don't send error emails
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @param   events
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global void executeNoEmail(List<SObject> objects) {
//US80608(rollback DE7583) 		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
//US80608(rollback DE7583) 		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
//US80608(rollback DE7583) 		List<SObject> deleteList = new List<SObject>();
//US80608(rollback DE7583) 		List<SObject> updateList = new List<SObject>();
//US80608(rollback DE7583) 		for(SObject o : objects) {
//US80608(rollback DE7583) 			if(o instanceof OpportunityLineItem) {
//US80608(rollback DE7583) 				lineItems.add((OpportunityLineItem)o);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			else if(o instanceof Event__c) {
//US80608(rollback DE7583) 				Event__c ev = (Event__c)o;
//US80608(rollback DE7583) 				if(ev.Processed__c == true || ev.Opportunity__c == null) {
//US80608(rollback DE7583) 					deleteList.add(o);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				else {
//US80608(rollback DE7583) 					ev.Processed__c = true;
//US80608(rollback DE7583) 					updateList.add(o);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			else {
//US80608(rollback DE7583) 				deleteList.add(o);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		try {
//US80608(rollback DE7583) 			try {
//US80608(rollback DE7583) 				try {
//US80608(rollback DE7583) 					if(! deleteList.isEmpty()) {
//US80608(rollback DE7583) 						for(Database.DeleteResult dr : Database.delete(deleteList,false)) {
//US80608(rollback DE7583) 							for(Database.Error e : dr.getErrors()) {
//US80608(rollback DE7583) 								errorList.add(e.getMessage());
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				catch(Exception ex1) {
//US80608(rollback DE7583) 					errorList.add('Caught Exception: '+ex1);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				finally {
//US80608(rollback DE7583) 					if(! lineItems.isEmpty()) {
//US80608(rollback DE7583) 						errorList.addAll(rebuildSplitDetails(lineItems));
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			catch(Exception ex2) {
//US80608(rollback DE7583) 				errorList.add('Caught Exception: '+ex2);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			finally {
//US80608(rollback DE7583) 				if(! updateList.isEmpty()) {
//US80608(rollback DE7583) 					for(Database.SaveResult sr : Database.update(updateList,false)) {
//US80608(rollback DE7583) 						for(Database.Error e : sr.getErrors()) {
//US80608(rollback DE7583) 							errorList.add(e.getMessage());
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		catch(Exception ex3) {
//US80608(rollback DE7583) 			errorList.add('Caught Exception: '+ex3);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * finish method
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @param job the async apex job
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	global override void finish(AsyncApexJob job) {
//US80608(rollback DE7583) 		if(processingSetting.Value__c != true) {
//US80608(rollback DE7583) 			executeNoEmail((List<SObject>)events);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		super.finish(job);
//US80608(rollback DE7583) 		retryEvents(true);
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	global static Map<String, String> isoCodeFieldMap {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(isoCodeFieldMap == null) {
//US80608(rollback DE7583) 				isoCodeFieldMap = new Map<String,String>();
//US80608(rollback DE7583) 				for(String fieldName : 
//US80608(rollback DE7583) 					Schema.SObjectType.Opportunity_Split_Detail__c.fields.getMap().keySet()) 
//US80608(rollback DE7583) 				{
//US80608(rollback DE7583) 					if(fieldName.length() > 3 
//US80608(rollback DE7583) 						&& fieldName.substring(3) == '_Conversion_Rate__c')
//US80608(rollback DE7583) 					{
//US80608(rollback DE7583) 						isoCodeFieldMap.put(fieldName.substring(0,3).toUpperCase(),fieldName);
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return isoCodeFieldMap;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		set;
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	/**
//US80608(rollback DE7583) 	 * Start method impl for Database.Batchable interface.
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 * @param   setOpportunityIds set<Id>
//US80608(rollback DE7583) 	 * @return  list<String> collection of error messages
//US80608(rollback DE7583) 	 *
//US80608(rollback DE7583) 	 */
//US80608(rollback DE7583) 	public List<String> rebuildSplitDetails(List<OpportunityLineItem> lineItems) {
//US80608(rollback DE7583) 		List<String> retval = new List<String>();
//US80608(rollback DE7583) 		if(! events.isEmpty()) {
//US80608(rollback DE7583) 			Set<Id> oppIds = new Set<Id>();
//US80608(rollback DE7583) 			Set<Date> closeDates = new Set<Date>();
//US80608(rollback DE7583) 			Date maxDate = null;
//US80608(rollback DE7583) 			for(OpportunityLineItem lineItem : lineItems) {
//US80608(rollback DE7583) 				oppIds.add(lineItem.OpportunityId);
//US80608(rollback DE7583) 				if(lineItem.Opportunity.CloseDate != null) {
//US80608(rollback DE7583) 					closeDates.add(lineItem.Opportunity.CloseDate);
//US80608(rollback DE7583) 					if(maxDate == null || maxDate < lineItem.Opportunity.CloseDate) {
//US80608(rollback DE7583) 						maxDate = lineItem.Opportunity.CloseDate;
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			Map<Id,List<OpportunityTeamMember>> oppTeamMembersByOppIdMap = new Map<Id,List<OpportunityTeamMember>>();
//US80608(rollback DE7583) 			for(OpportunityTeamMember otm : [
//US80608(rollback DE7583) 				SELECT
//US80608(rollback DE7583) 					OpportunityId,
//US80608(rollback DE7583) 					UserId,
//US80608(rollback DE7583) 					TeamMemberRole 
//US80608(rollback DE7583) 				FROM OpportunityTeamMember
//US80608(rollback DE7583) 				WHERE OpportunityId in :oppIds
//US80608(rollback DE7583) 					AND User.IsActive = true ] )
//US80608(rollback DE7583) 			{
//US80608(rollback DE7583) 				List<OpportunityTeamMember> otmList = oppTeamMembersByOppIdMap.get(otm.OpportunityId);
//US80608(rollback DE7583) 				if(otmList == null) {
//US80608(rollback DE7583) 					otmList = new List<OpportunityTeamMember>();
//US80608(rollback DE7583) 					oppTeamMembersByOppIdMap.put(otm.OpportunityId,otmList);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				otmList.add(otm);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			Map<Id,Map<Id,List<OpportunitySplit>>> oppSplitsByOwnerIdMap = new Map<Id,Map<Id,List<OpportunitySplit>>>();
//US80608(rollback DE7583) 			for(OpportunitySplit os : [
//US80608(rollback DE7583) 				SELECT
//US80608(rollback DE7583) 					OpportunityId,
//US80608(rollback DE7583) 					SplitAmount,
//US80608(rollback DE7583) 					SplitPercentage,
//US80608(rollback DE7583) 					SplitType.MasterLabel,
//US80608(rollback DE7583) 					SplitOwnerId,
//US80608(rollback DE7583) 					Country__c,
//US80608(rollback DE7583) 					Region__c,
//US80608(rollback DE7583) 					Sub_Region__c,
//US80608(rollback DE7583) 					Super_Region__c
//US80608(rollback DE7583) 				FROM OpportunitySplit
//US80608(rollback DE7583) 				WHERE OpportunityId IN :oppIds ] )
//US80608(rollback DE7583) 			{
//US80608(rollback DE7583) 				Map<Id,List<OpportunitySplit>> oppSplitsMap = oppSplitsByOwnerIdMap.get(os.OpportunityId);
//US80608(rollback DE7583) 				if(oppSplitsMap == null) {
//US80608(rollback DE7583) 					oppSplitsMap = new Map<Id,List<OpportunitySplit>>();
//US80608(rollback DE7583) 					oppSplitsByOwnerIdMap.put(os.OpportunityId,oppSplitsMap);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				List<OpportunitySplit> oppSplits = oppSplitsMap.get(os.SplitOwnerId);
//US80608(rollback DE7583) 				if(oppSplits == null) {
//US80608(rollback DE7583) 					oppSplits = new List<OpportunitySplit>();
//US80608(rollback DE7583) 					oppSplitsMap.put(os.SplitOwnerId,oppSplits);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 				oppSplits.add(os);
//US80608(rollback DE7583) 			}

//US80608(rollback DE7583) 			// get the array of most recent dated conversion rates
//US80608(rollback DE7583) 			Map<String,DatedConversionRate> mostRecentConversionRateMap = new Map<String,DatedConversionRate>();
//US80608(rollback DE7583) 			if(maxDate != null) {
//US80608(rollback DE7583) 				for(DatedConversionRate dcr : [
//US80608(rollback DE7583) 					select ConversionRate, IsoCode, StartDate, NextStartDate
//US80608(rollback DE7583) 					from DatedConversionRate
//US80608(rollback DE7583) 					where StartDate <= :maxDate and nextStartDate > :maxDate
//US80608(rollback DE7583) 						and IsoCode in :isoCodeFieldMap.keySet() ] ) 
//US80608(rollback DE7583) 				{
//US80608(rollback DE7583) 					mostRecentConversionRateMap.put(dcr.IsoCode,dcr);
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			Map<Date,Map<String,Decimal>> conversionMap2 = new Map<Date,Map<String,Double>>();
//US80608(rollback DE7583) 			if(!closeDates.isEmpty()) {
//US80608(rollback DE7583) 				Map<String, Map<Date, Double>> conversionMap = new DatedCurrencyConversion().getConversionRateMap(isoCodeFieldMap.keySet(),closeDates);
//US80608(rollback DE7583) 				for(String isoCode : isoCodeFieldMap.keySet()) {
//US80608(rollback DE7583) 					Map<Date,Double> ddMap = conversionMap.get(isoCode);
//US80608(rollback DE7583) 					DatedConversionRate dcr = mostRecentConversionRateMap.get(isoCode);
//US80608(rollback DE7583) 					if(ddMap != null || dcr != null) {
//US80608(rollback DE7583) 						for(Date d : closeDates) {
//US80608(rollback DE7583) 							Double value = null;
//US80608(rollback DE7583) 							if(ddMap != null) {
//US80608(rollback DE7583) 								value = ddMap.get(d);
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 							if(value == null && dcr != null && d >= dcr.StartDate) {
//US80608(rollback DE7583) 								value = dcr.ConversionRate.doubleValue();
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 							if(value != null) {
//US80608(rollback DE7583) 								Map<String,Double> sdMap = conversionMap2.get(d);
//US80608(rollback DE7583) 								if(sdMap == null) {
//US80608(rollback DE7583) 									sdMap = new Map<String,Decimal>();
//US80608(rollback DE7583) 									conversionMap2.put(d,sdMap);
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								sdMap.put(isoCode,Decimal.valueOf(value));
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}

//US80608(rollback DE7583) 			// use two different lists, so if we have to truncate we'll most likely remove ones without splits
//US80608(rollback DE7583) 			List<OpportunitySplit> oppSplitsNull = new List<OpportunitySplit>{null};
//US80608(rollback DE7583) 			List<Opportunity_Split_Detail__c> oppSplitDetails = new List<Opportunity_Split_Detail__c>();
//US80608(rollback DE7583) 			List<Opportunity_Split_Detail__c> oppSplitDetailsNoSplit = new List<Opportunity_Split_Detail__c>();
//US80608(rollback DE7583) 			for(OpportunityLineItem lineItem : lineItems) {
//US80608(rollback DE7583) 				Id eventId = eventIdByOppId.get(lineItem.OpportunityId);
//US80608(rollback DE7583) 				List<OpportunityTeamMember> otmList = oppTeamMembersByOppIdMap.get(lineItem.OpportunityId);
//US80608(rollback DE7583) 				if(eventId != null && otmList != null && ! otmList.isEmpty()) {
//US80608(rollback DE7583) 					Map<String,Decimal> exchangeRateMap = conversionMap2.get(lineItem.Opportunity.CloseDate);
//US80608(rollback DE7583) 					Map<Id,List<OpportunitySplit>> oppSplitsMap = oppSplitsByOwnerIdMap.get(lineItem.OpportunityId);
//US80608(rollback DE7583) 					for(OpportunityTeamMember otm : otmList){
//US80608(rollback DE7583) 						List<OpportunitySplit> oppSplits = oppSplitsNull;
//US80608(rollback DE7583) 						if(oppSplitsMap != null && oppSplitsMap.containsKey(otm.UserId)) {
//US80608(rollback DE7583) 							oppSplits = oppSplitsMap.get(otm.UserId);
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 						for(OpportunitySplit os : oppSplits) {
//US80608(rollback DE7583) 							Opportunity_Split_Detail__c osd = new Opportunity_Split_Detail__c(
//US80608(rollback DE7583) 								Team_Member_Role__c = otm.TeamMemberRole,
//US80608(rollback DE7583) 								CurrencyIsoCode = lineItem.Opportunity.CurrencyIsoCode,
//US80608(rollback DE7583) 								Entitle_To_Country__c = lineItem.Entitle_To_Address__r.Country__c,
//US80608(rollback DE7583) 								Event__c = eventId,
//US80608(rollback DE7583) 								Product__c = lineItem.PricebookEntry.Product2.Id,
//US80608(rollback DE7583) 								OwnerId = otm.UserId,
//US80608(rollback DE7583) 								Opportunity__c = lineItem.OpportunityId,
//US80608(rollback DE7583) 								Opportunity_Line_Item_Total_Price__c = lineItem.TotalPrice,
//US80608(rollback DE7583) 								Configured_SKU__c = lineItem.Configured_SKU__c,
//US80608(rollback DE7583) 								OpportunityLineItem__c = lineItem.Id,
//US80608(rollback DE7583) 								Total_Amount__c = 0,
//US80608(rollback DE7583) 								Split_Amount__c = 0,
//US80608(rollback DE7583) 								Split_Percent__c = 0,
//US80608(rollback DE7583) 								Year1_Amount__c = 0,
//US80608(rollback DE7583) 								Year2_Amount__c = 0,
//US80608(rollback DE7583) 								Year3_Amount__c = 0,
//US80608(rollback DE7583) 								Year4_Amount__c = 0,
//US80608(rollback DE7583) 								Year5_Amount__c = 0,
//US80608(rollback DE7583) 								Year6_Amount__c = 0 );
//US80608(rollback DE7583) 							if(lineItem.TotalPrice != 0){
//US80608(rollback DE7583) 								if(lineItem.PricebookEntry.Product2.Primary_BU__c != NULL) { //change in logic as per US60849
//US80608(rollback DE7583) 									osd.Primary_Business_Unit_Amount__c = (lineItem.PricebookEntry.Product2.Primary_BU__c * lineItem.TotalPrice)/100;
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								if(lineItem.PricebookEntry.Product2.Secondary_BU__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 									osd.Secondary_Business_Unit_Amount__c = (lineItem.PricebookEntry.Product2.Secondary_BU__c * lineItem.TotalPrice)/100;
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								if(lineItem.PricebookEntry.Product2.Tertiary__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 									osd.Tertiary_Business_Unit_Amount__c = (lineItem.PricebookEntry.Product2.Tertiary__c * lineItem.TotalPrice)/100;
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								if(lineItem.PricebookEntry.Product2.Quaternary_BU__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 									osd.Quaternary_Business_Unit_Amount__c = (lineItem.PricebookEntry.Product2.Quaternary_BU__c * lineItem.TotalPrice)/100;
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								if(lineItem.PricebookEntry.Product2.Quinary_BU__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 									osd.Quinary_Business_Unit_Amount__c = (lineItem.PricebookEntry.Product2.Quinary_BU__c * lineItem.TotalPrice)/100;
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 							if(exchangeRateMap != null && ! exchangeRateMap.isEmpty()){//lineItem.Opportunity.StageName == 'Closed Booked' && 
//US80608(rollback DE7583) 								for(String isoCode : isoCodeFieldMap.keySet()) {
//US80608(rollback DE7583) 									osd.put(isoCodeFieldMap.get(isoCode),exchangeRateMap.get(isoCode));
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 							List<Opportunity_Split_Detail__c> xoppSplitDetails = oppSplitDetailsNoSplit;
//US80608(rollback DE7583) 							if(os != null) {
//US80608(rollback DE7583) 								xoppSplitDetails = oppSplitDetails;
//US80608(rollback DE7583) 								osd.Sales_Incentive_Country__c = os.Country__c;
//US80608(rollback DE7583) 								osd.Split_Amount__c = os.SplitAmount;
//US80608(rollback DE7583) 								osd.Opportunity_Split_Type__c = os.SplitType.MasterLabel;
//US80608(rollback DE7583) 								if(os.SplitPercentage != null) {
//US80608(rollback DE7583) 									osd.Total_Amount__c = (lineItem.TotalPrice * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									osd.Split_Percent__c = os.SplitPercentage;
//US80608(rollback DE7583) 									if(lineItem.Year1Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year1_Amount__c = (lineItem.Year1Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 									if(lineItem.Year2Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year2_Amount__c = (lineItem.Year2Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 									if(lineItem.Year3Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year3_Amount__c = (lineItem.Year3Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 									if(lineItem.Year4Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year4_Amount__c = (lineItem.Year4Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 									if(lineItem.Year5Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year5_Amount__c = (lineItem.Year5Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 									if(lineItem.Year6Amount__c != NULL) {//change in logic as per US60849
//US80608(rollback DE7583) 										osd.Year6_Amount__c = (lineItem.Year6Amount__c * os.SplitPercentage)/100;
//US80608(rollback DE7583) 									}
//US80608(rollback DE7583) 								}
//US80608(rollback DE7583) 								osd.OpportunitySplit__c = os.Id;
//US80608(rollback DE7583) 								osd.Region__c = os.Region__c;
//US80608(rollback DE7583) 								osd.Sub_Region__c = os.Sub_Region__c;
//US80608(rollback DE7583) 								osd.Super_Region__c = os.Super_Region__c;
//US80608(rollback DE7583) 							}
//US80608(rollback DE7583) 							xoppSplitDetails.add(osd);
//US80608(rollback DE7583) 						}
//US80608(rollback DE7583) 					}
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			oppSplitDetails.addAll(oppSplitDetailsNoSplit);
//US80608(rollback DE7583) 			for(Integer i=oppSplitDetails.size(),dlimit=dmlRows;i > dlimit;) {
//US80608(rollback DE7583) 				retval.add('Too many split details: '+i);
//US80608(rollback DE7583) 				do {
//US80608(rollback DE7583) 					oppSplitDetails.remove(--i);
//US80608(rollback DE7583) 				} while(i > dlimit);
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			for(Database.SaveResult sr : Database.insert(oppSplitDetails, false)){
//US80608(rollback DE7583) 				for(Database.Error err : sr.getErrors()) {
//US80608(rollback DE7583) 					retval.add(err.getMessage());
//US80608(rollback DE7583) 				}
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		return retval;
//US80608(rollback DE7583) 	}
//US80608(rollback DE7583) }