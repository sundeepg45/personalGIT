trigger MA_Order_Opportunity_Batchable on MonitoredActivity__c (after insert) {
	AbstractBatchable batchable = new Order_Opportunity_Batchable();
	String subject = DailyScheduler.injectBatchable(Trigger.new,'Order_Opportunity_Batchable',batchable);
	if(subject != null) {
		DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
	}
}