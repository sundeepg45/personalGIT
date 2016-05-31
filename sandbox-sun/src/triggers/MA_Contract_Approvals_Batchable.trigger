trigger MA_Contract_Approvals_Batchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'Contract_Approvals_Batchable',new Contract_Approvals_Batchable());
}