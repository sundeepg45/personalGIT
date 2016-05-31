trigger MA_CampaignTagsDeleteBatchable on MonitoredActivity__c (after insert) {
    DailyScheduler.injectBatchable(Trigger.new,'CampaignTagsDeleteBatchable',new CampaignTagsDeleteBatchable());
}