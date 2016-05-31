/**
 * This class is a set of unit tests for the AccountProfile_PS_ControllerExtension class.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-07
 * 2012-01-07 - created
 */
@isTest
private class AccountProfile_PS_SetControllerTest {
	static Account_Profile__c accountProfile {
		get { return AccountProfile_PS_ControllerExtnTest.accountProfile; }
	}

	@isTest
	static void lookupTest() {
		PageReference r = new PageReference('/apex/AccountProfile_PS_Manage');
		r.getParameters().put('id',accountProfile.Id);
		Test.setCurrentPage(r);
		Test.startTest();
		AccountProfile_PS_SetController psc = new AccountProfile_PS_SetController();
		System.assertNotEquals(null,psc.partnerStatusRecords);
		System.assertEquals(1,psc.getPartnerStatusPagination().size());
		System.assertEquals(1,psc.getPageCount());
		// the following are just for coverage
		psc.last();
		psc.first();
		psc.next();
		psc.previous();
		psc.updateSearchString();
		// now lets try a search that fails
		psc.searchString = 'DOGGY DOG';
		System.assertNotEquals(null,psc.partnerStatusRecords);
		System.assertEquals(0,psc.getPartnerStatusPagination().size());
		Test.stopTest();
		System.assertNotEquals(null,psc.cancel());
	}
}