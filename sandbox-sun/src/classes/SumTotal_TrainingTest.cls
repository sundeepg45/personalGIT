@isTest(SeeAllData=true)
private class SumTotal_TrainingTest {

    static testmethod void testCourse() {
        // have to use an existing user here to avoid SF "setup object" errors
        User u = [select Id, ContactId from User where Contact.Account.IsPartner = true and Contact.Account.Global_Region__c = 'NA' and IsActive = true and UserType != 'Standard' limit 1];

        SumTotal_Catalog__c cat = new SumTotal_Catalog__c();
        cat.Activity_Name__c = 'chicken';
        cat.Global_Region__c = 'NA';
        cat.Language__c = 'en_US';
        cat.SumTotal_ID__c = 'chicken';
        cat.Training_Type__c = 'course';
        insert cat;

        Partner_Points_LMS_Catalog__c lcat = new Partner_Points_LMS_Catalog__c();
        lcat.Course_ID__c = 'chicken';
        lcat.Full_Points__c = 35;
        lcat.Global_Region__c = 'NA';
        lcat.Language__c = 'en_US';
        lcat.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS'].Id;
        lcat.SumTotal_Catalog__c = cat.Id;
        insert lcat;

        SumTotal_Training__c pt = new SumTotal_Training__c();
//        pt.Catalog__c = cat.Id;
        pt.External_ID__c = 'attempt.chicken';
        pt.SumTotal_Activity_ID__c = 'chicken';
        pt.User__c = u.Id;
        pt.When_Earned__c = Datetime.newInstance(2012,1,1,12,0,0);
        insert pt;

        PP_LMS_Stage__c stage = [select Id from PP_LMS_Stage__c where Contact__c = :u.ContactId and Course_Id__c = :cat.SumTotal_ID__c];
    }

}