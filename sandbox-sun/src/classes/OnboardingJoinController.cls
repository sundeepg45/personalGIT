public without sharing class OnboardingJoinController {

    public Partner_Onboarding_Registration__c   theLead {get; private set; }
    public List<Country__c> selectableCountryList;
    public String theLeadCountry {get; set; }
    public String languageCode {get; set; }
    public String language;
    public String leadCountry {get; set; }
    public String VATNumber {get; set; }
    public String selectedPartnerStatus {get; set; }
    public String messageType { get; set; }
    public Boolean caseSubmitted {get; set; }

    public Boolean HasOnboardingCase {get;set;}
    public Boolean HasInactiveUserError {get; private set;}
    public Boolean HasNoUserError {get; private set;}
    public Boolean HasUserExistsError {get; private set;}
    public Boolean HasPendingRequestError {get; private set;}
    public Boolean hasExistingInvite {get; private set; }

    public String FederationId {get; set;}


    public Case OnboardingCase{get;set;}
    public String OnboardingCaseEmail{get;set;}

    public String     partnerInviteId {get; set; }
    private String logTag = '[OnboardingJoinController]';
    public static final String HKEY_TIER_READY = 'PARTNER_TIER.READY';
    public static final String HKEY_TIER_AFFILIATED = 'PARTNER_TIER.AFFILIATED';
    public static final String EMBEDDED = 'Embedded';


    public OnboardingJoinController() {
        thelead = new Partner_Onboarding_Registration__c();
        HasOnboardingCase = false;
        String program = getParam('program');
        if (program != null) {
            partnerType = program;
        }
    }

    public PageReference init() {
        //
        // Load the countries and states
        //

        selectableCountryList = [
            select Name, Abbreviation__c, Global_Region__c, Country_Name__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c, Supported_Specialized_Partner_Types__c, SearchByVAT__c
         , (select Name, Abbreviation__c from States__r order by Name asc)
              from Country__c order by Name asc
        ];

        theLead.Company__c = getParam(OnboardingApplyController.PARAM_COMPANY);
        if (theLead.Company__c == null || theLead.Company__c.equals('')){
            theLead.Company__c = getParam(OnboardingApplyController.PARAM_PARTNER_NAME) != null ? getParam(OnboardingApplyController.PARAM_PARTNER_NAME) : '';
        }

        // Make sure the current request has a federation-id parameter
        // If not, send them to the rh.com login page
        FederationId = getParam(OnboardingApplyController.PARAM_FEDERATION_ID);
        if (FederationId == null) {
            return Page.PartnerAccess;
        }

        String customerType = getParam(OnboardingApplyController.PARAM_CUSTOMER_TYPE);
        if (customerType != null && (customerType == 'P' || customerType == 'p')) {
            return Page.OnboardingJoinPersonal;
        }
        else {
            if (customerType == null) {
                // not provided
                if (theLead.Company__c.length() == 0) {
                    return Page.OnboardingJoinPersonal;
                }
            }
        }

        languageCode = getParam(OnboardingApplyController.PARAM_LANGUAGE);
        if (languageCode == null) {
            languageCode = 'en';
        }
        language = OnboardingApplyController.getLocalePicklistName(languageCode, null);

        //
        // Copy the RHN information to the lead
        //

        theLead.FirstName__c = getParam(OnboardingApplyController.PARAM_FIRST_NAME);
        theLead.LastName__c = getParam(OnboardingApplyController.PARAM_LAST_NAME);
        theLead.Email__c = getParam(OnboardingApplyController.PARAM_EMAIL);
        theLead.Salutation__c = getParam(OnboardingApplyController.PARAM_SALUTATION);
        theLead.Company__c = getParam(OnboardingApplyController.PARAM_COMPANY);
        theLead.RHNLogin__c = FederationId;
        theLead.Onboarding_Language_Preference__c = LanguageCode;

        System.debug('Email: ' + theLead.Email__c);

        PartnerTierReady = [
            select  Name,
                    HierarchyKey__c
            from    Classification__c
            where   HierarchyKey__c = :HKEY_TIER_READY
            limit   1
        ];
        System.debug('*****[debug]***** PartnerTierReady.Id=' + PartnerTierReady.Id);

        PartnerTierAffiliated = [
            select  Name,
                    HierarchyKey__c
            from    Classification__c
            where   HierarchyKey__c = :HKEY_TIER_AFFILIATED
            limit   1
        ];

        system.debug(logTag + 'begin handleExisting code checks...');

        // Check for errors / issues related to this partner or user
        if (handleExistingInvite()) {
            PageReference ref = new PageReference('/partner/apex/PartnerUserResponsePage?invitationid=' + partnerInviteId);
            return ref;
        }
//        Boolean existingCase = handleExistingCase();
//        Boolean existingInvite = handleExistingInvite();
//        Boolean existingUser = handleExistingUser();
//        Boolean existingContact = handleExistingContact();
        if (handleExistingCase() || handleExistingInvite() || handleExistingUser() || handleExistingContact()) {
//            System.debug('*****[debug]***** existingCase=' + existingCase);
//            System.debug('*****[debug]***** existingInvite=' + existingInvite);
//            System.debug('*****[debug]***** existingCUser=' + existingUser);
//            System.debug('*****[debug]***** existingContact=' + existingContact);
            return Page.OnboardingJoinIssue;
        }

        if (handleExistingLead()) {
            PageReference page = new PageReference('/OnboardingDisplayLeadStatus');
            page.getParameters().put('id', theLead.Id);
            page.setRedirect(true);
            return page;
        }
        return null;
    }


    public PageReference initIssuesPage(){
        FederationId = theLead.RHNLogin__c;

    	 if (handleExistingCase()
            || handleExistingInvite()
            || handleExistingUser()
            || handleExistingContact()
            || handleExistingLead()
           ){}

         return null;
    }

    public String getCorpResellerCountries() {
        String[] names = new List<String>();
        for (Country__c country : selectableCountryList) {
            if (country.Supported_Specialized_Partner_Types__c != null && country.Supported_Specialized_Partner_Types__c.indexOf('Corporate Reseller') != -1) {
                names.add(country.Abbreviation__c);
            }
        }
        return PartnerUtil.joinArray(names, ',');
    }

    public OnboardingJoinController(ApexPages.StandardController controller) {

    }

    public String partnerType {
        get {
            return partnerType;
        }
        set {
            partnerType = value;
            if (partnerType != null) {
                if (partnerType == EMBEDDED) {
                    theLead.Subtype__c = EMBEDDED;
                } else {
                    theLead.Subtype__c = '';
                    Classification__c ptype = [select Id, Name from Classification__c where HierarchyKey__c = :partnerType];
                    theLead.Partner_Type__c = ptype.Id;
                }
            }
        }
    }

    public List<Partner_Program__c> getExistingPartnerList() {
        List<Partner_Program__c> partnerList = null;

        try {
            System.debug('*****[debug]***** getExistingPartnerList');

            if (partnerType == null || getLead().Email__c == null || leadCountry == null) {
                System.debug('*****[debug]***** missing params - done');
                //return new List<PartnerStatus__c>();
                return null;
            }
            String email = getLead().Email__c;
            String domain = '';
            if (email == null) {
                domain = '%';
            }
            else {
                domain = email.substring(email.indexOf('@') + 1, email.length()).toLowerCase();
            }

            String region = 'NA';
            for (Country__c country : selectableCountryList) {
                if (country.Abbreviation__c == leadCountry) {
                    region = country.Global_Region__c;
                    break;
                }
            }

            if (selectedCountry.SearchByVAT__c == false || VATNumber == null || VATNumber.length() == 0) {
                //
                // this handles regular and embedded type searches on domain
                //
                String[] parts = domain.split('\\.');
                while (parts.size() >= 2) {
                    String searchDomain = '%' + PartnerUtil.joinArray(parts, '.') + '%';
                    partnerList = performDomainSearch(searchDomain, partnerType, theLead.Partner_Type__c);
                    if (partnerList.size() > 0) {
                        break;
                    }
                    parts.remove(0);
                }
/*
                partnerList = performDomainSearch(domain, partnerType, theLead.Partner_Type__c);
                if (partnerList.size() == 0) {
                    //
                    // try narrowing down the domain
                    //
                    Integer first = domain.indexOf('.');
                    if (first > 0) {
                        domain = '%' + domain.substring(first + 1, domain.length());
                        if (partnerList.size() == 0) {
                            //
                            // try narrowing down the domain one more level
                            //
                            Integer second = domain.substring(domain.indexOf('.')+1, domain.length()).indexOf('.');
                            if (second > 0) {
                                domain = domain.substring(second + 1, domain.length());
                                partnerList = performDomainSearch(domain, partnerType, theLead.Partner_Type__c);
                            }
                        }
                    }
                }
*/
            }

            if ((selectedCountry.SearchByVAT__c && VATNumber != null && VATNumber.length() > 0) && partnerType != EMBEDDED) {
                System.debug('*****[debug]***** searching by vat ' + VATNumber);
                partnerList = [
                    select Program__r.Program_Category__c
                         , Account__c
                         , Account__r.Primary__c
                         , Account__r.Name
                         , Account__r.VATNumber__c
                         , Account__r.Account_Alias_Name__c
                         , Account__r.AliasPublicViewable__c
                         , Account__r.BillingStreet
                         , Account__r.BillingCity
                         , Account__r.BillingState
                         , Account__r.BillingPostalCode
                         , Account__r.BillingCountry
                         , Account__r.PrimaryPartnerUser__c
                         , Account__r.OwnerId
                         , Account__r.Global_Region__c
                         , Account__r.Subregion__c
                     from Partner_Program__c
                     where
                           Account__r.VATNumber__c = :VATNumber
                       and Is_Primary__c = true
                       and Account__r.RecordTypeId in (:PartnerConst.NA_PARTNER, :PartnerConst.EMEA_PARTNER, :PartnerConst.LATAM_PARTNER, :PartnerConst.APAC_PARTNER)
                       and Status__c in ('Active','Approved')
                       and Tier__c not in (:PartnerConst.UNAFFILIATED, :PartnerConst.UNAFFILIATED_RENEWAL)
                  order by Account__r.Name asc, Program__r.Program_Category__c asc
                     limit 100
                ];
            }

            if ((selectedCountry.SearchByVAT__c && VATNumber != null && VATNumber.length() > 0) && partnerType == EMBEDDED) {
                System.debug('*****[debug]***** searching for embedded by vat ' + VATNumber);
                partnerList = [
                    select Program__r.Program_Category__c
                         , Account__c
                         , Account__r.Primary__c
                         , Account__r.Name
                         , Account__r.VATNumber__c
                         , Account__r.Account_Alias_Name__c
                         , Account__r.AliasPublicViewable__c
                         , Account__r.BillingStreet
                         , Account__r.BillingCity
                         , Account__r.BillingState
                         , Account__r.BillingPostalCode
                         , Account__r.BillingCountry
                         , Account__r.PrimaryPartnerUser__c
                         , Account__r.OwnerId
                         , Account__r.Global_Region__c
                         , Account__r.Subregion__c
                     from Partner_Program__c
                     where
                           Account__r.VATNumber__c = :VATNumber
                       and Is_Primary__c = false
                       and Account__r.RecordTypeId in (:PartnerConst.NA_PARTNER, :PartnerConst.EMEA_PARTNER, :PartnerConst.LATAM_PARTNER, :PartnerConst.APAC_PARTNER)
                       and Status__c in ('Active','Approved')
                       and Tier__c not in (:PartnerConst.UNAFFILIATED, :PartnerConst.UNAFFILIATED_RENEWAL)
                  order by Account__r.Name asc, Program__r.Program_Category__c asc
                     limit 100
                ];
            }

        } catch (System.DmlException dmlException) {
            addExceptionMessage(dmlException);
        } catch (System.QueryException queryException) {
            addExceptionMessage(queryException);
        }

        //return new List<PartnerStatus__c>();

        // If there's no results, return null
        if(partnerList != null && partnerList.isEmpty()) partnerList = null;

        return partnerList;
    }

    private Partner_Program__c[] performDomainSearch(String domain, String partnerType, ID legacyPartnerType) {
        System.debug('***** debug ***** searching for domain ' + domain);
        List<Partner_Program__c> partnerList = new List<Partner_Program__c>();
        if (partnerType != EMBEDDED) {

            partnerList = [
                select Program__r.Program_Category__c
                     , Account__c
                     , Account__r.Primary__c
                     , Account__r.Name
                     , Account__r.Account_Alias_Name__c
                     , Account__r.AliasPublicViewable__c
                     , Account__r.BillingStreet
                     , Account__r.BillingCity
                     , Account__r.BillingState
                     , Account__r.BillingPostalCode
                     , Account__r.BillingCountry
                     , Account__r.PrimaryPartnerUser__c
                     , Account__r.OwnerId
                     , Account__r.Global_Region__c
                     , Account__r.Subregion__c
                 from Partner_Program__c
                 where
                       Status__c in ('Active','Approved')
                   and Is_Primary__c = true
                   and Account__r.RecordTypeId in (:PartnerConst.NA_PARTNER, :PartnerConst.EMEA_PARTNER, :PartnerConst.LATAM_PARTNER, :PartnerConst.APAC_PARTNER)
                   and Account__r.AllowedEmailDomains__c like :domain
                   and Program__r.Legacy_Partner_Type__c = :theLead.Partner_Type__c
                   and Tier__c not in (:PartnerConst.UNAFFILIATED, :PartnerConst.UNAFFILIATED_RENEWAL)
              order by Account__r.Name asc, Program__r.Program_Category__c asc
                 limit 100
            ];
        }
        else {
            System.debug('*****[debug]***** searching for embedded, not by vat ' + VATNumber);
            partnerList = [
                select Program__r.Program_Category__c
                     , Account__c
                     , Account__r.Primary__c
                     , Account__r.Name
                     , Account__r.Account_Alias_Name__c
                     , Account__r.AliasPublicViewable__c
                     , Account__r.BillingStreet
                     , Account__r.BillingCity
                     , Account__r.BillingState
                     , Account__r.BillingPostalCode
                     , Account__r.BillingCountry
                     , Account__r.PrimaryPartnerUser__c
                     , Account__r.OwnerId
                     , Account__r.Global_Region__c
                     , Account__r.Subregion__c
                 from Partner_Program__c
                 where
                       Status__c in ('Active','Approved')
                   and Is_Primary__c = false
                   and Account__r.RecordTypeId in (:PartnerConst.NA_PARTNER, :PartnerConst.EMEA_PARTNER, :PartnerConst.LATAM_PARTNER, :PartnerConst.APAC_PARTNER)
                   and Account__r.AllowedEmailDomains__c like :domain
                   and Program_Name__c = :PartnerConst.EMBED
                   and Tier__c not in (:PartnerConst.UNAFFILIATED, :PartnerConst.UNAFFILIATED_RENEWAL)
              order by Account__r.Name asc, Program__r.Program_Category__c asc
                 limit 100
            ];
        }
        return partnerList;
    }

    public PageReference submitApplication() {

        theLead.Country__c = selectedCountry.Id;
        Savepoint pSavepoint = null;

        Partner_Program__c joinStatus = [
            select  Id, Account__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState,
                    Account__r.BillingCountry, Account__r.BillingPostalCode, Account__r.Global_Region__c, Account__r.Subregion__c
            from    Partner_Program__c
            where   Id = :selectedPartnerStatus
        ];
        try {
            pSavepoint = Database.setSavepoint();
            theLead.Account__c = joinStatus.Account__c;
            theLead.Company__c = joinStatus.Account__r.Name;
            theLead.Address1__c = joinStatus.Account__r.BillingStreet;
            theLead.City__c = joinStatus.Account__r.BillingCity;
            theLead.State_Province__c = selectedState;
            //theLead.Country__c = theLeadCountry;
            theLead.Postal_Code__c = joinStatus.Account__r.BillingPostalCode;
            theLead.Global_Region__c = joinStatus.Account__r.Global_Region__c;
            theLead.Subregion__c = joinStatus.Account__r.Subregion__c;
            insertOnboardingLead();
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
            addErrorMessage(Label.Onboarding_Controller_Error_Lead_Values + ' ' + theLead);
            Database.rollback(pSavepoint);
            return null;
        }
        return Page.OnboardingJoinThankYou;
    }

    public void insertOnboardingLead() {
        //Profile p = PartnerUtil.onboardingProfileByClassificationId(getLead().Global_Region__c, getLead().Partner_Type__c);
        System.debug('Partner Global Region: ' + getLead().Global_Region__c);
        System.debug('Partner Type: ' + getLead().Partner_Type__c);
        // Mark as submitted and set the proper profile and record type.
        getLead().Partner_Onboarding_Status__c = 'Submitted';
        //getLead().Partner_Onboarding_Profile__c = p.Name;
        //getLead().Onboarding_Profile_Id__c = p.Id;
        System.debug('Partner Profile Name: ' + getLead().Partner_Onboarding_Profile__c);
//        if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id) {
//            getLead().Partner_Tier__c = PartnerTierAffiliated.Id;
//        }
//        else {
            getLead().Partner_Tier__c = PartnerTierReady.Id;
//        }

        getLead().RecordTypeId = [
            select Id
              from RecordType
             where DeveloperName = 'Business_Partner_Registration'
               and SObjectType = 'Partner_Onboarding_Registration__c'
             limit 1
        ].Id;

        // If there is a referenced account AND that account has an associated
        // primary contact, then assign ownership to them
        //

        if (getLead().OwnerId == null && getLead().Account__c != null) {
            Account account = [
                 select PrimaryPartnerUser__r.IsActive
                      , OwnerId
                   from Account
                  where Id = :getLead().Account__c
                  limit 1
            ];

            if (account.PrimaryPartnerUser__r != null && account.PrimaryPartnerUser__r.IsActive == true) {
                getLead().OwnerId = account.PrimaryPartnerUser__r.Id;
            } else {
                getLead().OwnerId = account.OwnerId;
            }
        }

        insert getLead();

        PartnerEmailUtils.sendLeadEmail(getLead().Id, getLead().email__c);
    }


    public Country__c selectedCountry {
        get {
            for (Country__c country : selectableCountryList) {
                if (country.Abbreviation__c == leadCountry) {
                    return country;
                }
            }
            return null;
        }
    }

    public void setCountry() {
        System.debug('*****[debug]***** >>>>>>>>>>>>>>> country=' + lead.Country);
    }

    public void setLeadCountry(String s) {
        theLeadCountry = s;
        //agreements = getRelevantAgreementList();    // prime the agreement list
//      theLead.Country = s;
    }

    private Boolean handleExistingInvite() {
        Integer existingInvites = [
            select count()
              from Partner_User_Invitation__c
             where FederationId__c = :theLead.RHNLogin__c
               and Response_Type__c in ('', null)
        ];
        if (existingInvites > 0) {
            Partner_User_Invitation__c invite = [select Id
              from Partner_User_Invitation__c
             where FederationId__c = :theLead.RHNLogin__c
               and Response_Type__c in ('', null) limit 1];
            partnerInviteId = invite.id;
            hasExistingInvite = true;
            system.debug(logTag + 'Existing invite.');
            return true;
        }
        return false;
    }

    private Boolean handleExistingLead() {
        Integer existingLeads = [
            select count()
              from Partner_Onboarding_Registration__c
             where RHNLogin__c = :theLead.RHNLogin__c
               and RecordType.DeveloperName = 'Business_Partner_Registration'
               and partner_onboarding_status__c in ('Rejected', 'Submitted', 'Pending', 'Pending Data Review')
        ];
        if (existingLeads > 0) {
            //  get the most recent onboarding lead for this federationID
            Partner_Onboarding_Registration__c lead = [
                select id
                     , partner_onboarding_status__c
                     , partner_type__c
                     , partner_type__r.Name
                     , account__c
                     , FirstName__c
                     , LastName__c
                     , email__c
                     , company__c
                     , address1__c
                     , city__c
                     , state_province__c
                     , country__c
                     , postal_code__c
                     , global_region__c
                     , subregion__c
                     , RHNLogin__c
                     , Is_Primary_Public_Sector__c
                     , Public_Sector_Market__c
                     , Other_Countries__c
                     , Onboarding_Language_Preference__c
                     , HasCustomTerms__c
                     , Agree_To_Partner_TC__c
                  from Partner_Onboarding_Registration__c
                 where RHNLogin__c = :theLead.RHNLogin__c
                   and RecordType.DeveloperName = 'Business_Partner_Registration'
              order by createdDate desc
                 limit 1
            ];
            if (lead.partner_onboarding_status__c != 'Approved') {
                theLead = lead;
                messageType = 'DisplayLeadStatus';
                system.debug(logTag + 'Existing Lead.');
                return true;
            }
        }
        return false;
    }

    private Boolean handleExistingCase() {
        OnboardingCase = OnboardingUtils.getOnboardingCase(federationId);
        if (OnboardingCase != null && OnboardingCase.Status != 'Closed') {
        	HasOnboardingCase = true;

        	//OnboardingCaseEmail = OnboardingUtils.CASE_OWNER_QUEUE_EMAIL.get(OnboardingCase.Owner.Name);
        	if (selectedCountry != null) {
	        	String region = selectedCountry.Global_Region__c;
	            System.debug(logTag + 'handleExistingCase - region: [' + region + ']');
	            OnboardingCaseEmail = OnboardingUtils.getCaseEmailByRegion(region);
	            System.debug(logTag + 'handleExistingCase - email: [' + OnboardingCaseEmail + ']');
        	}

            return true;
        }
        return false;
    }

    private Boolean handleExistingUser() {
        User user = OnboardingUtils.getUserWithFederationId(federationId);
        if (user != null) {
            if (user.isActive) {
                // this will be handled by new front gate controller
//              messageType = 'RedirectToPRM';
                System.debug(logTag + 'handleExistingUser - user is ACTIVE.');
                return false;
            } else {
                //messageType = 'ErrorUserIsInactive';
                System.debug(logTag + 'handleExistingUser - user is INACTIVE.');
                HasInactiveUserError = true;
            }
            return true;
        }
        return false;
    }

    private Boolean handleExistingContact() {
        Contact contact = OnboardingUtils.getContactWithFederationId(federationId);
        System.debug('handleExistingContact result: ' + contact);
        if (contact != null) {
            messageType = 'ErrorUserIsMissing';
            HasNoUserError = true;
            system.debug(logTag + 'Existing contact.');
            return true;
        }
        return false;
    }

/*
    private Contact getContactWithFederationId() {
        Contact contact = null;

        if(theLead.RHNLogin__c != null)
            system.debug('handleExistingContact - lead RHNLogin is ' + theLead.RHNLogin__c );
        else
            system.debug('handleExistingContact - lead RHNLogin IS NULL!!!!');

        List<Contact> matchingContacts = [select Id, Name from Contact where LoginName__c = :theLead.RHNLogin__c and Contact.Account.IsPartner = true];
        system.debug('handleExistingContact - matchingContacts size is ' + matchingContacts.size());

        if (theLead.RHNLogin__c != null && matchingContacts.size() > 0) {
            contact = [
                select id
                     , LoginName__c
                     , AccountId
                     , Name
                     , Account.BillingCountry
                  from Contact
                 where LoginName__c = :theLead.RHNLogin__c
                        and Contact.Account.IsPartner = true
                 limit 1
            ];
        }
        return contact;
    }
*/

   public static void addErrorMessage(String message) {
        if (message == null) return;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    public static void addExceptionMessage(Exception pageException) {
        if (pageException == null) return;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Caught Exception: ' + pageException));
    }

    public List<SelectOption> selectableCountryOptions {
        get {
            return OnboardingApplyController.getSelectableCountryOptionsForLang(languageCode, selectableCountryList);
        }
    }

    public Partner_Onboarding_Registration__c getLead() {
        return theLead;
    }

    public Boolean getIsCCP() {
        return partnerType == OnboardingApplyController.HKEY_CLOUD_PROVIDER;
    }

    public boolean IsCCP {
        get {
            boolean ccp;
            if (partnerType != null) {
                ccp = (partnerType == OnboardingApplyController.HKEY_CLOUD_PROVIDER ? true : false);
                } else {
                    User[] user = [
                    select id
                    , Name
                    , IsActive
                    , Email
                    , Compliant_Email_Notices__c
                    , FederationIdentifier
                    , contactId
                    , contact.accountId
                    , migratedOverride__c
                    , LanguageLocaleKey
                    , Contact.Id
                    , Contact.MailingCountry
                    , Contact.Account.BillingCountry
                    , Contact.Account.PartnerStatuses__c
                    , Contact.Account.AllowedEmailDomains__c
                    , Contact.Account.Global_Region__c
                    , Contact.Account.IsPartner
                    , AccountId
                    , ConsumerUserCreated__c
                    from User
                    where FederationIdentifier = :federationId
                    and profile.name like '%Partner Portal%'
                    //and isPortalEnabled = true
                    and ContactId != null
                    limit 1
                    ];
                    if (user.size() == 1) {
                        User u = user[0];
                        if (u.Contact.Account.PartnerStatuses__c != null &&
                            u.Contact.Account.PartnerStatuses__c != '' &&
                            u.Contact.Account.PartnerStatuses__c.contains(PartnerConst.SCP)){
                            ccp = true;
                        }
                    }
                }
                return ccp;
            }
        }

    public boolean isEmbeddedPartner {
        get {
            boolean isEmbed = false;
            Partner_Onboarding_Registration__c[] lead = [select id, subtype__c
                                                            from  Partner_Onboarding_Registration__c
                                                            where RHNLogin__c = :federationId
                                                            and   RecordType.DeveloperName = 'Business_Partner_Registration'
                                                            order by createdDate desc
                                                            limit 1
                                                        ];

            if(lead.size() == 1 && lead.get(0).subType__c == EMBEDDED) {
                isEmbed = true;
            }
            return isEmbed;
        }
    }

    public boolean IsAgreedToTerms {
        get {
            boolean agreed = false;
            system.debug('FederationID ====> '+federationId);
            Partner_Onboarding_Registration__c[] lead = [
                select id
                     , partner_onboarding_status__c
                     , partner_type__c
                     , partner_type__r.Name
                     , account__c
                     , FirstName__c
                     , LastName__c
                     , email__c
                     , company__c
                     , address1__c
                     , city__c
                     , state_province__c
                     , country__c
                     , postal_code__c
                     , global_region__c
                     , subregion__c
                     , RHNLogin__c
                     , Is_Primary_Public_Sector__c
                     , Public_Sector_Market__c
                     , Other_Countries__c
                     , Onboarding_Language_Preference__c
                     , HasCustomTerms__c
                     , Agree_To_Partner_TC__c
                  from Partner_Onboarding_Registration__c
                 where RHNLogin__c = :federationId
                   and RecordType.DeveloperName = 'Business_Partner_Registration'
              order by createdDate desc
                 limit 1
            ];
            if(lead.size() == 1 && (lead.get(0).Agree_To_Partner_TC__c == true || lead.get(0).HasCustomTerms__c == true)) {
                agreed = true;
                System.debug('Agree_To_Partner_TC__c ====> '+lead.get(0).Agree_To_Partner_TC__c);
                System.debug('HasCustomTerms__c ====> '+lead.get(0).HasCustomTerms__c);
                System.debug('Agreements accepted ===>>> '+agreed);
            }
            return agreed;
        }
    }

    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }


    public PageReference convertContactSubmit() {
        // this might end up being code that actually converts the user
        // if that's so, where do we send them?  I guess to be federated
        // for now, create a case and submit it

        Contact contact = OnboardingUtils.getContactWithFederationId(FederationId);
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Creation Request'
                , contact.Name + ' has requested to be converted to a partner user'
                , 'To convert the contact to a partner user, click the Contact Name associated with this case. ' +
                  'Then, click the "Enable Partner User" button on the Contact.'
                , contact.Id
                , contact.AccountId
                , contact.Account.Global_Region__c
                , OnboardingUtils.getCountryByAbbreviation(contact.account.BillingCountry).Country_of_Order__c
                , 'Medium');
        //CurrentPageName = 'DisplayCaseStatus';
        HasNoUserError = false;
        HasOnboardingCase = true;
        /*PageReference p = Page.OnboardingJoinIssue;
        p.setRedirect(true);
        return p;*/
        return null;
    }


    //convertContactCancel
    public PageReference convertContactCancel() {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name);
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference activateUserSubmit() {
        if (!HasOnboardingCase) {
            User user = OnboardingUtils.getUserWithFederationId(federationId);
            OnboardingCase = createPartnerOnboardingCase(FederationId
                    , 'User Activation Request'
                    , user.Name + ' has requested to be activated as a partner user'
                    , 'This request might require clearing out the Federation ID field of an existing User record.  '+
                      'Additionally, verify a valid email address for the user based on the Allowed Domains for the account.'
                    , user.contactId
                    , user.contact.AccountId
                    , user.contact.Account.Global_Region__c
                    , OnboardingUtils.getCountryByAbbreviation(user.contact.account.BillingCountry).Country_of_Order__c
                    , 'Medium');
            HasOnboardingCase = true;
        }
        HasInactiveUserError = false;
        return null;
    }


    //
    // Creates a case when a user cannot find their company in the search results.
    //
    public PageReference missingAccountCase() {
        User user = OnboardingUtils.getUserWithFederationId(federationId);
        OnboardingCase = createPartnerOnboardingCase(
                FederationId
                , 'Onboarding - No Account Found'
                , theLead.FirstName__c + ' ' + theLead.LastName__c + ' is attempting to onboard but a company match cannot be found.'
                , 'There are no companies that match the user\'s email domain (' + theLead.Email__c + '). You may need to determine if there is an alternate domain name in use for the partner company or instruct the user to create a new partner account.'
                , null //user.contactId
                , null // user.contact.AccountId
                , selectedCountry.Global_Region__c  // region
                , null  // country
                , 'High');
        HasOnboardingCase = true;
        //return  null;
        return Page.OnboardingJoinIssue;
    }



    public PageReference partnerApply() {
        //return  null;
        map<string,string> params = ApexPages.currentPage().getParameters();
        String qs = 'rhn-first-name=' + params.get('rhn-first-name') +
                            '&rhn-last-name=' + params.get('rhn-last-name') +
                            '&rhn-company-name=' + params.get('rhn-company-name') +
                            '&rhn-email=' + params.get('rhn-email') +
                            '&federation-id=' + params.get('federation-id');
        PageReference nextpage = new PageReference('/apex/OnboardingApply?' + qs);
        nextPage.setRedirect(true);
        return nextPage;
    }


    public PageReference activateUserCancel() {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name);
            pageReference.setRedirect(true);
            return pageReference;
    }

     private Case createPartnerOnboardingCase(String federationId, String issueType, String subject, String description,
                String contactId, String accountId, String region, String countryName, String priority) {

        Case c = new Case();
        c.Region__c = region;
        c.Country__c = countryName;

/*
        if (getLead() != null && getLead().Country != null && getLead().Country != ''){
            System.debug('*****[debug]***** lead.country=' + getLead().Country);
            Country__c country = [select Abbreviation__c, Global_Region__c, Country_Name__c
                from Country__c where Abbreviation__c = :getLead().Country];
            c.Country__c = country.Country_Name__c;
        }
        else {
            if (selectedCountry != null) {
                System.debug('*****[debug]***** selected.country=' + selectedCountry.Country_Name__c);
                c.Country__c = selectedCountry.Country_Name__c;
            }
            else {
                System.debug('*** missing country: ' + leadCountry);
                return null;
            }
        }
*/
        String PartnerGeneralIssuesRecordTypeId = [
            select id
              from RecordType
             where sObjectType = 'Case'
               and Name = 'Partner General Issues'
        ].id;

        c.RecordTypeId = PartnerGeneralIssuesRecordTypeId;
        c.Issue_Type_Classification__c = 'Partner Onboarding';
        c.Issue_Type__c = issueType;
        c.Subject = subject;
        c.Description = description;
        c.Origin = 'Portal';
        c.RedHatLoginName__c = FederationId;
        c.Status = 'New';
        c.Priority = priority;

        if (accountId != null) {
            c.AccountId = accountId;
        }
        if (contactId != null) {
            c.ContactId = contactId;
        }

        Database.Dmloptions dmo = new Database.Dmloptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);

        try {
        insert c;
        }
        catch (System.DmlException ex) {
            System.debug('----------------------->> RecordTypeId=' + c.RecordTypeId);
            System.debug('----------------------->> ContactId=' + c.ContactId);
            throw ex;
        }
        return [
            select Issue_Type__c
                 , CaseNumber
                 , Status
              from Case
             where ID = :c.ID
        ];
    }

    public Classification__c PartnerTierReady {
        set;
        get;
    }

    public Classification__c PartnerTierAffiliated {
        set;
        get;
    }

    public String selectedState {
        get;
        set {
            selectedState = value;
            if (selectedState != null && selectedState.length() == 2) {
                // translate from 2-letter to full name
                try {
                    State__c state = [select Name from State__c where Abbreviation__c = :selectedState and Country__c = :selectedCountry.Id limit 1];
//                    selectedState = state.Name;
                    //theLead.State_Province__c = selectedState;
                }
                catch (DMLException ex) {
                    // safe to ignore
                }
            }
        }
    }
}