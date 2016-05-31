public with sharing class PPUserView {
    
    public class Score {
        public String   id {get; set; }
        public String   name {get; set; }
        public String   cat {get; set; }
        public Boolean  expiringSoon {get; set; }
        public Double   points {get; set; }
        public String   status {get; set; }
        public String   subcat {get; set; }
        public DateTime whenEarned {get; set; }
        public String   track {get; set; }
        public String   whatid {get; set; }
        public String   scoredFrom {get; set; }
    }
    
    public class ContentStage {
        public Boolean  eligible {get; set; }
        public String   id {get; set; }
        public String   name {get; set;}
        public String   batchid {get; set; }
        public String   contentid {get; set; }
        public DateTime whenEarned {get; set; }
    }

    public class LMSStage {
        public Boolean  eligible {get; set; }
        public String   id {get; set; }
        public String   name {get; set;}
        public String   batchid {get; set; }
        public String   courseid {get; set; }
        public String   region {get; set; }
        public String   language {get; set; }
        public String   trainingType {get; set; }
        public String   transcriptItem {get; set; }
        public DateTime whenEarned {get; set; }
    }

    public Contact theContact {get; set; }
    public String contactId { get; set; }
    public Score[] scores { get; private set; }
    public ContentStage[] contents {get; private set; }
    public LMSStage[] lmss {get; private set; }
    public PP_User_Points__c userPoints { get; private set; }


    public PPUserView() {
        contactId = ApexPages.currentPage().getParameters().get('id');
        if (contactId != null) getPoints();
    }

    public PageReference getPoints() {
        theContact = [select Id, Point_Accrual_Start__c from Contact where Id = :contactId];
        userPoints = [
            select  Id, Current_Points__c, Delivery_Points__c, Expired_Points__c, Expiring_Points__c, PreSales_Points__c, Sales_Points__c,
                    Total_Lifetime_Points__c, Uncapped_Points__c
            from    PP_User_Points__c
            where   Contact__c = :contactId
        ];

        scores = new List<Score>();
        PP_Scores__c[] ascores = [
            select  Id, Name, Category__c, Expiring_Soon__c, Points__c, Points_Status__c, SubCategory__c, When_Earned__c,
                    BatchItemStageRef__c, ContentRef__c, LMS_Ref__c, Partner_Track__r.Track__c, ScoredFromId__c
            from    PP_Scores__c
            where   Contact__c = :contactId
            order by When_Earned__c
        ];
        for (PP_Scores__c score : ascores) {
            Score s = new Score();
            s.id = score.Id;
            s.name = score.Name;
            s.cat = score.Category__c;
            s.expiringSoon = score.Expiring_Soon__c;
            s.points = score.Points__c;
            s.status = score.Points_Status__c;
            s.subcat = score.SubCategory__c;
            s.whenEarned = score.When_Earned__c;
            s.track = score.Partner_Track__r.Track__c;
            s.scoredFrom = score.ScoredFromId__c;
            if (score.BatchItemStageRef__c != null) {
                s.whatid = score.BatchItemStageRef__c;
            }
            if (score.ContentRef__c != null) {
                s.whatid = score.ContentRef__c;
            }
            if (score.LMS_Ref__c != null) {
                s.whatid = score.LMS_Ref__c;
            }
            scores.add(s);
        }
        
        contents = new List<ContentStage>();
        PP_ContentStage__c[] cslist = [
            select  Id, Name, ContentBatch__c, ContentId__c, When_Earned__c
            from    PP_ContentStage__c
            where   Contact__c = :contactId
            order by When_Earned__c
        ];
        for (PP_ContentStage__c cs : cslist) {
            ContentStage c = new ContentStage();
            c.id = cs.id;
            c.name = cs.Name;
            c.batchid = cs.ContentBatch__c;
            c.contentid = cs.ContentId__c;
            c.whenEarned = cs.When_Earned__c;
            if (theContact.Point_Accrual_Start__c != null)
                c.eligible = cs.When_Earned__c >= theContact.Point_Accrual_Start__c;
            contents.add(c);
        }
        
        lmss = new List<LMSStage>();
        PP_LMS_Stage__c[] lmslist = [
            select  Id, Name, Course_Id__c, Global_Region__c, Language__c, Training_Type__c, Transcript_Item__c, When_Earned__c
            from    PP_LMS_Stage__c
            where   Contact__c = :contactId
            order by When_Earned__c
        ];
        for (PP_LMS_Stage__c lms : lmslist) {
            LMSStage ls = new LMSStage();
            ls.id = lms.id;
            ls.name = lms.Name;
            ls.courseid = lms.Course_Id__c;
            ls.region = lms.Global_Region__c;
            ls.language = lms.Language__c;
            ls.trainingType = lms.Training_Type__c;
            ls.transcriptItem = lms.Transcript_Item__c;
            ls.whenEarned = lms.When_Earned__c;
            if (theContact.Point_Accrual_Start__c != null)
                ls.eligible = lms.When_Earned__c >= theContact.Point_Accrual_Start__c;

            lmss.add(ls);
        }


        return null;
    }

    @istest(SeeAllData=true)    
    static private void simpleTest() {
        PP_Scores__c[] scores = [select Contact__c from PP_Scores__c limit 1];
        if (scores.size() > 0) {
            PP_Scores__c score = scores.get(0);
            ApexPages.currentPage().getParameters().put('id', score.Contact__c);
            PPUserView uv = new PPUserView();
        }
    }
}