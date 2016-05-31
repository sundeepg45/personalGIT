@isTest(SeeAllData = true)
public class OnboardingApplyControllerTest {


   static testMethod void ccnspTest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Timelord');
        pmap.put('rhn-company-name', 'Gallifrey');
        pmap.put('rhn-email', 'thedoctor@gallifrey.net');
        pmap.put('rhn-salutation', 'Dr');
        pmap.put('rhn-first-name', 'John');
        pmap.put('rhn-last-name', 'Smith');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.SERVICECLOUD_PROVIDER';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Time & Space';
        ctrl.theLead.City__c = 'Raleigh';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLeadCountry = 'US';
        ctrl.selectedState = 'NC';
           ctrl.theLead.Postal_Code__c = '27610';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'You break it, we have already fixed it';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'No';
        PageReference page = ctrl.submitApplication();

        Partner_Onboarding_Registration__c mylead = [select Email__c, SubRegion__c from Partner_Onboarding_Registration__c where Id = :ctrl.theLead.Id];
        System.debug('*****[debug]***** >> subregion__c = ' + mylead.SubRegion__c);
        System.assert(mylead.Email__c != null, 'Email is null');

        PartnerAgreement__c[] agreements = [select Id from PartnerAgreement__c where Partner_Onboarding__c = :ctrl.getLead().Id];
        System.assert(agreements.size() == 0, 'Expected no agreements for CC&SP, found ' + agreements.size());

        CCSP_Form__c form = [select Id, Contact_Email__c, Status__c from CCSP_Form__c where CCSPOnboardingRegistration__c = :ctrl.theLead.Id];
        System.assert(form.Contact_Email__c == ctrl.theLead.Email__c, 'Email mismatch on CCSP Form');
        System.assert(form.Status__c == 'User Notified', 'CCSP Form status expected to be "User Notified", found "' + form.Status__c + '"');


    }

    static testMethod void simpleTest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_simple');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Umbrella Corp';
        ctrl.theLead.City__c = 'Raleigh';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLeadCountry = 'US';
        ctrl.selectedState = 'NC';
        ctrl.theLead.Postal_Code__c = '27610';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'Purveyors of fine DNA for a darker future';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'Yes';
        PageReference page = ctrl.submitApplication();

        Partner_Onboarding_Registration__c mylead = [select Email__c, SubRegion__c from Partner_Onboarding_Registration__c where Id = :ctrl.theLead.Id];
        System.debug('*****[debug]***** >> subregion__c = ' + mylead.SubRegion__c);
        System.assert(mylead.Email__c != null, 'Email is null');
    }

    static testMethod void simpleEMEATest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_emea');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Umbrella Corp';
        ctrl.theLead.City__c = 'London';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLeadCountry = 'GB';
        ctrl.theLead.Postal_Code__c = 'WC2E 9RZ';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'Purveyors of fine DNA for a darker future';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'Yes';
        PageReference page = ctrl.submitApplication();

    }


     static testMethod void personalTypeTest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_personalType');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        pmap.put('customer-type','P');
        PageReference p = ctrl.init();

       system.assertEquals('/apex/onboardingjoinpersonal', p.getUrl());

       // reset the controller
       ctrl = new OnboardingApplyController();
       pmap.remove('customer-type'); // Now leave out the customer type param
       pmap.remove('rhn-company-name'); // No company name provided
       ctrl.theLead.Company__c = ''; // The lead company is also null

        PageReference p2 = ctrl.init();

        system.assertEquals('/apex/onboardingjoinpersonal', p2.getUrl());
     }



     static testMethod void existingCaseTest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_existingCase');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'darklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        pmap.put('customer-type','P');

        RecordType rt = [select id from RecordType where sObjectType = 'Case' and Name = 'Partner General Issues'];
        Case testCase = new Case(
            recordTypeId = rt.Id,
            redhatLoginName__c = 'HeWhoShallNotBeNamed',
            issue_type_classification__c = 'Partner Onboarding'
        );
        insert(testCase);
        system.debug('Test case: [' + testCase + ']');
        system.debug('Test case record type: [' + testCase.recordtype + ']');
        system.assertEquals(rt.Id, testCase.RecordTypeId);


        PageReference p;
        test.startTest();
        p = ctrl.init();
        test.stopTest();

        //ctrl.createPartnerOnboardingCase(pmap.get('federation-Id'),
        //                                        'Partner Onboarding',
        //                                        'subject',
        //                                        'description', String contactId, String accountId, String region, String countryName, String priority)

        //system.assertEquals(true, ctrl.HasOnboardingCase); // not working b/c recordtype of case isn't set yet

     }

     static testMethod void embeddedOnboardingTest() {

        OnboardingApplyController ctrl = new OnboardingApplyController();
        ctrl.getPublicSectorMarketOptions();
        ctrl.getPublicSectorMarket();
        ctrl.getSplitPicklistField('');
        ctrl.getAdditionalCountriesOfOperations();
        ctrl.getAdditionalCountriesOfOperationsOptions();
        ctrl.getTotalAnnualRevenueOptions();
        ctrl.getNumberOfEmployeesOptions();
        ctrl.getTargetMarketSize();
        ctrl.getTargetMarketSizeOptions();
        ctrl.getSoftwareFocus();
        ctrl.getSoftwareFocusOptions();
        ctrl.getOperatingSystemSupportedOptions();
        ctrl.getOperatingSystemSupported();
        ctrl.getApplicationTypes();
        ctrl.getApplicationTypesOptions();
        ctrl.getAdditionalPartnerships();
        ctrl.getAdditionalPartnershipsOptions();
        ctrl.getMiddlewareSupported();
        ctrl.getMiddlewareSupportedOptions();
        boolean embed = ctrl.isEmbeddedPartner;
        boolean agree = ctrl.IsAgreedToTerms;
        boolean isCCP = ctrl.IsCCP;
        ctrl.getSelectableStateOptions();


        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Timelord');
        pmap.put('rhn-company-name', 'Gallifrey');
        pmap.put('rhn-email', 'thedoctor@gallifrey.net');
        pmap.put('rhn-salutation', 'Dr');
        pmap.put('rhn-first-name', 'John');
        pmap.put('rhn-last-name', 'Smith');
        pmap.put('program', 'Embedded');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'Embedded';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Time & Space';
        ctrl.theLead.City__c = 'Raleigh';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLeadCountry = 'US';
        ctrl.selectedState = 'NC';
        ctrl.theLead.Postal_Code__c = '27610';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.setPublicSectorMarket(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'You break it, we have already fixed it';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'No';
        PageReference page = ctrl.submitApplication();

        Partner_Onboarding_Registration__c mylead = [select Email__c, SubRegion__c from Partner_Onboarding_Registration__c where Id = :ctrl.theLead.Id];
        System.debug('*****[debug]***** >> subregion__c = ' + mylead.SubRegion__c);
        System.assert(mylead.Email__c != null, 'Email is null');

        PartnerAgreement__c[] agreements = [select Id from PartnerAgreement__c where Partner_Onboarding__c = :ctrl.getLead().Id];
        System.assert(agreements.size() == 0, 'Expected no agreements for Embedded, found ' + agreements.size());


        //PARF_Form__c form = [select Id, Admin_Contact_Email__c from PARF_Form__c where Partner_Onboarding_Record__c = :ctrl.theLead.Id];
        //System.assert(form.Admin_Contact_Email__c == ctrl.theLead.Email__c, 'Email mismatch on Embedded Form');
        //System.assert(form.Status__c == 'User Notified', 'CCSP Form status expected to be "User Notified", found "' + form.Status__c + '"');
        ref = ctrl.init();

     }

     static testMethod void embeddedTermsPendingMessageTest() {
        User owner = PartnerTestUtils.getAdminUser();
        Account a = PartnerTestUtils.makeAccount('testAccName', owner);
        Contact c = PartnerTestUtils.makeContact(a.id, 'embedFederationId');
        insert c;

        Partner_Program__c ip = PartnerTestUtils.makeProgram(a.id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert ip;
        Partner_Program__c ep = PartnerTestUtils.makeProgram(a.id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED, false);
        insert ep;

        User u = PartnerTestUtils.makePartnerUser(a, c);
        insert u;

        OnboardingApplyController ctrl = new OnboardingApplyController();

        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'embedFederationId');
        pmap.put('rhn-company-name', 'testAccName');
        pmap.put('rhn-email', 'thedoctor@gallifrey.net');
        pmap.put('rhn-salutation', 'Dr');
        pmap.put('rhn-first-name', 'John');
        pmap.put('rhn-last-name', 'Smith');
        PageReference ref = ctrl.init();
        ref = ctrl.convertContactSubmit();
        ref = ctrl.convertContactCancel();

     }
}