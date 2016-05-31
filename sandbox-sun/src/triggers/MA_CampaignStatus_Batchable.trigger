trigger MA_CampaignStatus_Batchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'CampaignStatus_Batchable',new CampaignStatus_Batchable());
}