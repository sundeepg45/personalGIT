trigger PPBatchStageTrigger on PP_InboundBatchStage__c (after update) {

	for (PP_InboundBatchStage__c batch : Trigger.new) {
		if (batch.Status__c == 'Ready' && Trigger.oldMap.get(batch.Id).Status__c == 'Pending') {
			
			//
			// cleanup scores from any prior run (if we are rerunning the same batch)
			//
			PP_InboundBatchItemStage__c[] items = [
				select	Id, First_Name__c, Last_Name__c, Partner__c, Email__c, Federation_Id__c, Create_Contact__c
				from	PP_InboundBatchItemStage__c
				where	InboundBatch__c = :batch.Id
			];
			ID[] referenceIds = new List<ID>();
			for (PP_InboundBatchItemStage__c item : items) {
				referenceIds.add(item.Id);
			}
			if (!referenceIds.isEmpty()) {
				PP_Scores__c[] scores = [select Id from PP_Scores__c where BatchItemStageRef__c in :referenceIds];
				delete scores;
				//PP_ItemAudit__c[] audits = [select Id from PP_ItemAudit__c where Related_Id__c in :referenceIds];
				//delete audits;
			}
			
			//
			// go through and create contacts as needed
			//
			Contact[] newcontacts = new List<Contact>();
			for (PP_InboundBatchItemStage__c item : items) {
				if (item.Create_Contact__c) {
					Contact c = new Contact();
					c.FirstName = item.First_Name__c;
					c.LastName = item.Last_Name__c;
					c.AccountId = item.Partner__c;
					c.Email = item.Email__c;
					c.LoginName__c = item.Federation_Id__c;
					c.Origination_Type__c = 'CSV Load';
					c.Origination_Name__c = batch.Name;
					newcontacts.add(c);
				}
			}
			
			//
			// After inserting, update the original batch item with the new contact.
			// This way we won't try and repeat the create operation on a rerun
			//
			if (newcontacts.size() > 0) {
				insert newcontacts;

				PP_InboundBatchItemStage__c[] updateditems = new List<PP_InboundBatchItemStage__c>();
				for (PP_InboundBatchItemStage__c item : items) {
					if (item.Create_Contact__c == false) continue;
					
					for (Contact c : newcontacts) {
						if (c.LoginName__c == item.Federation_Id__c) {
							item.Create_Contact__c = false;
							item.Contact__c = c.Id;
							updateditems.add(item);
						}
					}
				}
				if (updateditems.size() > 0) {
					update updateditems;
				}
			}

			PPBatchPlugin plugin = new PPBatchPlugin();
			plugin.scoreBatch(batch.Id);
			//batch.Status__c = 'Complete';
			//update batch;
		}
	}
}