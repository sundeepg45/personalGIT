@isTest(SeeAllData = true)
private class CCSP_Terms_Controller_Test {

    @isTest static void testStandardTerms() {

        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'CCSP Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getCCSPTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        CCSP_Terms_Controller ctrl = new CCSP_Terms_Controller();
        ctrl.init();
        ctrl.termType = 'standard';

        ctrl.submitButton();
}

        onb = [select Id, Agree_to_Partner_TC__c from Partner_Onboarding_Registration__c where Id = :onb.Id];
        System.assert(onb.Agree_to_Partner_TC__c == true, 'Expected Agree_to_Partner_TC__c to be true');

        PartnerAgreement__c[] agreementlist = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];
        System.assert(agreementlist.size() > 0, 'Expected to be at least 1 agreement registered');
    }


    @isTest static void testApplyStandardTerms() {

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.RESELLER, PartnerConst.READY);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        pgm.Is_Primary__c = false;
        insert pgm;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'CCSP Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(acct.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Account__c = acct.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getCCSPTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', 'masmith+standard@redhat.com');

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        CCSP_Terms_Controller ctrl = new CCSP_Terms_Controller();
        ctrl.init();
        ctrl.termType = 'standard';

        ctrl.submitButton();
        System.assert(ctrl.getIsEnrolling(), 'Expected isEnrolling to be true');
}
        pgm = [select Id, Status__c from Partner_Program__c where Id = :pgm.Id];
        System.assert(pgm.Status__c == 'Active', 'Expected status of program to be active');

        PartnerAgreement__c[] agreementlist = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];
        System.assert(agreementlist.size() > 0, 'Expected to be at least 1 agreement registered');
    }

    @isTest static void testApplyCustomTerms() {

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.RESELLER, PartnerConst.READY);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        pgm.Status__c = 'Pending Terms';
        insert pgm;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'CCSP Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(acct.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Account__c = acct.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getCCSPTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', 'masmith+apply@redhat.com');

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        CCSP_Terms_Controller ctrl = new CCSP_Terms_Controller();
        ctrl.init();

        ctrl.termType = 'custom';
        ctrl.customText = 'custom terms';
        ctrl.submitButton();
}

        pgm = [select Id, Status__c from Partner_Program__c where Account__c = :acct.Id and Program__r.Program_Category__c = :PartnerConst.SCP];
        System.assert(pgm.Status__c == 'Pending Terms', 'Expected partner program status to be pending terms');

        Contract con = [select Id, Requesting_User__c from Contract where AccountId = :sales.Id limit 1];
        System.assert(con.Requesting_User__c != null, 'Requesting_User__c is null');

    }


    @isTest static void testCustomTerms() {

        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'CCSP Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getCCSPTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        CCSP_Terms_Controller ctrl = new CCSP_Terms_Controller();
        ctrl.init();

        ctrl.termType = 'custom';
        ctrl.customText = 'custom terms';
        ctrl.submitButton();
}

        onb = [select Id, Agree_to_Partner_TC__c, HasCustomTerms__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where Id = :onb.Id];
        System.assert(onb.Agree_to_Partner_TC__c == false, 'Expected Agree_to_Partner_TC__c to be false');
        System.assert(onb.HasCustomTerms__c == false, 'Expected HasCustomTerms__c to be false');

        Contract con = [select Id, Requesting_User__c from Contract where AccountId = :sales.Id limit 1];
        System.assert(con.Requesting_User__c != null, 'Requesting_User__c is null');

    }

    @isTest static void testLoginButton() {
        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Controller_Test');
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'CCSP Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+logintest@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getCCSPTermsFullURL(token.Token__c);
        update token;
        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

        CCSP_Terms_Controller ctrl = new CCSP_Terms_Controller();
        ctrl.init();

        ctrl.loginButton();
    }

}