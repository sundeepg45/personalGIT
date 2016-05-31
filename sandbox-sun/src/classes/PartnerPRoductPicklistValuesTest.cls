@isTest
private class PartnerPRoductPicklistValuesTest {

    static testMethod void myUnitTest() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('PartnerProductPicklistValuesTest');
        update acct;
        PartnerProduct__c prod = PartnerTestUtils.makeProduct(acct.Id);
        insert prod;
        update prod;
    }
}