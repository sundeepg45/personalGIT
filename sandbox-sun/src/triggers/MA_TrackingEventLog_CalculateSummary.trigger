trigger MA_TrackingEventLog_CalculateSummary on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'TrackingEventLog_CalculateSummary',new TrackingEventLog_CalculateSummary());
}