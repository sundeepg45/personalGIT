@isTest(SeeAllData = true)
public without sharing class Embedded_Terms_Controller_Test {

    @isTest static void testStandardTerms() {

        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm.Is_Primary__c = false;
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV').ObjectId__c;
        onb.Subtype__c = 'Embedded';
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
        ctrl.init();
        ctrl.termType = 'standard';

        ctrl.submitButton();
}

        onb = [select Id, Agree_to_Partner_TC__c from Partner_Onboarding_Registration__c where Id = :onb.Id];
        System.assert(onb.Agree_to_Partner_TC__c == true, 'Expected Agree_to_Partner_TC__c to be true');

        PartnerAgreement__c[] agreementlist = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];
        System.assert(agreementlist.size() > 0, 'Expected to be at least 1 agreement registered');

        Partner_Program__c[] programs = [select Id, Tier__c from Partner_Program__c where Account__c = :acct.Id];
        System.assert(programs.size() > 1, 'Expected at least 2 programs');
        System.assert(programs.get(1).Tier__c == 'Affiliated', 'Expected Affiliated program status, got ' + programs.get(1).Tier__c);
    }


    @isTest static void testApplyStandardTerms() {

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.READY);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm.Is_Primary__c = false;
        insert pgm;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Is_Active__c = true;
        token.Token__c = PartnerEmailUtils.generateEmailToken(acct.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Account__c = acct.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', 'masmith+standard@redhat.com');

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
        ctrl.init();
        ctrl.termType = 'standard';

        ctrl.submitButton();
}
        pgm = [select Id, Status__c from Partner_Program__c where Id = :pgm.Id];
        System.assert(pgm.Status__c == 'Active', 'Expected status of program to be active');

        PartnerAgreement__c[] agreementlist = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];
        System.assert(agreementlist.size() > 0, 'Expected to be at least 1 agreement registered');
    }

    @isTest static void testApplyCustomTerms() {

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.READY);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm.Status__c = 'Pending Terms';
        pgm.Is_Primary__c = false;
        insert pgm;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(acct.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Account__c = acct.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', 'masmith+apply@redhat.com');

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
        ctrl.init();

        ctrl.termType = 'custom';
        ctrl.customText = 'custom terms';
        ctrl.submitButton();
}

        pgm = [select Id, Status__c from Partner_Program__c where Account__c = :acct.Id and Program__r.Program_Category__c = :PartnerConst.EMBED];
        System.assert(pgm.Status__c == 'Pending Terms', 'Expected partner program status to be pending terms');

        Contract con = [select Id, Requesting_User__c from Contract where AccountId = :sales.Id limit 1];
        System.assert(con.Requesting_User__c != null, 'Requesting_User__c is null');

    }

    @isTest static void testCustomTerms() {

        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.READY);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm.Status__c = 'Pending Terms';
        pgm.Is_Primary__c = false;
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV').ObjectId__c;
        onb.Subtype__c = 'Embedded';
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+standard@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

User u = [select Id from User where Id = '00560000000niki'];
System.runAs(u) {

        Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
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

    @isTest static void testCustomTermsReentry() {

        Partner_Onboarding_Registration__c onb = [select Id, RHNLogin__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where RHNLogin__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test_Reentry');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;

        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm.Status__c = 'Pending Terms';
        pgm.Is_Primary__c = false;
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV').ObjectId__c;
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Contract contract = new Contract();
        contract.AccountId = sales.Id;
        contract.Contract_Type__c = Embedded_Terms_Controller.CONTRACT_TYPE;
        contract.CountryOfOrder__c = 'United States';
        contract.Stage__c = 'Draft';
        contract.Requesting_User__c = UserInfo.getUserId();
        contract.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = 'Customer_or_Partner_Contract'
            and     IsActive = true
        ].Id;
        insert contract;
        contract.Status = 'Rejected';
        update contract;

        contract = [select Id, Status from Contract where Id = :contract.Id];
        System.debug('***** [debug] ***** contract status is ' + contract.Status);

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+standard@redhat.com');
        token.Is_Active__c = true;
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;

        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

        User u = [select Id from User where Id = '00560000000niki'];
        System.runAs(u) {
            Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
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

        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Controller_Test');
        insert acct;
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;

        onb.ConvertedAccount__c = acct.Id;
        onb.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV').ObjectId__c;
        onb.Agree_to_Partner_TC__c = false;
        onb.HasCustomTerms__c = false;
        update onb;

        Test.startTest();

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = 'masmith+standard@redhat.com';
        token.Notification_Type__c = 'Embedded Terms';
        token.Token__c = PartnerEmailUtils.generateEmailToken(onb.Id, 'masmith+logintest@redhat.com');
        insert token;
        token.Partner_Onboarding__c = onb.Id;
        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmbeddedTermsFullURL(token.Token__c);
        update token;
        ApexPages.currentPage().getParameters().put('token', token.Token__c);
        ApexPages.currentPage().getParameters().put('federationId', onb.RHNLogin__c);

        Embedded_Terms_Controller ctrl = new Embedded_Terms_Controller();
        ctrl.init();

        ctrl.loginButton();
    }

}