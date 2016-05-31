@isTest
private class NFRListControllerTest {

	@isTest static void testCancel() {
        Account acc = PartnerTestUtils.basicAccountSetup('NFRListControllerTestAccount');
        ApexPages.StandardController stdCon = new ApexPages.StandardController(acc);
		NFRListController c = new NFRListController(stdCon);
        c.backToAccount();
	}

	@isTest static void testCreateNewNFR() {
        Account acc = PartnerTestUtils.basicAccountSetup('NFRListControllerTestAccount');
        ApexPages.StandardController stdCon = new ApexPages.StandardController(acc);
        NFRListController c = new NFRListController(stdCon);
        c.createNewNFR();
	}

    static testMethod void myTest() {
        //get owner for the nfr
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        //create account
        Account testAcc = PartnerTestUtils.basicAccountSetup('NFRListControllerTestAccount');
        Id testAccountId = testAcc.Id;
        String profileName = testAcc.Global_Region__c + ' Partner Portal – Strategic License – ALL Modules';
        //create contact
        Contact testContact = PartnerTestUtils.makeContact(testAcc.Id, 'TestContact');
        testContact.LoginName__c = 'someone@redhat.com';
        insert testContact;
        //create user
        User testUser = PartnerTestUtils.makeUser(testAcc, testContact);
        testUser.FederationIdentifier = testContact.LoginName__c;
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :profileName
                                LIMIT 1].Id;
        insert testUser;
        //create NFR
        NFR_Request__c nfrRequest = new NFR_Request__c();
        nfrRequest.Contact_at_Partner__c = testContact.Id;
        nfrRequest.Partner__c = testAccountId;
        nfrRequest.OwnerId = owner.Id;
        nfrRequest.Partner_Status__c ='Ready - Reseller';
        nfrRequest.User_RHN_Entitlement_Login__c = testUser.FederationIdentifier;
        insert nfrRequest;

        PageReference ref = Page.NFRList;
        Test.setCurrentPage(ref);
        ApexPages.currentPage().getParameters().put('id', nfrRequest.Partner__c);

        ApexPages.StandardController stdController = new ApexPages.StandardController(testAcc);
        NFRListController nfrs = new NFRListController(stdController);

        NFR_Request__c nr = [select id, Partner__c from NFR_Request__c limit 1];

        ref = nfrs.createNewNFR();
        ref = nfrs.backToAccount();
    }

}