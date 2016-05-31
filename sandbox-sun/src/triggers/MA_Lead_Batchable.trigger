trigger MA_Lead_Batchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new Lead_Batchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'Lead_Batchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}