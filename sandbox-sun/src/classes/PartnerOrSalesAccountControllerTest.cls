@isTest(SeeAllData = true)
private class PartnerOrSalesAccountControllerTest {

	@isTest static void test() {
		ApexPages.StandardController standardController = new ApexPages.StandardController(new Account());
		PartnerOrSalesAccountController controller = new PartnerOrSalesAccountController(standardController);
		controller.createSalesAccount();
		controller.createPartnerAccount();
		controller.cancel();
	}
}