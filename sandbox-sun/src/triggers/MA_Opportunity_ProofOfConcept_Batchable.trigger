trigger MA_Opportunity_ProofOfConcept_Batchable on MonitoredActivity__c (after insert) {
	DailyScheduler.injectBatchable(Trigger.new,'Opportunity_ProofOfConcept_Batchable',new Opportunity_ProofOfConcept_Batchable());
}