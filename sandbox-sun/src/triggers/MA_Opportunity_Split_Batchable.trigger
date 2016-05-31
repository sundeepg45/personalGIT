trigger MA_Opportunity_Split_Batchable on MonitoredActivity__c (after insert) {
    DailyScheduler.injectBatchable(Trigger.new,'Opportunity_Split_Batchable',new Opportunity_Split_Batchable());
}