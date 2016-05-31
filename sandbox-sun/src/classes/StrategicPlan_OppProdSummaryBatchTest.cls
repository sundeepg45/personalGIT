/**
 * This is the test class for StrategicPlan_OppProdSummaryBatch.
 *
 * @version 2013-08-08
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-08 - Renamed OpportunityTriggerBeforeTest to OpportunityTriggerBefore2Test
 * 2013-05-23 - Updated test object references
 * 2013-04-19 - Created
 */
@isTest
private class StrategicPlan_OppProdSummaryBatchTest {
	static StrategicPlan_SolutionOpportunity__c solutionOpportunity {
		get {
			if(solutionOpportunity == null) {
				StrategicPlan_Solution__c solution = StrategicPlan_SolutionControllerExtnTest.solution;
				Opportunity opportunity = OpportunityTriggerBefore2Test.opportunity;
				opportunity.AccountId = solution.StrategicPlan__r.Account__c;
				solutionOpportunity = new StrategicPlan_SolutionOpportunity__c(
					Opportunity__c=OpportunityTriggerBefore2Test.opportunityId,
					StrategicPlan_Solution__c=StrategicPlan_SolutionControllerExtnTest.solutionId);
				insert solutionOpportunity;
				solutionOpportunity.Opportunity__r = opportunity;
				solutionOpportunity.StrategicPlan_Solution__r = solution;
			}
			return solutionOpportunity;
		}
		set;
	}

	static OpportunityProductSummary__c opportunityProductSummary {
		get {
			if(opportunityProductSummary == null) {
				Product2 product = OpportunityTriggerBefore2Test.product;
				opportunityProductSummary = new OpportunityProductSummary__c(
					Amount__c = 100.0,
					AmountUSD__c = 100.0,
					CurrencyIsoCode = 'USD',
					DateCaptured__c = System.today(),
					ExternalId__c = ''+solutionOpportunity.Opportunity__c+product.Id,
//					Forecast_Category__c = solutionOpportunity.Opportunity__r.ForecastCategoryName,
//					Stage__c = solutionOpportunity.Opportunity__r.StageName,
					Opportunity__c = solutionOpportunity.Opportunity__c,
					Product__c = product.Id );
				insert opportunityProductSummary;
				opportunityProductSummary.Opportunity__r = solutionOpportunity.Opportunity__r;
				opportunityProductSummary.Product__r = product;
			}
			return opportunityProductSummary;
		}		
	}

	static StrategicPlan_OppProdSummaryBatch createBatch(OpportunityProductSummary__c o) {
		return new StrategicPlan_OppProdSummaryBatch();
	}

	@isTest
	static void startTest() {
		StrategicPlan_OppProdSummaryBatch batch = createBatch(opportunityProductSummary);
		Test.startTest();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batch.start(null));
		ssc.setPageSize(100);
		List<OpportunityProductSummary__c> records = ssc.getRecords();
		Test.stopTest();
		System.assert(records.size() > 0, 'failed to find records');
	}

	@isTest
	static void executeTest() {
		StrategicPlan_OppProdSummaryBatch batch = createBatch(opportunityProductSummary);
		List<OpportunityProductSummary__c> records = [
			select 
				Amount__c,
				AmountUSD__c,
				CurrencyIsoCode,
				DateCaptured__c,
				Opportunity__c,
				Opportunity__r.ForecastCategoryName,
				Opportunity__r.StageName,
				Product__c
			from OpportunityProductSummary__c
			where Id = :opportunityProductSummary.Id ];
		System.assertEquals(opportunityProductSummary.Id,records[0].Id);
		Test.startTest();
		batch.execute(null,records);
		Test.stopTest();
		System.assert(batch.errorMessages.isEmpty(),'Found error messages '+batch.errorMessages);
		System.assertEquals(1,batch.recordCount);
		System.assertEquals(0,batch.failureCount);
		List<StrategicPlan_OppProdSummary__c> summaries = [
			select StrategicPlan__c, Product__c 
			from StrategicPlan_OppProdSummary__c 
			where StrategicPlan__c = :solutionOpportunity.StrategicPlan_Solution__r.StrategicPlan__c ];
		System.assertEquals(1,summaries.size());
		System.assertEquals(solutionOpportunity.StrategicPlan_Solution__r.StrategicPlan__c,summaries[0].StrategicPlan__c);
		System.assertNotEquals(null,summaries[0].Product__c);
		// delete test
		records[0].DateCaptured__c = system.today().addDays(-1);
		batch.execute(null,records);
		records = [
			select Id
			from OpportunityProductSummary__c
			where Id = :opportunityProductSummary.Id ];
		System.assertEquals(0,records.size());
		System.assert(batch.errorMessages.isEmpty(),'Found error messages '+batch.errorMessages);
	}

	@isTest
	static void insertSummariesFailureTest() {
		List<StrategicPlan_OppProdSummary__c> summaries = new List<StrategicPlan_OppProdSummary__c>{
			new StrategicPlan_OppProdSummary__c() };
		StrategicPlan_OppProdSummaryBatch batch = new StrategicPlan_OppProdSummaryBatch();
		batch.insertSummaries(summaries);
		System.assertEquals(1,batch.recordCount);
		System.assertEquals(1,batch.failureCount);
		System.assertEquals(1,batch.errorMessages.size());
	}

	// strictly coverage test
	@isTest
	static void finishFailureTest() {
		Database.BatchableContext bc = null;
		StrategicPlan_OppProdSummaryBatch batch = new StrategicPlan_OppProdSummaryBatch();
		try {
			batch.finish(bc);
		}
		catch(Exception ignored) {}
	}

	// strictly coverage test
	@isTest
	static void finishTest() {
		StrategicPlan_OppProdSummaryBatch batch = new StrategicPlan_OppProdSummaryBatch();
		batch.errorMessages.add('anything');
		Id jobId = null;
		batch.finish(jobId);
	}
}