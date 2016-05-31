@isTest
private class PartnerProducts_screenshotsTest {

    static testMethod void myUnitTest() {
    	Account acct = PartnerTestUtils.quickGenericAccountSetup('PartnerProducts_screenshotsTest');
    	update acct;
    	PartnerProduct__c prod = PartnerTestUtils.makeProduct(acct.Id);
    	insert prod;

		ApexPages.currentPage().getParameters().put('id', prod.Id);
        PartnerProducts_screenshots controller = new PartnerProducts_screenshots(new ApexPages.Standardcontroller(prod));
    	controller.attachmentFile = EncodingUtil.base64Decode('a fake image body');
    	controller.attachmentFileName = 'testfile.png';
		controller.addScreenshot();

		controller.productLogo.Body = EncodingUtil.base64Decode('a fake image body');
		controller.productLogo.Name = 'testfile.png';
		controller.replaceLogo();

/*
		ID logoId = [select Id from PartnerProductLogo__c where PartnerProduct__c = :prod.Id limit 1].Id;
		ID PartnerScreenshotId = [select Id from PartnerProductScreenshot__c where PartnerProduct__c = :prod.Id limit 1].Id;
		ApexPages.currentPage().getParameters().put('partnerLogoId', logoId);
		ApexPages.currentPage().getParameters().put('partnerScreenshotId', partnerScreenshotId);
		controller.deleteAttachments();
*/
    }
}