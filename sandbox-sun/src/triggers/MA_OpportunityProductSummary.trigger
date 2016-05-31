trigger MA_OpportunityProductSummary on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'OpportunityProductSummary',new OpportunityProductSummaryBatch());
}