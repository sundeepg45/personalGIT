trigger MA_ProcessInstance_Batchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new ProcessInstance_Batchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'ProcessInstance_Batchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}