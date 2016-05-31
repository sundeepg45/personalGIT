trigger MA_AddChatterGroupMembersBatchable on MonitoredActivity__c (after insert) {
    DailyScheduler.injectBatchable(Trigger.new,'AddChatterGroupMembersBatchable',new AddChatterGroupMembersBatchable());
}