public with sharing class PartnerOrSalesAccountController {

	public PartnerOrSalesAccountController(ApexPages.StandardController controller) {

	}

	public PageReference createSalesAccount() {
		return new PageReference('/apex/SearchBeforeCreateAccountPage?retURL=/001/o');
	}

	public PageReference createPartnerAccount() {
		return new PageReference('/apex/ManualOnboarding?retURL=/001/o');
	}

	public PageReference cancel() {
		return new PageReference('/001/o');
	}
}