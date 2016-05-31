/****************************************************************************************
 Name: CCSPFormController
 Desc: Controller for the anti-corruption questions CC&SP checklist sent to the
       prospective CC&SP partner, prior to the approval process.

 Modification Log
-----------------------------------------------------------------------------------------
 Developer              Date            Description
-----------------------------------------------------------------------------------------
 Jonathan Garrison      08-Apr-2015     Created
 Jonathan Garrison      06-May-2015     Modified for Distributor Partner use.
 Jonathan Garrison      18-May-2015     Updated CSSP Form page reference to distiguish
                                        between an internal and external version for
                                        styling differences.
 Jonathan Garrison      03-Jun-2015     Autopopulating contact email, name, phone from
                                        onboarding record.
 Jonathan Garrison      03-Jun-2015     Established variables for program and technical
                                        guide links for the checklist page.
 Jonathan Garrison      11-Jun-2015     Added new field for internal users:
                                        Custom_Terms_Required__c.
 Jonathan Garrison      16-Jun-2015     Added support for partners to self-apply for
                                        CCSP.
 Jonathan Garrison      29-Jun-2015     Added support to allow distributors to refer
                                        existing partners to CCSP.
 Jonathan Garrison      07-Jul-2015     Added support for transferring preferred language
                                        from onboarding record to ccsp form.
 Jonathan Garrison      09-Jul-2015     Added two new questions to CCSP form, per story
                                        US70334.
 Jonathan Garrison      14-Jul-2015     Added two separate messages for partners who
                                        try to fill out the CCSP form unnecessarily:
                                        one indicating that the application is in
                                        progress and another indicating that they are
                                        already enrolled.
 Jonathan Garrison      16-Jul-2015     Altered the Custom Terms Required question to
                                        only be required by internal editors AFTER the
                                        prospective CCSP member has returned the form to
                                        Red Hat.
****************************************************************************************/
public without sharing class CCSPFormController {

    // Anticorruption Items
    public String governmentPosition                        {get; set;}
    public String convicted                                 {get; set;}
    public String underlyingFacts                           {get; set;}
    ///////////////////////

    public String distributorDirected                       {get; set;}
    public String distributorName                           {get; set;}
    public String requirementsExceptions                    {get; set;}
    public String managedOSServices                         {get; set;}
    public String dedicatedPhysicalServersBareMetal         {get; set;}
    public String dedicatedPhysicalServersVirtualization    {get; set;}
    public String howWillYouSetUpYourService                {get; set;}
    public String multiTenantVirtualInstances               {get; set;}
    public String planToOfferJBoss                          {get; set;}
    public String contactName                               {get; set;}
    public String contactEmail                              {get; set;}
    public String contactPhone                              {get; set;}
    public String contactPreferredLanguage                  {get; set;}
    public String style                                     {get; private set;}

    public String[] authorizationCountries                  {get; set;}

    public boolean revenueUnitMatching                      {get; set;}
    public boolean monthlyReportingRequirement              {get; set;}
    public boolean systemForReporting                       {get; set;}
    public boolean requirementToImplementAndUpdate          {get; set;}
    public boolean isGuestUser                              {get; private set;} // Prospective, not yet onboarded partner.
    public boolean isDistributor                            {get; private set;} // Distributor referring a new/existing partner to CCSP.
    public boolean isRedHatUser                             {get; private set;} // Red Hat user referring a new/existing partner to CCSP.
    public boolean isPartner                                {get; private set;} // Existing partner being referred to or enrolling in CCSP.
    public boolean formReturned                             {get; private set;}
    public boolean formSent                                 {get; private set;}
    public boolean alreadyEnrolled                          {get; private set;}
    public boolean inProgress                               {get; private set;}
    public boolean governmentPositionAnswered               {get; private set;}
    public boolean convictedAnswered                        {get; private set;}
    public boolean underlyingFactsProvided                  {get; private set;}

    public List<SelectOption> selectableCountries           {get; private set;}

    public CCSP_Form__c ccspForm                            {get; set;}

    private List<Country__c> countries;
    private Partner_Onboarding_Registration__c partnerOnboardingRegistration = null;
    private boolean newlyCreated = false;
    private boolean submitted = false;
    private boolean isSelfEnrolling = false;
    private String retURL;
    private String federationId;
    private String token;
    private String pageName = 'CCSPForm';
    private Id ccspId;
    private Id onboardingRegistrationId;
    private Id partnerAccountId;
    private Id enrollProgramId;
    private Id placeholderOnboardingRecordTypeId;
    private Id standardOnboardingRecordTypeId;
    private Account partnerAccount = null;

    private static final String CUSTOM_TERMS_ERROR = 'You must specify if custom terms are required.';

    public CCSPFormController(ApexPages.StandardController stdController) {
        ccspId = stdController.getId();
    }

    public static final Map<String, List<Schema.PicklistEntry>> PICKLIST_ENTRIES = new Map<String, List<Schema.PicklistEntry>> {
        'Products__c' => CCSP_Form__c.Products__c.getDescribe().getPicklistValues(),
        'Certified_Hypervisor__c' => CCSP_Form__c.Certified_Hypervisor__c.getDescribe().getPicklistValues(),
        'Cloud_Services__c' => CCSP_Form__c.Cloud_Services__c.getDescribe().getPicklistValues(),
        'Relationships__c' => CCSP_Form__c.Relationships__c.getDescribe().getPicklistValues()
    };

    public List<SelectOption> getRedHatProductsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Products__c'));
    }

    public List<String> getRedHatProducts() {
        return getSplitPicklistField(ccspForm.Products__c);
    }

    public void setRedHatProducts(List<String> valuesList) {
        setSelectOptionsValuesToField('Products__c', valuesList);
    }

    public List<SelectOption> getCertifiedHypervisorsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Certified_Hypervisor__c'));
    }

    public List<String> getCertifiedHypervisors() {
        return getSplitPicklistField(ccspForm.Certified_Hypervisor__c);
    }

    public void setCertifiedHypervisors(List<String> valuesList) {
        setSelectOptionsValuesToField('Certified_Hypervisor__c', valuesList);
    }

    public List<SelectOption> getCloudServicesOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Cloud_Services__c'));
    }

    public List<String> getCloudServices() {
        return getSplitPicklistField(ccspForm.Cloud_Services__c);
    }

    public void setCloudServices(List<String> valuesList) {
        setSelectOptionsValuesToField('Cloud_Services__c', valuesList);
    }

    public List<SelectOption> getRelationshipsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Relationships__c'));
    }

    public List<String> getRelationships() {
        return getSplitPicklistField(ccspForm.Relationships__c);
    }

    public void setRelationships(List<String> valuesList) {
        setSelectOptionsValuesToField('Relationships__c', valuesList);
    }

    public CCSPFormController() {
    }

    public void init() {

        placeholderOnboardingRecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Partner_Onboarding_Registration__c'
            and     DeveloperName = 'Placeholder'
        ].Id;

        standardOnboardingRecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Partner_Onboarding_Registration__c'
            and     DeveloperName = 'Business_Partner_Registration'
        ].Id;

        onboardingRegistrationId = (Id)ApexPages.currentPage().getParameters().get('onboardingId');
        federationId = ApexPages.currentPage().getParameters().get('federationId');
        token = ApexPages.currentPage().getParameters().get('token');
        partnerAccountId = (Id)ApexPages.currentPage().getParameters().get('accountId');
        enrollProgramId = (Id)ApexPages.currentPage().getParameters().get('enrollProgramId');
        retURL = ApexPages.currentPage().getParameters().get('retURL');

        User me = [
            select  Id,
                    Contact.AccountId,
                    Name,
                    Email,
                    Phone,
                    Profile.Name
            from    User
            where   Id = :UserInfo.getUserId()
            limit   1
        ];

        // Determine what kind of user is interacting with the CCSP form.
        isDistributor = false;
        isPartner = false;
        isGuestUser = false;

        // If an onboarding registration was passed in,
        // must be a Red Hat user or a referring distributor.
        if (!String.isEmpty(onboardingRegistrationId) && me.Contact.AccountId != null) {
            // If an account is present, must be a distributor.
            isDistributor = true;
        }

        // If we know we need to enroll instead of onboard,
        // must be an existing partner.
        if (!String.isEmpty(enrollProgramId)) {
            isPartner = true;
            isGuestUser = true; // Needed for consistency in formatting the CCSP page.
        }
        if (!String.isEmpty(federationId)) {
            isGuestUser = true;
        }
        if (String.isEmpty(federationId) && !String.isEmpty(enrollProgramId)) {
            isSelfEnrolling = true;
        }

        // If nothing else, must be a Red Hat user.
        isRedHatUser = (!isDistributor && !isPartner && !isGuestUser);

        if (!String.isEmpty(partnerAccountId)) {
            partnerAccount = [
                select  Id,
                        Finder_Partner_Type__c,
                        Partner_Onboarding_Application__c
                from    Account
                where   Id = :partnerAccountId
                limit   1
            ];
            if (!String.isEmpty(partnerAccount.Partner_Onboarding_Application__c) && !isSelfEnrolling) {
                onboardingRegistrationId = partnerAccount.Partner_Onboarding_Application__c;
            }
        }

        style = (isGuestUser ? 'display:inline' : 'display:none');

        if (!isGuestUser) {
            pageName = 'CCSPForm_Internal';
        }

        if (!String.isEmpty(ccspId)) {
            CCSP_Form__c tempCCSPForm = [
                select  Id,
                        CCSPOnboardingRegistration__c
                from    CCSP_Form__c
                where   Id = :ccspId
                limit   1
            ];
            onboardingRegistrationId = tempCCSPForm.CCSPOnboardingRegistration__c;
        }

        // If coming in from the public site, use the token to get the
        // onboarding registration record.
        if (!String.isEmpty(token)) {
            PartnerUser_Email_Token__c emailToken = [
                select  Id,
                        Date_Confirmed__c,
                        Is_Active__c,
                        Partner_Onboarding__c,
                        Token__c
                from    PartnerUser_Email_Token__c
                where   Token__c = :token
                and     Is_Active__c = true
                limit   1
            ];
            onboardingRegistrationId = emailToken.Partner_Onboarding__c;
            if (emailToken.Date_Confirmed__c == null) {
                emailToken.Date_Confirmed__c = Datetime.now();
                update emailToken;
            }
        }

        if (!String.isEmpty(onboardingRegistrationId) && !isSelfEnrolling) {
            partnerOnboardingRegistration = [
                select  Id,
                        Do_they_act_in_any_government_position__c,
                        FCPA_Underlying_Facts__c,
                        Have_they_been_convicted__c,
                        Onboarding_Language_Preference__c,
                        FirstName__c,
                        LastName__c,
                        Email__c,
                        Phone__c
                from    Partner_Onboarding_Registration__c
                where   Id = :onboardingRegistrationId
            ];
        }

        if (partnerOnboardingRegistration != null && !isPartner && !isSelfEnrolling) {
            governmentPositionAnswered = !String.isEmpty(partnerOnboardingRegistration.Do_they_act_in_any_government_position__c);
            convictedAnswered = !String.isEmpty(partnerOnboardingRegistration.Have_they_been_convicted__c);
            underlyingFactsProvided = !String.isEmpty(partnerOnboardingRegistration.FCPA_Underlying_Facts__c);
        }

        if (isPartner) {
            governmentPositionAnswered = true;
            convictedAnswered = true;
        }

        if (!String.isEmpty(federationId) && !isPartner && !isSelfEnrolling) {
            partnerOnboardingRegistration.RHNLogin__c = federationId;
            update partnerOnboardingRegistration;
        }

        List<CCSP_Form__c> ccspForms = new List<CCSP_Form__c>();

        if (!String.isEmpty(partnerAccountId)) {
            //ccspForms = [
            //    select  Authorization_Countries__c,
            //            Account__c,
            //            CCSPOnboardingRegistration__c,
            //            Certified_Hypervisor__c,
            //            Cloud_Services__c,
            //            Contact_Email__c,
            //            Contact_Name__c,
            //            Contact_Phone__c,
            //            Contact_Preferred_Language__c,
            //            Convicted__c,
            //            Custom_Terms_Required__c,
            //            Dedicated_Servers_Metal__c,
            //            Dedicated_Servers_Virt__c,
            //            Distributor_Directed__c,
            //            Distributor_Name__c,
            //            Form_Returned__c,
            //            Form_Sent__c,
            //            Government_Position__c,
            //            Id,
            //            Implement_And_Update__c,
            //            Managed_OS_Services__c,
            //            Monthly_Reporting_Requirement__c,
            //            Multi_Tenant__c,
            //            Products__c,
            //            Relationships__c,
            //            Requirements_Exceptions__c,
            //            Revenue_Unit_Matching__c,
            //            System_For_Reporting__c,
            //            Underlying_Facts__c
            //    from    CCSP_Form__c
            //    where   Account__c = :partnerAccountId
            //    limit   1
            //];
        } else if (!String.isEmpty(ccspId)) {
            ccspForms = [
                select  Authorization_Countries__c,
                        Account__c,
                        CCSPOnboardingRegistration__c,
                        Certified_Hypervisor__c,
                        Cloud_Services__c,
                        Contact_Email__c,
                        Contact_Name__c,
                        Contact_Phone__c,
                        Contact_Preferred_Language__c,
                        Convicted__c,
                        Custom_Terms_Required__c,
                        Dedicated_Servers_Metal__c,
                        Dedicated_Servers_Virt__c,
                        Distributor_Directed__c,
                        Distributor_Name__c,
                        Form_Returned__c,
                        Form_Sent__c,
                        Government_Position__c,
                        How_will_you_set_up_your_service__c,
                        Id,
                        Implement_And_Update__c,
                        Managed_OS_Services__c,
                        Monthly_Reporting_Requirement__c,
                        Multi_Tenant__c,
                        Plan_to_Offer_JBoss__c,
                        Products__c,
                        Relationships__c,
                        Requirements_Exceptions__c,
                        Revenue_Unit_Matching__c,
                        System_For_Reporting__c,
                        Underlying_Facts__c
                from    CCSP_Form__c
                where   Id = :ccspId
                limit   1
            ];
        } else {
            ccspForms = [
                select  Authorization_Countries__c,
                        Account__c,
                        CCSPOnboardingRegistration__c,
                        Certified_Hypervisor__c,
                        Cloud_Services__c,
                        Contact_Email__c,
                        Contact_Name__c,
                        Contact_Phone__c,
                        Contact_Preferred_Language__c,
                        Convicted__c,
                        Custom_Terms_Required__c,
                        Dedicated_Servers_Metal__c,
                        Dedicated_Servers_Virt__c,
                        Distributor_Directed__c,
                        Distributor_Name__c,
                        Form_Returned__c,
                        Form_Sent__c,
                        Government_Position__c,
                        How_will_you_set_up_your_service__c,
                        Id,
                        Implement_And_Update__c,
                        Managed_OS_Services__c,
                        Monthly_Reporting_Requirement__c,
                        Multi_Tenant__c,
                        Plan_to_Offer_JBoss__c,
                        Products__c,
                        Relationships__c,
                        Requirements_Exceptions__c,
                        Revenue_Unit_Matching__c,
                        System_For_Reporting__c,
                        Underlying_Facts__c
                from    CCSP_Form__c
                where   CCSPOnboardingRegistration__c = :onboardingRegistrationId
                limit   1
            ];
        }

        // Prior to this point, partnerAccountId will only have a value if it was passed in via the URL (self-enroll).
        if (isPartner && !isDistributor && !isSelfEnrolling) { // Referral of an existing partner.

            User referredUser = [
                select  Id,
                        Federation_ID__c,
                        ContactId,
                        Contact.Account.Id,
                        LanguageLocaleKey
                from    User
                where   Federation_ID__c = :federationId
            ];

            partnerAccountId = referredUser.Contact.Account.Id;

            partnerAccount = [
                select  Id,
                        Finder_Partner_Type__c,
                        Partner_Onboarding_Application__c
                from    Account
                where   Id = :partnerAccountId
                limit   1
            ];
        }

        selectableCountries = new List<SelectOption>();

        countries = [
            select      Name
            from        Country__c
            order by    Name asc
        ];

        for (Country__c country : countries) {
            selectableCountries.add(new SelectOption(country.Name, country.Name.toUpperCase()));
        }

        clearFields();

        if (ccspForms != null && ccspForms.size() > 0) {
            ccspForm = ccspForms[0];
            loadFormData();
        } else {
            ccspForm = new CCSP_Form__c();
            newlyCreated = true;
            if (isDistributor) {
                Id contactId = [
                    select  ContactId
                    from    User
                    where   Id = :Userinfo.getUserId()
                    limit   1
                ].ContactId;

                Id referringAccountId = [
                    select  AccountId
                    from    Contact
                    where   Id = :ContactId
                    limit   1
                ].AccountId;

                Account account = [
                    select  Id,
                            Name
                    from    Account
                    where   Id = :referringAccountId
                    limit   1
                ];

                distributorDirected = System.Label.yes;
                distributorName = account.Name;
            }
            if (!isSelfEnrolling && !isPartner) {
                ccspForm.CCSPOnboardingRegistration__c = onboardingRegistrationId;
            }
            formSent = false;
            formReturned = false;
        }

        if (partnerOnboardingRegistration != null && !isSelfEnrolling) {
            governmentPosition = partnerOnboardingRegistration.Do_they_act_in_any_government_position__c;
            convicted = partnerOnboardingRegistration.Have_they_been_convicted__c;
            underlyingFacts = partnerOnboardingRegistration.FCPA_Underlying_Facts__c;
            contactName = partnerOnboardingRegistration.FirstName__c + ' ' + partnerOnboardingRegistration.LastName__c;
            contactEmail = partnerOnboardingRegistration.Email__c;
            contactPhone = partnerOnboardingRegistration.Phone__c;
            contactPreferredLanguage = partnerOnboardingRegistration.Onboarding_Language_Preference__c;
        }

        if (isSelfEnrolling) {
            contactName = me.Name;
            contactEmail = me.Email;
            contactPhone = me.Phone;
        }

        List<Partner_Program__c> ccspEnrolledProgramMemberships = [
            select  Id
            from    Partner_Program__c
            where   Account__c = :partnerAccountId
            and     Program__c = :enrollProgramId
            and     Status__c in ('Active')
        ];

        List<Partner_Program__c> ccspInProgressProgramMemberships = [
            select  Id
            from    Partner_Program__c
            where   Account__c = :partnerAccountId
            and     Program__c = :enrollProgramId
            and     Status__c in ('Approved', 'Pending', 'Pending Terms', 'Pending First Approver')
        ];

        alreadyEnrolled = (ccspEnrolledProgramMemberships.size() > 0);
        inProgress = (ccspInProgressProgramMemberships.size() > 0) && !alreadyEnrolled;

        presentFormSentOrReturnedMessage();
    }

    public PageReference submit() {

        boolean errors = false;

        if (isGuestUser) {
            if (!isPartner &&
                (String.isEmpty(governmentPosition) ||
                String.isEmpty(convicted) ||
                (String.isEmpty(underlyingFacts) &&
                    underlyingFactsRequired))) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Anti_Corruption_Items));
                errors = true;
            }

            if (String.isEmpty(distributorDirected)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Specify_Distributor_Direction));
                errors = true;
            }

            if ((!String.isEmpty(distributorDirected) && distributorDirected.equalsIgnoreCase(System.Label.yes)) && String.isEmpty(distributorName)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Distributor_Name));
                errors = true;
            }

            if (String.isEmpty(planToOfferJBoss)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Plan_to_Offer_JBoss));
                errors = true;
            }

            if (String.isEmpty(howWillYouSetUpYourService)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_How_Will_You_Set_Up_Service));
                errors = true;
            }

            if (authorizationCountries == null || authorizationCountries.size() < 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Countries));
                errors = true;
            }

            if (getRedHatProducts() == null || getRedHatProducts().size() < 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Specify_Products));
                errors = true;
            }

            if (!revenueUnitMatching) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Revenue_Unit_Matching));
                errors = true;
            }

            if (!systemForReporting) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_System_For_Reporting));
                errors = true;
            }

            if (!monthlyReportingRequirement) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Monthly_Reporting));
                errors = true;
            }

            if (!requirementToImplementAndUpdate) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Implement_And_Update));
                errors = true;
            }

            if (getCertifiedHypervisors() == null || getCertifiedHypervisors().size() < 1)  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Certified_Hypervisors));
                errors = true;
            }

            if (getCertifiedHypervisors() != null && getCertifiedHypervisors().size() > 1) {
                for (String hypervisor : getCertifiedHypervisors()) {
                    if (hypervisor.equalsIgnoreCase('--none--')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_None_Along_With_Other_Hypervisor));
                        errors = true;
                    }
                }
            }

            if (String.isEmpty(managedOSServices)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Managed_OS_Services));
                errors = true;
            }

            if (String.isEmpty(dedicatedPhysicalServersVirtualization)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Dedicated_Servers_Virt));
                errors = true;
            }

            if (String.isEmpty(dedicatedPhysicalServersBareMetal)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Dedicated_Servers_Metal));
                errors = true;
            }

            if (getCloudServices() == null || getCloudServices().size() < 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Clouds_Services_Offered));
                errors = true;
            }

            if (getRelationships() == null || getRelationships().size() < 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Other_Relationships));
                errors = true;
            }

            if (getRelationships() != null && getRelationships().size() > 1) {
                for (String relationship : getRelationships()) {
                    if (relationship.equalsIgnoreCase('--none--')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_None_Along_With_Other));
                        errors = true;
                    }
                }
            }

            if (String.isEmpty(contactPhone)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Phone));
                errors = true;
            }
        }

        if (isRedHatUser && ccspForm.Form_Returned__c) {
            if (ccspForm.Custom_Terms_Required__c == null || String.isEmpty(ccspForm.Custom_Terms_Required__c) || ccspForm.Custom_Terms_Required__c.equalsIgnoreCase('--None--'))  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CUSTOM_TERMS_ERROR));
                errors = true;
            }
        }

        if (String.isEmpty(contactName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Contact_Name));
            errors = true;
        }

        if (String.isEmpty(contactEmail) || !validEmail(contactEmail)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSPForm_Error_Email));
            errors = true;
        }

        if (errors) {
            return null;
        }

        submitted = true;

        return saveForm();
    }

    public PageReference ok() {
        if (!String.isEmpty(retURL)) {
            return new PageReference(retURL);
        }
        return currentPage();
    }

    private PageReference currentPage() {
        String url = '/apex/' + pageName;
        if (!String.isEmpty(partnerAccountId)) {
            url += '?accountId=' + partnerAccountId;
            return new PageReference(url);
        }
        if (!String.isEmpty(federationId) && !String.isEmpty(token)) {
            url += '?federationId=' + federationId;
            url += '&token=' + token;
            return new PageReference(url);
        }
        if (!String.isEmpty(onboardingRegistrationId)) {
            url += '?onboardingId=' + onboardingRegistrationId;
            return new PageReference(url);
        }

        return new PageReference(url);
    }

    public PageReference saveForm() {

        saveCCSPForm();

        if (isRedHatUser && ccspForm.Form_Returned__c) {
            if (ccspForm.Custom_Terms_Required__c == null || String.isEmpty(ccspForm.Custom_Terms_Required__c) || ccspForm.Custom_Terms_Required__c.equalsIgnoreCase('--None--'))  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CUSTOM_TERMS_ERROR));
                return currentPage();
            }
        }

        if (isPartner && !isDistributor) {
            if (submitted) {
                if (!isSelfEnrolling && (partnerOnboardingRegistration.RecordTypeId == placeholderOnboardingRecordTypeId)) {
                    ccspForm.CCSPOnboardingRegistration__c = null;
                    update ccspForm;
                    delete partnerOnboardingRegistration;
                }
                if (!alreadyEnrolled && !inProgress) {
                    PartnerPgmDashController ppdController = new PartnerPgmDashController();
                    ppdController.init(federationId);
                    return ppdController.enrollCCSP(enrollProgramId, ccspForm.Id);
                }
            }

            return Page.PartnerPrograms;
        }

        return ok();
    }

    private void loadFormData() {

        authorizationCountries                  = (ccspForm.Authorization_Countries__c == null ? null : ccspForm.Authorization_Countries__c.split(';'));
        contactEmail                            = ccspForm.Contact_Email__c;
        contactName                             = ccspForm.Contact_Name__c;
        contactPhone                            = ccspForm.Contact_Phone__c;
        contactPreferredLanguage                = ccspForm.Contact_Preferred_Language__c;
        convicted                               = ccspForm.Convicted__c;
        dedicatedPhysicalServersBareMetal       = ccspForm.Dedicated_Servers_Metal__c;
        dedicatedPhysicalServersVirtualization  = ccspForm.Dedicated_Servers_Virt__c;
        distributorDirected                     = ccspForm.Distributor_Directed__c;
        distributorName                         = ccspForm.Distributor_Name__c;
        formReturned                            = ccspForm.Form_Returned__c;
        formSent                                = ccspForm.Form_Sent__c;
        governmentPosition                      = ccspForm.Government_Position__c;
        howWillYouSetUpYourService              = ccspForm.How_will_you_set_up_your_service__c;
        managedOSServices                       = ccspForm.Managed_OS_Services__c;
        monthlyReportingRequirement             = ccspForm.Monthly_Reporting_Requirement__c;
        multiTenantVirtualInstances             = ccspForm.Multi_Tenant__c;
        planToOfferJBoss                        = ccspForm.Plan_to_Offer_JBoss__c;
        requirementsExceptions                  = ccspForm.Requirements_Exceptions__c;
        requirementToImplementAndUpdate         = ccspForm.Implement_And_Update__c;
        revenueUnitMatching                     = ccspForm.Revenue_Unit_Matching__c;
        systemForReporting                      = ccspForm.System_For_Reporting__c;
        underlyingFacts                         = ccspForm.Underlying_Facts__c;

        if (isGuestUser) {
            formSent = true;
            ccspForm.Form_Sent__c = true;
            update ccspForm;
        }
    }

    public boolean underlyingFactsRequired {
        get {
            return (!isPartner &&
                    (!String.isEmpty(governmentPosition) &&
                    !String.isEmpty(convicted) &&
                    (governmentPosition.equalsIgnoreCase(System.Label.yes) ||
                        convicted.equalsIgnoreCase(System.Label.yes))));
        }
    }

    public boolean distributorNameRequired {
        get {
            return !String.isEmpty(distributorDirected) && distributorDirected.equalsIgnoreCase(System.Label.yes);
        }
    }

    public static boolean validEmail(String email) {
        Boolean result = true;
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern pat = Pattern.compile(emailRegex);
        Matcher mat = pat.matcher(email);
        if (!mat.matches()) {
            result = false;
        }
        return result;
    }

    public void setSelectOptionsValuesToField(String fieldName, List<String> valuesList) {
        String field = '';

        for(String value : valuesList) {
            if (field != '') {
                field += ';';
            }
            field += value;
        }

        ccspForm.put(fieldName, field);
    }

    public List<String> getSplitPicklistField(String values) {
        return values == null ? new List<String>() : values.split(';');
    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList) {
            selectOptionList.add(new SelectOption(p.Value, p.Label));
        }

        return selectOptionList;
    }

    private void saveCCSPForm() {

        if (distributorDirected != null && distributorDirected.equalsIgnoreCase(System.Label.No)) {
            distributorName = '';
        }

        String allSelectedCountries = '';

        if (authorizationCountries != null && authorizationCountries.size() > 0) {
            for (String selectedCountry : authorizationCountries) {
                allSelectedCountries += selectedCountry + ';';
            }
        }

        ccspForm.Authorization_Countries__c             = allSelectedCountries;
        ccspForm.Contact_Email__c                       = contactEmail;
        ccspForm.Contact_Name__c                        = contactName;
        ccspForm.Contact_Phone__c                       = contactPhone;
        ccspForm.Contact_Preferred_Language__c          = contactPreferredLanguage;
        ccspForm.Convicted__c                           = convicted;
        ccspForm.Dedicated_Servers_Metal__c             = dedicatedPhysicalServersBareMetal;
        ccspForm.Dedicated_Servers_Virt__c              = dedicatedPhysicalServersVirtualization;
        ccspForm.Distributor_Directed__c                = distributorDirected;
        ccspForm.Distributor_Name__c                    = distributorName;
        ccspForm.Government_Position__c                 = governmentPosition;
        ccspForm.How_will_you_set_up_your_service__c    = howWillYouSetUpYourService;
        ccspForm.Implement_And_Update__c                = requirementToImplementAndUpdate;
        ccspForm.Managed_OS_Services__c                 = managedOSServices;
        ccspForm.Monthly_Reporting_Requirement__c       = monthlyReportingRequirement;
        ccspForm.Multi_Tenant__c                        = multiTenantVirtualInstances;
        ccspForm.Plan_to_Offer_JBoss__c                 = planToOfferJBoss;
        ccspForm.Requirements_Exceptions__c             = requirementsExceptions;
        ccspForm.Revenue_Unit_Matching__c               = revenueUnitMatching;
        ccspForm.System_For_Reporting__c                = systemForReporting;
        ccspForm.Underlying_Facts__c                    = underlyingFacts;

        if (partnerAccount != null) {
            ccspForm.Account__c = partnerAccountId;
        }

        if (newlyCreated) {
            insert ccspForm;
            newlyCreated = false;
        } else {
            update ccspForm;
        }

        if (isGuestUser && !isPartner && !isSelfEnrolling) {
            if (!governmentPositionAnswered) {
                partnerOnboardingRegistration.Do_they_act_in_any_government_position__c = ccspForm.Government_Position__c;
            }

            if (!convictedAnswered) {
                partnerOnboardingRegistration.Have_they_been_convicted__c = ccspForm.Convicted__c;
            }

            if (!underlyingFactsProvided) {
                partnerOnboardingRegistration.FCPA_Underlying_Facts__c = ccspForm.Underlying_Facts__c;
            }
            update partnerOnboardingRegistration;
        }

        if (submitted) {
            if (!isGuestUser) {
                formSent = true;
                ccspForm.Form_Sent__c = formSent;
                ccspForm.Status__c = 'Pending';
            } else {
                if (isPartner) {
                    formSent = true;
                    ccspForm.Form_Sent__c = formSent;
                }
                formReturned = true;
                ccspForm.Form_Returned__c = formReturned;
                ccspForm.Status__c = 'Complete';

                // Create the proper onboarding registration object.
                if (!isPartner && isGuestUser && !isSelfEnrolling) {
                    partnerOnboardingRegistration.RecordTypeId = standardOnboardingRecordTypeId;
                    update partnerOnboardingRegistration;
                }
            }

            update ccspForm;
        }

        presentFormSentOrReturnedMessage();
    }

    public PageReference cancel() {
        if (isPartner) {
            return new PageReference('/apex/PartnerPrograms');
        }

        return ok();
    }

    private void clearFields() {
        authorizationCountries                  = null;
        contactEmail                            = '';
        contactName                             = '';
        contactPhone                            = '';
        convicted                               = '';
        dedicatedPhysicalServersBareMetal       = '';
        dedicatedPhysicalServersVirtualization  = '';
        distributorDirected                     = '';
        distributorName                         = '';
        governmentPosition                      = '';
        howWillYouSetUpYourService              = '';
        managedOSServices                       = '';
        multiTenantVirtualInstances             = '';
        planToOfferJBoss                        = '';
        requirementsExceptions                  = '';
        underlyingFacts                         = '';
        monthlyReportingRequirement             = false;
        requirementToImplementAndUpdate         = false;
        revenueUnitMatching                     = false;
        systemForReporting                      = false;
    }

    private void presentFormSentOrReturnedMessage() {
        if (!isGuestUser && formSent && !formReturned) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.CCSPForm_Info_Sent_to_Partner));
        }

        if (!isGuestUser && formReturned) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.CCSPForm_Info_Completed_and_Submitted));
        }

        //if (isGuestUser && formReturned) {
        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.CCSPForm_Info_Submitted_to_Red_Hat));
        //}
    }

    public String programGuide {
        get {
            return System.Label.CCSPForm_Program_Guide_Link;
        }
    }

    public String technicalGuide {
        get {
            return System.Label.CCSPForm_Technical_Guide_Link;
        }
    }

    public String pageTitle {
        get {
            return (formReturned ? System.Label.CCSPForm_Title_ThankYou : System.Label.CCSPForm_Title);
        }
    }
}