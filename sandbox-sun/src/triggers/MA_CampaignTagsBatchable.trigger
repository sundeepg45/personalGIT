trigger MA_CampaignTagsBatchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'CampaignTagsBatchable',new CampaignTagsBatchable());
}