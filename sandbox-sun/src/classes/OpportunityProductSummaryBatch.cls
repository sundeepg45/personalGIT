/**
 * This class schedules creating aggregations of data for opportunities linked
 * to StrategicPlan_Solution__c objects.
 *
 * This job is scheduled with the Daily Scheduler.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-18
 *
 * 2013-04-18 - Created
 */
global class OpportunityProductSummaryBatch implements Database.Batchable<SObject>, Database.Stateful {
	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'OppProdSummary.LastProcessed';
	/** Used to keep track of the date on which the data was captured. */
	global Date dateCaptured = system.today();
	/** Error messages */
	global List<String> errorMessages = new List<String>();
	/** Number of processed records */
	global Integer recordCount = 0;
	/** Number of processed records that failed */
	global Integer failureCount = 0;
	/** Keep track of the lastProcessedDateTime */
	global DateTime lastProcessedDateTime = DateTime.newInstance(0L);

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @param	strategic plan solution opportunity objects
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null) {
			lastProcessedDateTime = lastProcessed.Value__c;
		}
		final DateTime lpt = lastProcessedDateTime;
		lastProcessedDateTime = DateTime.now();
// to do: We really only want to look at update records, but to do that
// we need a way to detect if a product has been removed from an opportunity
// so the obsolete record can be purged.  Purhaps a delete trigger on the line item?
		return Database.getQueryLocator([
			select 
				Opportunity__r.Amount,
				Opportunity__r.CloseDate,
//				Opportunity__r.ForecastCategoryName,
//				Opportunity__r.StageName,
				Opportunity__r.CurrencyIsoCode
			from StrategicPlan_SolutionOpportunity__c
//			where LastModifiedDate >= :lpt
//				or Opportunity__r.LastModifiedDate >= :lpt 
				]);
	}

	global Double getConversionRate(Map<String, Map<Date, Double>> conversionMap,Opportunity opp,boolean ignoreOppAmount) {
		Double conversionRate = 1.0;
		if(conversionMap != null && opp.CurrencyIsoCode != 'USD' && (ignoreOppAmount || opp.Amount !=0.0)) {
			conversionRate = 0.0;
			Map<Date, Double> datedMap = conversionMap.get(opp.CurrencyIsoCode);
			if(datedMap != null) {
				Double xconversionRate = datedMap.get(opp.CloseDate);
				if(xconversionRate != null) {
					conversionRate = xconversionRate;
				}
			}
		}
		return conversionRate;
	}

	/**
	 * Create a list of OpportunityProductSummary__c records from a given list of StrategicPlan_SolutionOpportunity__c reords.
	 * 
	 * @param	solutionOpportunities strategic plan solution opportunity objects
	 * @return list of OpportunityProductSummary__c records
	 */
	global List<OpportunityProductSummary__c> createSummaries(List<StrategicPlan_SolutionOpportunity__c> solutionOpportunities) {
		Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
		Set<String> isoCodes = new Set<String>();
		Set<Date> dates = new Set<Date>();
		for(StrategicPlan_SolutionOpportunity__c o : solutionOpportunities) {
			opportunityMap.put(o.Opportunity__c,o.Opportunity__r);
			if(o.Opportunity__r.CurrencyIsoCode != 'USD') {
				dates.add(o.Opportunity__r.CloseDate);
				isoCodes.add(o.Opportunity__r.CurrencyIsoCode);
			}
		}
		Map<String, Map<Date, Double>> conversionMap = null;
		if(! dates.isEmpty()) {
			conversionMap = new DatedCurrencyConversion().getConversionRateMap(isoCodes,dates);
		}
		Set<Id> opportunityIdsWithProducts = new Set<Id>();
		List<OpportunityProductSummary__c> summaries = new List<OpportunityProductSummary__c>();
		Opportunity opp = null;
		OpportunityProductSummary__c summary = null;
		Double conversionRate = 0.0;
		for(OpportunityLineItem lineItem : [
			select
				OpportunityId,
				PricebookEntry.Product2Id,
				TotalPrice
			from OpportunityLineItem
			where OpportunityId in :opportunityMap.keySet()
			order by OpportunityId, PricebookEntry.Product2Id ])
		{
			System.debug('lineItem='+lineItem);
			if(lineItem.TotalPrice != null) {
				String externalId = ''+lineItem.OpportunityId+lineItem.PricebookEntry.Product2Id;
				if(summary == null || summary.ExternalId__c != externalId) {
					Opportunity xopp = opportunityMap.remove(lineItem.OpportunityId);
					if(xopp != null) {
						opp = xopp;
					}
					conversionRate = getConversionRate(conversionMap,opp,true);
					summary = new OpportunityProductSummary__c(
						Amount__c=0.0,
						CurrencyIsoCode = opp.CurrencyIsoCode,
						ExternalId__c = externalId,
						DateCaptured__c=dateCaptured,
//						Forecast_Category__c=opp.ForecastCategoryName,
//						Stage__c=opp.StageName
						Opportunity__c = lineItem.OpportunityId,
						Product__c = lineItem.PricebookEntry.Product2Id );
					summaries.add(summary);
				}
				summary.Amount__c += lineItem.TotalPrice;
				if(conversionRate != 0.0) {
					summary.AmountUSD__c = summary.Amount__c / conversionRate;
				}
				System.debug('summary='+summary);
			}
		}
		// now add records for opportunities without products
		for(Opportunity xopp : opportunityMap.values()) {
			if(xopp.Amount != null) {
				summary = new OpportunityProductSummary__c(
					Amount__c=xopp.Amount,
					CurrencyIsoCode = xopp.CurrencyIsoCode,
					ExternalId__c = ''+xopp.Id,
					DateCaptured__c=dateCaptured,
//					Forecast_Category__c=xopp.ForecastCategoryName,
//					Stage__c=xopp.StageName,
					Opportunity__c = xopp.Id );
				conversionRate = getConversionRate(conversionMap,xopp,false);
				if(conversionRate != 0.0) {
					summary.AmountUSD__c = summary.Amount__c / conversionRate;
				}
				summaries.add(summary);
			}
		}
		// zero is the same for all currencies
		for(OpportunityProductSummary__c s : summaries) {
			if(s.Amount__c == 0.0) {
				s.AmountUSD__c = 0.0;
			}
		}
		return summaries;
	}

	/**	
	 * Upsert the list of OpportunityProductSummary__c records
	 *
	 * @param summaries
	 */
	global void upsertSummaries(List<OpportunityProductSummary__c> summaries) {
		// Use an upsert to update existing records, as we don't need to maintain a history
		// at the opportunity level, only collect current values.
		for(Database.UpsertResult r : Database.upsert(summaries,OpportunityProductSummary__c.Fields.ExternalId__c,false)) {
			OpportunityProductSummary__c summary = summaries.remove(0);
			recordCount++;
			if(! r.isSuccess()) {
				failureCount++;
				for(Database.Error e : r.getErrors()) {
					errorMessages.add('Failed to upsert '+summary+': '+e);
				}
			}
		}
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	bc
	 * @param	solutionOpportunities strategic plan solution opportunity objects
	 */
	global void execute(Database.BatchableContext bc, List<StrategicPlan_SolutionOpportunity__c> solutionOpportunities) {
		upsertSummaries(createSummaries(solutionOpportunities));
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param bc
	 */
	global void finish(Database.BatchableContext bc) {
		finish(bc.getJobId());
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param jobId
	 */
	global void finish(Id jobId) {
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed == null) {
			lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
		}
		lastProcessed.Value__c = lastProcessedDateTime;
		try {
			upsert lastProcessed;
		}
		catch(Exception e) {
			errorMessages.add('Failed to update lastProcessed '+e);
		}
		// query the AsyncApexJob object to retrieve the current job's information.
		AsyncApexJob job = new AsyncApexJob();
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
		if(! errorMessages.isEmpty() || job.Id == null || job.NumberOfErrors == null || job.NumberOfErrors > 0) {
			// Send an email to notify me of the jobs status
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'Opportunity Product Summary Update ' + job.Status +' processed '+recordCount+'records with '+failureCount+' failures running as '+UserInfo.getUserName());
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