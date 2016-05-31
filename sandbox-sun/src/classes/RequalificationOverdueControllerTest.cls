@isTest
private class RequalificationOverdueControllerTest {

    static testMethod void myUnitTest() {
    	User adminuser = PartnerTestUtils.getAdminUser();
    	Account account = PartnerTestUtils.makeAccount('RequalOverdueControllerTestAccount', adminuser);
    	account.RequalificationDate__c = System.today().addDays(2);
    	account.RequalStatus__c = 'Eligible';
        update account;

    	Contact contact = PartnerTestUtils.makeContact(account.id, 'abc123def456ghi789j0');
    	insert contact;
        User user = PartnerTestUtils.makeUser(account, contact);
        insert user;

		RequalificationOverdueController roc = new RequalificationOverdueController(user.id);
		roc.createRequalOverdueCase();

		// run "already exists" scenario
		roc.createRequalOverdueCase();
    }
}