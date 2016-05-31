@isTest
private class RequalificationHelperTest {

    static testMethod void myUnitTest() {
        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        Set<Id> overdue = new Set<Id>();
        overdue.add(account.id);
        Test.startTest();
        RequalificationHelper.markOverdueAccounts(overdue);
        RequalificationHelper.reinstateOverdueAccounts(overdue);
        Test.stopTest();
    }
}