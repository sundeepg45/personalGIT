@isTest(SeeAllData = true)
private with sharing class NFRPageLayoutControllerTest {

    @isTest
    static void testRedHatUserNFRCreation() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account testAccount1 = PartnerTestUtils.quickGenericAccountSetup('NFRPageLayoutControllerTestAccount1');
        //Account testAccount2 = PartnerTestUtils.quickGenericAccountSetup('NFRPageLayoutControllerTestAccount2');
        Id testAccount1Id = testAccount1.Id;
        //Id testAccount2Id = testAccount2.Id;
        String profileName = testAccount1.Global_Region__c + ' Partner Portal – Strategic License – ALL Modules';
        Contact testContact = PartnerTestUtils.makeContact(testAccount1.Id, 'TestContact1');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount1, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :profileName
                                LIMIT 1].Id;
        insert testUser;

        testAccount1.OwnerId = UserInfo.getUserId();
        //testAccount2.OwnerId = UserInfo.getUserId();

        update testAccount1;
        //update testAccount2;

        testAccount1 = [select Finder_Partner_Tier_Name__c,
                            Finder_Partner_Type_Name__c
                            from Account
                            where Id = :testAccount1Id
                            limit 1];
        //testAccount2 = [select Finder_Partner_Tier_Name__c,
        //                    Finder_Partner_Type_Name__c
        //                    from Account
        //                    where Id = :testAccount2Id
        //                    limit 1];

        //List<Account> testAccounts = [
        //    select  Finder_Partner_Tier_Name__c,
        //            Finder_Partner_Type_Name__c
        //    from    Account
        //    where   Id in (:testAccount1Id, :testAccount2Id)
        //    limit   2
        //];

        //for (Account account : testAccounts) {
        //    if (account.Id == testAccount1Id) {
        //        testAccount1 = account;
        //    }
        //    if (account.Id == testAccount2Id) {
        //        testAccount2 = account;
        //    }
        //}

        //ApexPages.currentPage().getParameters().put('retURL', '/' + testAccount2.Id);
        NFRPageLayoutController controller = new NFRPageLayoutController(null);
        //controller.doOnLoad();
        //System.assertEquals(false, String.isEmpty(controller.partnerTypeAndTier));
        //System.assertEquals((testAccount2.Finder_Partner_Tier_Name__c + ' ' + testAccount2.Finder_Partner_Type_Name__c).toLowerCase().trim(), controller.partnerTypeAndTier.toLowerCase().trim());

        // Change accounts.
        controller.partnerAccount = testAccount1;
        ApexPages.currentPage().getParameters().put('partnerId', testAccount1.Id);
        controller.setPartnerId();
        System.assertEquals(false, String.isEmpty(controller.partnerTypeAndTier));
        System.assertEquals((testAccount1.Finder_Partner_Tier_Name__c + ' ' + testAccount1.Finder_Partner_Type_Name__c).toLowerCase().trim(), controller.partnerTypeAndTier.toLowerCase().trim());

        // Select contact on account.
        controller.NFR_Request.Contact_at_Partner__c = testContact.Id;
        String tempRHNLogin = controller.rhnLogin;
        System.assertEquals(false, String.isEmpty(tempRHNLogin));
        System.assertEquals(testContact.LoginName__c.toLowerCase().trim(), tempRHNLogin.toLowerCase().trim());

        // Get NFR request use cases.
        List<SelectOption> nfrUseCases = new List<SelectOption>();
        nfrUseCases = controller.getUseCaseNames();

        // Save without selecting any use cases, NFRs or accepting terms.
        controller.save_submit();

        // Save after having selected a use case, but no NFRs and no acceptance of terms.
        controller.useCases.add(nfrUseCases[0].getLabel());
        controller.save_submit();

        // Save after having selected a use case and agreeing to terms, but no NFRs.
        controller.agreeToTerms = true;
        controller.save_submit();

        // Save after having selected a use case, all NFRs and agreeing to terms.
        for (Integer counter = 0; counter < controller.skumatrix.size(); counter++) {
            controller.skumatrix[counter].Selected__c = true;
        }
        controller.skumatrix[0].Default_Quantity__c = controller.skumatrix[0].Max_Quantity__c + 1;
        controller.save_submit();
    }

    @isTest
    static void testPartnerUserNFRCreation() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account testAccount1 = PartnerTestUtils.quickGenericAccountSetup('NFRPageLayoutControllerTestAccount1');
        Id testAccount1Id = testAccount1.Id;
        String profileName = testAccount1.Global_Region__c + ' Partner Portal – Strategic License – ALL Modules';
        Contact testContact = PartnerTestUtils.makeContact(testAccount1.Id, 'TestContact2');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount1, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :profileName
                                LIMIT 1].Id;
        insert testUser;

        testAccount1 = [select Finder_Partner_Tier_Name__c,
                            Finder_Partner_Type_Name__c
                            from Account
                            where Id = :testAccount1Id
                            limit 1];

        System.runAs(testUser) {
            NFRPageLayoutController controller = new NFRPageLayoutController(null);
            controller.doOnLoad();
            System.assertEquals(false, String.isEmpty(controller.partnerTypeAndTier));
            System.assertEquals((testAccount1.Finder_Partner_Tier_Name__c + ' ' + testAccount1.Finder_Partner_Type_Name__c).toLowerCase().trim(), controller.partnerTypeAndTier.toLowerCase().trim());

            // Check contact on account.
            String tempRHNLogin = controller.rhnLogin;
            System.assertEquals(false, String.isEmpty(tempRHNLogin));
            System.assertEquals(testContact.LoginName__c.toLowerCase().trim(), tempRHNLogin.toLowerCase().trim());

            // Get NFR request use cases.
            List<SelectOption> nfrUseCases = new List<SelectOption>();
            nfrUseCases = controller.getUseCaseNames();

            // Save without selecting any use cases, NFRs or accepting terms.
            controller.save_submit();

            // Save after having selected a use case, but no NFRs and no acceptance of terms.
            controller.useCases.add(nfrUseCases[0].getLabel());
            controller.save_submit();

            // Save after having selected a use case and agreeing to terms, but no NFRs.
            controller.agreeToTerms = true;
            controller.save_submit();

            // Save after having selected a use case, one NFR and agreeing to terms.
            controller.skumatrix[0].Selected__c = true;
            controller.save_submit();
        }
    }

    @isTest
    static void testCancel() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        NFRPageLayoutController controller = new NFRPageLayoutController(null);
        controller.cancel();
    }

    @isTest
    static void testCaseCreation() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        NFRPageLayoutController controller = new NFRPageLayoutController(null);
        controller.doCreateCase();
    }
}