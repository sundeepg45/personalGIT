@isTest(SeeAllData = true)
private class Account_DirectPurchasingAgreementTest {

    //1. Admins can uncheck anything and everything
	@isTest static void test_Admins_Can_Uncheck_DPA() {
		Account a = PartnerTestUtils.buildPartnerAccount('testDPAAccount', PartnerTestUtils.getAdminUser());
        a.Direct_Purchasing_Agreement__c = true;
        insert a;

		PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(a.Id, PartnerConst.RESELLER, PartnerConst.READY);

        //check Admins can uncheck DPA
        a.Direct_Purchasing_Agreement__c = false;
        update a;
	}

	//2. Admin Ops can uncheck DPA on all Accounts except: SI, CCSP, Embed
    @isTest static void test_Stop_AdminOps_Uncheck_DPA() {
        User opsUser = [Select Id, Name from User Where Profile.Name = 'Administrator - Operations' and isActive = true limit 1];
		Account a = PartnerTestUtils.buildPartnerAccount('testDPAAccount', PartnerTestUtils.getAdminUser());
        a.Direct_Purchasing_Agreement__c = true;
        insert a;

		PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(a.Id, PartnerConst.RESELLER, PartnerConst.READY);

        Test.startTest();

        System.runAs(opsUser) {
            //check Admins can uncheck DPA
            a.Direct_Purchasing_Agreement__c = false;
            try {
                update a;
            } catch(DmlException e) {
                System.assert(e.getMessage().contains('This Partner is been identified as they have \'Direct Purchasing agreements\' with Red Hat. You can not uncheck the \'Direct Purchasing agreements\' flag once checked'));
            }
        }
        Test.stopTest();
	}

    //3. Admin Ops can uncheck DPA on all Accounts except: SI, CCSP, Embed
    @isTest static void test_AdminOps_Can_Uncheck_DPA_For_SI_CCSP_EMBED() {
        User adminOps = [Select Id, Name from User Where Profile.Name = 'Administrator - Operations' and isActive = true and UserRole.DeveloperName = 'Global' limit 1];
        Account a = PartnerTestUtils.buildPartnerAccount('testDPAAccount', PartnerTestUtils.getAdminUser());
        a.Direct_Purchasing_Agreement__c = true;
        insert a;

		PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(a.Id, PartnerConst.SI, PartnerConst.READY);

        //check Admins can uncheck DPA
        a.Direct_Purchasing_Agreement__c = false;
        update a;

    }

    //4. Non-Admin Users can not uncheck the DPA on Any Accounts
    @isTest static void test_Stop_All_Unchecking_DPA() {
        User nonAdmin = [Select Id, Name from User Where Profile.Name = 'Channel Sales' and isActive = true and UserRole.DeveloperName = 'Global' limit 1];
        Account a = PartnerTestUtils.buildPartnerAccount('testDPAAccount', PartnerTestUtils.getAdminUser());
        a.Direct_Purchasing_Agreement__c = true;
        insert a;

		PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(a.Id, PartnerConst.RESELLER, PartnerConst.READY);

        Test.startTest();

        System.runAs(nonAdmin) {
            //check Admins can uncheck DPA
            a.Direct_Purchasing_Agreement__c = false;
            try {
                update a;
            } catch(DmlException e) {
                System.assert(e.getMessage().contains('This Partner is been identified as they have \'Direct Purchasing agreements\' with Red Hat. You can not uncheck the \'Direct Purchasing agreements\' flag once checked'));
            }
        }
        Test.stopTest();
    }

}