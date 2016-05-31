@isTest
private class Contact_ConvertToUserTest {

    static testMethod void myUnitTest() {
    	Account acct = PartnerTestUtils.quickGenericAccountSetup('Contact_ConvertToUserTest');
    	update acct;
    	Contact con = PartnerTestUtils.makeContact(acct.Id, 'FireflyClassSerenity');
    	insert con;

		//
		// test successful conversion
		//
		con = [select id, Account.Global_Region__c, LoginName__c, AccountId from Contact where Id = :con.Id];
        Contact_ConvertToUser controller = new Contact_ConvertToUser(new ApexPages.Standardcontroller(con));
        controller.convertToUser();

		// run again for dup check
		controller.convertToUser();
        System.assert(ApexPages.hasMessages(), 'dup check failure');
    }
}