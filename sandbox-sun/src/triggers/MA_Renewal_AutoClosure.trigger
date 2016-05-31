trigger MA_Renewal_AutoClosure on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'Renewal_AutoClosure',new Renewal_AutoClosure());
}