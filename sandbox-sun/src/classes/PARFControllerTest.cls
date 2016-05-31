@isTest(SeeAllData = true)
private class PARFControllerTest {

    @isTest static void test() {
        String federationId = String.valueOf(System.currentTimeMillis());
        System.debug('federationId = ' + federationId);
        createOnboardingRegistration(federationId);

        PARFController controller = new PARFController(new ApexPages.StandardController(new PARF_Form__c()));
        System.currentPageReference().getParameters().put('federationId', federationId);

        controller.init();
        controller.cancel();
        createOnboardingRegistration(federationId);
        controller = new PARFController(new ApexPages.StandardController(new PARF_Form__c()));
        System.currentPageReference().getParameters().put('federationId', federationId);
        controller.init();

        System.assert(!controller.parfProductsExist, 'PARF: There should not be any products on the PARF yet.');
        controller.prodName = 'Product 1';
        controller.prodDesc = '';
        controller.prodURL = '';
        controller.save();
        controller.prodName = '';
        controller.prodDesc = 'Product 1 Description';
        controller.save();
        controller.prodName = 'Product 1';
        controller.prodDesc = 'Product 1 Description';
        controller.save();
        System.assert(controller.parfProductsExist, 'PARF: There should be at least one product on the PARF.');
        System.assert(controller.moreProductsAllowed, 'PARF: More products should be allowed.');
        for (Integer counter = 1; counter < 10; counter++) {
            controller.prodName = 'Product ' + String.valueOf(counter + 1);
            controller.prodDesc = 'Product ' +  + String.valueOf(counter + 1) + ' Description';
            controller.prodURL = 'http://product' + String.valueOf(counter + 1) + '.com';
            controller.save();
        }
        System.assert(!controller.moreProductsAllowed, 'PARF: More products should NOT be allowed.');
        controller.productToDelete = 4;
        controller.deleteProduct();
        System.assert(controller.moreProductsAllowed, 'PARF: More products should be allowed.');
        controller.submit();
        controller.parf.Program_Contact__c = 'program contact';
        controller.parf.Program_Contact_Email__c = 'test@email.com';
        controller.submit();
        controller.parf.Distributor_Directed__c = 'Yes';
        controller.submit();
        controller.parf.EDP_Name__c = 'EDP name';
        controller.parf.EDP_Email__c = 'test@email.com';
        controller.parf.Desired_RH_Prod_Desc__c = 'Cloud Computing;Storage';
        controller.submit();
    }

    @isTest static void internalReferral() {

        String federationId = String.valueOf(System.currentTimeMillis());
        PARFController controller;

        // Create the test distributor.
        // String profileName = 'Partner Portal - Strategic License - OEM - SI';
        // Account distiAcct = PartnerTestUtils.makeAccount('testEmbeddedDistiReferral', PartnerTestUtils.getAdminUser());
        // PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        // PartnerTestUtils.makeAccountDistributor(distiAcct.Id);
        // Contact distiContact = PartnerTestUtils.makeContact(distiAcct.Id, federationId);
        // insert distiContact;
        // User distiUser = PartnerTestUtils.makeUser(distiAcct, distiContact);
        // distiUser.FederationIdentifier = distiContact.LoginName__c;
        // distiUser.ProfileId = [
        //  select  Name
        //  from    Profile
        //  where   Name like :profileName
        //  limit   1
        // ].Id;
        // insert distiUser;
        // Id distiUserId = distiUser.Id;
        // distiUser = [
        //  select  Id,
        //          Contact.AccountId
        //  from    User
        //  where   Id = :distiUserId
        // ];
        // Account tmpAcct = [select Finder_Partner_Type__c from Account where Id = :distiUser.Contact.AccountId];
        // System.debug('Partner acct type: ' + tmpAcct.Finder_Partner_Type__c);

        // Find the guest user.
        User guestUser = [
            select  Id
            from    User
            where   Name
            like    'Partner Center Site Guest User'
            limit   1
        ];

        Id onboardingRecordId;

        // As a Red Hat User, refer the prospective partner.
        System.debug('federationId = ' + federationId);
        ManualOnboardingController moController = ManualOnboardingControllerTest.setUpData();
        moController.partnerType = 'Embedded';
        moController.companyName = federationId;
        moController.language = 'English';
        moController.firstName = federationId;
        moController.lastName = federationId;
        PageReference pr = moController.submit();
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        if (msgs != null && msgs.size() > 0) {
            for (ApexPages.Message msg : msgs) {
                System.debug('>>>>>>>>>>>>>>>> ' + msg);
            }
        } else {
            System.debug('No page messages.');
        }
        System.debug('Page parameters: ' + pr.getParameters());
        onboardingRecordId = pr.getParameters().get('onboardingId');

        controller = new PARFController(new ApexPages.StandardController(new PARF_Form__c()));
        System.debug('Onboarding record Id: ' + onboardingRecordId);
        System.debug('Partner type: ' + moController.partnerType);
        System.currentPageReference().getParameters().put('onboardingId', onboardingRecordId);
        controller.init();

        for (Integer counter = 1; counter < 2; counter++) {
            controller.prodName = 'Product ' + String.valueOf(counter + 1);
            controller.prodDesc = 'Product ' +  + String.valueOf(counter + 1) + ' Description';
            controller.prodURL = 'http://product' + String.valueOf(counter + 1) + '.com';
            controller.save();
        }
        controller.parf.Program_Contact__c = 'program contact';
        controller.parf.Program_Contact_Email__c = 'test@email.com';
        controller.parf.Distributor_Directed__c = 'No';
        controller.parf.Desired_RH_Prod_Desc__c = 'Cloud Computing;Storage';
        controller.submit();

        PARFController newController = new PARFController(new ApexPages.StandardController(controller.parf));
        newController.init();
        newController.submit();

        System.debug('Underlying facts required: ' + controller.underlyingFactsRequired);
        System.debug('Product details required: ' + controller.productDetailsRequired);
    }

    @isTest static void distributorReferral() {

        String federationId = String.valueOf(System.currentTimeMillis());
        PARFController controller;

        // Create the test distributor.
        String profileName = 'Partner Portal - Strategic License - OEM - SI';
        Account distiAcct = PartnerTestUtils.makeAccount('testEmbeddedDistiReferral', PartnerTestUtils.getAdminUser());
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        PartnerTestUtils.makeAccountDistributor(distiAcct.Id);
        Contact distiContact = PartnerTestUtils.makeContact(distiAcct.Id, federationId);
        insert distiContact;
        User distiUser = PartnerTestUtils.makeUser(distiAcct, distiContact);
        distiUser.FederationIdentifier = distiContact.LoginName__c;
        distiUser.ProfileId = [
            select  Name
            from    Profile
            where   Name like :profileName
            limit   1
        ].Id;
        insert distiUser;
        Id distiUserId = distiUser.Id;
        distiUser = [
            select  Id,
                    Contact.AccountId
            from    User
            where   Id = :distiUserId
        ];
        Account tmpAcct = [select Finder_Partner_Type__c from Account where Id = :distiUser.Contact.AccountId];
        System.debug('Partner acct type: ' + tmpAcct.Finder_Partner_Type__c);

        // Find the guest user.
        User guestUser = [
            select  Id
            from    User
            where   Name
            like    'Partner Center Site Guest User'
            limit   1
        ];

        Id onboardingRecordId;

        Test.startTest();
       
        // As the distributor, refer the prospective partner.
        System.runAs(distiUser) {
            System.debug('federationId = ' + federationId);
            ManualOnboardingController moController = ManualOnboardingControllerTest.setUpData();
            moController.partnerType = 'Embedded';
            moController.companyName = federationId;
            moController.language = 'English';
            moController.firstName = federationId;
            moController.lastName = federationId;
            PageReference pr = moController.submit();
            List<ApexPages.Message> msgs = ApexPages.getMessages();
            if (msgs != null && msgs.size() > 0) {
                for (ApexPages.Message msg : msgs) {
                    System.debug('>>>>>>>>>>>>>>>> ' + msg);
                }
            } else {
                System.debug('No page messages.');
            }
            System.debug('Page parameters: ' + pr.getParameters());
            onboardingRecordId = pr.getParameters().get('onboardingId');

            controller = new PARFController(new ApexPages.StandardController(new PARF_Form__c()));
            System.debug('Onboarding record Id: ' + onboardingRecordId);
            System.debug('Partner type: ' + moController.partnerType);
            System.currentPageReference().getParameters().put('onboardingId', onboardingRecordId);
            controller.init();

            for (Integer counter = 1; counter < 2; counter++) {
                controller.prodName = 'Product ' + String.valueOf(counter + 1);
                controller.prodDesc = 'Product ' +  + String.valueOf(counter + 1) + ' Description';
                controller.prodURL = 'http://product' + String.valueOf(counter + 1) + '.com';
                controller.save();
            }
            controller.parf.Program_Contact__c = 'program contact';
            controller.parf.Program_Contact_Email__c = 'test@email.com';
            controller.parf.Distributor_Directed__c = 'Yes';
            controller.parf.EDP_Name__c = distiAcct.Name;
            controller.parf.EDP_Email__c = 'test@email.com';
            controller.parf.Desired_RH_Prod_Desc__c = 'Cloud Computing;Storage';
            controller.submit();
        }
        Test.stopTest();
    }

    public static void createOnboardingRegistration(String federationId) {
        Partner_Onboarding_Registration__c partnerOnboardingRegistration = new Partner_Onboarding_Registration__c();
        partnerOnboardingRegistration.RHNLogin__c = federationId;
        partnerOnboardingRegistration.Subtype__c = OnboardingApplyController.EMBEDDED;
        partnerOnboardingRegistration.FirstName__c = 'Firstname';
        partnerOnboardingRegistration.LastName__c = 'Lastname';
        partnerOnboardingRegistration.Email__c = 'email@test.com';
        insert partnerOnboardingRegistration;
    }
}