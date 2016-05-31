@isTest
private class Account_UpdateKeywordsTest {

    static testMethod void myUnitTest() {

        User adminuser = PartnerTestUtils.getAdminUser();
        Account acct = PartnerTestUtils.makeAccount('Account Update Keywords Trigger Test', adminuser);

		acct.Hardware_Focus__c = 'Hardware Focus';
		acct.Hardware_Platform__c = 'Hardware Platform';
		acct.Industry_Focus__c = 'Industry Focus';
		acct.Operating_System_Supported__c = 'OS Supported';
		acct.Software_Focus__c = 'Software Focus';
		acct.Middleware_Supported__c = 'Middleware Supported';
		acct.Application_Types__c = 'App Type';
		update acct;

		String expected = ';Hardware Focus;Hardware Platform;Industry Focus;OS Supported;Software Focus;Middleware Supported;App Type';

		//acct = [select PartnerKeywords__c from Account where Id = :acct.Id];
		//System.assert(acct.PartnerKeywords__c == expected, 'got ' + acct.PartnerKeywords__c);
    }
}