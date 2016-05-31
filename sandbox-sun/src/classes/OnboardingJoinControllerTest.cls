@isTest(SeeAllData=true)
private class OnboardingJoinControllerTest {

    static testMethod void myUnitTest() {

        OnboardingJoinController ctrl = new OnboardingJoinController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Voldemort');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        ctrl.init();

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Hogwarts test account');
        acct.AllowedEmailDomains__c = 'diagonalley.com';
        update acct;
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();

    }

    static testMethod void testPartialEmailDomain() {

        OnboardingJoinController ctrl = new OnboardingJoinController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Voldemort');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@dl.diagonalley.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        ctrl.init();

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Hogwarts test account');
        acct.AllowedEmailDomains__c = 'diagonalley.com';
        update acct;
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist != null, 'Program list is null');
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();

    }

    static testMethod void testCCnSP() {

        OnboardingJoinController ctrl = new OnboardingJoinController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'VoldemortJr');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        ctrl.init();


        Account acct = PartnerTestUtils.basicAccountSetup('Hogwarts CC&SP test account');
        acct.AllowedEmailDomains__c = 'diagonalley.com';
        update acct;
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.ADVANCED);
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.SERVICECLOUD_PROVIDER';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();

    }

    static testMethod void testVATLookup() {


        Country__c c = [select Id from Country__c where Abbreviation__c = 'US' limit 1];
        c.SearchByVAT__c = true;
        update c;

        OnboardingJoinController ctrl = new OnboardingJoinController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Voldemort');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        ctrl.init();

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Hogwarts test account');
        acct.AllowedEmailDomains__c = 'diagonalley.com';
        acct.VATNumber__c = '123456';
        update acct;
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        ctrl.VATNumber = '123456';
        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();

    }

    static testMethod void embeddedOnboardingTest() {

        OnboardingJoinController ctrl = new OnboardingJoinController();
        boolean embed = ctrl.isEmbeddedPartner;
        boolean agree = ctrl.IsAgreedToTerms;
        boolean isCCP = ctrl.IsCCP;
        String lc = ctrl.theLeadCountry;
        String mtype = ctrl.messageType;
        Boolean caseSub = ctrl.caseSubmitted;
        Boolean HasInacUserError = ctrl.HasInactiveUserError;
        Boolean HNoUErr = ctrl.HasNoUserError;
        Boolean HUExErr = ctrl.HasUserExistsError;
        Boolean HPReErr = ctrl.HasPendingRequestError;
        Boolean HExInvi = ctrl.hasExistingInvite;
        String onbCEmil = ctrl.OnboardingCaseEmail;
        String pInvitID = ctrl.partnerInviteId;

        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'VoldemortJr');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        ctrl.init();

        Account acct = PartnerTestUtils.basicAccountSetup('Hogwarts EMbedded test account');
        acct.AllowedEmailDomains__c = 'diagonalley.com';
        update acct;
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Partner_Program__c ip = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.ADVANCED);
        insert ip;
        Partner_Program__c ep = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.AFFILIATED, false);
        insert ep;
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id and Program__r.Program_Category__c = :PartnerConst.EMBED];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.ISV';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();
        // page = ctrl.initIssuesPage();
        // page = ctrl.convertContactCancel();
        // page = ctrl.missingAccountCase();

        Partner_Onboarding_Registration__c mylead = [select Email__c, SubRegion__c from Partner_Onboarding_Registration__c where Id = :ctrl.theLead.Id];
        System.debug('*****[debug]***** >> subregion__c = ' + mylead.SubRegion__c);
        System.assert(mylead.Email__c != null, 'Email is null');
     }

     static testMethod void embeddedTermsPendingMessageTest() {
        User owner = PartnerTestUtils.getAdminUser();
        Account a = PartnerTestUtils.makeAccount('testAccName', owner);
        Contact c = PartnerTestUtils.makeContact(a.id, 'embedFederationId');
        insert c;

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Partner_Program__c ip = PartnerTestUtils.makeProgram(a.id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert ip;
        Partner_Program__c ep = PartnerTestUtils.makeProgram(a.id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED, false);
        insert ep;

        User u = PartnerTestUtils.makePartnerUser(a, c);
        insert u;

        OnboardingJoinController ctrl = new OnboardingJoinController();

        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'embedFederationId');
        pmap.put('rhn-company-name', 'testAccName');
        pmap.put('rhn-email', 'thedoctor@gallifrey.net');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'Dr');
        pmap.put('rhn-first-name', 'John');
        pmap.put('rhn-last-name', 'Smith');
        PageReference ref = ctrl.init();
        ref = ctrl.convertContactSubmit();

        OnboardingJoinController.addErrorMessage('Error');
     }
}