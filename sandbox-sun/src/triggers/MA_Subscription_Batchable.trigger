trigger MA_Subscription_Batchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new Subscription_Batchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'Subscription_Batchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}