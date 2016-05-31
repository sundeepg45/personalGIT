trigger MA_AccountHierarchy_Batchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'AccountHierarchy_Batchable',new AccountHierarchy_Batchable());
}