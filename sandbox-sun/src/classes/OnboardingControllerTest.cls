@IsTest
private without sharing class OnboardingControllerTest {

     public static testMethod void testNew() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TYPE.%'];
        List<Country__c> countryList = null;
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        List<Classification__c> partnerTierClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TIER.%'];

        Classification__c resellerClassification = null;
        Classification__c isvClassification = null;
        for (Classification__c partnerType : partnerTypeClassifications) {
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.RESELLER') {
                resellerClassification = partnerType;
            }
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.ISV') {
                isvClassification = partnerType;
            }
        }

        Classification__c readyClassification = null;
        for (Classification__c partnerTier : partnerTierClassifications) {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY') {
                readyClassification = partnerTier;
            }
        }


        Account account = PartnerTestUtils.makeAccount('Onboarding Test', adminUser);
        // note: you must not insert a PartnerStatus for these tests -- will cause DML problems with
//        PartnerTestUtils.setNewStatus(PartnerTestUtils.makeStatus(account.Id, 'PARTNER_TYPE.RESELLER', 'PARTNER_TIER.READY'));
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact1');
        insert contact;

        User user1  = new User(username = 'test1abvasdasasdsa@redhat.com',LastName='lname',CommunityNickname='Test1abv', email = 'test1abvasdasasdsa@redhat.com', alias = 'test1abv', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='123456789iuyt',ContactId =contact.Id);
        insert user1;

        Lead leadInfo = new Lead();
        leadInfo.Partner_Type__c = resellerClassification.Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        //leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Is_Primary_Public_Sector__C = 'No';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';


        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', '');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('partner-id', '');
        ApexPages.currentPage().getParameters().put('language', 'en');
        ApexPages.currentPage().getParameters().put('partner-name', '');
        ApexPages.currentPage().getParameters().put('legacy', '');

        test.starttest();

        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        Classification__c classification = controller.SelectedPartnerType;
        //System.assert(classification.Name == 'Reseller', 'Partner classifications are not correct');
        controller.getLead().Partner_Type__c = isvClassification.Id;
        classification = controller.SelectedPartnerType;
        //System.assert(classification.Name == 'ISV', 'Partner classifications are not correct');
        System.debug('Get Page Name--------->'+ controller.CurrentPageName);

        String debugParams = controller.getDebugParams();

        controller.setLead(leadInfo);
        //System.assert(controller.getLead() != null);

        System.debug('controller.getIndustryFocusOptions()=========>'+ controller.getIndustryFocusOptions());
        System.assert(controller.getIndustryFocusOptions()!= null, 'Industry focus options are empty');
        System.assert(controller.getIndustryFocus()!= null, 'Industry focus is empty');
        System.assert(controller.getTargetMarketSizeOptions()!= null, 'Target market options are empty');
        System.assert(controller.getTargetMarketSize() != null, 'Target market size is empty');
        System.assert(controller.getSoftwareFocusOptions() != null, 'Software Focus options are empty');
        System.assert(controller.getSoftwareFocus() != null, 'Software Focus is empty');
        System.assert(controller.getOperatingSystemSupportedOptions() != null, 'Operating System Supported Options ae empty');
        System.assert(controller.getOperatingSystemSupported() != null,'Operating Systems supported is empty');
        System.assert(controller.getMiddlewareSupportedOptions()!= null,'Middleware Supported options is empty');
        System.assert(controller.getMiddlewareSupported()!= null,'Middleware supported is empty');
        System.assert(controller.getApplicationTypesOptions() != null,'Application type options are empty');
        System.assert(controller.getApplicationTypes() != null ,'Application types are empty');
        System.assert(controller.getAdditionalPartnershipsOptions() != null,'Additional Partnership options are empty');
        System.assert(controller.getAdditionalPartnerships() != null,'Partnerships are empty');
        System.debug('Countries --------->'+ controller.SelectableCountryList);
        System.assert(controller.SelectableCountryList != null,'Countries are not loaded');
        System.assert(controller.SelectableCountryOptions != null,'Selectable countries are not loaded.');
        System.assert(controller.SelectableStateOptions != null,'Selectable states are not loaded.');

        controller.setMiddlewareSupported(controller.getMiddlewareSupported());
        controller.setApplicationTypes(controller.getApplicationTypes());
        controller.setTargetMarketSize(controller.getTargetMarketSize());
        controller.setAdditionalPartnerships(controller.getAdditionalPartnerships());
        controller.setAdditionalCountriesOfOperations(controller.getAdditionalCountriesOfOperations());
        controller.setOperatingSystemSupported(controller.getOperatingSystemSupported());
        controller.setSoftwareFocus(controller.getSoftwareFocus());

        // Poking various UI checks
        controller.getPublicSectorMarketOptions();
        controller.getPublicSectorMarket();
        Integer throwaway = controller.CurrentStep;
        controller.getIsJoinOnlyFlow();

        List<PartnerStatus__c> existingPartnerList = controller.getExistingPartnerList();
        controller.registerPartnerStart();
        System.assert(controller.CurrentPageName == 'RegisterPartner','Invalid launch Page');

        // case 1 :: Partner Type and country are not specified.
        //controller.getLead().Partner_Type__c = null;
        //controller.getLead().Country = null;
        //controller.registerPartnerSubmit();
        //System.assert(controller.CurrentPageName =='RegisterPartner', 'Partner onboarding cannot continue without specifying country and partner Type');
        // case 2 :: Partner Type and country are  specified ,should go to agreements page.
        controller.getLead().Country = 'US';
        controller.getLead().Partner_Type__c = resellerClassification.Id;
        List<Agreement__c> agreementList = controller.getRelevantAgreementList();
        controller.OnboardingType = 'create';
        controller.registerPartnerSubmit();
        System.debug('***[debug] currentPageName=' + controller.CurrentPageName);
        debugMessages();
        System.assert((agreementList != null && controller.CurrentPageName =='RegisterAgreements'), 'Partner should go to the agreements page');

        controller.agreementAcceptence = 'Yes';
        controller.registerAgreementsSubmit();
        System.assert(controller.CurrentPageName == 'RegisterProfile', 'Partner should be redirected to profile page.');

/*
        controller.getLead().Street='';
        controller.getLead().City ='';
        controller.getLead().State ='';
        controller.getLead().Phone ='';
        controller.getLead().PostalCode ='';
        controller.getLead().Website ='';
        controller.getLead().Industry_Focus__c ='';
        controller.getLead().Do_they_act_in_any_government_position__c = 'No';
        controller.getLead().Have_they_been_convicted__c = 'No';
        controller.registerProfileSubmit();
        System.assert(controller.getHasErrorMessages(), 'Profile is not populated properly');
*/

        controller.getLead().Street = '417 Montgomery';
        controller.getLead().City = 'San Francisco';
        controller.getLead().State ='CA';
        controller.getLead().Phone ='4156325768';
        controller.getLead().Country = 'US';
        controller.getLead().PostalCode ='94104';
        controller.getLead().Website ='www.apprivo.com';
        controller.getLead().Industry_Focus__c ='Aerospace';
        controller.getLead().Do_they_act_in_any_government_position__c='Yes';
        controller.getLead().Is_Primary_Public_Sector__C = 'No';
        controller.getLead().Have_they_been_convicted__c='No';

        controller.registerProfileSubmit();
//        System.assert(controller.CurrentPageName == 'RegisterDemographics', 'Partner should be redirected to demographics page, found ' + controller.CurrentPageName);

/*
        controller.getLead().Company = '';
        controller.getLead().Company_Description__c ='';
        controller.getLead().Number_of_Employees__c ='';
        controller.getLead().Total_Annual_Revenue__c ='';
        controller.getLead().Target_Market_Size__c ='';
        controller.getLead().Software_Focus__c ='';
        controller.getLead().Operating_System_Supported__c ='';
        controller.getLead().Middleware_Supported__c ='';
        controller.getLead().Application_Types__c ='';
        controller.getLead().Additional_Partnerships__c ='';
        controller.registerDemographicsSubmit();
        System.assert(controller.getHasErrorMessages(), 'Profile demographics is not populated properly');
*/

        controller.getLead().Company = 'Red Hat';
        controller.getLead().Company_Description__c ='Test';
        controller.getLead().Number_of_Employees__c ='2';
        controller.getLead().Total_Annual_Revenue__c ='100';
        controller.getLead().Target_Market_Size__c ='100';
        controller.getLead().Software_Focus__c ='Test';
        controller.getLead().Operating_System_Supported__c ='Test';
        controller.getLead().Middleware_Supported__c ='Linux';
        controller.getLead().Application_Types__c ='SFW';
        controller.getLead().Additional_Partnerships__c ='Test';
        controller.registerDemographicsSubmit();
//        System.assert(controller.CurrentPageName == 'RegisterThankYou', 'Partner should be redirected to register thank you page');



/*
        leadInfo = new Lead();
        leadInfo.Partner_Type__c = resellerClassification.Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Other_Countries__c ='Camaroon';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';
        controller.setLead(leadInfo);
        controller.joinPartnerSubmit();
        */
        //System.assert(controller.CurrentPageName == 'JoinThankYou', 'Partner is not redirected to confirmation page');
//        controller.migratePartnerSubmit();
        //System.assert(controller.CurrentPageName.equals('DisplayCaseStatus'));

// masmith - had to comment out the following 2 tests b/c was not working correctly in poc and qa0, but was fine in prod
//        controller.activateUserSubmit();
        //System.assert(controller.CurrentPageName.equals('DisplayCaseStatus'));
//        controller.convertContactSubmit();
        System.debug('Current Page Name------>'+ controller.CurrentPageName);
        //System.assert((controller.getRelevantAgreementList() != null && controller.CurrentPageName =='RegisterAgreements'),'Partner profile cancel redirect failure');

        /*
        System.assert(controller.CurrentPageName.equals('JoinOrRegister'),'Partner register cancel failed');
        System.assert(controller.getLead().Partner_Type__c == null,'Partner registration cancel did not clear the values');
        System.assert(controller.getLead().Country == null,'Partner registration cancel did not clear the values');
        */

        controller.registerDemographicsCancel();
        //System.assert(controller.CurrentPageName.equals('RegisterProfile'),'Partner Demographics cancel failed');
        controller.registerAgreementsCancel();
        //System.assert(controller.CurrentPageName.equals('RegisterPartner'),'Partner registration cancel failed');
        controller.joinPartnerCancel();
        //System.assert(controller.CurrentPageName.equals('JoinOrRegister'),'Partner register cancel failed');
        controller.activateUserCancel();
        //System.assert(controller.CurrentPageName.equals('BackToRedHat'),'User activate failed');
        controller.convertContactCancel();
        //System.assert(controller.CurrentPageName.equals('BackToRedHat'),'User activate failed');
//        controller.migratePartnerCancel();
       // System.assert(controller.CurrentPageName.equals('RedirectToLegacyPC'),'User migrate cancel failed');
        //controller.insertOnboardingLead();

        //
        // test redirect to login page
        //
        ApexPages.currentPage().getParameters().remove('federation-id');
        controller = null;
        controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        System.debug('Current Page Name--------->'+ controller.CurrentPageName);
        //System.assert(controller.CurrentPageName == 'Login','Invalid launch Page');
        controller.CurrentPageName = 'RedirectToLegacyPC';
        controller.processRedirects();
        controller.CurrentPageName = 'Login';
        controller.processRedirects();
        controller.CurrentPageName = 'BackToRedHat';
        controller.processRedirects();

        User ufid = [
        	select
        		FederationIdentifier from User
        	where
    			FederationIdentifier != null
    			and profile.name like '%Partner Portal%'
           		and isPortalEnabled = true
                and ContactId != null
            limit 1];
        controller.FederationId = ufid.FederationIdentifier;

        controller.CurrentPageName = 'RedirectToJoinAccept';
        controller.processRedirects();
        controller.CurrentPageName = 'RedirectToPRM';
        controller.processRedirects();
//        controller.migratePartnerCancel();

        controller = null;


        test.stopTest();
     }

    private static void debugMessages() {
     	ApexPages.Message[] msglist = ApexPages.getMessages();
     	for (ApexPages.Message msg : msglist) {
     		System.debug('***[debug] MSG=' + msg.getDetail());
     	}
     }

	public static testMethod void testHandleExistingCase() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TYPE.%'];
//        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        List<Country__c> countryList = null;
        //List<Classification__c> isvPartnerClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'ISV' limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        List<Classification__c> partnerTierClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TIER.%'];

        Classification__c resellerClassification = null;
        Classification__c isvClassification = null;
        for (Classification__c partnerType : partnerTypeClassifications) {
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.RESELLER') {
                resellerClassification = partnerType;
            }
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.ISV') {
                isvClassification = partnerType;
            }
        }

        Classification__c readyClassification = null;
        for (Classification__c partnerTier : partnerTierClassifications) {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY') {
                readyClassification = partnerTier;
            }
        }


        Account account = PartnerTestUtils.makeAccount('Onboarding Test', adminUser);
        // note: you must not insert a PartnerStatus for these tests -- will cause DML problems with
//        PartnerTestUtils.setNewStatus(PartnerTestUtils.makeStatus(account.Id, 'PARTNER_TYPE.RESELLER', 'PARTNER_TIER.READY'));
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact2');
        insert contact;

        User user1  = new User(username = 'test2abvasdasasdsa@redhat.com',LastName='lname',CommunityNickname='Test2abv', email = 'test2abvasdasasdsa@redhat.com', alias = 'test1abv', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='123456789iuytt',ContactId =contact.Id);
        user1.isActive = true;
        insert user1;

        Lead leadInfo = new Lead();
        leadInfo.LastName = 'lastname';
        leadInfo.FirstName = 'firstname';
        leadInfo.Partner_Type__c = resellerClassification.Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuytt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';
        leadInfo.partner_onboarding_status__c = 'Approved';
        insert leadInfo;

        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', '');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test1@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', '123456789iuytt');
        ApexPages.currentPage().getParameters().put('partner-id', '');
        ApexPages.currentPage().getParameters().put('language', 'en');
        ApexPages.currentPage().getParameters().put('partner-name', '');
        ApexPages.currentPage().getParameters().put('legacy', '');

        test.starttest();

        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        controller.setLead(leadInfo);
        controller.activateUserSubmit();
        System.assert(controller.CurrentPageName == 'DisplayCaseStatus','expected DisplayCaseStatus Page after activateUserSubmit');

        controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        controller.setLead(leadInfo);
        System.assert(controller.CurrentPageName == 'DisplayCaseStatus','expected DisplayCaseStatus Page');

    }

    public static testMethod void testHandleExistingUser() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TYPE.%'];
//        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        List<Country__c> countryList = null;
        //List<Classification__c> isvPartnerClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'ISV' limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        List<Classification__c> partnerTierClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TIER.%'];

        Classification__c resellerClassification = null;
        Classification__c isvClassification = null;
        for (Classification__c partnerType : partnerTypeClassifications) {
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.RESELLER') {
                resellerClassification = partnerType;
            }
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.ISV') {
                isvClassification = partnerType;
            }
        }

        Classification__c readyClassification = null;
        for (Classification__c partnerTier : partnerTierClassifications) {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY') {
                readyClassification = partnerTier;
            }
        }


        Account account = PartnerTestUtils.makeAccount('Onboarding Test', adminUser);
        // note: you must not insert a PartnerStatus for these tests -- will cause DML problems with
//        PartnerTestUtils.setNewStatus(PartnerTestUtils.makeStatus(account.Id, 'PARTNER_TYPE.RESELLER', 'PARTNER_TIER.READY'));
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact1');
        insert contact;

        User user1  = new User(username = 'test3abvasdasasdsa@redhat.com',LastName='lname',CommunityNickname='Test3abv', email = 'test3abvasdasasdsa@redhat.com', alias = 'test3abv', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='123456789iuyttt',ContactId =contact.Id);
        user1.isActive = true;
        insert user1;

        Lead leadInfo = new Lead();
        leadInfo.LastName = 'lastname';
        leadInfo.FirstName = 'firstname';
        leadInfo.Partner_Type__c = resellerClassification.Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyttt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';
        leadInfo.partner_onboarding_status__c = 'Approved';
        insert leadInfo;

        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', '');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test1@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', '123456789iuyttt');
        ApexPages.currentPage().getParameters().put('partner-id', '');
        ApexPages.currentPage().getParameters().put('language', 'en');
        ApexPages.currentPage().getParameters().put('partner-name', '');
        ApexPages.currentPage().getParameters().put('legacy', '');

        test.starttest();

        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        controller.setLead(leadInfo);
        PartnerTestUtils.makeAccountISV(account.Id);
        PartnerStatus__c ps = [select Id, isVisible__C, ApprovalStatus__c from PartnerStatus__c where Partner__c = :account.Id and ActivationStatus__c = 'Active' limit 1];
        ApexPages.currentPage().getParameters().put('partner-status-id', ps.Id);
        controller.joinPartnerStart();
        controller.joinPartnerSubmit();
        controller.registerPartnerCancel();
        controller.registerProfileCancel();
        //System.assert(controller.CurrentPageName == 'RedirectToPRM','expected RedirectToPRM Page');

     }

     public static testMethod void testJoin() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TYPE.%'];
//        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        List<Country__c> countryList = null;
        //List<Classification__c> isvPartnerClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'ISV' limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        List<Classification__c> partnerTierClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TIER.%'];

        Classification__c resellerClassification = null;
        Classification__c isvClassification = null;
        for (Classification__c partnerType : partnerTypeClassifications) {
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.RESELLER') {
                resellerClassification = partnerType;
            }
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.ISV') {
                isvClassification = partnerType;
            }
        }

        Classification__c readyClassification = null;
        for (Classification__c partnerTier : partnerTierClassifications) {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY') {
                readyClassification = partnerTier;
            }
        }


        Account account = PartnerTestUtils.makeAccount('Onboarding Test', adminUser);
        // note: you must not insert a PartnerStatus for these tests -- will cause DML problems with
//        PartnerTestUtils.setNewStatus(PartnerTestUtils.makeStatus(account.Id, 'PARTNER_TYPE.RESELLER', 'PARTNER_TIER.READY'));
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact1');
        insert contact;

        User user1  = new User(username = 'test4abvasdasasdsa@redhat.com',LastName='lname',CommunityNickname='Test4abv', email = 'test4abvasdasasdsa@redhat.com', alias = 'test4abv', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='23456789iuyt',ContactId =contact.Id);
        user1.isActive = true;
        insert user1;

        Lead leadInfo = new Lead();
        leadInfo.Partner_Type__c = resellerClassification.Id;
        //leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='23456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';


        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', '');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', 'test4@apprivo.com');
        ApexPages.currentPage().getParameters().put('partner-id', '');
        ApexPages.currentPage().getParameters().put('language', 'en');
        ApexPages.currentPage().getParameters().put('partner-name', '');
        ApexPages.currentPage().getParameters().put('legacy', '');

        test.starttest();

        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        controller.setLead(leadInfo);
        PartnerTestUtils.makeAccountISV(account.Id);
        PartnerStatus__c ps = [select Id, isVisible__C, ApprovalStatus__c from PartnerStatus__c where Partner__c = :account.Id and ActivationStatus__c = 'Active' limit 1];
        ApexPages.currentPage().getParameters().put('partner-status-id', ps.Id);
        controller.joinPartnerStart();
        controller.joinPartnerSubmit();

        controller.joinPartnerCancel(); // mls
     }


     public static testMethod void testNewSIDecline() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TYPE.%'];
//        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        List<Country__c> countryList = null;
        //List<Classification__c> isvPartnerClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'ISV' limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        List<Classification__c> partnerTierClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c like 'PARTNER_TIER.%'];

        Classification__c siClassification = null;
        for (Classification__c partnerType : partnerTypeClassifications) {
            if (partnerType.HierarchyKey__c == 'PARTNER_TYPE.SI') {
                siClassification = partnerType;
                break;
            }
        }

        Classification__c readyClassification = null;
        for (Classification__c partnerTier : partnerTierClassifications) {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY') {
                readyClassification = partnerTier;
                break;
            }
        }

        Account account = PartnerTestUtils.makeAccount('Onboarding Test SI', adminUser);
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact1');
        insert contact;

        User user1  = new User(username = 'test5abvasdasasdsa@redhat.com',LastName='lname',CommunityNickname='Test5abv', email = 'test5abvasdasasdsa@redhat.com', alias = 'test5abv', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='13456789iuyt',ContactId =contact.Id);
        insert user1;

        Lead leadInfo = new Lead();
        leadInfo.Partner_Type__c = siClassification.Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        //leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='23456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Is_Primary_Public_Sector__C = 'No';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Onboarding_Language_Preference__c = 'en';

        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', '');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', 'test5@apprivo.com');
        ApexPages.currentPage().getParameters().put('partner-id', '');
        ApexPages.currentPage().getParameters().put('language', 'en');
        ApexPages.currentPage().getParameters().put('partner-name', '');
        ApexPages.currentPage().getParameters().put('legacy', '');

        test.starttest();

        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        Classification__c classification = controller.SelectedPartnerType;
        //System.assert(classification.Name == 'Reseller', 'Partner classifications are not correct');
        controller.getLead().Partner_Type__c = siClassification.Id;
        classification = controller.SelectedPartnerType;
        //System.assert(classification.Name == 'ISV', 'Partner classifications are not correct');
        System.debug('Get Page Name--------->'+ controller.CurrentPageName);
        controller.setLead(leadInfo);
        //System.assert(controller.getLead() != null);

        System.debug('controller.getIndustryFocusOptions()=========>'+ controller.getIndustryFocusOptions());
        System.assert(controller.getIndustryFocusOptions()!= null, 'Industry focus options are empty');
        System.assert(controller.getIndustryFocus()!= null, 'Industry focus is empty');
        System.assert(controller.getTargetMarketSizeOptions()!= null, 'Target market options are empty');
        System.assert(controller.getTargetMarketSize() != null, 'Target market size is empty');
        System.assert(controller.getSoftwareFocusOptions() != null, 'Software Focus options are empty');
        System.assert(controller.getSoftwareFocus() != null, 'Software Focus is empty');
        System.assert(controller.getOperatingSystemSupportedOptions() != null, 'Operating System Supported Options ae empty');
        System.assert(controller.getOperatingSystemSupported() != null,'Operating Systems supported is empty');
        System.assert(controller.getMiddlewareSupportedOptions()!= null,'Middleware Supported options is empty');
        System.assert(controller.getMiddlewareSupported()!= null,'Middleware supported is empty');
        System.assert(controller.getApplicationTypesOptions() != null,'Application type options are empty');
        System.assert(controller.getApplicationTypes() != null ,'Application types are empty');
        System.assert(controller.getAdditionalPartnershipsOptions() != null,'Additional Partnership options are empty');
        System.assert(controller.getAdditionalPartnerships() != null,'Partnerships are empty');
        System.debug('Countries --------->'+ controller.SelectableCountryList);
        System.assert(controller.SelectableCountryList != null,'Countries are not loaded');
        System.assert(controller.SelectableCountryOptions != null,'Selectable countries are not loaded.');
        System.assert(controller.SelectableStateOptions != null,'Selectable states are not loaded.');

        controller.setMiddlewareSupported(controller.getMiddlewareSupported());
        controller.setApplicationTypes(controller.getApplicationTypes());
        controller.setTargetMarketSize(controller.getTargetMarketSize());
        controller.setAdditionalPartnerships(controller.getAdditionalPartnerships());
        controller.setAdditionalCountriesOfOperations(controller.getAdditionalCountriesOfOperations());
        controller.setOperatingSystemSupported(controller.getOperatingSystemSupported());
        controller.setSoftwareFocus(controller.getSoftwareFocus());
        List<PartnerStatus__c> existingPartnerList = controller.getExistingPartnerList();
        controller.registerPartnerStart();
        System.assert(controller.CurrentPageName == 'RegisterPartner','Invalid launch Page');

        controller.getLead().Country = 'US';
        controller.getLead().Partner_Type__c = siClassification.Id;
        List<Agreement__c> agreementList = controller.getRelevantAgreementList();
//        controller.registerPartnerSubmit();
//        System.assert((agreementList != null && controller.CurrentPageName =='RegisterAgreements'), 'Partner should go to the agreements page');

        controller.agreementAcceptence = 'No';
        controller.registerAgreementsSubmit();
        System.assert(controller.CurrentPageName != 'RegisterAgreements', 'Partner should be force to enter decline reason.');

        // can skip further testing here, it's covered in testNew()

        controller = null;

        test.stopTest();
     }
}