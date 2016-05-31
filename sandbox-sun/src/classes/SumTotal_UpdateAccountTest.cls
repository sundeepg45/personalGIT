@isTest(SeeAllData=true)
private class SumTotal_UpdateAccountTest {
    static testmethod void basicTest() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.basicAccountSetup('Los Pollos Hermanos');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'gustavo.fring@madrigal.com');
        insert c;
        User u = PartnerTestUtils.makeUser(acct, c);
        u.SumTotal_ID__c = 'testing123';
        insert u;
        acct.Global_Region__c = 'EMEA';
        update acct;
        
        SumTotal_Request__c[] request = [select Id from SumTotal_Request__c where User__c = :u.Id];
        System.assert(request.size() == 1, 'expected to find a sumtotal request in the queue');
    }
}