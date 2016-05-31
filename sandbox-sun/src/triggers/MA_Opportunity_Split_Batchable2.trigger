trigger MA_Opportunity_Split_Batchable2 on MonitoredActivity__c (after insert) {
//US80608(rollback DE7583)    AbstractBatchable batchable = new Opportunity_Split_Batchable2();
//US80608(rollback DE7583)    String subject = DailyScheduler.injectBatchable(Trigger.new,'Opportunity_Split_Batchable2',batchable);
//US80608(rollback DE7583)    if(subject != null) {
//US80608(rollback DE7583)        DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
//US80608(rollback DE7583)    }
}