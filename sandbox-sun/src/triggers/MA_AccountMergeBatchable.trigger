trigger MA_AccountMergeBatchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new AccountMergeBatchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'AccountMergeBatchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}