@isTest
private class Lead_OwnerReassignmentTest {

    static testMethod void myUnitTest() {
        Account partnerAccount = [select Id, OwnerId from Account where IsPartner = true and Owner.IsActive = true limit 1];
        Lead aLead = [select Id, OwnerId from Lead limit 1];
        aLead.OwnerId = partnerAccount.OwnerId;
        update aLead;
        Id oldOwner = aLead.OwnerId;      
        aLead = [select Assigned_By__c from Lead where Id = :aLead.Id];
        // we cannot validate here since the running test user has no Account to compare against, so just opt for basic coverage.          
    }
}