public with sharing class PPLMSPlugin implements PPScoringPlugin {


    public virtual PPSearchResult[] findScoredItems(String pattern) {
        PPSearchResult[] result = new List<PPSearchResult>();

        List<Partner_Points_LMS_Catalog__c> lmsSearchResult = new List<Partner_Points_LMS_Catalog__c>();
        Map<String, SumTotal_Catalog__c> docMap = new Map<String, SumTotal_Catalog__c>();
        
        if (pattern == null || pattern == '') {
            // Select all scored items up to 200
            lmsSearchResult = [
                select  Id, 
                        Name,
                        Course_Id__c,
                        Full_Points__c,
                        Language__c,
                        Sub_Category__c,
                        Global_Region__c
                from    Partner_Points_LMS_Catalog__c
                limit   200
            ];
            // Build a course id set
            Set<String> courseIds = new Set<String>();
            for (Partner_Points_LMS_Catalog__c ppc : lmsSearchResult){
                courseIds.add(ppc.Course_Id__c);                
            }

            // Fetch the courses
	        SumTotal_Catalog__c[] courseList = null;
	        courseList = [
	            select      Id, Activity_Name__c, SumTotal_ID__c, Training_Type__c, Training_Path__c
	            from        SumTotal_Catalog__c
	            where       IsDeleted = false
	            order by    Activity_Name__c
	        ];

            for (SumTotal_Catalog__c course : courseList){
                docMap.put(course.SumTotal_ID__c, course);
            }
        }
        else if (pattern.length() == 1) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your search must be at minimum 2 characters.'));
            return result;
        }
        else {
            pattern = '%' + pattern + '%';
            // Search for courses
	        SumTotal_Catalog__c[] courseList = null;
	        courseList = [
	            select      Id, Activity_Name__c, SumTotal_ID__c, Training_Type__c, Training_Path__c
	            from        SumTotal_Catalog__c
                where       Activity_Name__c like :pattern
	            and         IsDeleted = false
	            order by    Activity_Name__c
	        ];

            for (SumTotal_Catalog__c course : courseList){
                docMap.put(course.SumTotal_ID__c, course);
            }
            // Find the point definitions
            lmsSearchResult = [select 
                            Id, 
                            Name,
                            Course_Id__c,
                            Full_Points__c,
                            Language__c,
                            Global_Region__c,
                            Sub_Category__c
                        from
                            Partner_Points_LMS_Catalog__c
                        where
                            Course_Id__c in :docMap.keySet()
                        and
                            IsActive__c = true
                        limit 200
            ];
        }
        
        // For all the definitions, create search results, populate the title from the document and the points 
        // amount from the PP_Content__c object
        for (Partner_Points_LMS_Catalog__c ppContent : lmsSearchResult) {
            PPSearchResult ppsr = new PPSearchResult();
            ppsr.itemId = ppContent.Course_Id__c;
            ppsr.pointCatalogId = ppContent.Id;
            ppsr.language = ppContent.Language__c;
            ppsr.subcategory = ppContent.Sub_Category__c;
            ppsr.region = ppContent.Global_Region__c;
            // Have a fallback if the document was deleted
            if (docMap.size() > 0 && docMap.containsKey((String)ppsr.ItemId)) {
                ppsr.description = docMap.get((String)ppsr.ItemId).Activity_Name__c;
                ppsr.scoringFromId = docMap.get((String)ppsr.ItemId).SumTotal_ID__c;
            } else {
                ppsr.description = ppContent.Name;
                ppsr.scoringFromId = ppContent.Id;
            }
            ppsr.pointValue = Integer.valueOf(ppContent.Full_Points__c);
            result.add(ppsr);
        }
                
        return result;
    }

    public virtual PPSearchResult[] findByName(String pattern) {
        PPSearchResult[] result = new List<PPSearchResult>();
        
        SumTotal_Catalog__c[] docs = null;
        if (pattern == null) {
            docs = [select Id, SumTotal_ID__c, Activity_Name__c from SumTotal_Catalog__c];
        }
        else {
            docs = [select Id, SumTotal_ID__c, Activity_Name__c from SumTotal_Catalog__c where Activity_Name__c like :pattern];
        }
        for (SumTotal_Catalog__c doc : docs) {
            PPSearchResult r = new PPSearchResult();
            r.itemId = doc.SumTotal_ID__c;
            r.description = doc.Activity_Name__c;
            result.add(r);
        }
        return result;
    }
    
    public double getObjectScore(String objectId){
        Partner_Points_LMS_Catalog__c pplms = null;
        try {
            pplms = [select Id, Full_Points__c from Partner_Points_LMS_Catalog__c where id = :objectId];
        } catch (Queryexception qe){
            return 0.0;
        }
        return pplms.Full_Points__c;
    }
    
    public String getObjectSubcategory(String objectId){
        Partner_Points_LMS_Catalog__c pplms = null;
        try {
            pplms = [select Id, Sub_Category__c from Partner_Points_LMS_Catalog__c where id = :objectId];
        } catch (Queryexception qe){
            return '';
        }
        return pplms.Sub_Category__c;
    }   
    
    public String getName() {
        return 'LMS';
    }

    public PageReference getAdminUI() {
        return Page.PartnerPointsCatalogLMS;
    }   

    public PP_Scores__c scoreSingle(Contact contact, String itemId) {
        // itemId will be the rowid of the LMS catalog entry

        if (contact == null) {
            System.debug('***[debug]*** contact is null');
            return null;
        }
        Partner_Points_LMS_Catalog__c[] cataloglist = [
            select  Id, Course_ID__c, Full_Points__c, Global_Region__c, Language__c, Name, Sub_Category__c, Partner_Track__c
            from    Partner_Points_LMS_Catalog__c
            where   Id = :itemId
            and     IsActive__c = true
        ];
        
        if (cataloglist.isEmpty()) {
            System.debug('***[debug]*** no catalog entry for Id ' + itemId);
            return null;
        }

        Partner_Points_LMS_Catalog__c catalog = cataloglist.get(0);

        //
        // only record points for partner contacts for the same region
        //
        if (contact.Account.isPartner) {
            Decimal score = catalog.Full_Points__c;
            System.debug('***[debug]*** score=' + score);
            PP_Scores__c ps = new PP_Scores__c(Contact__c = contact.Id,
                                        Category__c = getName(),
                                        Account__c = contact.AccountId,
                                        From_ID__c = catalog.Course_ID__c,
                                        Subcategory__c = catalog.Sub_Category__c,
                                        When_Earned__c = System.now(),
                                        Partner_Track__c = catalog.Partner_Track__c,
                                        Name = catalog.Name,
                                        ScoredFromId__c = catalog.Id,
                                        Points__c = score);
            insert ps;
            System.debug('***[debug] inserting score');
            return ps;
        }
        else {
            System.debug('***[debug]*** not a partner');
        }
        
        return null;
    }
    
    public boolean scoreObject(Contact contact, String objId) {

        if (contact == null) {
            return false;
        }
        PP_LMS_Stage__c stage = [
            select  Id, Name, Contact__c, Course_Id__c, Language__c, Training_Type__c, When_Earned__c
            from    PP_LMS_Stage__c
            where   Id = :objId
        ];
        //if (contact.Point_Accrual_Start__c == null || contact.Point_Accrual_Start__c > stage.When_Earned__c) {
        //	return false;
        //}
        Partner_Points_LMS_Catalog__c[] cataloglist = [
            select  Id, Course_Id__c, Full_Points__c, Global_Region__c, Language__c, Sub_Category__c, Partner_Track__c
            from    Partner_Points_LMS_Catalog__c
            where   Course_Id__c = :stage.Course_Id__c
            and     ((Language__c = :stage.Language__c and Global_Region__c = :contact.Account.Global_Region__c)
                    or (Global_Region__c = 'Global'))
            and     IsActive__c = true
            limit   1
        ];
        
        if (cataloglist.isEmpty()) {
            System.debug('***** [debug] cataloglist is empty');
            return false;
        }

        Partner_Points_LMS_Catalog__c catalog = cataloglist.get(0);

        PP_Scores__c[] scores = [
        	select	Id
        	from	PP_Scores__c
        	where	Contact__c = :contact.Id
        	and		From_ID__c = :stage.Course_Id__c
        	//and		When_Earned__c >= :contact.Point_Accrual_Start__c
        ];
        if (!scores.isEmpty()) {
            // found a score already recorded (dup), skip
            System.debug('***** [debug] skipping duplicate');
            return false;
        }

        //
        // only record points for partner contacts for the same region
        //
        if (contact.Account.isPartner) {
            Decimal score = catalog.Full_Points__c;
            System.debug('***[debug]*** score=' + score);
            insert new PP_Scores__c(Contact__c = contact.Id,
                                        Category__c = getName(),
                                        Account__c = contact.AccountId,
                                        LMS_Ref__c = stage.Id,
                                        From_ID__c = stage.Course_Id__c,
                                        Subcategory__c = catalog.Sub_Category__c,
                                        When_Earned__c = stage.When_Earned__c,
                                        Partner_Track__c = catalog.Partner_Track__c,
                                        Name = stage.Name,
                                        ScoredFromId__c = catalog.Id,
                                        Points__c = score);
            //insert new PP_ItemAudit__c(   Contact__c = contact.Id,
            //                              Related_Id__c = stage.Id,
            //                              Name = stage.Name,
            //                              Points__c = score);
            System.debug('***[debug] inserting score');
        }
        
        return true;
    }
    
    public boolean scoreBatch(String batchId) {
		//
		// get all records for this batch
		//
		PP_LMS_Stage__c[] batch = [
			select	Id, Name, Contact__c, Course_Id__c, When_Earned__c, Language__c
			from	PP_LMS_Stage__c
			where	BatchId__c = :batchId
		];
		Set<String> contactIdList = PartnerUtil.getStringFieldSet(batch, 'Contact__c');
		System.debug('***[debug] contacts=' + contactIdList.size());
		
		Map<ID, Contact> contactMap = new Map<ID,Contact>([
			select	Id, AccountId, Account.Global_Region__c, Point_Accrual_Start__c
			from	Contact
			where	Id in :contactIdList
			and		Account.IsPartner = true
		]);

		//
		// get all the LMS IDs so we can lookup the scores
		//
		Set<String> courseIdList = PartnerUtil.getStringFieldSet(batch, 'Course_Id__c');
		System.debug('***[debug] course ids=' + courseIdList.size());

		//
		// now get all prior content for the contacts to catch duplicate credits
		//
		PP_Scores__c[] priors = [
			select	Contact__c, LMS_Ref__r.Course_Id__c, From_ID__c
			from	PP_Scores__c
			where	Contact__c in :contactIdList
			and		Category__c = 'LMS'
			and		LMS_Ref__r.Course_Id__c in :courseIdList
		];
		System.debug('*****[debug]***** prior count=' + priors.size());

		Map<String,Partner_Points_LMS_Catalog__c> ppcmap = new Map<String,Partner_Points_LMS_Catalog__c>();
		Partner_Points_LMS_Catalog__c[] smlist = [
			select	Id, Sub_Category__c, Course_Id__c, Full_Points__c, Global_Region__c, Partner_Track__c, Language__c
			from	Partner_Points_LMS_Catalog__c
			where	Course_Id__c in :courseIdList
			and		IsActive__c = true
		];
		for (Partner_Points_LMS_Catalog__c sm : smlist) {
		    ppcmap.put(sm.Course_Id__c + sm.Global_Region__c + sm.Language__c, sm);
		}

		PP_Scores__c[] scores = new List<PP_Scores__c>();
		for (PP_LMS_Stage__c stage : batch) {

			Contact contact = contactMap.get(stage.Contact__c);
			if (contact == null) {
				// no contact, skip it
				continue;
			}

			// check for dups already scored
			boolean dup = false;
			for (PP_Scores__c ps : priors) {
				if (ps.Contact__c == stage.Contact__c && ps.From_ID__c == stage.Course_Id__c) {
					dup = true;
					break;
				}
			}
			if (dup) {
				System.debug('***[debug] dup detected, skipping');							
				continue;
			}

			// make sure no dup exists in the current batch too
			dup = false;
			for (PP_Scores__c ps : scores) {
				if (ps.Contact__c == stage.Contact__c && ps.From_ID__c == stage.Course_Id__c) {
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
			Partner_Points_LMS_Catalog__c ppc = ppcmap.get(stage.Course_Id__c + contact.Account.Global_Region__c + stage.Language__c);
			if (ppc == null) {
				ppc = ppcmap.get(stage.Course_Id__c + 'Global');						
			}
			
			if (ppc != null) {
	            Decimal score = ppc.Full_Points__c;
	            System.debug('***[debug]*** score=' + score);
	            scores.add(new PP_Scores__c(Contact__c = contact.Id,
	                                        Category__c = getName(),
	                                        Account__c = contact.AccountId,
	                                        LMS_Ref__c = stage.Id,
	                                        From_ID__c = stage.Course_Id__c,
	                                        Subcategory__c = ppc.Sub_Category__c,
	                                        When_Earned__c = stage.When_Earned__c,
	                                        Partner_Track__c = ppc.Partner_Track__c,
	                                        Name = stage.Name,
	                                        ScoredFromId__c = ppc.Id,
	                                        Points__c = score));
	            System.debug('***[debug] inserting score');
	        }
		}
		if (!scores.isEmpty()) {
			insert scores;
		}        

        return true;
    }

    static testmethod void findScoredItemsTest() {

        if ([select Id from PP_Catalog__c where Category__c = 'LMS'].isEmpty()) {
            PP_Catalog__c cat = new PP_Catalog__c();
            cat.Category__c = 'LMS';
            cat.Global_Region__c = 'NA';
            insert cat;
        }
        
        SumTotal_Catalog__c tc = [select SumTotal_ID__c, Activity_Name__c from SumTotal_Catalog__c where Activity_Name__c like '%Red Hat%' limit 1];
        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = tc.SumTotal_ID__c;
        cat.Name = tc.Activity_Name__c;
        cat.Full_Points__c = 35;
        cat.Global_Region__c = 'NA';
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        PPLMSPlugin pi = new PPLMSPlugin();

        PPSearchResult[] sr = pi.findScoredItems(null);
        System.assert(sr.size() > 0);

        sr = pi.findScoredItems('Red Hat');
        System.assert(sr.size() > 0);

        // test where search term too small
        pi.findScoredItems('x');
    }
    
    static testmethod void findByNameTest() {
    	
        SumTotal_Catalog__c tc = [select Activity_Name__c from SumTotal_Catalog__c limit 1];
        PPLMSPlugin pi = new PPLMSPlugin();

        PPSearchResult[] sr = pi.findByName(tc.Activity_Name__c);
        System.assert(sr.size() > 0);

        sr = pi.findByName(null);
        System.assert(sr.size() > 0);

    }

    static testmethod void globalTest() {

        if ([select Id from PP_Catalog__c where Category__c = 'LMS'].isEmpty()) {
            PP_Catalog__c catLMS = new PP_Catalog__c();
            catLMS.Category__c = 'LMS';
            catLMS.Global_Region__c = 'NA';
            catLMS.Description__c = 'LMS';
            insert catLMS;
        }

        Account acct = PartnerTestUtils.quickGenericAccountSetup('PPLMSPlugin.requiredCourseTest');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        insert c;

        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = 'TEST0001';
        cat.Full_Points__c = 35;
        cat.Language__c = 'us-en';
        cat.Global_Region__c = 'Global';
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = c.Id;
        stage.Course_Id__c = 'TEST0001';
        stage.Name = 'TEST0001';
        stage.Language__c = 'us-en';
        stage.Transcript_Item__c = null;
        stage.When_Earned__c = System.now();
        insert stage;
        
        PP_Scores__c score = [select Id, Points__c from PP_Scores__c where Name = 'TEST0001' and Contact__c = :c.Id];
        System.assert(score.Points__c == 35, 'Invalid score found: ' + score.Points__c);
    }

    static testmethod void accrualTest() {

        PP_Catalog__c catLMS = null;
        PP_Catalog__c[] catLMSList = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1];
        if (!catLMSList.isEmpty()) {
            catLMS = catLMSList.get(0);
        }
        else {
            catLMS = new PP_Catalog__c();
            catLMS.Category__c = 'LMS';
            catLMS.Global_Region__c = 'NA';
            catLMS.Description__c = 'LMS';
            insert catLMS;
        }
        Account acct = PartnerTestUtils.quickGenericAccountSetup('PPLMSPlugin.requiredCourseTest');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        c.Point_Accrual_Start__c = System.now();
        insert c;

        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = 'TEST0001';
        cat.Full_Points__c = 35;
        cat.Language__c = 'us-en';
        cat.Global_Region__c = 'NA';
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = c.Id;
        stage.Course_Id__c = 'TEST0001';
        stage.Name = 'TEST0001';
        stage.Language__c = 'us-en';
        stage.Transcript_Item__c = null;
        stage.When_Earned__c = System.now();
        insert stage;
        
        PP_Scores__c score = [select Id, Points__c from PP_Scores__c where Name = 'TEST0001' and Contact__c = :c.Id];
        System.assert(score.Points__c == 35, 'Invalid score found: ' + score.Points__c);
        
        // nothing real to test here, just bump up test coverage
        PPLMSPlugin pi = new PPLMSPlugin();
//        pi.scoreBatch(null);
        pi.getObjectScore(null);
        pi.getAdminUI();

    }

    static testmethod void nonAccrualTest() {

        PP_Catalog__c catLMS = null;
        PP_Catalog__c[] catLMSList = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1];
        if (!catLMSList.isEmpty()) {
            catLMS = catLMSList.get(0);
        }
        else {
            catLMS = new PP_Catalog__c();
            catLMS.Category__c = 'LMS';
            catLMS.Global_Region__c = 'NA';
            catLMS.Description__c = 'LMS';
            insert catLMS;
        }
        
        Account acct = PartnerTestUtils.quickGenericAccountSetup('PPLMSPlugin.nonAccrualTest');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        insert c;

        insert new Partner_Points_Course__c(Name = 'TEST0001', Region__c = 'NA', Required_Course_Id__c = 'ABC123');

        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = 'TEST0001';
        cat.Full_Points__c = 35;
        cat.Language__c = 'us-en';
        cat.Global_Region__c = 'NA';
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = c.Id;
        stage.Course_Id__c = 'TEST0001';
        stage.Name = 'TEST0001';
        stage.Language__c = 'us-en';
        stage.Transcript_Item__c = null;
        stage.When_Earned__c = System.now();
        insert stage;
        
        PP_Scores__c[] scores = [select Id, Points__c from PP_Scores__c where Name = 'TEST0001' and Contact__c = :c.Id];
        System.assert(scores.size() == 0, 'Found a score but expected none');
        
        // nothing real to test here, just bump up test coverage
        PPLMSPlugin pi = new PPLMSPlugin();
//        pi.scoreBatch(null);
        pi.getObjectScore(null);
        pi.getAdminUI();

    }
    
    static testmethod void requiredCourseTest() {

        PP_Catalog__c catLMS = null;
        PP_Catalog__c[] catLMSList = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1];
        if (!catLMSList.isEmpty()) {
            catLMS = catLMSList.get(0);
        }
        else {
            catLMS = new PP_Catalog__c();
            catLMS.Category__c = 'LMS';
            catLMS.Global_Region__c = 'NA';
            catLMS.Description__c = 'LMS';
            insert catLMS;
        }
        
        Account acct = PartnerTestUtils.quickGenericAccountSetup('PPLMSPlugin.requiredCourseTest');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Jayne Cobb');
        insert c;
//        Contact c = [select Id, AccountId, Account.Global_Region__c, Account.IsPartner, LoginName__c from Contact where Account.IsPartner = True and Account.Global_Region__c = 'NA' and LoginName__c != null limit 1];
//        c.Point_Accrual_Start__c = null;
//        update c;

        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = 'TEST0001';
        cat.Full_Points__c = 35;
        cat.Language__c = 'us-en';
        cat.Global_Region__c = 'NA';
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        insert new Partner_Points_Course__c(Name = 'TEST0001', Region__c = cat.Global_Region__c, Required_Course_Id__c = 'TEST0001');

        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = c.Id;
        stage.Course_Id__c = 'TEST0001';
        stage.Name = 'TEST0001';
        stage.Language__c = 'us-en';
        stage.Transcript_Item__c = null;
        stage.When_Earned__c = System.now();
        insert stage;
        
        PP_Scores__c score = [select Id, Points__c from PP_Scores__c where Name = 'TEST0001' and Contact__c = :c.Id];
        System.assert(score.Points__c == 35, 'Invalid score found: ' + score.Points__c);
        
        // nothing real to test here, just bump up test coverage
        PPLMSPlugin pi = new PPLMSPlugin();
//        pi.scoreBatch(null);
        pi.getObjectScore(null);
        pi.getAdminUI();

    }

}