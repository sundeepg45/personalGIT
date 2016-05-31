trigger MA_StrategicPlan_OppProdSummary on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'StrategicPlan_OppProdSummary',new StrategicPlan_OppProdSummaryBatch());
}