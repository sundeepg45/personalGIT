trigger MA_AccountReadOnly_Batchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'AccountReadOnly_Batchable',new AccountReadOnly_Batchable());
}