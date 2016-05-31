trigger MA_OpportunityOwner_Batchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new OpportunityOwner_Batchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'OpportunityOwner_Batchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}