trigger PPContentBatchStageTrigger on PP_ContentBatchStage__c (after update) {

	for (PP_ContentBatchStage__c batch : Trigger.new) {
		if (batch.Status__c == 'Ready' && Trigger.oldMap.get(batch.Id).Status__c == 'Pending') {

			//
			// cleanup scores from any prior run (if we are rerunning the same batch)
			//
			PP_ContentStage__c[] items = [select Id from PP_ContentStage__c where ContentBatch__c = :batch.Id];
			ID[] referenceIds = new List<ID>();
			for (PP_ContentStage__c item : items) {
				referenceIds.add(item.Id);
			}
			if (!referenceIds.isEmpty()) {
				PP_Scores__c[] scores = [select Id from PP_Scores__c where ContentRef__c in :referenceIds];
				delete scores;
				//PP_ItemAudit__c[] audits = [select Id from PP_ItemAudit__c where Related_Id__c in :referenceIds];
				//delete audits;
			}

			PPContentPlugin plugin = new PPContentPlugin();
			plugin.scoreBatch(batch.Id);
			//batch.Status__c = 'Complete';
			//update batch;
		}
	}
	
}