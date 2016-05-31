@isTest
private class PPContentBatchStageTriggerTest {

	static testmethod void simpleTest() {
		PP_ContentBatchStage__c batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		
		PP_ContentStage__c c1 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c1.Contact__c = [select Id from Contact where Account.isPartner = True and Account.Global_Region__c = 'NA' limit 1].Id;
		ContentDocument cv = [select Id from ContentDocument limit 1];
		c1.ContentID__c = cv.Id;
		insert c1;

		PP_Catalog__c cat = new PP_Catalog__c();
		cat.Global_Region__c = 'NA';
		insert cat;

		PP_Content__c pc = new PP_Content__c();
		pc.Full_Points__c = 5;
		pc.PP_Catalog__c = cat.Id;
		pc.DocumentId__c = cv.Id;
		insert pc;
		
		batch.Status__c = 'Ready';
		update batch;

		PP_Scores__c[] scores = [select Points__c from PP_Scores__c where ContentRef__c = :c1.Id];
		System.assert(scores.size() > 0);
		System.assert(scores.get(0).Points__c == 5);
		
		//
		// now test with duplicates in same batch
		//
		Integer oldsize = scores.size();
		batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		ContentDocument cv2 = [select Id from ContentDocument where Id != :cv.Id limit 1];
		delete [select Id from PP_Scores__c where ContentRef__c = :cv2.Id];
		PP_ContentStage__c c3 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c3.Contact__c = c1.Contact__c;
		c3.ContentID__c = cv2.Id;
		insert c3;
		PP_ContentStage__c c4 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c4.Contact__c = c1.Contact__c;
		c4.ContentID__c = cv2.Id;
		insert c4;
		
		batch.Status__c = 'Ready';
		update batch;
		scores = [select Points__c from PP_Scores__c where ContentRef__c = :c4.Id];
		System.assert(scores.size() == 0);		
		
		// test dups across batches

//		pi = new PPContentPlugin();
		batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		PP_ContentStage__c c2 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c2.Contact__c = c1.Contact__c;
		c2.ContentID__c = c1.ContentID__c;
		insert c2;
		
		batch.Status__c = 'Ready';
		update batch;
//		pi.scoreBatch(batch.Id);

		String[] tmp = new List<String>();
		tmp.add(c1.Id);
		tmp.add(c2.Id);
		scores = [select Points__c from PP_Scores__c where ContentRef__c in :tmp];
		System.assert(scores.size() == 1, 'duplicate check failed');

	}


}