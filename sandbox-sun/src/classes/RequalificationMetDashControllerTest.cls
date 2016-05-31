@isTest
private class RequalificationMetDashControllerTest {

    static testMethod void myUnitTest() {
   		DeactivateAllTestUtil.setDeactivateAll(false);

    	Account account = PartnerTestUtils.quickRequalAccountSetup(null);

		ApexPages.currentPage().getParameters().put('accountId', account.id);
    	RequalificationMetDashController controller = new RequalificationMetDashController();


    }
}