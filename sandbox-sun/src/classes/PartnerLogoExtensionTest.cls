@isTest
private class PartnerLogoExtensionTest {

    static testMethod void myUnitTest() {
    	User adminuser = PartnerTestUtils.getAdminUser();
    	Account acct = PartnerTestUtils.makeAccount('PartnerLogoExtensionTestAccount', adminuser);
    	PartnerLogoExtension ext = new PartnerLogoExtension(acct.Id);
    	ext.doOnLoad();
    	ext.attachmentFile = EncodingUtil.base64Decode('a fake image body');
    	ext.attachmentFileName = 'testfile.png';
    	
    	//
    	// this should be rejected
    	//
    	ext.attachmentContentType = 'image/virus';
    	ext.doReplaceLogo();
    	
    	//
    	// create a new logo
    	//
    	ext.attachmentContentType = 'image/png';
    	ext.doReplaceLogo();

    	//
    	// replace an existing logo
    	//
    	ext.attachmentFile = EncodingUtil.base64Decode('another fake image body');
    	ext.attachmentContentType = 'image/png';
    	ext.doReplaceLogo();
    	
    	//
    	// finally, test the exception catch block
    	//
    	ext.attachmentFileName = null;
    	ext.doReplaceLogo();
    }
}