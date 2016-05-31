@isTest(SeeAllData=true)
private class PartnerRequal_UpdateStatus {

    static testMethod void myUnitTest() {
        Account acct = PartnerTestUtils.quickRequalAccountSetup('Complete');
        
        acct.RequalificationDate__c = System.today().addDays(-1);
        update acct;

		acct = [select Id, StatusExpirationDate__c from Account where Id = :acct.Id];
        System.debug('*****[debug]***** date=' + acct.StatusExpirationDate__c);
		System.assert(acct.StatusExpirationDate__c > System.today());        
    }
}