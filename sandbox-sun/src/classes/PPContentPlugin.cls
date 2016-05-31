public with sharing class PPContentPlugin implements PPScoringPlugin {

	public virtual PPSearchResult[] findScoredItems(String pattern) {
		PPSearchResult[] result = new List<PPSearchResult>();

		List<PP_Content__c> contentSearchResult = new List<PP_Content__c>();
		Map<String, ContentVersion> docMap = new Map<String, ContentVersion>();
		
		if (pattern == null || pattern == ''){
			// Select all scored items up to 200
			contentSearchResult = [select 
							Id, 
							Name,
							DocumentId__c,
							Full_Points__c,
							Sub_Category__c,
							Global_Region__c
						from
							PP_Content__c
						where
							IsActive__c = true
						limit 200
			];
			// Build a document id set
			Set<id> docIds = new Set<Id>();
			for (PP_Content__c ppc : contentSearchResult){
				docIds.add(ppc.DocumentId__c);				
			}
			// Fetch the documents
			List<ContentVersion> docs = [select
											ContentDocumentId, 						
											Title
										from
											ContentVersion
										where
											ContentDocumentId in :docIds
										order by
											VersionNumber
			];
			// Map them for lookup later
			for (ContentVersion doc : docs){
				String truncId = ((String)doc.ContentDocumentId).substring(0,15);
				docMap.put(truncId, doc);
			}
		} else if (pattern.length() == 1){ 
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your search must be at minimum 2 characters.'));
		} else {
			// Search for documents
			String searchPattern = '%' + pattern + '%';
			List<ContentVersion> searchList = [
				select	Id, ContentDocumentId, Title, Description
				from	ContentVersion
				where	Title like :searchPattern
				and		isLatest = true
				order by Title
				limit	200
			];
/*
			List<List<SObject>> searchList = [
				find 
					:pattern 
				in all fields
				returning 
					ContentVersion (
						ContentDocumentId, 						
						Title,
						Description
						where
						    isLatest = true
						order by
							Title
						limit 200
					)
					
			];
*/
			// Create a document map for lookup later
			for (ContentVersion cv : searchList) { //((List<ContentVersion>)searchList[0])){
				docMap.put((String)cv.ContentDocumentId, cv);
			}
			// Find the point definitions
			contentSearchResult = [select 
							Id, 
							Name,
							DocumentId__c,
							Global_Region__c,
							Full_Points__c,
							Sub_Category__c
						from
							PP_Content__c
						where
							DocumentId__c in :docMap.keySet()
							and IsActive__c = true
						limit 200
			];
		}
		
		// For all the definitions, create search results, populate the title from the document and the points 
		// amount from the PP_Content__c object
		for(PP_Content__c ppContent : contentSearchResult){
			PPSearchResult ppsr = new PPSearchResult();
			ppsr.pointCatalogId = ppContent.Id;
			ppsr.scoringFromId = ppContent.DocumentId__c;
			ppsr.itemId = ppContent.DocumentId__c;
			ppsr.subcategory = ppContent.Sub_Category__c;
			ppsr.region = ppContent.Global_Region__c;			
			// Have a fallback if the document was deleted
			if (docMap.size() > 0 && docMap.containsKey(((String)ppsr.ItemId).substring(0,15))){
				ppsr.description = docMap.get(((String)ppsr.ItemId).substring(0,15)).Title;
			} else {
				ppsr.description = ppContent.Name;
			}
			ppsr.pointValue = Integer.valueOf(ppContent.Full_Points__c);
			result.add(ppsr);
		}
		
		return result;
	}

	public virtual PPSearchResult[] findByName(String pattern) {
		PPSearchResult[] result = new List<PPSearchResult>();
		ContentDocument[] docs = null;
		if (pattern == null) {
			docs = [select Id, Title from ContentDocument];
		}
		else {
			docs = [select Id, Title from ContentDocument where title like :pattern];
		}
		for (ContentDocument doc : docs) {
			PPSearchResult r = new PPSearchResult();
			r.itemId = doc.Id;
			r.description = doc.Title;
			result.add(r);
		}
		return result;
	}
	
	public double getObjectScore(String objectId){
		PP_Content__c ppc = null;
		try {
			ppc = [select Id, Full_Points__c from PP_Content__c where id = :objectId];
		} catch (Queryexception qe){
			return 0.0;
		}
		return ppc.Full_Points__c;
	}
	
	public String getObjectSubcategory(String objectId){
		PP_Content__c ppc = null;
		try {
			ppc = [select Id, Sub_Category__c from PP_Content__c where id = :objectId];
		} catch (Queryexception qe){
			return '';
		}
		return ppc.Sub_Category__c;
	}	
	
	public String getName() {
		return 'Content';
	}

	public PageReference getAdminUI() {
		return Page.PartnerPointsCatalogContent;
	}

	public boolean scoreObject(Contact contact, String contentId) {
		return false;
	}
	
	public PP_Scores__c scoreSingle(Contact contact, String contentId) {

		try {		
			PP_Content__c ppc = [
				select	Id, Name, Sub_Category__c, DocumentId__c, Full_Points__c, Global_Region__c, Partner_Track__c
				from	PP_Content__c
				where	Id = :contentId and IsActive__c = true
			];
		
			PP_Scores__c score = new PP_Scores__c(Contact__c = contact.Id,
										Category__c = getName(),
										Subcategory__c = ppc.Sub_Category__c,
										Account__c = contact.AccountId,
										From_ID__c = ppc.DocumentId__c,
										When_Earned__c = System.now(),
										Partner_Track__c = ppc.Partner_Track__c,
										Name = ppc.Name,
										ScoredFromId__c = ppc.Id,
										Points__c = ppc.Full_Points__c);
			insert score;
			return score;
		} catch (Exception e){
			System.debug('ERROR OCCURED: ' + e.getMessage());			
		}
		return null;
	}

	public virtual boolean scoreBatch(String batchId) {

		//
		// get all content for this batch
		//
		PP_ContentStage__c[] batch = [
			select	Id, Name, Contact__c, ContentID__c, When_Earned__c
			from	PP_ContentStage__c
			where	ContentBatch__c = :batchId
		];
		Set<ID> contactIdList = new Set<ID>();
		for (PP_ContentStage__c item : batch) {
			contactIdList.add(item.Contact__c);
		}
		
		System.debug('***[debug] contacts=' + contactIdList.size());
		
		Map<ID, Contact> contactMap = new Map<ID,Contact>([
			select	Id, AccountId, Account.IsPartner, Account.Global_Region__c, Point_Accrual_Start__c
			from	Contact
			where	Id in :contactIdList
		]);

		//
		// now get all prior content for the contacts to catch duplicate credits
		//
		PP_Scores__c[] priors = [
			select	Contact__c, From_ID__c
			from	PP_Scores__c
			where	Contact__c in :contactIdList
		];

		/*
		PP_ContentStage__c[] priors = [
			select	ContentID__c, Contact__c, Contact__r.Point_Accrual_Start__c, When_Earned__c
			from	PP_ContentStage__c
			where	Contact__c in :contactIdList and ContentBatch__c != :batchId
		];

		System.debug('***[debug] priors=' + priors.size());

		//
		// ignore content in this batch that is a duplicate
		//
		System.debug('***[debug]*** batch size before dedup: ' + batch.size());
		removePriors(priors, batch);
		System.debug('***[debug]*** batch size after dedup: ' + batch.size());
		*/

		//
		// get all the content IDs so we can lookup the scores
		//
		Set<ID> contentIdList = new Set<ID>();
		for (PP_ContentStage__c item : batch) {
			contentIdList.add(item.ContentID__c);
		}
		System.debug('***[debug] content ids=' + contentIdList.size());

		Map<String,PP_Content__c> ppcmap = new Map<String,PP_Content__c>();
		PP_Content__c[] smlist = [
			select	Id, Sub_Category__c, DocumentId__c, Full_Points__c, Global_Region__c, ExcludeBatchId__c, Partner_Track__c
			from	PP_Content__c
			where	DocumentId__c in :contentIdList
			and		IsActive__c = true
		];
		for (PP_Content__c sm : smlist) {
		    ppcmap.put(sm.DocumentId__c.substring(0,15) + sm.Global_Region__c, sm);
		}

		Set<String> excludedBatches = PartnerUtil.getStringFieldSet(smlist, 'ExcludeBatchId__c');
		System.debug('***[debug]*** excludebatchsize=' + excludedBatches.size());

		PP_InboundBatchItemStage__c[] excludedBatchItems = [
			select	Id, Contact__c,  InboundBatch__r.Batch__c
			from	PP_InboundBatchItemStage__c
			where	InboundBatch__r.Batch__c in :excludedBatches
		];
		Map<String,PP_InboundBatchItemStage__c> exclusionMap = new Map<String,PP_InboundBatchItemStage__c>();
		for (PP_InboundBatchItemStage__c bis : excludedBatchItems) {
			String c = bis.Contact__c;
			String b = bis.InboundBatch__r.Batch__c;
			exclusionMap.put(c + b, bis);
			System.debug('***[debug]*** added to exclusionmap: ' + c + b);
		}

		//
		// now ready to score and record points for content
		//
		
		//PP_ItemAudit__c[] audit = new List<PP_ItemAudit__c>();
		PP_Scores__c[] scores = new List<PP_Scores__c>();
		System.debug('***[debug]*** batch size ' + batch.size());
		List<Contact> toupdate = new List<Contact>();
		for (PP_ContentStage__c item : batch) {
			Contact contact = contactMap.get(item.Contact__c);
			if (contact != null) {
				// make sure no dup exists in current scores
				boolean dup = false;
				for (PP_Scores__c ps : priors) {
					if (ps.Contact__c == item.Contact__c && ps.From_ID__c == item.ContentID__c) {
						dup = true;
						break;
					}
				}
				if (dup) {
					System.debug('***[debug] dup detected, skipping');							
					continue;
				}

				// make sure no dup exists in the current batch
				dup = false;
				for (PP_Scores__c ps : scores) {
					if (ps.Contact__c == item.Contact__c && ps.From_ID__c == item.ContentID__c) {
						dup = true;
						break;
					}
				}
				if (dup) {
					System.debug('***[debug] dup detected, skipping');							
					continue;
				}


				//
				// only record points for partner contacts for the same region
				//
				if (contact.Account.isPartner) {
					
					//
					// check if contact is eligible to receive points
					//
					if (PPScoringUtil.isEligible(contact, item.When_Earned__c, toupdate) == false) {
						continue;
					}

					// check region
					PP_Content__c ppc = ppcmap.get(item.ContentID__c.substring(0, 15) + contact.Account.Global_Region__c);
					if (ppc == null){
						ppc = ppcmap.get(item.ContentID__c.substring(0, 15) + 'Global');						
					}
					
					if (ppc != null) {
						// check exclusions
						String cid = contact.Id;
						String bid = ppc.ExcludeBatchId__c;
						System.debug('***[debug]*** cid+bid=' + cid+bid);
						if (bid != null && exclusionMap.containsKey(cid + bid)) {
							System.debug('***[debug]*** exclusion detected - skipping');
							continue;
						}

						scores.add(new PP_Scores__c(Contact__c = item.Contact__c,
													Category__c = getName(),
													Subcategory__c = ppc.Sub_Category__c,
													Account__c = contact.AccountId,
													ContentRef__c = item.Id,
													From_ID__c = item.ContentID__c,
													When_Earned__c = item.When_Earned__c,
													Partner_Track__c = ppc.Partner_Track__c,
													Name = item.Name,
													ScoredFromId__c = ppc.Id,
													Points__c = ppc.Full_Points__c));
						//audit.add(new PP_ItemAudit__c(	Contact__c = item.Contact__c,
						//								Related_Id__c = item.Id,
						//								Name = item.Name,
						//								Points__c = ppc.Full_Points__c));
						System.debug('***[debug] inserting score');
					}
				}
			}
		}

		if (!toupdate.isEmpty()) {
			update toupdate;
		}

		if (!scores.isEmpty()) {
			insert scores;
			//insert audit;
		}		

		return true;
	}

/*
	private Integer removePriors(List<PP_ContentStage__c> priors, List<PP_ContentStage__c> batch) {
		Integer cnt = 0;
		for (PP_ContentStage__c prior : priors) {
			Integer index = 0;
			for (PP_ContentStage__c item : batch) {
				if (item.Contact__c == prior.Contact__c && item.ContentID__c == prior.ContentID__c &&
					item.Contact__r.Point_Accrual_Start__c != null && item.Contact__r.Point_Accrual_Start__c < item.When_Earned__c) {
					batch.remove(index);
					cnt += 1;
					break;
				}
				index += 1;
			}
		} 
		return cnt;
	}
*/	

	static testmethod void fullCreditTest() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('partner points test');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        insert c;

		PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
		insert cat;

		PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 6, Partial_Points__c = 1, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Nothing', Name = 'Test Batch');
		insert batch;

		PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA', Name=batch.Name);
		insert ib;
		
		PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
		item.Federation_Id__c = c.LoginName__c;
		item.First_Name__c = 'Malcolm';
		item.Last_Name__c = 'Reynolds';
		item.Company_Name__c = 'Browncoats';
		item.InboundBatch__c = ib.Id;
		item.Partner_Type__c = 'ISV';
		item.Units_of_Credit__c = batch.Max_Units__c;
		item.Contact__c = c.Id;
		item.Status__c = 'Matched';
		insert item;

		ib.Status__c = 'Ready';
		update ib;
		
		PP_Scores__c score = [select Points__c from PP_Scores__c where Contact__c = :c.Id and BatchItemStageRef__c = :item.Id];
		System.assert(score.Points__c == batch.Full_Points__c);

		//
		// test for duplicates
		//
		ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA', Name=batch.Name);
		insert ib;

		item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
		item.Federation_Id__c = c.LoginName__c;
		item.First_Name__c = 'Malcolm';
		item.Last_Name__c = 'Reynolds';
		item.Company_Name__c = 'Browncoats';
		item.InboundBatch__c = ib.Id;
		item.Partner_Type__c = 'ISV';
		item.Units_of_Credit__c = batch.Max_Units__c;
		item.Contact__c = c.Id;
		item.Status__c = 'Matched';
		insert item;
		
		ib.Status__c = 'Ready';
		update ib;

		PP_Scores__c[] scores = [select Points__c from PP_Scores__c where Contact__c = :c.Id and BatchItemStageRef__c = :item.Id];
		System.assert(scores.size() == 0, 'Failed duplicate test');
		
		//
		// single
		//
		PPBatchPlugin plugin = new PPBatchPlugin();
		plugin.scoreSingle(c, batch.Id);
		
	}

	static testmethod void exclusionTest() {
		PP_ContentBatchStage__c cbatch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert cbatch;
		
		PP_ContentStage__c c1 = new PP_ContentStage__c(ContentBatch__c = cbatch.Id);
        Account acct = PartnerTestUtils.quickGenericAccountSetup('partner points test');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        insert c;

		c1.Contact__c = c.Id;

		//
		// insert bulk upload records
		//
		PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
		insert cat;

		PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 6, Partial_Points__c = 1, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Nothing', Name = 'Test Batch');
		insert batch;

		PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA', Name=batch.Name);
		insert ib;
		
		PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
		item.Federation_Id__c = c.LoginName__c;
		item.First_Name__c = 'Malcolm';
		item.Last_Name__c = 'Reynolds';
		item.Company_Name__c = 'Browncoats';
		item.InboundBatch__c = ib.Id;
		item.Partner_Type__c = 'ISV';
		item.Units_of_Credit__c = batch.Max_Units__c;
		item.Contact__c = c.Id;
		item.Status__c = 'Matched';
		insert item;
		ib.Status__c = 'Ready';
		update ib;


		ContentDocument cv = [select Id, Title, LatestPublishedVersionId, LatestPublishedVersion.Title from ContentDocument limit 1];
		System.debug('Found document ' + cv.LatestPublishedVersion.Title);
		if (cv.LatestPublishedVersion.Title.length() > 80)
			c1.Name = cv.LatestPublishedVersion.Title.substring(0, 80);
		else
			c1.Name = cv.LatestPublishedVersion.Title;
		c1.ContentID__c = cv.Id;
		insert c1;

		PP_Catalog__c cat2 = new PP_Catalog__c();
		cat2.Global_Region__c = 'NA';
		insert cat2;

		PP_Content__c pc = new PP_Content__c();
		pc.Full_Points__c = 5;
		pc.PP_Catalog__c = cat2.Id;
		pc.DocumentId__c = cv.Id;
		pc.Global_Region__c = 'NA';
		pc.ExcludeBatchId__c = batch.Id;
		insert pc;

		//
		// do the test
		//

		cbatch.Status__c = 'Ready';
		update cbatch;

		PP_Scores__c[] scores = [select Points__c from PP_Scores__c where ContentRef__c = :c1.Id];
		System.assert(scores.size() == 0);
	}

	static testmethod void simpleTest() {
		PPContentPlugin pi = new PPContentPlugin();
		pi.getAdminUI();
		pi.getName();
		
		PP_ContentBatchStage__c batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		
		PP_ContentStage__c c1 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c1.Contact__c = [select Id from Contact where Account.isPartner = True and Account.Global_Region__c = 'NA' limit 1].Id;
		ContentDocument cv = [select Id, Title, LatestPublishedVersionId, LatestPublishedVersion.Title from ContentDocument limit 1];
		System.debug('Found document ' + cv.LatestPublishedVersion.Title);
		if (cv.LatestPublishedVersion.Title.length() > 80)
			c1.Name = cv.LatestPublishedVersion.Title.substring(0, 80);
		else
			c1.Name = cv.LatestPublishedVersion.Title;
		c1.ContentID__c = cv.Id;
		insert c1;

		PP_Catalog__c cat = new PP_Catalog__c();
		cat.Global_Region__c = 'NA';
		insert cat;

		PP_Content__c pc = new PP_Content__c();
		pc.Full_Points__c = 5;
		pc.PP_Catalog__c = cat.Id;
		pc.DocumentId__c = cv.Id;
		pc.Global_Region__c = 'NA';
		insert pc;

		batch.Status__c = 'Ready';
		update batch;
		//pi.scoreBatch(batch.Id);

		PP_Scores__c[] scores = [select Points__c from PP_Scores__c where ContentRef__c = :c1.Id];
		System.assert(scores.size() > 0);
		System.assert(scores.get(0).Points__c == 5);
		
		// test a specific search scenario here
		System.debug('++++[debug]++++ title=' + c1.Name);
		PPSearchResult[] sr = pi.findScoredItems(c1.Name);
		System.assert(sr.size() > 0, 'no search match found');

		//
		// now test with a duplicate
		//
		pi = new PPContentPlugin();
		batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		PP_ContentStage__c c2 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c2.Contact__c = c1.Contact__c;
		c2.ContentID__c = c1.ContentID__c;
		insert c2;
		batch.Status__c = 'Ready';
		update batch;
		//pi.scoreBatch(batch.Id);

		String[] tmp = new List<String>();
		tmp.add(c1.Id);
		tmp.add(c2.Id);
		scores = [select Points__c from PP_Scores__c where ContentRef__c in :tmp];
		System.assert(scores.size() == 1, 'duplicate check failed');

	}
	
	static testmethod void simpleGlobalTest() {
		PPContentPlugin pi = new PPContentPlugin();
		pi.getAdminUI();
		pi.getName();
		
		PP_ContentBatchStage__c batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		
		PP_ContentStage__c c1 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c1.Contact__c = [select Id from Contact where Account.isPartner = True and Account.Global_Region__c = 'NA' limit 1].Id;
		ContentDocument cv = [select Id, Title, LatestPublishedVersionId, LatestPublishedVersion.Title from ContentDocument limit 1];
		System.debug('Found document ' + cv.LatestPublishedVersion.Title);
		if (cv.LatestPublishedVersion.Title.length() > 80)
			c1.Name = cv.LatestPublishedVersion.Title.substring(0, 80);
		else
			c1.Name = cv.LatestPublishedVersion.Title;
		c1.ContentID__c = cv.Id;
		insert c1;

		PP_Catalog__c cat = new PP_Catalog__c();
		cat.Global_Region__c = 'Global';
		insert cat;

		PP_Content__c pc = new PP_Content__c();
		pc.Full_Points__c = 5;
		pc.PP_Catalog__c = cat.Id;
		pc.DocumentId__c = cv.Id;
		pc.Global_Region__c = 'Global';
		insert pc;

		batch.Status__c = 'Ready';
		update batch;
		//pi.scoreBatch(batch.Id);

		PP_Scores__c[] scores = [select Points__c from PP_Scores__c where ContentRef__c = :c1.Id];
		System.assert(scores.size() > 0);
		System.assert(scores.get(0).Points__c == 5);
		
		// test a specific search scenario here
		System.debug('++++[debug]++++ title=' + c1.Name);
		PPSearchResult[] sr = pi.findScoredItems(c1.Name);
		System.assert(sr.size() > 0, 'no search match found');

		//
		// now test with a duplicate
		//
		pi = new PPContentPlugin();
		batch = new PP_ContentBatchStage__c(status__c = 'Pending');
		insert batch;
		PP_ContentStage__c c2 = new PP_ContentStage__c(ContentBatch__c = batch.Id);
		c2.Contact__c = c1.Contact__c;
		c2.ContentID__c = c1.ContentID__c;
		insert c2;
		batch.Status__c = 'Ready';
		update batch;
		//pi.scoreBatch(batch.Id);

		String[] tmp = new List<String>();
		tmp.add(c1.Id);
		tmp.add(c2.Id);
		scores = [select Points__c from PP_Scores__c where ContentRef__c in :tmp];
		System.assert(scores.size() == 1, 'duplicate check failed');

	}	

	static testmethod void searchTest() {
		//
		// test searches
		//		
		PPContentPlugin pi = new PPContentPlugin();

		PPSearchResult[] sr = pi.findScoredItems(null);
//		System.assert(sr.size() > 0);

		sr = pi.findScoredItems('');
//		System.assert(sr.size() > 0);

		ContentDocument cv = [select Id, Title, LatestPublishedVersionId, LatestPublishedVersion.Title from ContentDocument limit 1];
		System.debug('Found document ' + cv.LatestPublishedVersion.Title);

		System.debug('Searching for ' + cv.LatestPublishedVersion.Title);
		Id [] fixedSearchResults= new Id[1];
		fixedSearchResults[0] = cv.LatestPublishedVersionId;
		Test.setFixedSearchResults(fixedSearchResults);
		
		// Test target object search
		sr = pi.findByName(cv.Title);
		System.assertEquals(1, sr.size());
		
	}

}