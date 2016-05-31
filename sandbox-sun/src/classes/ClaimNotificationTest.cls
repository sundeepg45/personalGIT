@IsTest
private class ClaimNotificationTest {
    public static testmethod void testClaimNotification() {
		Account testacc = new Account();
		testacc.Name = 'Account';
		testacc.isAccountActive__c = true;
		testacc.Global_Region__c = 'NA';
        testacc.RecordTypeId = [
            select Id
            from RecordType
            where SObjectType = 'Account'
            and Name = 'NA Partner'
        ].Id;
		insert testacc;

        RecordType objRecordType = [
            select Id
              from RecordType
             where Name = 'MDF'
               and SobjectType='SFDC_Budget__c'
        ];

        SFDC_Budget__c testBudget=new SFDC_Budget__c();
        testBudget.Name='createClaimMail';
        testBudget.Account_master__c=testacc.Id;
        testBudget.Active__c=true;
        testBudget.RecordtypeId=objRecordType.Id;
        insert testBudget;

        SFDC_MDF__c testReq=new SFDC_MDF__c();
        testReq.Name='test';
        testReq.Account_master__c=testacc.Id;
        testReq.Budget__c=testBudget.Id;
        testReq.Activity_Type__c='Dedicated Red Hat Product Specialist';
        testReq.Approval_Status__c='Draft';
        insert testReq;

        SFDC_MDF_Claim__c testclaim=new SFDC_MDF_Claim__c();
        testclaim.Name='test';
        testclaim.Account__c=testacc.Id;
        testclaim.Budget__c=testBudget.Id;
        testclaim.Fund_Request__c=testReq.Id;
        testclaim.Approval_Status__c='Draft';
        insert testclaim;

        Attachment testatt = new Attachment();
        testatt.Name = 'Attachment';
        testatt.ParentId = testacc.Id;
        testatt.Body = Blob.valueOf('Attachment');
        insert testatt;

        Red_Hat_Attachment__c newRhatt=new Red_Hat_Attachment__c();
        newRhatt.Name='testRh';
        newRhatt.Fund_Claim__c=testclaim.Id;
        insert newRhatt;

        Attachment att_new=new Attachment();
        att_new.Name=testatt.Name;
        att_new.Body=testatt.Body;
        att_new.ParentId=testclaim.Id;
        insert att_new;

        Attachment Rh_att_new=new Attachment();
        Rh_att_new.Name=testatt.Name;
        Rh_att_new.Body=testatt.Body;
        Rh_att_new.ParentId=newRhatt.Id;
        insert Rh_att_new;

        ClaimNotification.createClaimMail(testclaim);
    }
}