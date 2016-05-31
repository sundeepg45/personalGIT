@isTest(SeeAllData=true)
private class SumTotal_AccredidationTest {

    static testmethod void testAccredidation() {
        // have to use an existing user here to avoid SF "setup object" errors
        User u = [select Id, ContactId, Contact.Account.Id from User where Contact.Account.IsPartner = true and Contact.Account.Global_Region__c = 'NA' and IsActive = true and UserType != 'Standard' limit 1];

        SumTotal_Catalog__c cat = new SumTotal_Catalog__c();
        cat.Activity_Name__c = 'chicken';
        cat.Global_Region__c = 'NA';
        cat.Language__c = 'en_US';
        cat.SumTotal_ID__c = 'chicken';
        cat.Training_Type__c = 'course';
        cat.IsCertification__c = True;
		insert cat;

        PartnerTraining__c pt = new PartnerTraining__c();
        pt.SumTotal_Activity_ID__c =  'chicken';
        pt.Contact__c = u.ContactId;
        pt.Partner__c = u.Contact.Account.Id;
        pt.Date_Achieved__c = Date.newInstance(2012,1,1);
        insert pt;

        PartnerTraining__c cert = [select Id from PartnerTraining__c where Contact__c = :u.ContactId and LMS_Assignment__c = :cat.Id];
    }

}