@isTest(SeeAllData=true)
private class PartnerGatewayTest {

    @isTest static void testNotLoggedIn() {
        PartnerGateway gw = new PartnerGateway();
        PageReference pg = gw.init();
        System.assert(pg == null, 'expected to render default access page');
    }

	@isTest static void testLoggedInMissingUser() {
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, 'fedid-test');
        PageReference pg = gw.init();
        System.assert(pg == null, 'invalid page reference: not null');
    }

    @isTest static void testLoggedInOnboardApply() {
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, 'fedid-test');
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_ACTION, PartnerGateway.ACTION_APPLY);
        PageReference pg = gw.init();
        System.assert(pg != null, 'invalid page reference: null');
        System.assert(pg.getUrl() == '/apex/onboardingapply?action=apply&federation-id=fedid-test', 'expected to redirect to /apex/onboardingapply?action=apply&federation-id=fedid-test: got ' + pg.getUrl());

	}

    @isTest static void testLoginButton() {
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_ACTION, PartnerGateway.ACTION_APPLY);
        PageReference pg = gw.init();
        System.assert(pg == null, 'expected to render default access page');
        pg = gw.handleLogin();
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        System.assert(pg.getUrl().indexof('partner.html') > 0, 'Expected to redirect to partner.html, found ' + pg.getUrl());
        System.assert(pg.getUrl().indexof('login.html') > 0, 'Expected to find login.html, found ' + pg.getUrl());
    }

    @isTest static void testRegisterButton() {
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_ACTION, PartnerGateway.ACTION_APPLY);
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_PROGRAM, 'PARTNER_TYPE.RESELLER');
        PageReference pg = gw.init();
        System.assert(pg == null, 'expected to render default access page');
        pg = gw.handleRegister();
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        System.assert(pg.getUrl().indexof('wapps/ugc/register.html') > 0, 'Expected to redirect to wapps/ugc/register.html, found ' + pg.getUrl());
        System.assert(pg.getUrl().indexof('action%253Dapply') > 0, 'Expected to find action=apply, found ' + pg.getUrl());
    }

    private static User findExistingResellerUser() {
        return [
            select   FederationIdentifier
            from     User
            where    IsActive = true
            and      Contact.Account.IsPartner = true
            and      Contact.Account.PartnerStatuses__c includes ('Ready - Reseller')
            and      ContactId != null
            and      Profile.Name like '%Partner Portal%'
            limit    1
        ];

    }

    @isTest static void testUserAlreadyExistsErrorForApply() {
        User testuser = findExistingResellerUser();
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_ACTION, PartnerGateway.ACTION_APPLY);
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, testuser.FederationIdentifier);
        PageReference pg = gw.init();
        System.assert(pg != null, 'invalid page reference: null');
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        System.assert(pg.getUrl().endsWith(Page.OnboardingUserAssociatedError.getUrl()), 'Expected to be redirected to ' +Page.OnboardingUserAssociatedError.getUrl() + ', | Found:' + pg.getUrl());
    }

    @isTest static void testUserAlreadyExistsErrorForJoin() {
        User testuser = findExistingResellerUser();
        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(PartnerGateway.PARAM_ACTION, PartnerGateway.ACTION_JOIN);
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, testuser.FederationIdentifier);
        PageReference pg = gw.init();
        System.assert(pg != null, 'invalid page reference: null');
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        System.assert(pg.getUrl().endsWith(Page.OnboardingUserAssociatedError.getUrl()), 'Expected to be redirected to ' +Page.OnboardingUserAssociatedError.getUrl() + ', | Found:' + pg.getUrl());

    }
    //
    // US75121:
    // Embedded partner with pending terms should always be presented with std. terms upon Login
    //
    @isTest static void testEmbeddedTermsRedirect() {
        Account ac = PartnerTestUtils.makeNonpartnerAccount('testname', PartnerTestUtils.getAdminUser());

        Partner_Onboarding_Registration__c onb = PartnerTestUtils.makeOnboardingRequest('firstname',' lastname',' String company', PartnerTestUtils.getAdminUser());
        onb.RHNLogin__c = 'testfederatedEmbeddedUser';
        onb.ConvertedAccount__c = ac.Id;
        insert onb;

        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Token__c = 'token9797askhkdsh8789';
        token.Email__c = onb.Email__c;
        token.Partner_Onboarding__c = onb.Id;
        token.Is_Active__c = true;
        token.Notification_Type__c = 'Embedded Terms';


        PartnerUser_Email_Token__c[] tkn =[SELECT Token__c, Email__c, Federation_Id__c
                                             FROM PartnerUser_Email_Token__c
                                             WHERE Is_Active__c = true
                                             AND Partner_Onboarding__c != null
                                             AND Notification_Type__c = 'Embedded Terms'
                                             AND Partner_Onboarding__r.convertedAccount__c != null
                                             LIMIT 1];

        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, token.Federation_Id__c);

        PageReference pg = gw.init();
        pg = gw.handleLogin();
        System.assert(pg != null, 'invalid page reference: null');
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        //don't have a way to fake the SAML authentication programatically at the moment:
        //System.assert(pg.getUrl() == '/apex/embedded_terms?federationId=' +token.Federation_Id__c+ '&token=' +token.Token__c,
        //    'expected to redirect to: /apex/embedded_terms?federationId=' +token.Federation_Id__c+ '&token=' +token.Token__c+ 'got: ' + pg.getUrl());

    }

    //
    // US75121:
    // CCSP partner with pending terms should always be presented with std. terms upon Login
    //
    @isTest static void testCCSPTermsRedirect() {
        PartnerUser_Email_Token__c token = [SELECT Token__c, Email__c, Federation_Id__c
                                            FROM PartnerUser_Email_Token__c
                                            WHERE Is_Active__c = true
                                            AND Partner_Onboarding__c != null
                                            AND Notification_Type__c = 'CCSP Terms'
                                            AND Partner_Onboarding__r.convertedAccount__c != null
                                            LIMIT 1];

        Partner_Onboarding_Registration__c onb = OnboardingUtils.getLeadWithFederationId(token.Federation_Id__c);

        PartnerGateway gw = new PartnerGateway();
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, token.Federation_Id__c);

        PageReference pg = gw.init();
        pg = gw.handleLogin();
        System.assert(pg != null, 'invalid page reference: null');
        System.assert(pg.getRedirect() == true, 'Expected a redirect');
        //don't have a way to fake the SAML authentication programatically at the moment:
        //System.assert(pg.getUrl() == '/apex/embedded_terms?federationId=' +token.Federation_Id__c+ '&token=' +token.Token__c,
        //    'expected to redirect to: /apex/embedded_terms?federationId=' +token.Federation_Id__c+ '&token=' +token.Token__c+ 'got: ' + pg.getUrl());

    }


}