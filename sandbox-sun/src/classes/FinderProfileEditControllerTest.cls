@isTest(SeeAllData = true)
private class FinderProfileEditControllerTest {

	@isTest
    static void testEditCompanyInformation() {

        String uniqueIdentifier = String.valueOf(System.currentTimeMillis());
        String testDescription = 'Test Description'  + uniqueIdentifier;
        String testIndustryFocus = 'Aerospace;Construction';
        String testCompanyEmail = uniqueIdentifier + '@email.com';
        String testPhone = '9999999999';
        String testWebSite = 'www.' + uniqueIdentifier + '.com';

        Account testAccount = PartnerTestUtils.basicAccountSetup('FinderProfileEditControllerTestAccount');
        ID testAccountID = testAccount.id;

        ApexPages.currentPage().getParameters().put('id', testAccountID);
        FinderProfileEditController controller = new FinderProfileEditController();
        controller.account = testAccount;

        String originalDescription = testAccount.Description_of_Business__c;
        String originalIndustryFocus = testAccount.Industry_Focus__c;
        String originalCompanyEmail = testAccount.Company_Email_Address__c;
        String originalPhone = testAccount.Phone;
        String originalWebSite = testAccount.Website;

        // Cancel and validate values haven't changed.
        controller.account.Description_of_Business__c = testDescription;
        controller.account.Industry_Focus__c = testIndustryFocus;
        controller.account.Company_Email_Address__c = testCompanyEmail;
        controller.account.Phone = testPhone;
        controller.account.Website = testWebSite;
        controller.cancel();
        testAccount = [SELECT Id,
                        Company_Email_Address__c,
                        Description_of_Business__c,
                        Industry_Focus__c,
                        Is_Partner_Published__c,
                        Name,
                        Phone,
                        Website
                        FROM Account
                        WHERE Id = :testAccountID];
        System.assertEquals(originalDescription, testAccount.Description_of_Business__c);
        System.assertEquals(originalIndustryFocus, testAccount.Industry_Focus__c);
        System.assertEquals(originalCompanyEmail, testAccount.Company_Email_Address__c);
        System.assertEquals(originalPhone, testAccount.Phone);
        System.assertEquals(originalWebSite, testAccount.Website);

        // Save and validate values have changed.
        controller.account.Description_of_Business__c = testDescription;
        controller.account.Industry_Focus__c = testIndustryFocus;
        controller.account.Company_Email_Address__c = testCompanyEmail;
        controller.account.Phone = testPhone;
        controller.account.Website = testWebSite;
        controller.save();
        testAccount = [SELECT Id,
                        Company_Email_Address__c,
                        Description_of_Business__c,
                        Industry_Focus__c,
                        Is_Partner_Published__c,
                        Name,
                        Phone,
                        Website
                        FROM Account
                        WHERE Id = :testAccountID];
        System.assertEquals(testDescription, testAccount.Description_of_Business__c);
        System.assertEquals(testIndustryFocus, testAccount.Industry_Focus__c);
        System.assertEquals(testCompanyEmail, testAccount.Company_Email_Address__c);
        System.assertEquals(testPhone, testAccount.Phone);
        System.assertEquals(testWebSite, testAccount.Website);
	}

	@isTest
    static void testPublishAndUnpublish() {

        Account account = PartnerTestUtils.basicAccountSetup('FinderProfileEditControllerTestAccount');
        ID accountID = account.id;

        ApexPages.currentPage().getParameters().put('id', account.id);
        FinderProfileEditController controller = new FinderProfileEditController();

        boolean isPublished = account.Is_Partner_Published__c;

        controller.publish();
        account = [SELECT Is_Partner_Published__c
                    FROM Account
                    WHERE Id = :accountID];

        System.assertEquals(!isPublished, account.Is_Partner_Published__c);

        controller.publish();
        account = [SELECT Is_Partner_Published__c
                    FROM Account
                    WHERE Id = :accountID];

        System.assertEquals(isPublished, account.Is_Partner_Published__c);
	}

    @isTest
    static void testPartnerLocation() {

        Account testAccount = PartnerTestUtils.basicAccountSetup('FinderProfileEditControllerTestAccount');
        ID testAccountID = testAccount.id;

        ApexPages.currentPage().getParameters().put('id', testAccountID);
        FinderProfileEditController controller = new FinderProfileEditController();

        controller.create();

        controller.isInternalUser = false   ;
        controller.create();
    }

    @isTest
    static void testLogo() {

        Account testAccount = PartnerTestUtils.basicAccountSetup('FinderProfileEditControllerTestAccount');
        ID testAccountID = testAccount.id;

        ApexPages.currentPage().getParameters().put('id', testAccountID);
        FinderProfileEditController controller = new FinderProfileEditController();
        controller.onLoad();

        controller.attachmentFile = EncodingUtil.base64Decode('a fake image body');
        controller.attachmentFileName = 'testfile.png';

        // Invalid file type.
        controller.attachmentContentType = 'image/virus';
        controller.replaceLogo();

        // Create a logo.
        controller.attachmentContentType = 'image/png';
        controller.replaceLogo();

        // Replace logo.
        controller.attachmentFile = EncodingUtil.base64Decode('another fake image body');
        controller.replaceLogo();

        // File too big.
        String blobString = 'x';
        while (blobString.length() < FinderProfileEditController.MAX_BLOB_SIZE_IN_KB * 2048) {
            blobString += blobString;
        }
        controller.attachmentFile = EncodingUtil.base64Decode(blobString);
        controller.replaceLogo();

        // Null file name.
        controller.attachmentFile = null;
        controller.replaceLogo();
    }
}