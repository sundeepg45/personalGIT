trigger MA_Lead_StatusUpdate on MonitoredActivity__c (after insert) {
//depreciated	DailyScheduler.injectBatchable(Trigger.new,'Lead_StatusUpdate',new Lead_StatusUpdate());
}