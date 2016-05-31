public without sharing class OnboardingApplyController {

    public static final String PARAM_COMPANY = 'rhn-company-name';
    public static final String PARAM_EMAIL = 'rhn-email';
    public static final String PARAM_SALUTATION = 'rhn-salutation';
    public static final String PARAM_FIRST_NAME = 'rhn-first-name';
    public static final String PARAM_LAST_NAME = 'rhn-last-name';
    public static final String PARAM_FEDERATION_ID = 'federation-id';
    public static final String PARAM_PARTNER_ID = 'partner-id';
    public static final String PARAM_PARTNER_NAME = 'partner-name';
    public static final String PARAM_LANGUAGE = 'language';
    public static final String PARAM_CUSTOMER_TYPE = 'customer-type';
    public static final String HKEY_ISV = 'PARTNER_TYPE.ISV';
    public static final String HKEY_OEM = 'PARTNER_TYPE.OEM';
    public static final String HKEY_DISTRIBUTOR = 'PARTNER_TYPE.DISTRIBUTOR';
    public static final String HKEY_TRAINING = 'PARTNER_TYPE.TRAINING';
    public static final String HKEY_SI = 'PARTNER_TYPE.SI';
    public static final String HKEY_RESELLER = 'PARTNER_TYPE.RESELLER';
    public static final String HKEY_CORPORATE_RESELLER = 'PARTNER_TYPE.CORPORATE_RESELLER';
    public static final String HKEY_TIER_READY = 'PARTNER_TIER.READY';
    public static final String HKEY_TIER_AFFILIATED = 'PARTNER_TIER.AFFILIATED';
    public static final String HKEY_TIER_UNAFFILIATED = 'PARTNER_TIER.UNAFFILIATED';
    public static final String HKEY_CLOUD_PROVIDER = 'PARTNER_TYPE.SERVICECLOUD_PROVIDER';
    public static final String EMBEDDED = 'Embedded';

    public  Partner_Onboarding_Registration__c    theLead {get; private set; }
    public List<Country__c> selectableCountryList;
    public String theLeadCountry {get; set; }
    public String agreeTerms {get; set; }
    //public List<Agreement__c> agreements {get; set; }
    public String hasCustomTerms {get; set; }
    public String customTermsText {get; set; }
    public String languageCode;
    public String language;
    public String declinedReason {get; set; }

    public Case OnboardingCase{get;set;}
    public String OnboardingCaseEmail{get;set;}

    public Boolean HasOnboardingCase {get;set;}
    public Boolean HasInactiveUserError {get; private set;}
    public Boolean HasNoUserError {get; private set;}
    public Boolean HasUserExistsError {get; private set;}
    public Boolean HasExistingInviteError {get; private set;}

    public String federationId {get; set;}

    private String subtype = '';
    private Id placeholderOnboardingRecordTypeId;


    public static final Map<String, List<Schema.PicklistEntry>> PICKLIST_ENTRIES = new Map<String, List<Schema.PicklistEntry>> {
        'Additional_Countries_Of_Operations__c' => Partner_Onboarding_Registration__c.Additional_Countries_Of_Operations__c.getDescribe().getPicklistValues(),
        'Additional_Partnerships__c' => Partner_Onboarding_Registration__c.Additional_Partnerships__c.getDescribe().getPicklistValues(),
        'Application_Types__c' => Partner_Onboarding_Registration__c.Application_Types__c.getDescribe().getPicklistValues(),
        //'Industry_Focus__c' => Partner_Onboarding_Registration__c.Industry_Focus__c.getDescribe().getPicklistValues(),
        'Middleware_Supported__c' => Partner_Onboarding_Registration__c.Middleware_Supported__c.getDescribe().getPicklistValues(),
        'Operating_System_Supported__c' => Partner_Onboarding_Registration__c.Operating_System_Supported__c.getDescribe().getPicklistValues(),
        'Software_Focus__c' => Partner_Onboarding_Registration__c.Software_Focus__c.getDescribe().getPicklistValues(),
        'Target_Market_Size__c' => Partner_Onboarding_Registration__c.Target_Market_Size__c.getDescribe().getPicklistValues(),
        'Public_Sector_Market__c' => Partner_Onboarding_Registration__c.Public_Sector_Market__c.getDescribe().getPicklistValues(),
        'Total_Annual_Revenue__c' => Partner_Onboarding_Registration__c.Total_Annual_Revenue__c.getDescribe().getPicklistValues(),
        'Number_of_Employees__c' => Partner_Onboarding_Registration__c.Number_of_Employees__c.getDescribe().getPicklistValues()
    };


    public OnboardingApplyController() {
        thelead = new Partner_Onboarding_Registration__c();
        HasOnboardingCase = false;
        String program = getParam('program');
        if (program != null) {
            partnerType = program;
        }
    }

    public PageReference init() {

        placeholderOnboardingRecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Partner_Onboarding_Registration__c'
            and     DeveloperName = 'Placeholder'
        ].Id;

        federationId = getParam(PARAM_FEDERATION_ID);
        if (federationId != null) {
            Partner_Onboarding_Registration__c existingLead = findExistingLead(federationId);
            if (existingLead != null) {
                PageReference page = new PageReference('/OnboardingDisplayLeadStatus');
                page.getParameters().put('id', existingLead.Id);
                page.setRedirect(true);
                return page;
            }
        }

        //
        // Load the countries and states
        //

        selectableCountryList = [
            select Name, Abbreviation__c, Global_Region__c, Country_Name__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c, Supported_Specialized_Partner_Types__c, SearchByVAT__c
         , (select Name, Abbreviation__c from States__r order by Name asc)
              from Country__c order by Name asc
        ];

        theLead.Company__c = getParam(PARAM_COMPANY);
        if (theLead.Company__c == null || theLead.Company__c.equals(''))  theLead.Company__c = getParam(PARAM_PARTNER_NAME) != null ? getParam(PARAM_PARTNER_NAME) : '';


        // Make sure the current request has a federation-id parameter
        // If not, send them to the rh.com login page
        federationId = getParam(PARAM_FEDERATION_ID);
        if (federationId == null)  return Page.PartnerAccess;


        String customerType = getParam(PARAM_CUSTOMER_TYPE);
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

        languageCode = getParam(PARAM_LANGUAGE);
        if (languageCode == null) {
            languageCode = 'en';
        }
        language = getLocalePicklistName(languageCode, null);

        //
        // Copy the RHN information to the lead
        //

        theLead.FirstName__c = getParam(PARAM_FIRST_NAME);
        theLead.LastName__c = getParam(PARAM_LAST_NAME);
        theLead.Email__c = getParam(PARAM_EMAIL);
        theLead.Salutation__c = getParam(PARAM_SALUTATION);
        theLead.Company__c = getParam(PARAM_COMPANY);
        theLead.RHNLogin__c = federationId;
        theLead.Onboarding_Language_Preference__c = LanguageCode;

        String program = getParam('program');
        if (program != null) {
            partnerType = program;
        }

        //
        // Load the partner type objects
        //

        List<Classification__c> types = [
            select  Name,
                    HierarchyKey__c
            from    Classification__c
            where   HierarchyKey__c in (:HKEY_ISV, :HKEY_OEM, :HKEY_DISTRIBUTOR, :HKEY_TRAINING, :HKEY_SI, :HKEY_RESELLER, :HKEY_CORPORATE_RESELLER,
                        :HKEY_CLOUD_PROVIDER)
             and    AvailableForOnboarding__c = true
        ];

        for (Classification__c cfn : types){
            //if (cfn.HierarchyKey__c == HKEY_ISV){
            //    PartnerTypeISV = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_OEM){
            //    PartnerTypeOEM = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_DISTRIBUTOR){
            //    PartnerTypeDistributor = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_SI){
            //    PartnerTypeSI = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_TRAINING){
            //    PartnerTypeTraining = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_RESELLER){
            //    PartnerTypeReseller = cfn;
            //} else if (cfn.HierarchyKey__c == HKEY_CORPORATE_RESELLER){
            //    PartnerTypeCorporateReseller = cfn;
            if (cfn.HierarchyKey__c == HKEY_CLOUD_PROVIDER) {
                PartnerTypeCloudProvider = cfn;
            }
        }

        PartnerTierReady = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c = :HKEY_TIER_READY
             limit 1
        ];
        System.debug('*****[debug]***** PartnerTierReady.Id=' + PartnerTierReady.Id);

        PartnerTierAffiliated = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c = :HKEY_TIER_AFFILIATED
             limit 1
        ];


        PartnerTierUnaffiliated = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c = :HKEY_TIER_UNAFFILIATED
             limit 1
        ];

        //
        // Send user to Issue page if they have an existing onboarding case or a pending OB request sitting in the approval process queue..
        //
        if(handleExistingCase() || handleExistingInvite() || handleExistingUser() || handleExistingContact()){
            system.debug('USER HAS EXISTING CASES OR INVITES OR AN INACTIVE USER.');
            return Page.OnboardingApplyIssue;
        } else {
            system.debug('NO EXISTING CASES OR INVITES.');
        }


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

    static public Partner_Onboarding_Registration__c findExistingLead(String federationId) {
        system.debug('FederationID ====> '+federationId);
        Partner_Onboarding_Registration__c[] lead = [
            select id
                 , partner_onboarding_status__c
                 , partner_type__c
                 , partner_type__r.Name
                 , account__c
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
                 , Subtype__c
                 , Onb_As_Adv_Or_Prem__c
              from Partner_Onboarding_Registration__c
             where RHNLogin__c = :federationId
               and RecordType.DeveloperName = 'Business_Partner_Registration'
          order by createdDate desc
             limit 1
        ];
        if (lead.size() == 1 && lead.get(0).partner_onboarding_status__c != 'Approved') {
            return lead.get(0);
        }

        return null;
    }

    private Boolean handleExistingCase() {
        OnboardingCase = OnboardingUtils.getOnboardingCase(federationId);
        if(OnboardingCase != null && OnboardingCase.Status != 'Closed'){
            HasOnboardingCase = true;
            OnboardingCaseEmail = OnboardingUtils.CASE_OWNER_QUEUE_EMAIL.get(OnboardingCase.Owner.Name);
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
                System.debug('handleExistingUser - user is ACTIVE.');
                return false;
            } else {
                //messageType = 'ErrorUserIsInactive';
                System.debug('handleExistingUser - user is INACTIVE.');
                HasInactiveUserError = true;
            }
            return true;
        }
        return false;
    }

    private Boolean handleExistingInvite() {
        /*Integer existingInvites = [
            select count()
              from Partner_User_Invitation__c
             where federationId__c = :FederationId
               and Response_Type__c in ('', null)
        ];
        if (existingInvites > 0) {
            Partner_User_Invitation__c invite = [select Id
              from Partner_User_Invitation__c
             where federationId__c = :FederationId
               and Response_Type__c in ('', null) limit 1];
            partnerInviteId = invite.id;
            CurrentPageName = 'RedirectToJoinAccept';
            return true;
        }*/

        List<Partner_User_Invitation__c> existingInvites = [select Id
              from Partner_User_Invitation__c
             where federationId__c = :FederationId
               and Response_Type__c in ('', null)
             ORDER BY CreatedDate DESC
             LIMIT 1];
        return HasExistingInviteError = existingInvites.size() == 1;
    }


    public OnboardingApplyController(ApexPages.StandardController controller) {
//      theLead = new Lead();

    }

    public void processAgreementsSection() {
        System.debug('Partner Agreement Accepted--------->::'+ agreeTerms);
        getLead().Reason_Agreements_Declined__c = declinedReason;

        if (hasCustomTerms == 'Yes') {
            getLead().HasCustomTerms__c = true;
            getLead().CustomTerms__c = customTermsText;
        }

    }

    public PageReference submitApplication() {
        System.debug('*****[debug]***** theLead.Country=' + theLeadCountry);
        for (Country__c country : SelectableCountryList) {
            if (country.Abbreviation__c != theLeadCountry) {
                continue;
            }

            System.debug('*****[debug]***** setting subregion to ' + country.Subregion__c);
            getLead().Global_Region__c = country.Global_Region__c;
            getLead().Subregion__c = country.Subregion__c;
            getLead().Country__c = country.Id;
            break;
         }

        processAgreementsSection();

        if (getLead().Is_Primary_Public_Sector__c != null && getLead().Is_Primary_Public_Sector__c == 'Yes') {
            getLead().Subregion__c = 'Fed Sled';
        }
        else {
            try {
                // Override the subregion if the selected state has a specified subregion.
                List<State__c> stateList = [
                        select Subregion__c
                          from State__c
                         where Id = :getLead().State_Province__c
                           and Country__c = :getLead().Country__c
                           and Subregion__c != null
                ];

                if (stateList.size() != 0) {
                    System.debug('*****[debug]***** 2.setting subregion to ' + stateList[0].Subregion__c);
                    getLead().Subregion__c = stateList[0].Subregion__c;
                }
            } catch (Exception pageException) {
                System.debug('*****[debug]***** ' + pageException);
            }
        }
        insertOnboardingLead();

        if (subtype != null && subtype.equalsIgnoreCase(EMBEDDED)) {
            return new PageReference('/partner/PARF?federationId=' + federationId);
        }

        if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id) {
            //get the token for the ccsp checklist:
            PartnerUser_Email_Token__c token = [SELECT Token__c
                                                FROM PartnerUser_Email_Token__c
                                                WHERE Partner_Onboarding__c = :getLead().Id
                                                and Is_Active__c = true
                                                and Notification_Type__c = 'CCSP Checklist'
                                                LIMIT 1];
            return new PageReference('/partner/CCSPForm?federationId=' + federationId + '&token=' + token.Token__c);
        }
        return Page.OnboardingApplyThankYou;
    }

    private void insertOnboardingLead() {

        System.debug('*****[debug]***** region=' + theLead.Global_Region__c + ', type=' + theLead.Partner_Type__c);
//        Profile p = PartnerUtil.onboardingProfileByClassificationId(getLead().Global_Region__c, getLead().Partner_Type__c);
        System.debug('Partner Global Region: ' + getLead().Global_Region__c);
        System.debug('Partner Type: ' + getLead().Partner_Type__c);
        // Mark as submitted and set the proper profile and record type.
        getLead().Partner_Onboarding_Status__c = 'Submitted';
//        getLead().Partner_Onboarding_Profile__c = p.Name;
//        getLead().Onboarding_Profile_Id__c = p.Id;
        System.debug('Partner Profile Name: ' + getLead().Partner_Onboarding_Profile__c);
        if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id ||
            (subtype != null && subtype.equalsIgnoreCase(EMBEDDED))) {
            getLead().Partner_Tier__c = PartnerTierUnaffiliated.Id;
            getLead().Requalification_Date__c = null;
        }
        else {
            getLead().Partner_Tier__c = PartnerTierReady.Id;
        }

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
                 select PrimaryPartnerUser__r.IsActive, OwnerId
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

        //
        // If the owner id is still missing, then try to find the best owner from
        // the account team rules engine.
        //

        if (getLead().OwnerId == null) {
            String accountTeamQuery = '';
            accountTeamQuery += 'select User__c, Priority__c';
            accountTeamQuery += '  from AccountTeamRule__c';
            accountTeamQuery += ' where AccountAccessLevel__c = \'Owner\'';

            if (getLead().Global_Region__c != null) {
                accountTeamQuery += ' and (GlobalRegion__c = null or GlobalRegion__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Global_Region__c);
                accountTeamQuery += '\')';
            }

            if (getLead().Subregion__c != null) {
                accountTeamQuery += ' and (Subregion__c = null or Subregion__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Subregion__c);
                accountTeamQuery += '\')';
            }

            if (getLead().Country__c != null) {
                accountTeamQuery += ' and (Country__c = null or Country__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Country__c);
                accountTeamQuery += '\')';
            }

            if (getLead().Partner_Tier__c != null) {
                accountTeamQuery += ' and (PartnerTier__c = null or PartnerTier__c = \'';
                accountTeamQuery += getLead().Partner_Tier__c;
                accountTeamQuery += '\')';
            }

            if (getLead().Partner_Type__c != null) {
                accountTeamQuery += ' and (PartnerType__c = null or PartnerType__c = \'';
                accountTeamQuery += getLead().Partner_Type__c;
                accountTeamQuery += '\')';
            }

            // Finish and execute
            accountTeamQuery += ' order by Priority__c desc limit 1';
            system.debug('accountTeamQuery: [' + accountTeamQuery + ']');

            List<Sobject> objectList = Database.query(accountTeamQuery);

            if (objectList.size() != 0)
                getLead().OwnerId = ((AccountTeamRule__c) objectList[0]).User__c;
        }
        if (AgreementsAccepted == true) {
            getLead().Agree_To_Partner_TC__c = true;
        } else {
            getLead().Agree_To_Partner_TC__c = false;
        }

        // If Add'l countries of operation is "None", don't store the value "None" - just leave it empty
        if(getLead().Additional_Countries_Of_Operations__c == 'None')
            getLead().Additional_Countries_Of_Operations__c = null;

        if (subtype != null && subtype.equalsIgnoreCase(EMBEDDED)) {
            getLead().RecordTypeId = placeholderOnboardingRecordTypeId;
            getLead().Subtype__c = EMBEDDED;
        }

        if (subtype != null && getLead().Partner_Type__c == PartnerTypeCloudProvider.Id) {
            getLead().Subtype__c = PartnerConst.CCNSP;
        }

        String typeName = [
            select  Id,
                    Name
            from    Classification__c
            where   Id = :getLead().Partner_Type__c
        ].Name;

        getLead().Onb_As_Adv_Or_Prem__c = PartnerUtil.onbAsAdvancedOrPremier(typeName);
        System.debug('Onboard as Advanced or Premier? ' + getLead().Onb_As_Adv_Or_Prem__c);
        System.debug('Partner Type: ' + typeName);


        getLead().User_IP__c = PartnerUtil.getUserIPAddress();

        insert getLead();

 //       if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id) {
            //
            // US45477
            // For CCP's create the approval form object and attach to lead.  It will be filled out by a manager
            //
 //           insert new Partner_CCP_Form__c(Name = getLead().Company, Lead__c = getLead().Id);
 //       }

        // Build and submit the partner agreement relationship, but only when this is a
        // new registration process.
        if (getLead().Account__c == null && getLead().Partner_Type__c != PartnerTypeCloudProvider.Id) {
            List<PartnerAgreement__c> partnerAgreementList = new List<PartnerAgreement__c>();
            List<Agreement__c> agreementList = getRelevantAgreementList();
            if (agreementList != null && agreementList.size() > 0) {
                for(Agreement__c agreement : getRelevantAgreementList()) {
                    PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
                    partnerAgreement.Agreement__c = agreement.Id;
                    partnerAgreement.Partner_Onboarding__c = getLead().Id;
                    partnerAgreement.ActivationDate__c = Date.today();

                    if (!skipAgreement) {
                        //According to, US79276, Program guides should be marked as 'Approved' - Kiran on 12/15
                        //if (AgreementsAccepted == true && agreement.Is_Terms_Document__c)
                        if (AgreementsAccepted == true)
                            partnerAgreement.PartnerApprovalStatus__c = 'Approved';
                        else
                            partnerAgreement.PartnerApprovalStatus__c = 'Declined';
                        partnerAgreementList.add(partnerAgreement);
                    }
                }
                insert partnerAgreementList;
            } else {
                Partner_Onboarding_Registration__c l = new Partner_Onboarding_Registration__c(id=getLead().id);
                l.No_Agreements__c = true;
                update l;
            }
        }

        if (getLead().Partner_Type__c != PartnerTypeCloudProvider.Id) {
            if (!Test.isRunningTest()) {
                // handle all new account onboarding
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval.');
                approvalRequest.setObjectId(getLead().Id);

                // Ensure the approval was submitted properly
                if (subtype != null && !subtype.equalsIgnoreCase(EMBEDDED)) {
                  Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                  System.Assert(approvalResult.isSuccess(), approvalResult.getErrors());
                }
            }
        }
        else {
            CCSP_Form__c form = new CCSP_Form__c();
            form.CCSPOnboardingRegistration__c = getLead().Id;
            form.Contact_Email__c = getLead().Email__c;
            insert form;
            // update to Pending to send out email to user.  Can't do this on insert due to locking issues
            form.Status__c = 'Pending';
            update form;
        }
    }

    public Agreement__c[] getAgreements() {
        return getRelevantAgreementList();
    }

    public List<Agreement__c> getRelevantAgreementList() {
        System.debug('country=' + theLeadCountry);
        System.debug('partnerType=' + partnerType);
        List<Agreement__c> agreementList = new List<Agreement__c>();

        if (this.selectedCountry != null && getLead() != null && partnerType != null ) {

             System.debug('***** [DEBUG] ***** mylead.partnertype is ' + thelead.Partner_Type__c);
            // Here we are getting all the documents for a country.
            // We want all agreements for the Lead's preferred language and all non-specific ones
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                Select Agreement__c
                  From Agreement_Country__c
                 where Country__c = :this.selectedCountry.Id
                   and Agreement__r.PartnerType__c = :thelead.Partner_Type__c
                   and Agreement__r.ActivationStatus__c = 'Active'
                   and Agreement__r.Partner_Program__c = null
                   and (Agreement__r.Type__c = 'Partner' or Agreement__r.Type__c = 'Partner & User')
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }

            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                if (skipAgreement) {
                    agreementList = [select Id,Name, Is_Terms_Document__c, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet and Is_Terms_Document__c = False];
                }
                else {
                    agreementList = [select Id,Name, Is_Terms_Document__c, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet];
                }
            }

            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementList  = [
                    select Id
                         , Name
                         , IsSignatureRequired__c
                         , Is_Terms_Document__c
                         , Version__c
                         , (select Name from Attachments)
                      from Agreement__c
                     where Country_Count__c = 0
                       and ActivationStatus__c = 'Active'
                       and PartnerType__c = :thelead.Partner_Type__c
                       and Partner_Program__c = null
                       and Type__c != 'User'
            ];
            if (globalAgreementList != null && globalAgreementList.size() > 0) {
                for (Agreement__c globalAgreement :globalAgreementList) {
                    agreementList.add(globalAgreement);
                }
            }
        }

        for (Agreement__c agree : agreementList) {
            if (agree.Is_Terms_Document__c) {
                System.debug('*****[debug]***** attachment count=' + agree.Attachments.size());
                mainTermsAgreementAttachmentId = agree.Attachments[0].Id;
                System.debug('*****[debug]***** attachment name=' + agree.Attachments[0].Name);
                break;
            }
        }

        if (agreementList != null && agreementList.size() > 0) {
            System.debug('Agreement List---------->::' + agreementList.size());
        }
        return agreementList;
    }

    public ID mainTermsAgreementAttachmentId {get;set;}

/*
    public ID mainTermsAgreementAttachmentId {
        get {
            if (agreements == null) {
                agreements = getRelevantAgreementList();
            }
            for (Agreement__c agree : agreements) {
                if (agree.Is_Terms_Document__c && agree.Attachments.size() > 0) {
                    System.debug('*****[debug]***** attachment count=' + agree.Attachments.size());
                    System.debug('*****[debug]***** attachment name=' + agree.Attachments[0].Name);
                    return agree.Attachments[0].Id;
                }
            }
            return null;
        }

    }
*/

    public String partnerType {
        get;
        set {
            partnerType = value;
            System.debug('***** [DEBUG] ***** partnerType set to ' + partnerType);
            String pt = partnerType;
            subtype = '';
            if (partnerType.equalsIgnoreCase(EMBEDDED)) {
              pt = HKEY_ISV;
              subtype = EMBEDDED;
            }

            if (partnerType.equalsIgnoreCase(HKEY_CLOUD_PROVIDER)) {
                subtype = PartnerConst.CCNSP;
            }
            System.debug('Temporary partner type set to ' + pt);
            Classification__c clfn = [select Id from Classification__c where HierarchyKey__c = :pt];
            thelead.Partner_Type__c = clfn.Id;
            //agreements = getRelevantAgreementList();    // prime the agreement list

        }
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
                    theLead.State_Province__c = state.Id;
                }
                catch (DMLException ex) {
                    // safe to ignore
                }
            }
        }
    }

    public Boolean skipAgreement {
        get {
            if (PartnerTypeCloudProvider != null) {
                if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id) {
                    return true;
                }
            }
            if (subtype != null && subtype.equalsIgnoreCase(EMBEDDED)) {
                return true;
            }
            return false;
        }
    }
    public Boolean agreementsAccepted {
        get {
            if (agreeTerms == null) return false;
            return agreeTerms.equalsIgnoreCase('yes') ? true : false;
        }
    }

/*
    public Classification__c PartnerTypeISV {
        set;
        get;
    }

    public Classification__c PartnerTypeOEM {
        set;
        get;
    }

    public Classification__c PartnerTypeDistributor {
        set;
        get;
    }

    public Classification__c PartnerTypeSI {
        set;
        get;
    }

    public Classification__c PartnerTypeTraining {
        set;
        get;
    }

    public Classification__c PartnerTypeReseller {
        set;
        get;
    }

    public Classification__c PartnerTypeCorporateReseller {
        set;
        get;
    }

    public Classification__c PartnerTypeCloudProvider {
        set;
        get;
    }
*/

    public Classification__c PartnerTypeCloudProvider {
        set;
        get;
    }

    public Classification__c PartnerTierReady {
        set;
        get;
    }

    public Classification__c PartnerTierAffiliated {
        set;
        get;
    }

    public Classification__c PartnerTierUnaffiliated {
        set;
        get;
    }

    public Country__c selectedCountry {
        get {
            for (Country__c country : selectableCountryList) {
                if (country.Abbreviation__c == theLeadCountry) {
                    return country;
                }
            }
            return null;
        }
    }

    public Partner_Onboarding_Registration__c getLead() {
        return theLead;
    }

    public void setCountry() {
        System.debug('*****[debug]***** >>>>>>>>>>>>>>> country=' + lead.Country);
    }

    public void setLeadCountry(String s) {
        theLeadCountry = s;
//      theLead.Country = s;
    }

    public String getLeadCountry() {
        return theLeadCountry;
    }

    public List<SelectOption> getSelectableStateOptions() {
        if (theLeadCountry == null) {
            System.debug('*****[debug]***** selectableStateOptions nothing to do');
            return new SelectOption[0];
        }
        System.debug('*****[debug]***** selectableStateOptions for ' + theLeadCountry);
        List<SelectOption> stateOptionList = new List<SelectOption>();

        for(Country__c country : selectableCountryList) {
            if (theLeadCountry == country.Abbreviation__c) {
                // add all of the states
                for (State__c state : country.States__r) {
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));
                }
                break;
            }
        }

        return stateOptionList;
    }


    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList)
            selectOptionList.add(new SelectOption(p.Value, p.Label));

        return selectOptionList;
    }

    public List<SelectOption> selectableCountryOptions {
        get {
            return getSelectableCountryOptionsForLang(languageCode, selectableCountryList);
        }
    }

    static public List<SelectOption> getSelectableCountryOptionsForLang(String languageCode, List<Country__c> countryList){
        List<SelectOption> countryOptionList = new List<SelectOption>();

        Map<String, String> countryNames = new Map<String,String>();
        for (CountryTranslation__c cT: [
            select  LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c
            from    CountryTranslation__c
            where   LanguageCode__c = :languageCode
        ]) {
            countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
        }

        for (Country__c country : countryList) {
            String name = country.Name;
            if (countryNames.get(country.Iso3166Alpha2__c) != null) {
                name = countryNames.get(country.Iso3166Alpha2__c);
            }
            countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
        }

        // Add a "None" option to the country list
        countryOptionList.add( new SelectOption('None','None') );

        return countryOptionList;
    }

    public boolean getIsCCP {
        get {
            return partnerType == HKEY_CLOUD_PROVIDER;
        }
    }

    public boolean IsCCP {
        get {
            boolean ccp = false;
            if (partnerType != null) {
                ccp = (partnerType == HKEY_CLOUD_PROVIDER ? true : false);
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
                     , Onb_As_Adv_Or_Prem__c
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


    public List<SelectOption> getPublicSectorMarketOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Public_Sector_Market__c'));
    }

    public List<String> getPublicSectorMarket() {
        return getSplitPicklistField(thelead.Public_Sector_Market__c);
    }

    public void setPublicSectorMarket(List<String> valuesList) {
        setSelectOptionsValuesToField('Public_Sector_Market__c', valuesList);
    }

    public List<String> getSplitPicklistField(String values) {
        return values == null ? new List<String>() : values.split(';');
    }

    public List<SelectOption> getAdditionalCountriesOfOperationsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Countries_Of_Operations__c'));
    }

    public List<String> getAdditionalCountriesOfOperations() {
        return getSplitPicklistField(thelead.Additional_Countries_Of_Operations__c);
    }

    public void setAdditionalCountriesOfOperations(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Countries_Of_Operations__c', valuesList);
    }

    public List<SelectOption> getTotalAnnualRevenueOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Total_Annual_Revenue__c'));
    }

    public List<SelectOption> getNumberOfEmployeesOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Number_of_Employees__c'));
    }

    // Target Market Size

    public List<SelectOption> getTargetMarketSizeOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Target_Market_Size__c'));
    }

    public List<String> getTargetMarketSize() {
        return getSplitPicklistField(thelead.Target_Market_Size__c);
    }

    public void setTargetMarketSize(List<String> valuesList) {
        setSelectOptionsValuesToField('Target_Market_Size__c', valuesList);
    }

    // Software Focus

    public List<SelectOption> getSoftwareFocusOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Software_Focus__c'));
    }

    public List<String> getSoftwareFocus() {
        return getSplitPicklistField(thelead.Software_Focus__c);
    }

    public void setSoftwareFocus(List<String> valuesList) {
        setSelectOptionsValuesToField('Software_Focus__c', valuesList);
    }

    // Operating System Supported

    public List<SelectOption> getOperatingSystemSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Operating_System_Supported__c'));
    }

    public List<String> getOperatingSystemSupported() {
        return getSplitPicklistField(thelead.Operating_System_Supported__c);
    }

    public void setOperatingSystemSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Operating_System_Supported__c', valuesList);
    }

    // Middleware Supported

    public List<SelectOption> getMiddlewareSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Middleware_Supported__c'));
    }

    public List<String> getMiddlewareSupported() {
        return getSplitPicklistField(thelead.Middleware_Supported__c);
    }

    public void setMiddlewareSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Middleware_Supported__c', valuesList);
    }

    // Application Types

    public List<SelectOption> getApplicationTypesOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Application_Types__c'));
    }

    public List<String> getApplicationTypes() {
        return getSplitPicklistField(thelead.Application_Types__c);
    }

    public void setApplicationTypes(List<String> valuesList) {
        setSelectOptionsValuesToField('Application_Types__c', valuesList);
    }

    // Additional Partnerships

    public List<SelectOption> getAdditionalPartnershipsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Partnerships__c'));
    }

    public List<String> getAdditionalPartnerships() {
        return getSplitPicklistField(thelead.Additional_Partnerships__c);
    }

    public void setAdditionalPartnerships(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Partnerships__c', valuesList);
    }

    public void setSelectOptionsValuesToField(String fieldName, List<String> valuesList) {
        String field = '';

        for(String value : valuesList) {
            if (field != '')
                field += ';';
            field += value;
        }

        thelead.put(fieldName, field);
    }

    public static String getLocalePicklistName(String localeCode, String defaultName) {
        if (localeCode == null) {
            return (defaultName != null) ? defaultName : 'en';
        }
        localeCode = localeCode.toLowerCase();
        Map<String,String> listmap = new Map<String,String> {
            'en'    => 'English',
            'zh_TW' => 'Chinese',
            'zh_tw' => 'Chinese',
            'zh_CN' => 'Chinese (simplified)',
            'zh_cn' => 'Chinese (simplified)',
            'zh'    => 'Chinese (simplified)',
            'ja'    => 'Japanese',
            'pt_BR' => 'Portuguese',
            'pt'    => 'Portuguese',
            'ko'    => 'Korean',
            'de'    => 'German',
            'es'    => 'Spanish',
            'fr'    => 'French',
            'it'    => 'Italian',
            'ru'    => 'Russian'
        };
        for (String key : listmap.keySet()) {
            if (localeCode.startsWith(key)) {
                return listmap.get(key);
            }
        }
        return (defaultName != null) ? defaultName : 'en';
    }

    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }

    public PageReference activateUserSubmit() {
        if (!HasOnboardingCase) {
            User user = OnboardingUtils.getUserWithFederationId(federationId);
            OnboardingCase = createPartnerOnboardingCase(federationId
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
        c.RedHatLoginName__c = federationId;
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

    private Boolean handleExistingContact() {
        Contact contact = OnboardingUtils.getContactWithFederationId(federationId);
        System.debug('handleExistingContact result: ' + contact);
        if (contact != null) {
            HasNoUserError = true;
            return true;
        }
        return false;
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

    public PageReference convertContactCancel() {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name);
        pageReference.setRedirect(true);
        return pageReference;
    }
}