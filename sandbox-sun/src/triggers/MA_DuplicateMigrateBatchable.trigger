trigger MA_DuplicateMigrateBatchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new DuplicateMigrateBatchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'DuplicateMigrateBatchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}