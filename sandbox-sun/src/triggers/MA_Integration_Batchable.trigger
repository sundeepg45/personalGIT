trigger MA_Integration_Batchable on MonitoredActivity__c (after insert) {
    AbstractBatchable batchable = new Integration_Batchable();
    String subject = DailyScheduler.injectBatchable(Trigger.new,'Integration_Batchable',batchable);
    if(subject != null) {
        DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
    }
}