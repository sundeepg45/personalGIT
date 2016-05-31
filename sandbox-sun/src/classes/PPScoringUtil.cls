public without sharing class PPScoringUtil {

    private PP_Cap__c[] caps = new List<PP_Cap__c>();
    static private Partner_Points_Course__c[] requiredCourses = null;
    static private Map<String, Boolean> regionEligibilityRequired = null;


    public PPScoringUtil() {
        caps = [select Cap_Points__c, Global_Region__c, Partner_Type__c, Partner_Tier__c, Partner_Function__c from PP_Cap__c];
    }

    static public String getRequiredCourseIds(String globalRegion) {
        String courses = '';
        if (requiredCourses == null) {
            requiredCourses = [select Id, Region__c, Required_Course_Id__c from Partner_Points_Course__c];
        }
        for (Partner_Points_Course__c ppc : requiredCourses) {
            if (ppc.Region__c == globalRegion) {
                courses += ppc.Required_Course_Id__c + ' ';
            }
        }
        return courses;
    }

    static public Map<String, Boolean> getRegionEligibilityRequiredMap() {
        if (regionEligibilityRequired == null){
            regionEligibilityRequired = new Map<String, Boolean>{'APAC' => false, 'EMEA' => false, 'LATAM' => false, 'NA' => false};

            List<Partner_Points_Course__c> reqCourses = [select Id, Region__c, Required_Course_Id__c from Partner_Points_Course__c];
            for (Partner_Points_Course__c ppc : reqCourses) {
                regionEligibilityRequired.put(ppc.Region__c, true);
            }
        }
        return regionEligibilityRequired;
    }

    public Integer getCap(Contact contact, String function) {
        for (PP_Cap__c cap : caps) {
            if (function != null) {
                if (cap.Global_Region__c == contact.Account.Global_Region__c &&
                    cap.Partner_Type__c == contact.Account.Finder_Partner_Type__c &&
                    cap.Partner_Tier__c == contact.Account.Finder_Partner_Tier__c &&
                    cap.Partner_Function__c == function) {
                    return cap.Cap_Points__c.intValue();
                }
            }
            else {
                if (cap.Global_Region__c == contact.Account.Global_Region__c &&
                    cap.Partner_Type__c == contact.Account.Finder_Partner_Type__c &&
                    cap.Partner_Tier__c == contact.Account.Finder_Partner_Tier__c &&
                    cap.Partner_Function__c == null) {
                    return cap.Cap_Points__c.intValue();
                }
            }
        }
        return null;
    }

    public void updateUserPoints(Set<String> contactIdList) { //Contact[] contacts) {
        Map<String, PP_User_Points__c> pointsMap = new Map<String, PP_User_Points__c>();
        //
        // We are intentionally NOT ignoring inactive records here because we need to detect
        // later if a record already exists for a contact, even if inactive.
        // DO NOT add "and IsActive__c == true" to this query.
        //
        for (PP_User_Points__c up : [
            select      Id, Account__c, Contact__c, IsActive__c, Current_Points__c, Expired_Points__c, Uncapped_Points__c
            from        PP_User_Points__c
            where       Contact__c in :contactIdList
        ]) {
            // zero them out on each recalc for accuracy, also zeros out inactive ones to keep Account aggregates accurate
            up.Current_Points__c = 0.0;
            up.Expired_Points__c = 0.0;
            up.Expiring_Points__c = 0.0;
            up.Uncapped_Points__c = 0.0;
            up.Presales_Points__c = 0.0;
            up.Sales_Points__c = 0.0;
            up.Delivery_Points__c = 0.0;
            pointsMap.put(up.Contact__c, up);
        }

        PP_Scores__c[] scores = [
            select  Points__c, Account__c, Contact__c, Points_Status__c, Expiring_Soon__c, Partner_Track__r.Partner_Function__c
            from    PP_Scores__c
            where   Contact__c in :contactIdList
            order by When_Earned__c
        ];
        Map<String,Contact> contactMap = new Map<String,Contact>([
            select  Id, Account.Global_Region__c, Account.Finder_Partner_Type__c, Account.Finder_Partner_Tier__c,
            		(select Partner_Track__r.Partner_Function__c from Contact_Tracks__r where Primary__c = True)
            from    Contact
            where   Id in :contactIdList
        ]);

        // accumulate them all
        for (PP_Scores__c score : scores) {
            PP_User_Points__c up = pointsMap.get(score.Contact__c);
            if (up == null) {
                // if doesn't exist, create
                up = new PP_User_Points__c();
                up.Contact__c = score.Contact__c;
                up.Account__c = score.Account__c;
                up.Current_Points__c = 0.0;
                up.Expired_Points__c = 0.0;
                up.Expiring_Points__c = 0.0;
                up.Uncapped_Points__c = 0.0;
                up.Presales_Points__c = 0.0;
                up.Sales_Points__c = 0.0;
                up.Delivery_Points__c = 0.0;
                up.IsActive__c = true;
                System.debug('++++++++++++++[debug]==== account=' + up.Account__c);
                pointsMap.put(up.Contact__c, up);
            }
            else if (up.IsActive__c == false) {
                System.debug('+++++++[debug]===== account is inactive: ' + up.Account__c);
                // record exists but is inactive, ignore
                continue;
            }

            System.debug('++++[debug] updateUserPoints:contactId=' + up.Contact__c + ', accountid=' + up.Account__c);
            System.debug('++++[debug] score points=' + score.Points__c + ', status=' + score.Points_Status__c);

            Integer cap = null;
            Integer currentCap = null;
            Contact contact = contactMap.get(score.Contact__c);
            Contact_Track__c[] ctracks = contact.Contact_Tracks__r;

            if (score.Partner_Track__r != null) {
                cap = getCap(contact, score.Partner_Track__r.Partner_Function__c);
            }
            else {
                cap = getCap(contact, null);
                currentCap = cap;
            }

            if (score.Points_Status__c == 'Active') {
                up.Current_Points__c += score.Points__c;
                up.Uncapped_Points__c += score.Points__c;
                if (score.Partner_Track__r != null) {
                    String pfn = score.Partner_Track__r.Partner_Function__c;

                    String contactTrack = '';
                    if (!ctracks.isEmpty()) {
                        // first row will always be the primary track based on the soql above
	                    Contact_Track__c primaryTrack = ctracks.get(0);
                        contactTrack = primaryTrack.Partner_Track__r.Partner_Function__c;
                    }
                    if (pfn == 'Delivery and Sales Engineer') {
                        // TECH role special case
                        if (contactTrack == 'Sales Engineer' || contactTrack == 'Delivery') {
                            pfn = contactTrack;
                        }
                    }
                    if (contactTrack == pfn) {
                        if (pfn == 'Sales') {
                            up.Sales_Points__c += score.Points__c;
                            if (cap != null && up.Sales_Points__c > cap) up.Sales_Points__c = cap;
                        }
                        else if (pfn == 'Sales Engineer') {
                            up.Presales_Points__c += score.Points__c;
                            if (cap != null && up.Presales_Points__c > cap) up.Presales_Points__c = cap;
                        }
                        else if (pfn == 'Delivery') {
                            up.Delivery_Points__c += score.Points__c;
                            if (cap != null && up.Delivery_Points__c > cap) up.Delivery_Points__c = cap;
                        }
                        else {
                            System.debug('Partner Function not recognized: ' + pfn);
                        }
                    }
                }
            }
            else if (score.Points_Status__c == 'Expired') {
                up.Expired_Points__c += score.Points__c;
            }

            if (score.Expiring_Soon__c) {
                up.Expiring_Points__c += score.Points__c;
            }

            if (currentCap == null) {
                currentCap = getCap(contact, null);
            }
            if (currentCap != null && up.Current_Points__c > currentCap) {
                up.Current_Points__c = currentCap;
            }
            else if (currentCap == null) {
                if (up.Current_Points__c > Partner_Points__c.getInstance(contact.Account.Global_Region__c).Max_User_Points__c) {
                    up.Current_Points__c = Partner_Points__c.getInstance(contact.Account.Global_Region__c).Max_User_Points__c;
                }
            }

        }

        upsert pointsMap.values();
    }

    public void updateAccountPoints(Set<String> accountIdList) {
        AggregateResult[] groupedResults = [
            select      Account__c, Sum(Current_Points__c), Sum(Expired_Points__c), Sum(Expiring_Points__c), Sum(Uncapped_Points__c),
                        Sum(Sales_Points__c), Sum(PreSales_Points__c), Sum(Delivery_Points__c)
            from        PP_User_Points__c
            where       Account__c in :accountIdList
            group by    Account__c
        ];

        Map<String, PP_Account_Points__c> pointMap = new Map<String, PP_Account_Points__c>();
        for (PP_Account_Points__c accountPoints : [
            select  Id, Account__c
            from    PP_Account_Points__c
            where   Account__c in :accountIdList
        ]) {
            pointMap.put(accountPoints.Account__c, accountPoints);
        }

        for (AggregateResult result : groupedResults) {
            String accountId = (String) result.get('Account__c');
            Integer points = 0;
            if (result.get('expr0') != null) points = ((Decimal) result.get('expr0')).intValue();
            Integer expiredPoints = 0;
            if (result.get('expr1') != null) expiredPoints = ((Decimal) result.get('expr1')).intValue();
            Integer expiringPoints = 0;
            if (result.get('expr2') != null) expiringPoints = ((Decimal) result.get('expr2')).intValue();
            Integer uncappedPoints = 0;
            if (result.get('expr3') != null) uncappedPoints = ((Decimal) result.get('expr3')).intValue();
            Integer salesPoints = 0;
            if (result.get('expr4') != null) salesPoints = ((Decimal) result.get('expr4')).intValue();
            Integer presalesPoints = 0;
            if (result.get('expr5') != null) presalesPoints = ((Decimal) result.get('expr5')).intValue();
            Integer deliveryPoints = 0;
            if (result.get('expr6') != null) deliveryPoints = ((Decimal) result.get('expr6')).intValue();

            System.debug('****[debugtmp]**** account=' + accountId + ', points=' + points);

            PP_Account_Points__c ap = pointMap.get(accountId);
            if (ap == null) {
                ap = new PP_Account_Points__c(Account__c = accountId);
                pointMap.put(accountId, ap);
            }
            ap.Current_Points__c = points;
            ap.Expired_Points__c = expiredPoints;
            ap.Expiring_Points__c = expiringPoints;
            ap.Total_Uncapped_Points__c = uncappedPoints;
            ap.Sales_Points__c = salesPoints;
            ap.PreSales_Points__c = presalesPoints;
            ap.Delivery_Points__c = deliveryPoints;
        }

        upsert pointMap.values();

    }

    static public void handleUserUpdates(Map<String,Boolean> contactIdMap) {
        if (System.isFuture()){
            handleUserUpdatesInternal(contactIdMap);
        } else {
            handleUserUpdatesFuture(contactIdMap);
        }
    }

    @future
    static public void handleUserUpdatesFuture(Map<String,Boolean> contactIdMap) {
        handleUserUpdatesInternal(contactIdMap);
    }

    static private void handleUserUpdatesInternal(Map<String,Boolean> contactIdMap) {
        PP_User_Points__c[] points = [select Id, Contact__c, IsActive__c from PP_User_Points__c where Contact__c in :contactIdMap.keySet()];
        for (PP_User_Points__c point : points) {
            point.IsActive__c = contactIdMap.get(point.Contact__c);
        }
        if (points.size() > 0) {
            update points;
        }

    }

    @future
    static public void handleUserInserts(Map<String, Boolean> contactIdMap) {
        //
        // Inserting a new User - could be associating to an existing Points contact.
        //
        PP_User_Points__c[] points = [select Id, Contact__c, IsActive__c from PP_User_Points__c where Contact__c in :contactIdMap.keySet()];
        for (PP_User_Points__c point : points) {
            point.IsActive__c = contactIdMap.get(point.Contact__c);
        }
        if (points.size() > 0) {
            update points;
        }
    }

    static public Boolean isEligible(Contact contact, DateTime when_earned, List<Contact> toupdate) {
        if (getRequiredCourseIds(contact.Account.Global_Region__c).length() == 0) {
            //
            // There are no required courses for the contact's region
            //
            if (contact.Point_Accrual_Start__c == null) {
                Boolean exists = false;
                for (Contact c : toupdate) {
                    if (c.Id == contact.Id) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    contact.Point_Accrual_Start__c = when_earned;
                    toupdate.add(contact);
                }
            }
            return true;
        }
        else {
            //
            // There are one or more required courses, so make sure the contact has taken them
            //
            if (contact.Point_Accrual_Start__c == null || contact.Point_Accrual_Start__c > when_earned) {
                return false;
            }
        }
        return true;
    }

    static private testmethod void testRollups() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Tartarus');
        Contact c1 = PartnerTestUtils.makeContact(acct.Id, 'hercules');
        c1.Point_Accrual_Start__c = System.now();
        insert c1;
        Contact c2 = PartnerTestUtils.makeContact(acct.Id, 'ares');
        c1.Point_Accrual_Start__c = System.now();
        insert c2;

        // disable accrual checking
//      delete [select Id from Partner_Points_Course__c];

        //
        // setup tracks
        //
        PartnerTrack__c track_sales = new PartnerTrack__c();
        track_sales.Partner_Function__c = 'Sales';
        track_sales.Product_of_Interest__c = 'Cloud';
        insert track_sales;

        PartnerTrack__c track_delivery = new PartnerTrack__c();
        track_delivery.Partner_Function__c = 'Delivery';
        track_delivery.Product_of_Interest__c = 'Cloud';
        insert track_delivery;

        Contact_Track__c ctrack = new Contact_Track__c();
        ctrack.Partner_Track__c = track_sales.Id;
        ctrack.Contact__c = c1.Id;
        ctrack.Primary__c = True;
        insert ctrack;

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

        //
        // setup course catalog
        //
        Partner_Points_LMS_Catalog__c cat = new Partner_Points_LMS_Catalog__c();
        cat.Course_ID__c = 'TEST0001';
        cat.Full_Points__c = 35;
        cat.Language__c = 'us-en';
        cat.Global_Region__c = 'NA';
        cat.Partner_Track__c = track_sales.Id;
        cat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat.Sub_Category__c = 'E-Learning without Exam';
        insert cat;

        Partner_Points_LMS_Catalog__c cat2 = new Partner_Points_LMS_Catalog__c();
        cat2.Course_ID__c = 'TEST0002';
        cat2.Full_Points__c = 40;
        cat2.Language__c = 'us-en';
        cat2.Global_Region__c = 'NA';
        cat2.Partner_Track__c = track_delivery.Id;
        cat2.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1].Id;
        cat2.Sub_Category__c = 'E-Learning without Exam';
        insert cat2;

        Test.startTest();

        // setup and fire trigger

        //
        // Scenario 1: Contact 1 takes 1 sales and 1 delivery course
        //
        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = c1.Id;
        stage.Course_Id__c = 'TEST0001';
        stage.Name = 'TEST0001';
        stage.Language__c = 'us-en';
        stage.Transcript_Item__c = null;
        stage.When_Earned__c = System.now();

        PP_LMS_Stage__c stage2 = new PP_LMS_Stage__c();
        stage2.Contact__c = c1.Id;
        stage2.Course_Id__c = 'TEST0002';
        stage2.Name = 'TEST0002';
        stage2.Language__c = 'us-en';
        stage2.Transcript_Item__c = null;
        stage2.When_Earned__c = System.now();

        insert new PP_LMS_Stage__c[] { stage, stage2 };

        PP_Scores__c score = [select Id, Points__c from PP_Scores__c where Name = 'TEST0001' and Contact__c = :c1.Id];
        System.assert(score.Points__c == 35, 'Invalid score found: ' + score.Points__c);

        PP_User_Points__c up = [select Id, Current_Points__c, Sales_Points__c, Delivery_Points__c from PP_User_Points__c where Contact__c = :c1.Id];
        System.assert(up.Current_Points__c == 75, 'User rollup for current points not correct: ' + up.Current_Points__c);
        System.assert(up.Sales_Points__c == 35, 'User rollup for sales points not correct: ' + up.Sales_Points__c);
        System.assert(up.Delivery_Points__c == 0, 'User rollup for delivery points not correct: ' + up.Delivery_Points__c);

        PP_Account_Points__c ap = [select Id, Sales_Points__c, Delivery_Points__c from PP_Account_Points__c where Account__c = :acct.Id];
        System.assert(ap.Sales_Points__c == 35, 'Account rollup for sales points not correct: ' + ap.Sales_Points__c);

        Test.stopTest();

    }
}