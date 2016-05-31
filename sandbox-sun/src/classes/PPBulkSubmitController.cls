public with sharing class PPBulkSubmitController {

	private static final String TEST_CSV = 'USERID,EMAIL,FIRSTNAME,LASTNAME,UNITSEARNED,PARTNERTYPE,COMPANY\nalaabouz,alaab@mdsuae.ae.fte1,Alaa,Albouz2,13,Reseller,Mideast Data Systems Computers';

	private static final String FIELD_USER_ID		= 'USERID';
	private static final String FIELD_EMAIL			= 'EMAIL';
	private static final String FIELD_FNAME			= 'FIRSTNAME';
	private static final String FIELD_LNAME			= 'LASTNAME';
	private static final String FIELD_CREDITS		= 'UNITSEARNED';
	private static final String FIELD_PARTNERTYPE	= 'PARTNERTYPE';
	private static final String FIELD_COMPANY		= 'COMPANY';
	private static final Set<String> requiredHeaders = new Set<String>{FIELD_USER_ID, FIELD_EMAIL, FIELD_FNAME, FIELD_LNAME, FIELD_CREDITS, FIELD_PARTNERTYPE, FIELD_COMPANY};
	private static final Set<String> accountRecordTypes = new Set<String>{'APAC Partner', 'EMEA Partner', 'NA Partner', 'LATAM Partner'};
	
	private static final String COMPANY_NAME_REGEX = '[,\\.-_:;\'"&()\\+\\\\/ ]';
		
	private static final String PARTIALLY_MATCHED = 'Partially Matched';
	private static final String MATCHED = 'Matched';
	private static final String UNMATCHED = 'Unmatched';
	private static final String INELIGIBLE = 'Ineligible';

	public Attachment csvAttachment {get; set;}
	public String   csvContentType {get;set;}
    public String   csvFileName {get;set;}
    public transient Blob   csvFile {get;set;}

	public String stageBatchId {get;set;}
	public PP_InboundBatchStage__c batch {get;set;} 
	public List<PP_InboundBatchItemStage__c> matchedBatchItems {get;set;} 
	public List<PP_InboundBatchItemStage__c> unmatchedBatchItems {get;set;} 
	public List<PP_InboundBatchItemStage__c> batchItems {get;set;}
	private boolean showMatched = false; 
    
    public String batchCode {get; set;}
    public List<PP_Batch__c> batchTypes {get; set;}
    public List<SelectOption> batchTypeOptions {get; set;}
    public List<SelectOption> regionOptions {get; set;}
    public String selectedRegion {get; set;}
    
	public PPBulkSubmitController(){
		batch = new PP_InboundBatchStage__c();
		selectedRegion = '';
		batchTypeOptions = new List<SelectOption>();
		regionOptions = new List<SelectOption>();
		for (String reg : new List<String>{'APAC','EMEA','LATAM','NA'}){
			regionOptions.add(new SelectOption(reg, reg));
		}
	}
	
	public PageReference showMatched(){
		showMatched = true;
		loadBatchList();
		return null;
	}
	public PageReference showUnmatched(){
		showMatched = false;
		loadBatchList();
		return null;
	}
	
	public Boolean getShowMatched(){
		return showMatched;
	}

	public PageReference deleteBatch(){
		if (batch != null && batch.Id != null){
			delete batch;
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Batch Deleted'));
	        selectedRegion = null;
	        batchCode = null;
	        matchedBatchItems = null;
	        unmatchedBatchItems = null;
	        batchItems = null;
		}
		return Page.PartnerPointsBulkSubmit;
	}
	
	public PageReference submitBatch(){
		saveChanges();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Batch Submitted for Processing'));
        
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();   
        approvalReq.setComments('Batch Submitted for Approval.');         
        approvalReq.setObjectId(batch.Id);
        // Submit the approval request for the batch
        Approval.ProcessResult result = Approval.process(approvalReq);
        
		
		return Page.PartnerPointsBulkSubmit;
	}
	
	public boolean getBatchSubmitted(){
		if (batch != null && batch.Id != null){
			return [select count() FROM ProcessInstance where TargetObjectId = :batch.Id and Status in ('Started','Pending')] > 0;
		}
		return false;
	}

	public PageReference saveChanges(){
		if (batchItems != null && batchItems.size() > 0){
			Map<ID, Contact> contactMap = new Map<ID,Contact>([
				select	Id, Account.Global_Region__c, Point_Accrual_Start__c
				from	Contact
				where	Id in :PartnerUtil.getStringFieldSet(batchItems, 'Contact__c')
			]);
			Contact[] toupdate = new List<Contact>();
			Map<Id,Account> acctMap = new Map<Id, Account>();
			Set<Id> accts = new Set<Id>();			
			for (PP_InboundBatchItemStage__c item : batchItems){
				if (item.Contact__c == null && item.Partner__c != null){
					accts.add(item.Partner__c);
				}
			}
			for(Account a : [Select Id, Global_Region__c From Account where id in :accts])
        		acctMap.put(a.id, a);
			
			for (PP_InboundBatchItemStage__c item : batchItems){
				if (item.Contact__c != null){
					if (item.Status__c == INELIGIBLE) {
						continue;
					}
					Contact contact = contactMap.get(item.Contact__c);
					if (contact != null) {
						if (PPScoringUtil.isEligible(contact, item.When_Earned__c, toupdate) == false) {
							item.Status__c = INELIGIBLE;
							continue;
						}
					}

					if (item.Status__c != MATCHED || (item.Previous_Contact__c != null && item.Previous_Contact__c != item.Contact__c)){
						item.Status__c = MATCHED;
						item.Partner__c = [Select AccountId from Contact where Id = :item.Contact__c].AccountId;
						item.Previous_Partner__c = item.Partner__c;
					}
					item.Previous_Contact__c = item.Contact__c;
				} else if (item.Partner__c != null && item.Contact__c == null && !item.Create_Contact__c){
					if (item.Status__c != PARTIALLY_MATCHED || item.Previous_Partner__c != item.Partner__c){
						item.Status__c = PARTIALLY_MATCHED;
						item.Previous_Partner__c = item.Partner__c;
					}
				} 
				if (item.Partner__c != null && item.Status__c == PARTIALLY_MATCHED && item.Create_Contact__c){
					item.Status__c = MATCHED;
					item.Previous_Partner__c = item.Partner__c;
				}
				if (item.Partner__c == null && item.Contact__c == null){
					item.Status__c = UNMATCHED;
				}
			}
			
			// For any item that has an account but no contact, check to see if the account is in a region that requires eligibility
			// If they do, they cannot create a contact as it would be an inelibile contact 
			for (PP_InboundBatchItemStage__c item : batchItems){
				if (item.Contact__c == null && item.Partner__c != null ){
					if (acctMap.get(item.Partner__c).Global_Region__c == null || PPScoringUtil.getRegionEligibilityRequiredMap().get(acctMap.get(item.Partner__c).Global_Region__c)){
						// This region requires elibility to get points, mark as ineligible
						item.Status__c = INELIGIBLE;
						item.Create_Contact__c = false;
					}
				}
			}					
			
			try {
				update batchItems;
				loadBatchList();
				
				if (!toupdate.isEmpty()) {
					update toupdate;
				}
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Changes saved'));
			} catch (Exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Save failed: ' + e.getMessage()));
			}
		}

		return null;
	}
	
	public PageReference loadBatchList(){
        Id tmpid = ApexPages.currentPage().getParameters().get('id');
        if (tmpid != null) {
        	batch = [
        		select
        			Id,
        			Name
        		from
        			PP_InboundBatchStage__c
        		where
        			id = :tmpid
        	];
        	      
          	matchedBatchItems = [
        		select
        			Id,
        			First_Name__c,
        			Last_Name__c,
        			Company_Name__c,
        			Contact__c,
        			Contact__r.Name,
        			Contact__r.Account.Id,
        			Previous_Contact__c,
        			Partner__c,
        			Partner__r.Name,
        			Previous_Partner__c,
        			Create_Contact__c,
        			Federation_Id__c,
        			Email__c,
        			Partner_Type__c,
        			Units_of_Credit__c,
        			Status__c,
        			When_Earned__c
        		from
        			PP_InboundBatchItemStage__c
        		where
        			InboundBatch__c = :tmpid
        			and Status__c = :MATCHED
        		order by
        			Last_Name__c,
        			First_Name__c,
        			Company_Name__c
        	];

          	unmatchedBatchItems = [
        		select
        			Id,
        			First_Name__c,
        			Last_Name__c,
        			Company_Name__c,
        			Contact__c,
        			Contact__r.Name,
        			Contact__r.Account.Id,
        			Previous_Contact__c,
        			Partner__c,
        			Partner__r.Name,
        			Previous_Partner__c,
        			Create_Contact__c,
        			Federation_Id__c,
        			Email__c,
        			Partner_Type__c,
        			Units_of_Credit__c,
        			Status__c,
        			When_Earned__c
        		from
        			PP_InboundBatchItemStage__c
        		where
        			InboundBatch__c = :tmpid
        			and (Status__c = :PARTIALLY_MATCHED
        			or Status__c = :UNMATCHED
        			or Status__c = :INELIGIBLE)
        		order by
        			Last_Name__c,
        			First_Name__c,
        			Company_Name__c
        	];

			if (showMatched){
				batchItems = matchedBatchItems;
			} else {
				batchItems = unmatchedBatchItems;
			}
        	
        }
        return null;
	}
	
	public PageReference loadOptions(){
		if (batchTypeOptions.size() == 0){
	        batchTypes = [select
							Name,
							Batch_Code__c,
							Id,
							Region__c
						  from
						  	PP_Batch__c
						  where					  
						  	IsActive__c = true
						  order by
						  	Name
			];
			for (PP_Batch__c ppb : batchTypes){
				batchTypeOptions.add(new SelectOption(ppb.Batch_Code__c, ppb.Name + ' (' + ppb.Region__c + ' Only)'));
			}
		}
        return null;
	}
    
	public PageReference uploadCSV(){
		if (!passesValidation()){
			return null;
		}
		
		List<Map<String,String>> data = null;
		String text = csvFile.toString();
		try {
			data = CSVReader.process(csvFile, requiredHeaders);
		} catch (Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to process uploaded file, please check file and resubmit.'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Parser Error: ' + e.getMessage()));
			return null;
		} 

		Savepoint sp = Database.setSavepoint();

		Map<String, PP_InboundBatchItemStage__c> fedToStageMap = new Map<String, PP_InboundBatchItemStage__c>();
		Map<String, PP_InboundBatchItemStage__c> emailToStageMap = new Map<String, PP_InboundBatchItemStage__c>();

		PP_InboundBatchStage__c newBatch = new PP_InboundBatchStage__c();
		newBatch.Super_Region__c = selectedRegion;
		PP_Batch__c batchType = [Select Id, Name, Max_Units__c from PP_Batch__c where Batch_Code__c = :batchCode];
		newBatch.Name = batchType.Name;
		newBatch.Batch__c = batchType.Id;
		insert newBatch;
		
		Set<String> fedidList = new Set<String>();
		Set<String> emailList = new Set<String>();

		for (Map<String,String> m : data) {
			
			PP_InboundBatchItemStage__c stage = processEntry(m, newBatch, batchType.Max_Units__c);
			
			if (stage.Federation_Id__c != null) {
				if (fedidlist.contains(stage.Federation_Id__c.toLowerCase())){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, stage.Federation_Id__c.toLowerCase() + ' showed up multiple times, the last one wins.'));
				}
				fedidlist.add(stage.Federation_Id__c.toLowerCase());
				fedToStageMap.put(stage.Federation_Id__c.toLowerCase(), stage);
			}
			if (stage.Email__c != null) {
				if (emailList.contains(stage.Email__c.toLowerCase())){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, stage.Email__c.toLowerCase() + ' showed up multiple times, the last one wins.'));
				}
				emailList.add(stage.Email__c.toLowerCase());
				emailToStageMap.put(stage.Email__c.toLowerCase(), stage);
			}
		}
		
		matchContacts(fedToStageMap, fedidlist, emailToStageMap, emailList);
		matchAccounts(fedToStageMap);
		
		
		if (!fedToStageMap.values().isEmpty()) {
			try {
				insert fedToStageMap.values();
			} catch (Exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured while storing your processed file: ' + e.getMessage()));
				return null;
			}
		}
		else {
			// Don't record empty batches
			Database.rollback(sp);
		}
		PageReference pr = new PageReference('/apex/PartnerPointsBulkResolveIssues?id=' + newBatch.Id);
		return pr;

	}
	
	private boolean passesValidation(){
		boolean noErrors = true;
		if (batchCode == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing Batch Type'));
			noErrors = false;
		}
		if (selectedRegion == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing Region'));
			noErrors = false;
		}
		for (Selectoption so : batchTypeOptions){
			if (so.getValue() == batchCode){
				if (!so.getLabel().contains(' (' + selectedRegion + ' Only)')){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have to choose a region that is available for this Batch type'));
					noErrors = false;
				} else {
					break;
				}
			}
		}
		if (csvFile == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing CSV file'));
			noErrors = false;
		}
		
		System.debug('File Type sumbitted ' + csvContentType);
		
		if (csvContentType != 'text/csv'){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'File must be a text/csv file - you sumitted a ' + csvContentType + ' file'));
			noErrors = false;
		}		
		
		return noErrors;
	}

	//
	// match known contacts up with staged records
	//
	private void matchContacts(Map<String, PP_InboundBatchItemStage__c> fedToStageMap, Set<String> fedidlist, Map<String, PP_InboundBatchItemStage__c> emailToStageMap, Set<String> emailList){
		Contact[] toupdate = new List<Contact>();
		Contact[] contacts = [select Id, LoginName__c, AccountId, Account.Name, Email, Account.Global_Region__c, Point_Accrual_Start__c from Contact where Account.RecordType.Name in :accountRecordTypes and (LoginName__c in :fedidlist or Email in :emailList)];
		for (Contact contact : contacts) {
			PP_InboundBatchItemStage__c stage = null;
			if(contact.LoginName__c != null) {
			 	stage = fedToStageMap.get(contact.LoginName__c.toLowerCase());
			}

			if (stage != null) {
				if (PPScoringUtil.isEligible(contact, stage.When_Earned__c, toupdate) == false) {
					stage.Status__c = INELIGIBLE;
					continue;
				}

				stage.Partner__c = contact.AccountId;
				stage.Contact__c = contact.Id;
				stage.Status__c = MATCHED;
				//stageCompanylist.remove(contact.Account.Name.toLowerCase());
			} else if (contact.Email != null) {
				stage = emailToStageMap.get(contact.Email.toLowerCase());
				if (stage != null && stage.Contact__c == null) {
					stage.Partner__c = contact.AccountId;
					stage.Contact__c = contact.Id;
					stage.Status__c = MATCHED;

					if (PPScoringUtil.isEligible(contact, stage.When_Earned__c, toupdate) == false) {
						stage.Status__c = INELIGIBLE;
					}

					//stageCompanylist.remove(contact.Account.Name.toLowerCase());
				}				
			}
		}
		if (!toupdate.isEmpty()) {
			update toupdate;
		}
	}
	
	//
	// match known accounts that match if we didn't find company
	//
	private void matchAccounts(Map<String, PP_InboundBatchItemStage__c> fedToStageMap){
		Set<String> stageCompanySet = new Set<String>();
		for (PP_InboundBatchItemStage__c item : fedToStageMap.values()){
			if (item.Contact__c == null && item.Company_Name__c != null){
				stageCompanySet.add(item.Company_Name__c);
			}
		}

		String searchString = '(';
		for (String companyName : stageCompanySet){
			if (searchString.length() > 1){
				searchString += ' OR ';
			}
			searchString += companyName;
		}
		searchString += ')';
		if (searchString.length() > 2){
			System.debug(' Searching for companies that match ' + searchString);
			List<List<SObject>> searchList = [
				find 
					:searchString 
				in name fields
				returning 
					Account (
							Id, 
							Name, 
							Global_Region__c,
							Finder_Partner_Tier__r.Name, 
							Finder_Partner_Type__r.Name
						where 
							RecordType.Name in :accountRecordTypes
					)
			];
			List<Account> partners = ((List<Account>)searchList[0]);
			Map<String, Account> acctMap = new Map<String, Account>();
			for (Account acct : partners) {
				acctMap.put(acct.Name.toLowerCase().replaceAll(COMPANY_NAME_REGEX, ''), acct);
			}
			if (partners.size() > 0) {
				for (PP_InboundBatchItemStage__c stage : fedToStageMap.values()){
					String actName = stage.Company_Name__c.toLowerCase().replaceAll(COMPANY_NAME_REGEX, '');
					if (stage.Partner__c == null && acctMap.containsKey(actName)) {
						stage.Partner__c = acctMap.get(actName).Id;
						if (PPScoringUtil.getRegionEligibilityRequiredMap().get(acctMap.get(actName).Global_Region__c)){
							// This region requires elibility to get points, mark as ineligible
							stage.Status__c = INELIGIBLE;
						} else {
							// This region does not require elibility to get points, mark as partially matched
							stage.Status__c = PARTIALLY_MATCHED;
						}
					}
				}
			}
		}		
	}
	
	private PP_InboundBatchItemStage__c processEntry(Map<String,String> m, PP_InboundBatchStage__c newBatch, Decimal maxUnits){
		// start debugging stuff
		String buffer = '';
		for (String key : m.keySet()) {
			buffer = buffer + key;
			buffer = buffer + '=';
			buffer = buffer + m.get(key) + '|';
		}
		System.debug('***[debug] record=' + buffer);
		// end debugging
		
		String userid = m.get(FIELD_USER_ID);
		String email = m.get(FIELD_EMAIL);
		String firstName = m.get(FIELD_FNAME);
		String lastName = m.get(FIELD_LNAME);
		String credits = m.get(FIELD_CREDITS);
		String partnerType = m.get(FIELD_PARTNERTYPE);
		String company = m.get(FIELD_COMPANY);
		
		
		
		PP_InboundBatchItemStage__c stage = new PP_InboundBatchItemStage__c(InboundBatch__c = newBatch.Id);
		stage.Status__c = UNMATCHED;
		stage.Federation_Id__c = userid;
		stage.Email__c = email;
		stage.First_Name__c = firstName;
		stage.Last_Name__c = lastName;
		stage.Partner_Type__c = partnerType;
		if (credits != null) {
			stage.Units_of_Credit__c = Integer.valueOf(credits);
			if (stage.Units_of_Credit__c > maxUnits){
				stage.Units_of_Credit__c = maxUnits;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, stage.Federation_Id__c + ' earned units was ' + stage.Units_of_Credit__c + ' which exceeded the max and will be capped at ' + maxUnits + '.'));
			}
		}
		stage.Company_Name__c = company;
		
		return stage;
	}
	
    static testmethod void simpleTest() {
    	PPBulkSubmitController ctlr = new PPBulkSubmitController();
    	ctlr.loadOptions();
    	ctlr.loadBatchList();

    	System.assertEquals(ctlr.passesValidation(), false);
    	
		PP_Catalog__c cat = new PP_Catalog__c(Category__c = 'Bulk Uploads');
		insert cat;


		PP_Batch__c batch = new PP_Batch__c(Full_Points__c = 6, Region__c = 'NA', Partial_Points__c = 1, Max_Units__c = 5, Catalog__c = cat.Id, Sub_Category__c = 'Nothing', Name = 'Test Batch');
		insert batch;
		batch = [select Id, Batch_Code__c from PP_Batch__c where Id = :batch.Id ];

    	ctlr.batchCode = batch.Batch_Code__c;   	
    	System.assertEquals(ctlr.passesValidation(), false);

    	ctlr.selectedRegion = 'EMEA';
    	System.assertEquals(ctlr.passesValidation(), false);
    	
    	ctlr.selectedRegion = 'NA';
    	System.assertEquals(ctlr.passesValidation(), false);

		Contact[] contacts = [select Id, LoginName__c, AccountId, Account.Name, Email from Contact where Account.RecordType.Name in :accountRecordTypes and LoginName__c != '' limit 10];
		String csv = FIELD_USER_ID + ',' + FIELD_EMAIL + ',' + FIELD_FNAME + ',' + FIELD_LNAME + ',' + FIELD_CREDITS + ',' + FIELD_PARTNERTYPE + ',' + FIELD_COMPANY;
		Integer i = 0;
		for (Contact c : contacts){
			if (i < 3){
				csv += '\n' + c.LoginName__c + ',' + c.Email + ',Fname,Lname,5,Reseller,"' + c.Account.Name + '"';
			} else if (i >= 3 && i < 6){
				csv += '\n' + c.LoginName__c + 'BadFedId,' + c.Email + ',Fname,Lname,5,Reseller,"' + c.Account.Name + '"';
			} else if (i >= 6 && i < 9){
				csv += '\n' + c.LoginName__c + 'BadFedId,BadEmail' + c.Email + ',Fname,Lname,5,Reseller,"' + c.Account.Name + '"';
			} else {
				csv += '\n' + c.LoginName__c + 'BadFedId,BadEmail' + c.Email + ',Fname,Lname,5,Reseller,"badCompany ' + c.Account.Name + '"';
				csv += '\n' + c.LoginName__c + 'BadFedId,BadEmail' + c.Email + ',Fname,Lname,5,Reseller,"' + c.Account.Name + '."';
			}
			i++;
		}
		System.debug(csv);

    	ctlr.csvContentType = 'text/csv';
    	ctlr.csvFile = Blob.valueOf(csv);
    	System.assertEquals(ctlr.passesValidation(), true);
    	
    	PageReference pr = ctlr.uploadCSV();
    	String oid = pr.getUrl().subString(pr.getUrl().indexOf('id=') + 3);
    	System.debug('URL = ' + pr.getUrl() + ' parsed id = ' + oid);
    	ApexPages.currentPage().getParameters().put('id', oid);
    	
    	ctlr.loadBatchList();
    	
    	System.debug('Matched / UnMatched = ' + ctlr.matchedBatchItems.size() + ' / ' + ctlr.unmatchedBatchItems.size());
    	
    	ctlr.saveChanges();

    	ctlr.showMatched();
    	
    	ctlr.batchItems.get(0).Contact__c = contacts[7].Id;
    	ctlr.batchItems.get(1).Contact__c = null;

    	
    	ctlr.saveChanges();

    	ctlr.showUnmatched();
    	ctlr.batchItems.get(0).Create_Contact__c = true;
    	ctlr.batchItems.get(3).Contact__c = contacts[9].Id;

    	ctlr.saveChanges();

    	ctlr.batchItems.get(1).Email__c = 'bademailformat';
    	
    	ctlr.saveChanges();
    	
    	ctlr.showUnmatched();
    	ctlr.getBatchSubmitted();
    	
    	ctlr.deleteBatch();


    	ctlr.selectedRegion = 'NA';
    	ctlr.batchCode = batch.Batch_Code__c;   	
    	ctlr.csvFile = Blob.valueOf(csv);
    	pr = ctlr.uploadCSV();
		oid = pr.getUrl().subString(pr.getUrl().indexOf('id=') + 3);
    	ApexPages.currentPage().getParameters().put('id', oid);
    	ctlr.loadBatchList();

    	ctlr.showMatched();
    	
    	ctlr.batchItems.get(0).Contact__c = contacts[7].Id;
    	ctlr.saveChanges();

    	ctlr.showUnmatched();
    	ctlr.batchItems.get(2).Create_Contact__c = true;
    	
    	ctlr.saveChanges();

    	ctlr.submitBatch();
    	ctlr.getBatchSubmitted();
    	
    }	
}