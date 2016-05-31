@isTest(SeeAllData = true)
private with sharing class PartnerTierControllerExtTest {

    @isTest static void testTierChangeReseller() {

        Account testAccount1 = PartnerTestUtils.makeAccount('TierChangeTestAccount1', PartnerTestUtils.getAdminUser());

        Id testAccount1Id = testAccount1.Id;

        update testAccount1;

        Partner_Program__C pgm1 = PartnerTestUtils.makeAccountResellerProgram(testAccount1.Id);

        testAccount1 = [
            select  Id
            from    Account
            where   Id = :testAccount1Id
            limit   1
        ];

        ApexPages.currentPage().getParameters().put('AccountId', testAccount1.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm1.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Advanced';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
        controller.partnerProgramApprovalRequest.Tier__c = 'Premier';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
        controller.back();
    }

    @isTest static void testTierChangeOEM() {

        Account testAccount2 = PartnerTestUtils.makeAccount('TierChangeTestAccount2', PartnerTestUtils.getAdminUser());

        Id testAccount2Id = testAccount2.Id;

        update testAccount2;

        Partner_Program__C pgm2 = PartnerTestUtils.makeAccountOEMProgram(testAccount2.Id);

        testAccount2 = [
            select  Id
            from    Account
            where   Id = :testAccount2Id
            limit   1
        ];

        ApexPages.currentPage().getParameters().put('AccountId', testAccount2.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm2.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Advanced';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
    }

    @isTest static void testTierChangeWithRequalInProgress() {

        Account testAccount = PartnerTestUtils.makeAccount('TierChangeTestAccount3', PartnerTestUtils.getAdminUser());

        Id testAccountId = testAccount.Id;

        update testAccount;

        Partner_Program__C pgm1 = PartnerTestUtils.makeAccountResellerProgram(testAccount.Id);

        testAccount = [
            select  Id,
                    RequalStatus__c
            from    Account
            where   Id = :testAccountId
            limit   1
        ];

        testAccount.RequalStatus__c = 'In Progress';
        update testAccount;

        ApexPages.currentPage().getParameters().put('AccountId', testAccount.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm1.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Advanced';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
        controller.back();
    }

    @isTest static void testChangePendingSCP() {
        Account acct = PartnerTestUtils.newMakeBasicAccount('TierChangeTestAccount-testChangePendingSCP');
        //acct.Finder_Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        //acct.Finder_Partner_Tier__c = RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c;
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        insert pgm;
        Partner_Onboarding_Registration__c req = PartnerTestUtils.makeOnboardingRequest('Mark', 'Smith', 'Red Hat', [select Id from User where Id = :UserInfo.getUserId()]);
        req.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        req.Partner_Tier__c = RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c;
        req.ConvertedAccount__c = acct.Id;
        req.HasCustomTerms__c = false;
        req.Agree_to_Partner_TC__c = false;
        insert req;

        acct = [select Id, Finder_Partner_Type__c, Finder_Partner_Tier__c from Account where Id = :acct.Id];
        System.debug('-----[debug]----- type=' + acct.Finder_Partner_Type__c + ', tier=' + acct.Finder_Partner_Tier__c);
        ApexPages.currentPage().getParameters().put('AccountId', acct.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Advanced';
        PageReference ref = controller.validatePendingTierChange();
        //System.assert(controller.validationFailed, 'Expected validation to fail');
        //System.assert(ApexPages.hasMessages(), 'Expected tier change to be blocked');
    }
}