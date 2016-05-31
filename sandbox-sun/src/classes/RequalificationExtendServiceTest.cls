@isTest
private class RequalificationExtendServiceTest {

    static testMethod void myUnitTest() {
		Account acct = [select id, RequalificationDate__c, Requalification_Extended__c from Account where isPartner = true and RequalificationDate__c != null and Requalification_Extended__c = false limit 1];
		Date requalDate = acct.RequalificationDate__c;
		RequalificationExtendService.extendRequalificationDate(acct.Id);

		acct = [select id, RequalificationDate__c, Requalification_Extended__c from Account where Id = :acct.Id];
		System.assert(acct.Requalification_Extended__c);
		System.assert(acct.RequalificationDate__c == requalDate.addMonths(1));
    }
}