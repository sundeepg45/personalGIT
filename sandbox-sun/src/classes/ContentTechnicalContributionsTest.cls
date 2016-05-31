@isTest
private class ContentTechnicalContributionsTest {

    static testMethod void myUnitTest() {
        //User u = [select id from User where email like 'mmendoza@redhat.com%' limit 1];
        //System.runAs(u) {
            Temporal_Content__c tc = new Temporal_Content__c();
            tc.Approval_Status__c = 'New';
            insert tc;
    /*
            Attachment a = new Attachment();
            a.ParentId = tc.Id;
            a.Name = 'test';
            a.Body = Blob.valueOf('hello');
            a.Description = 'test attachment';
            a.ContentType = 'application/text';
            insert a;
            tc.Approval_Status__c = 'Approved';
    */
            update tc;
        //}
    }
}