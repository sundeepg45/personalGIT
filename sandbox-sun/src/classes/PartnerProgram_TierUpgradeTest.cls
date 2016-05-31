@isTest(SeeAllData = true)
private class PartnerProgram_TierUpgradeTest {

    @isTest static void testFCPAViolation() {

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

        Test.startTest();
        ApexPages.currentPage().getParameters().put('AccountId', testAccount1.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm1.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Advanced';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
        //controller.partnerProgramApprovalRequest.Tier__c = 'Premier';
        //controller.validatePendingTierChange();
        //controller.submitTierChangeRequest();
        //controller.back();
    }

    @isTest static void testDefaultFCPARecord() {

        Account testAccount1 = PartnerTestUtils.makeAccount('TierChangeTestAccount2', PartnerTestUtils.getAdminUser());

        Id testAccount1Id = testAccount1.Id;

        update testAccount1;

        Partner_Program__c pgm = PartnerTestUtils.makeProgram(testAccount1Id, PartnerConst.RESELLER, PartnerConst.ADVANCED);
        insert pgm;

        testAccount1 = [
            select  Id
            from    Account
            where   Id = :testAccount1Id
            limit   1
        ];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('AccountId', testAccount1.Id);
        ApexPages.currentPage().getParameters().put('PartnerProgramId', pgm.Id);
        PartnerTierControllerExt controller = new PartnerTierControllerExt();
        controller.partnerProgramApprovalRequest.Tier__c = 'Ready';
        controller.validatePendingTierChange();
        controller.submitTierChangeRequest();
        //controller.partnerProgramApprovalRequest.Tier__c = 'Premier';
        //controller.validatePendingTierChange();
        //controller.submitTierChangeRequest();
        //controller.back();

        System.debug('*****[debug]***** setting approval to Approved');
        Partner_Program_Approval__c ppa = [select Id from Partner_Program_Approval__c where Partner__c = :testAccount1Id];
        ppa.Status__c = 'Pending';
        ppa.Manager_Completed__c = true;
        ppa.Anti_Corruption_Exception__c = true;
        ppa.Internal_Review__c = 'I do not know of anything with this potential partner that should require additional checks';
        update ppa;

        //
        // make sure there is an anti corruption record created even without an FCPA violation
        //
        Anti_Corruption__c ac = [select Id from Anti_Corruption__c where Partner_Account__c = :testAccount1Id];

    }
}