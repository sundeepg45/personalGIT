/**
 * This class aggregates the OpportunityProductSummary__c objects based on
 * on linked StrategicPlan__c objects.
 *
 * This job is scheduled with the Daily Scheduler.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-25
 * 2013-04-25 - Removed Stage__c and Forecast_Name__c from the OpportunityProductSummary__c record
 * 2013-04-18 - Created
 */
global class StrategicPlan_OppProdSummaryBatch implements Database.Batchable<SObject>, Database.Stateful {
	global Date dateCaptured = system.today();
	global List<String> errorMessages = new List<String>();
	global Integer recordCount = 0;
	global Integer failureCount = 0;

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	bc
	 * @return	list of Opportunity Product Summary objects
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		Integer xlimit = 0;
		if([
			select count()
			from StrategicPlan_OppProdSummary__c
			where DateCaptured__c = :dateCaptured
			limit 1 ] == 0)
		{
			xlimit = Limits.getLimitQueryLocatorRows();
		}
		return Database.getQueryLocator([
			select 
				Amount__c,
				AmountUSD__c,
				CurrencyIsoCode,
				DateCaptured__c,
//				Forecast_Category__c,
//				Stage__c
				Opportunity__c,
				Opportunity__r.ForecastCategoryName,
				Opportunity__r.StageName,
				Product__c
			from OpportunityProductSummary__c
			order by DateCaptured__c desc,
				CurrencyIsoCode,
				Opportunity__r.ForecastCategoryName,
				Opportunity__r.StageName,
				Product__c,
				Opportunity__c
			limit :xlimit]);
	}

	/**	
	 * Insert the list of StrategicPlan_OppProdSummary__c records.
	 *
	 * @param summaries to insert
	 */
	global void insertSummaries(List<StrategicPlan_OppProdSummary__c> summaries) {
		summaries = new List<StrategicPlan_OppProdSummary__c>(summaries);
		for(Database.SaveResult r : Database.insert(summaries,false)) {
			StrategicPlan_OppProdSummary__c ops = summaries.remove(0);
			recordCount++;
			if(! r.isSuccess()) {
				failureCount++;
				for(Database.Error e : r.getErrors()) {
					errorMessages.add('Failed to insert '+ops+': '+e);
				}
			}
		}
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	bc
	 * @param	opportunityProductSummaries list of Opportunity Product Summary objects
	 */
	global void execute(Database.BatchableContext bc, List<OpportunityProductSummary__c> opportunityProductSummaries) {
		List<OpportunityProductSummary__c> deleteList = new List<OpportunityProductSummary__c>();
		Set<Id> oppIds = new Set<Id>();
		for(OpportunityProductSummary__c o : opportunityProductSummaries) {
			if(dateCaptured.daysBetween(o.DateCaptured__c) == 0) {
				oppIds.add(o.Opportunity__c);
			}
			else {
				deleteList.add(o);
			}
		}
		Map<Id,Id> planIdMap = new Map<Id,Id>();
		for(StrategicPlan_SolutionOpportunity__c spso : [
			select
				Opportunity__c,
				StrategicPlan_Solution__r.StrategicPlan__c
			from StrategicPlan_SolutionOpportunity__c
			where Opportunity__c in :oppIds ])
		{
			planIdMap.put(spso.Opportunity__c,spso.StrategicPlan_Solution__r.StrategicPlan__c);
		}
		Map<String,StrategicPlan_OppProdSummary__c> opsMap = new Map<String,StrategicPlan_OppProdSummary__c>();
		for(OpportunityProductSummary__c o : opportunityProductSummaries) {
			if(o.DateCaptured__c.daysBetween(dateCaptured) == 0) {
				Id planId = planIdMap.get(o.Opportunity__c);
				if(planId != null) {
					String key = planId+o.CurrencyIsoCode+o.Opportunity__r.StageName+o.Product__c+o.Opportunity__r.ForecastCategoryName;
					StrategicPlan_OppProdSummary__c ops = opsMap.get(key);
					if(ops == null) {
						ops = new StrategicPlan_OppProdSummary__c(
							Amount__c = 0.0,
							AmountUSD__c = 0.0,
							CurrencyIsoCode = o.CurrencyIsoCode,
							Forecast_Category__c = o.Opportunity__r.ForecastCategoryName,
							Product__c = o.Product__c,
							Stage__c = o.Opportunity__r.StageName,
							StrategicPlan__c = planId );
						opsMap.put(key,ops);
					}
					ops.Amount__c += o.Amount__c;
					if(o.AmountUSD__c == null) {
						ops.AmountUSD__c = null;
					}
					if(ops.AmountUSD__c != null) {
						ops.AmountUSD__c += o.AmountUSD__c;
					}
				}
			}
		}
		planIdMap = null;

		// Insert new records
		insertSummaries(opsMap.values());
		opsMap = null;

		// now do the deletes
		if(! deleteList.isEmpty()) {
			Database.delete(deleteList,false);
		}
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
			mail.setSubject( 'Strategic Plan Opp Prod Summary Update ' + job.Status +' processed '+recordCount+'records with '+failureCount+' failures running as '+UserInfo.getUserName());
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