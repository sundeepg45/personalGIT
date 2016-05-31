public with sharing class PPBatchPlugin implements PPScoringPlugin {
	
	public static final String NAME = 'Bulk Uploads';

	public virtual PPSearchResult[] findScoredItems(String pattern) {
		PPSearchResult[] result = new List<PPSearchResult>();
		if (pattern.length() == 0){
			List<PP_Batch__c> batchTypes = [
				select
						Id, 
						Max_Units__c, 
						Full_Points__c, 
						Partial_Points__c, 
						Region__c,
						Batch_Code__c,
						Name, 
						Sub_Category__c
					from 
						PP_Batch__c
					order by
						Sub_Category__c,
						Name
			];
			
			for (PP_Batch__c ppBatch : batchTypes){
				PPSearchResult ppsr = new PPSearchResult();
				ppsr.pointCatalogId = ppBatch.Id;
				ppsr.scoringFromId = ppBatch.Id;
				ppsr.itemId = ppBatch.Batch_Code__c;
				ppsr.subcategory = ppBatch.Sub_Category__c;
				ppsr.region = ppBatch.Region__c;
				ppsr.description = ppBatch.Sub_Category__c + ': ' + ppBatch.Name;
				ppsr.pointValue = Integer.valueOf(ppBatch.Full_Points__c);
				result.add(ppsr);
			}	 
		} else if (pattern.length() == 1){ 
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your search must be at minimum 2 characters.'));
		} else {
			List<List<SObject>> searchList = [
				find 
					:pattern 
				in all fields
				returning 
					PP_Batch__c (
						Id, 
						Max_Units__c, 
						Batch_Code__c,
						Full_Points__c, 
						Partial_Points__c, 
						Region__c, 
						Name, 
						Sub_Category__c
						order by
							Sub_Category__c,
							Name
						limit 200
					)
					
			];
			// Create a document map for lookup later
			for (PP_Batch__c ppBatch : ((List<PP_Batch__c>)searchList[0])){
				PPSearchResult ppsr = new PPSearchResult();
				ppsr.pointCatalogId = ppBatch.Id;
				ppsr.scoringFromId = ppBatch.Id;
				ppsr.itemId = ppBatch.Batch_Code__c;
				ppsr.description = ppBatch.Sub_Category__c + ': ' + ppBatch.Name;
				ppsr.subcategory = ppBatch.Sub_Category__c;
				ppsr.region = ppBatch.Region__c;
				ppsr.pointValue = Integer.valueOf(ppBatch.Full_Points__c);
				result.add(ppsr);
			}		
		}
		return result;
	}

	public virtual PPSearchResult[] findByName(String pattern) {
		PPSearchResult[] result = new List<PPSearchResult>();
		return result;
	}
	
	public double getObjectScore(String objectId){
		PP_Batch__c ppb = null;
		try {
			ppb = [
			select
					Max_Units__c, 
					Full_Points__c, 
					Partial_Points__c 
				from 
					PP_Batch__c
				where
					Id = :objectId
			];
		} catch (Exception e){
			return 0.0;
		}
		return ppb.Full_Points__c;
	}	

	public String getObjectSubcategory(String objectId){
		PP_Batch__c ppb = null;
		try {
			ppb = [
			select
					Sub_Category__c 
				from 
					PP_Batch__c
				where
					Id = :objectId
			];
		} catch (Exception e){
			return '';
		}
		return ppb.Sub_Category__c;
	}	
	
	public String getName() {
		return NAME;
	}	

	public PageReference getAdminUI() {
		String pageURL = '/' + PP_Batch__c.SObjectType.getDescribe().getKeyPrefix();
		System.debug('Redirecting you to ' + pageURL);
		PageReference pr = new PageReference(pageURL);
		pr.setRedirect(true);
		return pr;
	}	

	public virtual boolean scoreObject(Contact contact, String batchItemId) {
		return false;
	}
	
	public PP_Scores__c scoreSingle(Contact contact, String batchItemId) {
		try {		
			PP_Batch__c scoring = [
				select	Id, Name, Full_Points__c, Sub_Category__c, Partner_Track__c
				from	PP_Batch__c
				where	Id = :batchItemId
			];
			
			PP_Scores__c score = new PP_Scores__c(Contact__c = contact.Id,
											Category__c = getName(),
											Account__c = contact.AccountId,
											From_ID__c = scoring.Id,
											Name = scoring.Name,
											Subcategory__c = scoring.Sub_Category__c,
											When_Earned__c = System.now(),
											Partner_Track__c = scoring.Partner_Track__c,
											ScoredFromId__c = scoring.Id,
											Points__c = scoring.Full_Points__c);
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
		PP_InboundBatchStage__c batch = [select Id, Name, Batch__c from PP_InboundBatchStage__c where Id = :batchId];
		PP_InboundBatchItemStage__c[] batchitems = [
				select	Id,
						Contact__c,
						Units_of_Credit__c,
						When_Earned__c
				from	PP_InboundBatchItemStage__c
				where	InboundBatch__c = :batchId
				and		Contact__c != null
				and		Units_of_Credit__c > 0
				and		Status__c != 'Unmatched'
				and		Status__c != 'Ineligible'
		];

		Set<ID> contactIdList = new Set<ID>();
		for (PP_InboundBatchItemStage__c item : batchitems) {
			contactIdList.add(item.Contact__c);
		}
		
		Map<ID, Contact> contactMap = new Map<ID,Contact>([
			select	Id, AccountId, Point_Accrual_Start__c, Account.Global_Region__c
			from	Contact
			where	Id in :contactIdList
			and		Account.IsPartner = true
		]);

		// find the right catalog entry for scoring

		PP_Batch__c scoring = [
			select	Id, Max_Units__c, Full_Points__c, Partial_Points__c, Name, Sub_Category__c, Partner_Track__c
			from	PP_Batch__c
			where	Id = :batch.Batch__c
		];
		
		PP_Scores__c[] dupscores = [
			select	Id, Contact__c, When_Earned__c, ScoredFromId__c
			from	PP_Scores__c
			where	Contact__c in :contactMap.keySet()
			and		ScoredFromId__c = :scoring.Id
			and		Points_Status__c != 'Expired'
		];
//		Map<String, PP_Scores__c> scoremap = new Map<String, PP_Scores__c>();
//		for (PP_Scores__c dupscore : dupscores) {
//			scoremap.put(dupscore.Contact__c, dupscore);
//		}

		//
		// now ready to score and record points for content
		//
		
		//PP_ItemAudit__c[] audit = new List<PP_ItemAudit__c>();
		PP_Scores__c[] scores = new List<PP_Scores__c>();
		List<Contact> toupdate = new List<Contact>();
		for (PP_InboundBatchItemStage__c item : batchitems) {
			if (contactMap.containsKey(item.Contact__c)) {
				Contact contact = contactMap.get(item.Contact__c);
				if (!PPScoringUtil.isEligible(contact, item.When_Earned__c, toupdate)) {
					continue;
				}
				// check for and skip duplicates
				Boolean isdup = false;
				for (PP_Scores__c score : dupscores) {
					if (score.Contact__c == item.Contact__c) {
						isdup = true;
						break;
					}
				}
				if (isdup) {
					System.debug('***[debug] skipping duplicate for Contact ' + item.Contact__c);
					continue;
				}

				Decimal points = 0;
				if (item.Units_of_Credit__c < scoring.Max_Units__c) {
					points = item.Units_of_Credit__c * scoring.Partial_Points__c;
				}
				else {
					points = scoring.Full_Points__c;
				}

				scores.add(new PP_Scores__c(Contact__c = item.Contact__c,
											Category__c = getName(),
											Account__c = contact.AccountId,
											From_ID__c = scoring.Id,
											Name = scoring.Name,
											Subcategory__c = scoring.Sub_Category__c,
											BatchItemStageRef__c = item.Id,
											When_Earned__c = item.When_Earned__c,
											Partner_Track__c = scoring.Partner_Track__c,
											ScoredFromId__c = scoring.Id,
											Points__c = points));
				//audit.add(new PP_ItemAudit__c(	Contact__c = item.Contact__c,
				//								Related_Id__c = item.Id,
				//								Points__c = points));
				System.debug('***[debug] inserting score');
			}
		}

		if (!scores.isEmpty()) {
			insert scores;
			//insert audit;
		}		

		return true;
	}

	static testmethod void lameCoverageTest() {
		PPBatchPlugin plugin = new PPBatchPlugin();
		plugin.getAdminUI();
		plugin.getObjectScore(null);
		plugin.scoreObject(null, null);
	}

	static testmethod void findTest() {
		PPBatchPlugin plugin = new PPBatchPlugin();

		PP_Catalog__c cat = new PP_Catalog__c(Category__c = NAME);
		insert cat;

		PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 6, Partial_Points__c = 1, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Nothing', Name = 'Test Batch');
		insert batch;

		PPSearchResult[] results = plugin.findScoredItems('test');
		results = plugin.findScoredItems('');
		results = plugin.findScoredItems('a');
		results = plugin.findByName('red');
		
		// misc stuff
		plugin.getObjectSubcategory(batch.Id);
	}

	static testmethod void fullCreditTest() {
		Account acct = [select Id from Account where IsPartner = True and Global_Region__c = 'NA' limit 1];
		Contact c = PartnerTestUtils.makeContact(acct.Id, 'fullCreditTest Contact');
		insert c;

		PP_Catalog__c cat = new PP_Catalog__c(Category__c = NAME);
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
		System.assert(scores.size() == 0, 'Failed duplicate test, found ' + scores.size());
		
		//
		// single
		//
		PPBatchPlugin plugin = new PPBatchPlugin();
		plugin.scoreSingle(c, batch.Id);
		
	}

	static testmethod void partialCreditTest() {
		Contact c = [select Id, LoginName__c from Contact where Account.IsPartner = True and Account.Global_Region__c = 'NA' and LoginName__c != null limit 1];

		PP_Catalog__c cat = new PP_Catalog__c(Category__c = NAME);
		insert cat;

		PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 6, Partial_Points__c = 1, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Nothing', Name = 'Test Batch');
		insert batch;

		PP_InboundBatchStage__c ib = new PP_InboundBatchStage__c(Batch__c = batch.Id, Super_Region__c = 'NA', Name = batch.Name);
		insert ib;
		
		PP_InboundBatchItemStage__c item = new PP_InboundBatchItemStage__c(InboundBatch__c = ib.Id);
		item.Federation_Id__c = c.LoginName__c;
		item.First_Name__c = 'Malcolm';
		item.Last_Name__c = 'Reynolds';
		item.Company_Name__c = 'Browncoats';
		item.InboundBatch__c = ib.Id;
		item.Partner_Type__c = 'ISV';
		item.Units_of_Credit__c = batch.Max_Units__c - 1;
		item.Contact__c = c.Id;
		item.Status__c = 'Matched';
		insert item;

		ib.Status__c = 'Ready';
		update ib;
		
		PP_Scores__c score = [select Points__c from PP_Scores__c where Contact__c = :c.Id and BatchItemStageRef__c = :item.Id];
		
		System.assert(score.Points__c == batch.Partial_Points__c * item.Units_of_Credit__c);
		
	}

}