trigger MA_CreditCheck_Expiration on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'CreditCheck_Expiration',new CreditCheck_Expiration());
}