/**
 * This is the test class for OpportunityProductSummaryBatch.
 *
 * @version 2013-08-08
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-08 - Changed OpportunityTriggerBeforeTest to OpportunityTriggerBefore2Test
 * 2013-04-19 - Created
 */
@isTest
private class OpportunityProductSummaryBatchTest {
	static StrategicPlan_SolutionOpportunity__c solutionOpportunity {
		get {
			if(solutionOpportunity == null) {
				StrategicPlan_Solution__c solution = StrategicPlan_SolutionControllerExtnTest.solution; 
				if(solution.Id == null) {
					insert solution;
				}
				Opportunity opportunity = OpportunityTriggerBefore2Test.opportunity;
				opportunity.AccountId = solution.StrategicPlan__r.Account__c;
				opportunity.CurrencyIsoCode = 'EUR';
				OpportunityLineItem lineItem = OpportunityTriggerBefore2Test.opportunityLineItemGlobal;
				solutionOpportunity = new StrategicPlan_SolutionOpportunity__c(
					Opportunity__c=lineItem.OpportunityId,
					StrategicPlan_Solution__c=solution.Id);
				insert solutionOpportunity;
				solutionOpportunity.Opportunity__r = opportunity;
				solutionOpportunity.StrategicPlan_Solution__r = solution;
			}
			return solutionOpportunity;
		}
		set;
	}

	static OpportunityProductSummaryBatch createBatch(StrategicPlan_SolutionOpportunity__c o) {
		return new OpportunityProductSummaryBatch();
	}

	@isTest(SeeAllData = true)
	static void startTest() {
		OpportunityProductSummaryBatch batch = createBatch(solutionOpportunity);
		Test.startTest();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batch.start(null));
		ssc.setPageSize(100);
		List<StrategicPlan_SolutionOpportunity__c> records = ssc.getRecords();
		Test.stopTest();
		System.assert(records.size() > 0, 'failed to find records');
	}

	@isTest(SeeAllData = true)
	static void executeTest() {
		OpportunityProductSummaryBatch batch = createBatch(solutionOpportunity);
		List<StrategicPlan_SolutionOpportunity__c> records = [
			select 
				Opportunity__r.Amount,
				Opportunity__r.CloseDate,
				Opportunity__r.CurrencyIsoCode,
				Opportunity__r.ForecastCategoryName,
				Opportunity__r.StageName
			from StrategicPlan_SolutionOpportunity__c
			where Id = :solutionOpportunity.Id ];
		System.assertEquals(solutionOpportunity.Id,records[0].Id);
		Test.startTest();
		batch.execute(null,records);
		System.assert(batch.errorMessages.isEmpty(),'Found error messages '+batch.errorMessages);
		System.assertEquals(1,batch.recordCount);
		System.assertEquals(0,batch.failureCount);
		List<OpportunityProductSummary__c> summaries = [
			select
				Opportunity__c,
				Product__c
			from OpportunityProductSummary__c
			where Opportunity__c = :solutionOpportunity.Opportunity__c ];
		System.assertEquals(1,summaries.size());
		System.assertEquals(solutionOpportunity.Opportunity__c,summaries[0].Opportunity__c);
		System.assertNotEquals(null,summaries[0].Product__c);
		delete [select Id from OpportunityLineItem where Opportunity.Id = :solutionOpportunity.Opportunity__c];
		summaries = batch.createSummaries(records);
		Test.stopTest();
		System.assertEquals(1,summaries.size());
		System.assertEquals(solutionOpportunity.Opportunity__c,summaries[0].Opportunity__c);
		System.assertEquals(null,summaries[0].Product__c);
	}

	@isTest
	static void upsertSummariesFailureTest() {
		List<OpportunityProductSummary__c> summaries = new List<OpportunityProductSummary__c>{
			new OpportunityProductSummary__c() };
		OpportunityProductSummaryBatch batch = new OpportunityProductSummaryBatch();
		batch.upsertSummaries(summaries);
		System.assertEquals(1,batch.recordCount);
		System.assertEquals(1,batch.failureCount);
		System.assertEquals(1,batch.errorMessages.size());
	}

	// strictly coverage test
	@isTest
	static void finishFailureTest() {
		Database.BatchableContext bc = null;
		OpportunityProductSummaryBatch batch = new OpportunityProductSummaryBatch(); 
		try {
			batch.finish(bc);
		}
		catch(Exception ignored) {}
	}

	// strictly coverage test
	@isTest
	static void finishTest() {
		OpportunityProductSummaryBatch batch = new OpportunityProductSummaryBatch(); 
		batch.errorMessages.add('anything');
		Id jobId = null;
		batch.finish(jobId);
	}
}