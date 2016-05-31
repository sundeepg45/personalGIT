@isTest(SeeAllData = true)
private class Account_FinancialReviewTest {

    static testMethod void myUnitTest() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Account_FinancialReviewTet');
//    	Account acct = [select Id from Account where IsPartner = true and Is_Financials_Approved__c = false limit 1];
    	acct.Is_Financials_Approved__c = True;
    	update acct;
    }
}