public without sharing class OnboardingController {
    // ^ Sharing is DISABLED - write cautious code!!!!

    public static final String ERROR_REQUIRED_FIELD = Label.Onboarding_Controller_Error_Required_Field + ' ';

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
    public static final String HKEY_REGIONAL_SI = 'PARTNER_TYPE.REGIONAL_SI'; //US26401
    public static final String HKEY_CLOUD_PROVIDER = 'PARTNER_TYPE.SERVICECLOUD_PROVIDER';


    public static final String ONBOARDING_TYPE_JOIN = 'join';

    public Country__c selectedCountry {
        get {
            for(Country__c country : SelectableCountryList) {
                if (country.Abbreviation__c == getLead().Country){
                    return country;
                }
            }
            return null;
        }
    }

    public boolean isEmeaCountry {
        get {
            for(Country__c country : SelectableCountryList) {
                if (country.Abbreviation__c == getLead().Country && country.Global_Region__c == 'EMEA'){
                    return true;
                }
            }
            return null;
        }
    }

    public String declinedReason {get; set; }

    public String VATNumber {get; set; }

    public String customTerms {get; set; }
    public String customTermsText {get; set; }


    public String onboardingCountry {
        get;
    }

    public void setOnboardingCountry(String countryCode){
        for (Country__c c : SelectableCountryList){
            if (c.iso3166Alpha2__c.equals(countryCode)){
                getLead().Onboarding_Country__c = c.Id;
                break;
            }
        }
    }

    public ApexPages.StandardController controller {
        get;
        set;
    }


    public Lead getLead() {
        return (Lead) controller.getRecord();
    }

    public void setLead(Lead lead) {
        getLead().Partner_Onboarding_Status__c = lead.Partner_Onboarding_Status__c;
        getLead().Partner_Type__c = lead.Partner_Type__c;
        getLead().Account__c = lead.Account__c;
        getLead().Partner_Type__r = lead.Partner_Type__r;
        getLead().Is_Primary_Public_Sector__c = lead.Is_Primary_Public_Sector__c;
        getLead().Public_Sector_Market__c = lead.Public_Sector_Market__c;
        getLead().Company = lead.Company;
        getLead().Street = lead.Street;
        getLead().City = lead.City;
        getLead().State = lead.State;
        getLead().Country = lead.Country;
        getLead().PostalCode = lead.PostalCode;
        getLead().Global_Region__c = lead.Global_Region__c;
        getLead().Subregion__c = lead.Subregion__c;
        getLead().RHNLogin__c = lead.RHNLogin__c;
        getLead().Other_Countries__c = lead.Other_Countries__c;
        if (lead.Onboarding_Language_Preference__c != null) {
            getLead().Onboarding_Language_Preference__c = lead.Onboarding_Language_Preference__c;
        }
    }

    public String CurrentPageName {
        set;
        get;
    }

    public String LeadCompanyName {
        set;
        get;
    }

    public Boolean isCorporateUser {
        set;
        get;
    }

    public Integer CurrentStep {
        get {
            return new Map<String, Integer> {
                'Login' => 1,
                'Onboarding_RegisterPartner' => 2,
                'JoinOrRegister' => 2,
                'JoinConfirm' => 4,
                'JoinThankYou' => 99,

                'RegisterPartner' => 3,
                'RegisterAgreements' => 3,
                'RegisterProfile' => 4,
                'RegisterDemographics' => 4,
                'RegisterThankYou' => 99,

                null => 1
            }.get(currentPageName);
        }
    }

    //
    // Accessors
    //

    public Boolean AgreementsAccepted {
        set;
        get;
    }

    public String agreementAcceptence {
        set;
        get;
    }

    public PartnerStatus__c joinStatus {
        set;
        get;
    }

    public List<Country__c> SelectableCountryList {
        set;
        get;
    }

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

    public Classification__c PartnerTierReady {
        set;
        get;
    }

    public Classification__c PartnerTierAffiliated {
        set;
        get;
    }

    public Classification__c PartnerTypeRegionalSI {  //US26401
        set;
        get;
    }

    public Classification__c PartnerTypeCloudProvider {
        set;
        get;
    }

    public Classification__c SelectedPartnerType {
        get {
            if (getLead().Partner_Type__c == PartnerTypeISV.Id)
                return PartnerTypeISV;
            if (getLead().Partner_Type__c == PartnerTypeTraining.Id)
                return PartnerTypeTraining;
            if (getLead().Partner_Type__c == PartnerTypeReseller.Id)
                return PartnerTypeReseller;
            if (getLead().Partner_Type__c == PartnerTypeCorporateReseller.Id)
                return PartnerTypeCorporateReseller;
            if (getLead().Partner_Type__c == PartnerTypeOEM.Id)
                return PartnerTypeOEM;
            if (getLead().Partner_Type__c == PartnerTypeSI.Id)
                return PartnerTypeSI;
            if (getLead().Partner_Type__c == PartnerTypeDistributor.Id)
                return PartnerTypeDistributor;
//            if (getLead().Partner_Type__c == PartnerTypeOEM.Id)
//                return PartnerTypeOEM;
            if (getLead().Partner_Type__c == PartnerTypeRegionalSI.Id)  //US26401
                  return PartnerTypeRegionalSI;
//            if (getLead().Partner_Type__c == PartnerTypeCloudProvider.Id)  //US45477
//                  return PartnerTypeCloudProvider;

            return null;
        }
    }

    public String PartnerGeneralIssuesRecordTypeId {
        set;
        get;
    }

    public String Language {
        set;
        get;
    }

    public String LanguageCode {
        set;
        get;
    }

    public String FederationId {
        set;
        get;
    }

    public String partnerInviteId {
        get;
        set;
    }

    public Case OnboardingCase {
        set;
        get;
    }


    public String getDebugParams() {
        String params = '';

        for(String name : ApexPages.currentPage().getParameters().keySet())
            params += name + '=' + ApexPages.currentPage().getParameters().get(name) + '&';

        return params;
    }

    public String OnboardingType {
        set;
        get;
    }

    public Boolean getIsJoinOnlyFlow(){
        return getLead().Partner_Type__c == PartnerTypeSI.Id || getLead().Partner_Type__c == PartnerTypeOEM.Id || getLead().Partner_Type__c == PartnerTypeTraining.Id;
    }

    public Boolean getIsSIorOEMorTraining() {
    	return getIsEmailValidated();
    }

    public Boolean getIsEmailValidated(){
        return  getLead().Partner_Type__c == PartnerTypeSI.Id ||
                getLead().Partner_Type__c == PartnerTypeOEM.Id ||
                getLead().Partner_Type__c == PartnerTypeTraining.Id; // ||
//                getLead().Partner_Type__c == PartnerTypeCloudProvider.Id;
    }

    public Boolean getIsCCP(){
        system.debug('PARTNER TYPE: ' + getLead().Partner_Type__c);
        //return  getLead().Partner_Type__c == PartnerTypeCloudProvider.Id;
        return false;
    }

    public Boolean getIsJoinFlow(){
        return OnboardingType == ONBOARDING_TYPE_JOIN;
    }

    //
    // All of the describes are done up front, in a single exection. We are currently using
    // up 8 of 10 available getDescribe() calls.
    //

    public static final Map<String, List<Schema.PicklistEntry>> PICKLIST_ENTRIES = new Map<String, List<Schema.PicklistEntry>> {
        'Additional_Countries_Of_Operations__c' => Lead.Additional_Countries_Of_Operations__c.getDescribe().getPicklistValues(),
        'Additional_Partnerships__c' => Lead.Additional_Partnerships__c.getDescribe().getPicklistValues(),
        'Application_Types__c' => Lead.Application_Types__c.getDescribe().getPicklistValues(),
        'Industry_Focus__c' => Lead.Industry_Focus__c.getDescribe().getPicklistValues(),
        'Middleware_Supported__c' => Lead.Middleware_Supported__c.getDescribe().getPicklistValues(),
        'Operating_System_Supported__c' => Lead.Operating_System_Supported__c.getDescribe().getPicklistValues(),
        'Software_Focus__c' => Lead.Software_Focus__c.getDescribe().getPicklistValues(),
        'Target_Market_Size__c' => Lead.Target_Market_Size__c.getDescribe().getPicklistValues(),
        'Public_Sector_Market__c' => Lead.Public_Sector_Market__c.getDescribe().getPicklistValues()
    };

    //
    // Handle the onboarding process as an extension.
    //

    public OnboardingController(ApexPages.StandardController controller) {
        this.controller = controller;
        LeadCompanyName = getParam(PARAM_COMPANY);
        if (LeadCompanyName == null || LeadCompanyName.equals('')){
            LeadCompanyName = getParam(PARAM_PARTNER_NAME) != null ? getParam(PARAM_PARTNER_NAME) : '';
        }

        // Make sure the current request has a federation-id parameter
        // If not, send them to the rh.com login page
        FederationId = getParam(PARAM_FEDERATION_ID);
        if (federationId == null) {
            CurrentPageName = 'Login';
            return;
        }

        String customerType = getParam(PARAM_CUSTOMER_TYPE);
        if (customerType != null && (customerType == 'P' || customerType == 'p')) {
            isCorporateUser = false;
        }
        else {
            if (customerType == null) {
                // not provided
                if (LeadCompanyName.length() == 0) {
                    isCorporateUser = false;
                }
            }
            else {
                isCorporateUser = true;
            }
        }

        LanguageCode = getParam(PARAM_LANGUAGE);
        if (LanguageCode == null) {
            LanguageCode = 'en';
        }
        Language = getLocalePicklistName(LanguageCode, null);

        //
        // Copy the RHN information to the lead
        //

        getLead().FirstName = getParam(PARAM_FIRST_NAME);
        getLead().LastName = getParam(PARAM_LAST_NAME);
        getLead().Email = getParam(PARAM_EMAIL);
        getLead().Salutation = getParam(PARAM_SALUTATION);
        getLead().Company = getParam(PARAM_COMPANY);
        getLead().RHNLogin__c = federationId;
        getLead().Onboarding_Language_Preference__c = LanguageCode;

        //
        // Load the countries and states
        //

        SelectableCountryList = [
            select Name, Abbreviation__c, Global_Region__c, Country_Name__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c, Supported_Specialized_Partner_Types__c, SearchByVAT__c
         , (select Name, Abbreviation__c from States__r order by Name asc)
              from Country__c order by Name asc
        ];

        //
        // Load the partner type objects
        //

        List<Classification__c> types = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c in (:HKEY_ISV, :HKEY_OEM, :HKEY_DISTRIBUTOR, :HKEY_TRAINING, :HKEY_SI, :HKEY_RESELLER, :HKEY_CORPORATE_RESELLER,
                :HKEY_REGIONAL_SI) //, :HKEY_CLOUD_PROVIDER)
        ];

        for (Classification__c cfn : types){
            if (cfn.HierarchyKey__c == HKEY_ISV){
                PartnerTypeISV = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_OEM){
                PartnerTypeOEM = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_DISTRIBUTOR){
                PartnerTypeDistributor = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_SI){
                PartnerTypeSI = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_TRAINING){
                PartnerTypeTraining = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_RESELLER){
                PartnerTypeReseller = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_CORPORATE_RESELLER){
                PartnerTypeCorporateReseller = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_REGIONAL_SI){ //US26401
                PartnerTypeRegionalSI = cfn;
            } else if (cfn.HierarchyKey__c == HKEY_CLOUD_PROVIDER) {
       //         PartnerTypeCloudProvider = cfn;
            }
        }

        PartnerTierReady = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c = :HKEY_TIER_READY
             limit 1
        ];

        PartnerTierAffiliated = [
            select Name,
                    HierarchyKey__c
              from Classification__c
             where HierarchyKey__c = :HKEY_TIER_AFFILIATED
             limit 1
        ];

        //
        // Load other helpful data
        //

        PartnerGeneralIssuesRecordTypeId = [
            select id
              from RecordType
             where sObjectType = 'Case'
               and Name = 'Partner General Issues'
        ].id;

        //
        // Determine the initial action
        //
        processInitialAction();
    }

    //
    // Helper methods
    //

    public List<SelectOption> SelectableCountryOptions {
        get {
            return getSelectableCountryOptionsForLang();
        }
    }

    public List<SelectOption> getSelectableCountryOptionsForLang(){
            List<SelectOption> countryOptionList = new List<SelectOption>();

            Map<String, String> countryNames = new Map<String,String>();
            for(CountryTranslation__c cT: [select LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c
                                            from CountryTranslation__c where LanguageCode__c = :LanguageCode]){

                countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
            }

            for(Country__c country : SelectableCountryList){
                String name = country.Name;
                if (countryNames.get(country.Iso3166Alpha2__c) != null){
                    name = countryNames.get(country.Iso3166Alpha2__c);
                }
                countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
            }

            // Add a "None" option to the country list
            countryOptionList.add( new SelectOption('None','None') );

            return countryOptionList;
    }

    public List<SelectOption> SelectableStateOptions {
        get {
            List<SelectOption> stateOptionList = new List<SelectOption>();

            for(Country__c country : SelectableCountryList) {
                if (getLead().Country != country.Abbreviation__c)
                    continue;

                // add all of the states
                for(State__c state : country.States__r)
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));

                break;
            }

            return stateOptionList;
        }
    }

    public Integer SelectableStateOptionsSize {
        get {
            return SelectableStateOptions.size();
        }
    }

    private void processInitialAction() {
        if (!(handleExistingCase()
                || handleExistingUser()
                || handleExistingInvite()
                || handleExistingLead()
                || handleExistingContact())) {
            CurrentPageName = 'RegisterPartner';
        }
    }

    public PageReference processRedirects() {
        if (CurrentPageName == 'RedirectToPRM') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/protected/federate.html');
            updateUserFields();
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'RedirectToJoinAccept') {
            PageReference pageReference = new PageReference('/partner/apex/PartnerUserResponsePage?invitationid=' + partnerInviteId);
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'Login') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
            pageReference.getParameters().put('redirect', '/wapps/sfconnector/protected/partner.html');
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'BackToRedHat') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name);
            pageReference.setRedirect(true);
            return pageReference;
        }

        // return no page reference if the current page is not a redirect
        return null;
    }

    private Boolean handleExistingInvite() {
        Integer existingInvites = [
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
        }
        return false;
    }

    private Boolean handleExistingLead() {
        Integer existingLeads = [
            select count()
              from Lead
             where RHNLogin__c = :FederationId
               and RecordType.name = 'Partner Onboarding'
               and partner_onboarding_status__c in ('Rejected', 'Submitted', 'Pending', 'Pending Data Review')
        ];
        if (existingLeads > 0) {
            //  get the most recent onboarding lead for this federationID
            Lead lead = [
                select id
                     , partner_onboarding_status__c
                     , partner_type__c
                     , partner_type__r.Name
                     , account__c
                     , company
                     , street
                     , city
                     , state
                     , country
                     , postalCode
                     , global_region__c
                     , subregion__c
                     , RHNLogin__c
                     , Is_Primary_Public_Sector__c
                     , Public_Sector_Market__c
                     , Other_Countries__c
                     , Onboarding_Language_Preference__c
                  from lead
                 where RHNLogin__c = :FederationId
                   and RecordType.name = 'Partner Onboarding'
              order by createdDate desc
                 limit 1
            ];
            if (lead.partner_onboarding_status__c != 'Approved') {
                setLead(lead);
                CurrentPageName = 'DisplayLeadStatus';
                return true;
            }
        }
        return false;
    }

    private String getLocalePicklistName(String localeCode, String defaultName) {
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

    /**
     * We should catch both cases where Partner's have a requal request pending
     * for ALL users of an account, and for the situation where a particular user
     * has a requal case pending
    **/
    private Boolean handleExistingCase() {
        User user = getUserWithFederationId();
        String actId = '';
        if (user != null){
            actId = user.Contact.AccountId;
        }
        Integer existingCases = [
            select count()
              from Case
             where recordType.name = 'Partner General Issues'
               and ((redhatLoginName__c = :FederationId
                    and issue_type_classification__c = 'Partner Onboarding')
                or (issue_type_classification__c = 'Requalification Access Request'
                    and AccountId = :actId))
        ];
        if (existingCases > 0) {
            //  get the most recent partner onboarding case for this federationID
            OnboardingCase = [
               select id
                    , issue_type__c
                    , status
                    , caseNumber
                 from Case
                where recordType.name = 'Partner General Issues'
                  and ((redhatLoginName__c = :FederationId
                    and issue_type_classification__c = 'Partner Onboarding')
                or (issue_type_classification__c = 'Requalification Access Request'
                    and AccountId = :actId))
             order by createdDate desc
                limit 1
            ];

            if (OnboardingCase.Status != 'Closed') {
                // setup the case so that the DisplayCaseStatus page can see it
                CurrentPageName = 'DisplayCaseStatus';
                return true;
            }
        }
        return false;
    }


    private Boolean handleExistingUser() {
        User user = getUserWithFederationId();
        if (user != null) {
            if (user.isActive) {
                CurrentPageName = 'RedirectToPRM';
            } else {
                CurrentPageName = 'ErrorUserIsInactive';
            }
            return true;
        }
        return false;
    }

    private void updateUserFields(){
        User user = getUserWithFederationId();
        String code = getLanguageLocaleCode(user);
        if (user.LanguageLocaleKey != code) {
            user.LanguageLocaleKey = code;
            updateUserLocaleKey(user.Id, code);
        }
        postOnboardingUpdates(user.AccountId, user.id, user.Contact.Id);
    }

    @future
    private static void postOnboardingUpdates(Id accountId, Id userId, Id contactId){
        // Post onboarding updates
        Account a = [select PrimaryPartnerUser__c from Account where id = :accountId];
        if (a.PrimaryPartnerUser__c == null){
            a.PrimaryPartnerUser__c = userId;
            update a;
            try {
                NFR_Request__c nfr = [select id, ownerid, Contact_at_Partner__c from NFR_Request__c where Contact_at_Partner__c = :contactId and ownerid != :userId];
                nfr.ownerid = userId;
                update nfr;
            } catch (System.QueryException qE){
                System.debug('Error loading query ' + qE.getMessage());
            }
        }
    }

    private static void updateUserLocaleKey(Id userId, String localeKey){
        User user = new User(Id = userId);
        user.LanguageLocaleKey = localeKey;
        if (!test.isRunningTest()) {
            update user;
        }
    }

    private static boolean isValidLocale(String localeKey, List<Schema.PicklistEntry> locales) {
        for (Schema.PicklistEntry locale : locales) {
            if (locale.getValue() == localeKey) {
                return true;
            }
        }
        return false;
    }

    private String getLanguageLocaleCode(User user) {
        Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.LanguageLocaleKey;
        List<Schema.PicklistEntry> locales = f.getPicklistValues();
        if (isValidLocale(LanguageCode, locales)) {
            return LanguageCode;
        }
        String localeKey = LanguageCode;
        if (user.Contact.MailingCountry == null || user.Contact.MailingCountry.length() != 2) {
            if (user.Contact.Account.BillingCountry != null && user.Contact.Account.BillingCountry.length() == 2) {
                localeKey = LanguageCode + '_' + user.Contact.Account.BillingCountry;
            }
            else {
                System.debug('** Valid country not found.  This should never happen');
                return 'en_US';
            }
        }
        else {
            localeKey = LanguageCode + '_' + user.Contact.MailingCountry;
        }
        if (!isValidLocale(localeKey, locales)) {
            if (localeKey.startsWith('zh')){
                localeKey = 'zh_CN';
            }
            if (!isValidLocale(localeKey, locales) && localeKey.startsWith('pt')){
                localeKey = 'pt_BR';
            }
            if (!isValidLocale(localeKey, locales)) {
                localeKey = 'en_US';
            }
        }
        return localeKey;
    }

    private Boolean handleExistingContact() {
        Contact contact = getContactWithFederationId();
        if (contact != null) {
            CurrentPageName = 'ErrorUserIsMissing';
            return true;
        }
        return false;
    }

    private User getUserWithFederationId() {
        User user = null;
        if (FederationId != null && [select count() from User where FederationIdentifier = :FederationId] > 0) {
            user = [
                select id
                     , Name
                     , IsActive
                     , FederationIdentifier
                     , contactId
                     , contact.accountId
                     , migratedOverride__c
                     , LanguageLocaleKey
                     , Contact.Id
                     , Contact.MailingCountry
                     , Contact.Account.BillingCountry
                     , Contact.Account.PartnerStatuses__c
                     , AccountId
                     , ConsumerUserCreated__c
                  from User
                 where FederationIdentifier = :FederationId
                   and profile.name like '%Partner Portal%'
                   and isPortalEnabled = true
                   and ContactId != null
                 limit 1
            ];
            if (user != null && (
                user.Contact.Account.PartnerStatuses__c == null ||
                user.Contact.Account.PartnerStatuses__c == '' ||
                user.Contact.Account.PartnerStatuses__c.toLowerCase().contains('unaffiliated -'))){
                user.IsActive = false;
            }
        }
        return user;
    }

    private Contact getContactWithFederationId() {
        Contact contact = null;
        if (federationId != null && [select count() from Contact where LoginName__c = :FederationId and Contact.Account.IsPartner = true] > 0) {
            contact = [
                select id
                     , LoginName__c
                     , AccountId
                     , Name
                     , Account.BillingCountry
                  from Contact
                 where LoginName__c = :FederationId
                        and Contact.Account.IsPartner = true
                 limit 1
            ];
        }
        return contact;
    }

    //
    // Page helpers
    //

    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }

    public static void addMessage(String message, ApexPages.Severity severity) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    public static void addErrorMessage(String message) {
        if (message == null) return;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    public static void addExceptionMessage(Exception pageException) {
        if (pageException == null) return;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Caught Exception: ' + pageException));
    }

    public Boolean getHasErrorMessages() {
        if (test.isRunningTest()) {
            return false;
        } else {
            return ApexPages.hasMessages(ApexPages.Severity.ERROR);
        }
    }

    //
    // Search for existing / similar partner names
    //

    public List<PartnerStatus__c> getExistingPartnerList() {
        try {
            //
            // Parse out the URL string
            //

            String partnerName = getLead().Company;
            partnerName = partnerName == null ? '' : EncodingUtil.urlDecode(partnerName, 'UTF-8');
            partnerName = partnerName.replace(' ', '%');
            partnerName = partnerName.replace('*', '%');
            partnerName = '%' + partnerName + '%';
            partnerName = partnerName.replace('%%', '%');

            if (partnerName == '%')
                return new List<PartnerStatus__c>();

            //
            // Fetch the partner statuses
            //
            //Id typeISV = [select id from classification__c where hierarchykey__c = 'PARTNER_TYPE.ISV'].id;
            //Id typeReseller = [select id from classification__c where hierarchykey__c = 'PARTNER_TYPE.RESELLER'].id;
            List<Classification__c> clfnList = [select id from classification__c where hierarchykey__c like 'PARTNER_TIER.UNAFFILIATED%'];
            List<Id> unaffiliated = new List<Id>();
            for (Classification__c clfn : clfnList) unaffiliated.add(clfn.Id);

            if (getIsEmailValidated()){
                // We are joining a Global SI, Training, OEM, or Service/Cloud Provider
                String email = getLead().Email;
                String domain = '%' + email.substring(email.indexOf('@') + 1, email.length()).toLowerCase() + '%';

                String region = 'NA';
                for(Country__c country : SelectableCountryList) {
                    if (country.Abbreviation__c == getLead().Country){
                        region = country.Global_Region__c;
                        break;
                    }
                }

                return [
                    select PartnerType__r.Name
                         , Partner__r.Primary__c
                         , Partner__r.Name
                         , Partner__r.Account_Alias_Name__c
                         , Partner__r.AliasPublicViewable__c
                         , Partner__r.BillingStreet
                         , Partner__r.BillingCity
                         , Partner__r.BillingState
                         , Partner__r.BillingPostalCode
                         , Partner__r.BillingCountry
                         , Partner__r.PrimaryPartnerUser__c
                         , Partner__r.OwnerId
                         , Partner__r.Global_Region__c
                         , Partner__r.Subregion__c
                         //, Partner__r.AllowedEmailDomains__c
                      from PartnerStatus__c
                     where
                       (
                          Partner__r.Primary__c in ('OEM', 'SI', 'Training', 'Service/Cloud Provider')
                          and
                          Partner__r.AllowedEmailDomains__c like :domain
//                        and
//                        Partner__r.Global_Region__c = :region
                          and
                          (
                              Partner__r.Name like :partnerName
                              or (
                                 Partner__r.Account_Alias_Name__c like :partnerName
                                 and Partner__r.AliasPublicViewable__c = True
                              )
                          )
                       )
                       and ActivationStatus__c = 'Active'
                       and PartnerType__c = :getLead().Partner_Type__c
                       and PartnerTier__c not in :unaffiliated
                  order by Partner__r.Name asc, PartnerType__r.Name asc
                     limit 1000
                ];
            } else {
                return [
                    select PartnerType__r.Name
                         , Partner__r.Name
                         , Partner__r.Account_Alias_Name__c
                         , Partner__r.AliasPublicViewable__c
                         , Partner__r.BillingStreet
                         , Partner__r.BillingCity
                         , Partner__r.BillingState
                         , Partner__r.BillingPostalCode
                         , Partner__r.BillingCountry
                         , Partner__r.PrimaryPartnerUser__c
                         , Partner__r.OwnerId
                         , Partner__r.Global_Region__c
                         , Partner__r.Subregion__c
                      from PartnerStatus__c
                     where
                       (
                          Partner__r.Name like :partnerName
                          or (
                             Partner__r.Account_Alias_Name__c like :partnerName
                             and Partner__r.AliasPublicViewable__c = True
                          )
                       )
                       and ActivationStatus__c = 'Active'
                       and PartnerType__c = :getLead().Partner_Type__c
                       and PartnerTier__c not in :unaffiliated
                  order by Partner__r.Name asc, PartnerType__r.Name asc
                     limit 1000
                ];
            }
        } catch (System.DmlException dmlException) {
            addExceptionMessage(dmlException);
        } catch (System.QueryException queryException) {
            addExceptionMessage(queryException);
        }

        return new List<PartnerStatus__c>();
    }

    public List<PartnerStatus__c> getMatchingVATPartnerList() {
        try {
            if (VATNumber == null || VATNumber == '')
                return new List<PartnerStatus__c>();

            //
            // Fetch the partner statuses
            //
            List<Classification__c> clfnList = [select id from classification__c where hierarchykey__c like 'PARTNER_TIER.UNAFFILIATED%'];
            List<Id> unaffiliated = new List<Id>();
            for (Classification__c clfn : clfnList) unaffiliated.add(clfn.Id);

            return [
                select PartnerType__r.Name
                     , Partner__r.Name
                     , Partner__r.VATNumber__c
                     , Partner__r.Account_Alias_Name__c
                     , Partner__r.AliasPublicViewable__c
                     , Partner__r.BillingStreet
                     , Partner__r.BillingCity
                     , Partner__r.BillingState
                     , Partner__r.BillingPostalCode
                     , Partner__r.BillingCountry
                     , Partner__r.PrimaryPartnerUser__c
                     , Partner__r.OwnerId
                     , Partner__r.Global_Region__c
                     , Partner__r.Subregion__c
                  from PartnerStatus__c
                 where
                   (
                      Partner__r.VATNumber__c = :VATNumber
                   )
                   and ActivationStatus__c = 'Active'
                   and PartnerType__c = :getLead().Partner_Type__c
                   and PartnerTier__c not in :unaffiliated
              order by Partner__r.Name asc, PartnerType__r.Name asc
                 limit 1000
            ];
        } catch (System.DmlException dmlException) {
            addExceptionMessage(dmlException);
        } catch (System.QueryException queryException) {
            addExceptionMessage(queryException);
        }

        return new List<PartnerStatus__c>();
    }

    //
    // Find all relevant agreements
    //
    public List<Agreement__c> getRelevantAgreementList() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        if (this.selectedCountry != null && getLead() != null && getLead().Partner_Type__c != null ) {
            system.assert(null != selectedCountry);
            system.assert(null != selectedCountry.id);
            system.assert(null != getLead().Partner_Type__c);

            // Here we are getting all the documents for a country.
            // We want all agreements for the Lead's preferred language and all non-specific ones
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                Select Agreement__c
                  From Agreement_Country__c
                 where Country__c = :this.selectedCountry.Id
                   and Agreement__r.PartnerType__c = :getLead().Partner_Type__c
                   and Agreement__r.ActivationStatus__c = 'Active'
                   and Agreement__r.Partner_Program__c = null
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }

            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                agreementList = [select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet];
            }

            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementList  = [
                    select Id
                         , Name
                         , IsSignatureRequired__c
                         , Version__c
                         , (select Name from Attachments)
                      from Agreement__c
                     where Country_Count__c = 0
                       and ActivationStatus__c = 'Active'
                       and PartnerType__c = :getLead().Partner_Type__c
                       and Partner_Program__c = null
            ];
            if (globalAgreementList != null && globalAgreementList.size() > 0) {
                for (Agreement__c globalAgreement :globalAgreementList) {
                    agreementList.add(globalAgreement);
                }
            }
        }

        if (agreementList != null && agreementList.size() > 0) {
            System.debug('Agreement List---------->::' + agreementList.size());
        }
        return agreementList;
    }

    //
    // Page References
    //

    public PageReference joinPartnerStart() {
        if (getParam('partner-status-id') == null) {
            addErrorMessage(Label.Onboarding_Controller_Error_Partner_Status_Id_missing);
        } else try {
            String partnerStatusId = getParam('partner-status-id');
            joinStatus = [
               select PartnerType__r.Name
                     , Partner__r.Name
                     , Partner__r.Account_Alias_Name__c
                     , Partner__r.AliasPublicViewable__c
                     , Partner__r.BillingStreet
                     , Partner__r.BillingCity
                     , Partner__r.BillingState
                     , Partner__r.BillingPostalCode
                     , Partner__r.BillingCountry
                     , Partner__r.PrimaryPartnerUser__c
                     , Partner__r.OwnerId
                     , Partner__r.Global_Region__c
                     , Partner__r.Subregion__c
                  from PartnerStatus__c
                 where id = :partnerStatusId
            ];

            //getLead().Other_Countries__c = getParam('company-other-country');
            currentPageName = 'JoinConfirm';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public PageReference searchByVAT() {

        return null;
    }

    public PageReference joinPartnerSubmit() {
        Savepoint pSavepoint = null;

        try {
            getLead().Partner_Type__c = joinStatus.PartnerType__c;
            getLead().Account__c = joinStatus.Partner__c;
            getLead().Company = joinStatus.Partner__r.Name;
            getLead().Street = joinStatus.Partner__r.BillingStreet;
            getLead().City = joinStatus.Partner__r.BillingCity;
            getLead().State = joinStatus.Partner__r.BillingState;
            getLead().Country = joinStatus.Partner__r.BillingCountry;
            getLead().PostalCode = joinStatus.Partner__r.BillingPostalCode;
            getLead().Global_Region__c = joinStatus.Partner__r.Global_Region__c;
            getLead().Subregion__c = joinStatus.Partner__r.Subregion__c;
            pSavepoint = Database.setSavepoint();
            insertOnboardingLead();
            currentPageName = 'JoinThankYou';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
            addErrorMessage(Label.Onboarding_Controller_Error_Lead_Values + ' ' + getLead());
            Database.rollback(pSavepoint);
        }

        return null;
    }

    public PageReference joinPartnerCancel() {
        try {
            getLead().Company = LeadCompanyName;
            getExistingPartnerList();
            currentPageName = 'JoinOrRegister'; // back to the beginning
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    //
    // Onboarding_RegisterPartner
    //

    public PageReference registerPartnerStart() {
        try {
            if (getLead().Country == null){
                currentPageName = 'RegisterPartner';
            } else {
                checkAgreementsSetRegion();
            }
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public PageReference registerPartnerSubmit() {
        if (getLead().Partner_Type__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Partner_Type);
        } else if (getLead().Country == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_Headquarters);
        } else if (OnboardingType == null || OnboardingType == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Onboarding_Type);
        } else try {
            if (getExistingPartnerList().size() != 0
                || selectedCountry.SearchByVAT__c
                || OnboardingType == ONBOARDING_TYPE_JOIN
                || SelectedPartnerType.HierarchyKey__c.endswith('TRAINING')
                || SelectedPartnerType.HierarchyKey__c.endswith('DISTRIBUTOR')
                || SelectedPartnerType.HierarchyKey__c.endswith('OEM')
                || SelectedPartnerType.HierarchyKey__c.endswith('.SI')) {                    //US26401 - changed to (dot) ".SI" instead of just "SI" since the new Classification is Regional_SI and we don't want Regional SI's to fall into this block
                CurrentPageName = 'JoinOrRegister';
            } else {
                checkAgreementsSetRegion();
            }
        } catch (Exception pageException) {
            addErrorMessage(Label.Onboarding_Controller_Partner_Type_Id + ' ' + getLead().Partner_Type__c);
            addErrorMessage(Label.Onboarding_Controller_Caught + ' ' + pageException);
        }

        return null;
    }

    public void checkAgreementsSetRegion(){
         // Find and insert the global region
         for(Country__c country : SelectableCountryList) {
                if (country.Abbreviation__c != getLead().Country)
                    continue;

                getLead().Global_Region__c = country.Global_Region__c;
                getLead().Subregion__c = country.Subregion__c;
                getLead().Country__c = country.Id;
                System.debug('this.selectedCountry.IsAgreementSignatureRequired__c :::::'+ this.selectedCountry.IsAgreementSignatureRequired__c);
                break;
         }
         List<Agreement__c> agreementList = getRelevantAgreementList();
         if (agreementList != null && agreementList.size() > 0) {
             currentPageName = 'RegisterAgreements';
         } else {
             currentPageName = 'RegisterProfile';
         }
    }

    public PageReference registerPartnerCancel() {
        try {
            getLead().Partner_Type__c = null;
            getLead().Country = null;
            currentPageName = 'JoinOrRegister'; // back to the beginning
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    //
    // Onboarding_RegisterAgreements
    //

    public PageReference registerAgreementsSubmit() {
        System.debug('Partner Agreement Accepted--------->::'+ agreementAcceptence);
        if (getRelevantAgreementList() == null) {
            addErrorMessage(Label.Onboarding_Controller_Error_No_Agreements_Available);
        } else if (agreementAcceptence == null ) {
            addErrorMessage(Label.Onboarding_Controller_Error_Please_Accept_or_Decline_T_Cs);
        } else {
            try {
                if (agreementAcceptence != null && agreementAcceptence.equalsIgnoreCase('Yes')) {
                    AgreementsAccepted = true;
                    declinedReason = null;
                }
                if ((agreementAcceptence != null && agreementAcceptence.equalsIgnoreCase('No')) &&
                    (declinedReason == null || declinedReason.length() < 5)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PRQ_RequalController_Reason_for_declining));
                    return null;
                }
                getLead().Reason_Agreements_Declined__c = declinedReason;
                currentPageName = 'RegisterProfile';
            } catch (Exception pageException) {
                System.debug('** MLS Exception');
                addExceptionMessage(pageException);
            }
        }

        if (customTerms == 'Yes') {
            getLead().HasCustomTerms__c = true;
            getLead().CustomTerms__c = customTermsText;
        }

        return null;
    }

    public PageReference registerAgreementsCancel() {
        try {
            AgreementsAccepted = false;
            currentPageName = 'RegisterPartner';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    //
    // Onboarding_RegisterProfile
    //

    public PageReference registerProfileSubmit() {
        if (getLead().Is_Primary_Public_Sector__c == null && getLead().Country == 'US') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Is_Primary_Public);
        }

        if (getLead().Street == '' || getLead().Street == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_Address);
        } else if (getLead().Street.length() > 255) {
            addErrorMessage(Label.Onboarding_Controller_Errror_Max_Size_Comany_Address);
        }

        if (getLead().City == '' || getLead().City == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_City);
        } else if (getLead().City.length() > 40) {
            addErrorMessage(Label.Onboarding_Controller_Error_Max_Size_Company_City);
        }

        if (getLead().State == null && SelectableStateOptionsSize != 0) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_State_Province);
        }

        if (getLead().PostalCode == '' || getLead().PostalCode == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_Postal_Code);
        } else if (getLead().PostalCode.length() > 20) {
            addErrorMessage(Label.Onboarding_Controller_Error_Max_Size_Postal_Code);
        }

        if (getLead().Phone == '' || getLead().Phone == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Phone);
        } else if (getLead().Phone.length() > 40) {
            addErrorMessage(Label.Onboarding_Controller_Error_Max_Size_Phone);
        }

        if (getLead().Website == '' || getLead().Website == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Website);
        } else if (getLead().Website.length() > 255) {
            addErrorMessage(Label.Onboarding_Controller_Error_Max_Size_Website);
        }

        //Additional_Countries_Of_Operations__c
        if (getLead().Additional_Countries_Of_Operations__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Additional_Countries_Of_Operations);
        }

        if (getLead().Industry_Focus__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Industry_Focus);
        }
        if (getLead().Do_they_act_in_any_government_position__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Government_Position);
        }
        if (getLead().Have_they_been_convicted__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Conviction_Status);
        }
        if ((getLead().VATNumber__c == null || getLead().VATNumber__c.length() == 0) && selectedCountry.SearchByVAT__c) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_VAT_Required);
        }
        if ((getLead().Do_they_act_in_any_government_position__c == 'Yes' || getLead().Have_they_been_convicted__c == 'Yes') && (getLead().FCPA_Underlying_Facts__c == '' || getLead().FCPA_Underlying_Facts__c == null)) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_RegisterProfile_Underlying_Facts);
        }

        if (!getHasErrorMessages()) {
            if (getLead().Is_Primary_Public_Sector__c != null && getLead().Is_Primary_Public_Sector__c == 'Yes') {
                getLead().Subregion__c = 'Fed Sled';
                currentPageName = 'RegisterDemographics';
            }
            else {
                try {
                    // Override the subregion if the selected state has a specified subregion.
                    List<State__c> stateList = [
                        select Subregion__c
                          from State__c
                         where Abbreviation__c = :getLead().State
                           and Country__r.Abbreviation__c = :getLead().Country
                           and Subregion__c != null
                    ];

                    if (stateList.size() != 0)
                        getLead().Subregion__c = stateList[0].Subregion__c;

                    currentPageName = 'RegisterDemographics';
                } catch (Exception pageException) {
                    addExceptionMessage(pageException);
                }
            }
        }
        else {
            for (ApexPages.Message msg : ApexPages.getMessages()) {
                System.debug('--- ' + msg);
            }
        }
        return null;
    }

    public PageReference registerProfileCancel() {
        List<Agreement__c> agreementList = getRelevantAgreementList();
        if (agreementList != null && agreementList.size() > 0) {
            currentPageName = 'RegisterAgreements';
        } else {
            currentPageName = 'RegisterPartner';
        }

        return null;
    }

    //
    // Onboarding_RegisterDemographics
    //

    public PageReference registerDemographicsSubmit() {
        Savepoint pSavepoint = null;

        if (getLead().Company_Description__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Company_Desc);
        } else if (getLead().Company_Description__c.length() > 2000) {
            addErrorMessage(Label.Onboarding_Controller_Error_Max_Length_Company_Desc + ' ' + getLead().Company_Description__c.length() + ' ' + Label.Onboarding_Controller_Error_Max_Length_Company_Desc);
        }
        if (getLead().Number_of_Employees__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Num_Employees);
        }
        if (getLead().Total_Annual_Revenue__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Total_Rev);
        }
        if (getLead().Target_Market_Size__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Target_Market_Size);
        }
        if (getLead().Software_Focus__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Software_Platform);
        }
        if (getLead().Operating_System_Supported__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_OS_Expertese);
        }
        if (getLead().Middleware_Supported__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Middleware_Supported);
        }
        if (getLead().Application_Types__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_App_Types);
        }
        if (getLead().Additional_Partnerships__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + Label.Onboarding_Controller_Additional_Partnerships);
        }
        if (!getHasErrorMessages()) {
            try {
                pSavepoint = Database.setSavepoint();
                insertOnboardingLead();
                currentPageName = 'RegisterThankYou';
            } catch (Exception pageException) {
                addExceptionMessage(pageException);
                Database.rollback(pSavepoint);
            }
        }
        else {
            for (ApexPages.Message msg : ApexPages.getMessages()) {
                System.debug('--- ' + msg);
            }
        }

        return null;
    }

    public PageReference registerDemographicsCancel() {
        try {
            currentPageName = 'RegisterProfile';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public void insertOnboardingLead() {
        Profile p = PartnerUtil.onboardingProfileByClassificationId(getLead().Global_Region__c, getLead().Partner_Type__c);
        System.debug('Partner Global Region: ' + getLead().Global_Region__c);
        System.debug('Partner Type: ' + getLead().Partner_Type__c);
        // Mark as submitted and set the proper profile and record type.
        getLead().Partner_Onboarding_Status__c = 'Submitted';
        getLead().Partner_Onboarding_Profile__c = p.Name;
        getLead().Onboarding_Profile_Id__c = p.Id;
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
             where Name = 'Partner Onboarding'
               and SObjectType = 'Lead'
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

            if (getLead().Country != null) {
                accountTeamQuery += ' and (Country__c = null or Country__r.Abbreviation__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Country);
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

        // Push it
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
        if (getLead().Account__c == null) {
            List<PartnerAgreement__c> partnerAgreementList = new List<PartnerAgreement__c>();
            List<Agreement__c> agreementList = getRelevantAgreementList();
            if (agreementList != null && agreementList.size() > 0) {
            for(Agreement__c agreement : getRelevantAgreementList()) {
                PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
                partnerAgreement.Agreement__c = agreement.Id;
                partnerAgreement.PartnerLead__c = getLead().Id;
                partnerAgreement.ActivationDate__c = Date.today();

                if (AgreementsAccepted == true)
                    partnerAgreement.PartnerApprovalStatus__c = 'Approved';
                else
                    partnerAgreement.PartnerApprovalStatus__c = 'Declined';

                partnerAgreementList.add(partnerAgreement);
            }
                 insert partnerAgreementList;
            } else {
                Lead l = new Lead(id=getLead().id);
                l.No_Agreements__c = true;
                update l;
            }

        }

        //
        // handle joins for SI, OEM, Training accounts, Service/Cloud Providers
        //
        if (getLead().Account__c != null && getIsEmailValidated()) {
            //PartnerEmailUtils.generateTokenURL(getLead().Id, getLead().email);
//            PartnerEmailUtils.sendLeadEmail(getLead().Id, getLead().email);
        }
        else {
            // handle all new account onboarding
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Submitting request for approval.');
            approvalRequest.setObjectId(getLead().Id);

            // Ensure the approval was submitted properly
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            system.assert(approvalResult.isSuccess(), approvalResult.getErrors());
            //OnboardingExecuteConversion.submitLeadForApprovalFuture(getLead().Id);
        }
    }

    public PageReference activateUserSubmit() {
        User user = getUserWithFederationId();
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Activation Request'
                , user.Name + ' has requested to be activated as a partner user'
                , 'This request might require clearing out the Federation ID field of an existing User record.'
                , user.contactId
                , user.contact.AccountId);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }

    public PageReference joinNoPartnerFoundSubmit() {
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Join Problem'
                , getLead().FirstName + ' ' + getLead().LastName + ' with email ' + getLead().Email + ' is trying to join a company named ' + getLead().Company
                , 'There is no accounts that match this company name, we may need to update their redhat.com user record with the right company name.'
                , null
                , null);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }

    public PageReference activateUserCancel() {
        CurrentPageName = 'BackToRedHat';
        return processRedirects();
    }

    public PageReference convertContactSubmit() {
        // this might end up being code that actually converts the user
        // if that's so, where do we send them?  I guess to be federated
        // for now, create a case and submit it

        Contact contact = getContactWithFederationId();
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Creation Request'
                , contact.Name + ' has requested to be converted to a partner user'
                , 'To convert the contact to a partner user, click the Contact Name associated with this case. ' +
                  'Then, click the "Enable Partner User" button on the Contact.'
                , contact.Id
                , contact.AccountId);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }

    public PageReference convertContactCancel() {
        CurrentPageName = 'BackToRedHat';
        return processRedirects();
    }

    private Case createPartnerOnboardingCase(String federationId, String issueType, String subject, String description,
                String contactId, String accountId) {

        Case c = new Case();

        if (getLead() != null && getLead().Country != null && getLead().Country != ''){
            System.debug('*****[debug]***** lead.country=' + getLead().Country);
            Country__c country = [select Abbreviation__c, Global_Region__c, Country_Name__c
                from Country__c where Abbreviation__c = :getLead().Country];
            c.Region__c = country.Global_Region__c;
            c.Country__c = country.Country_Name__c;
        }
        else {
            if (selectedCountry != null) {
                System.debug('*****[debug]***** selected.country=' + selectedCountry.Country_Name__c);
                c.Region__c = selectedCountry.Global_Region__c;
                c.Country__c = selectedCountry.Country_Name__c;
            }
            else {
                System.debug('*****[debug]***** no country found');
            }
        }

        c.RecordTypeId = PartnerGeneralIssuesRecordTypeId;
        c.Issue_Type_Classification__c = 'Partner Onboarding';
        c.Issue_Type__c = issueType;
        c.Subject = subject;
        c.Description = description;
        c.Origin = 'Portal';
        c.RedHatLoginName__c = federationId;
        c.Status = 'New';
        c.Priority = 'Medium';

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

    //
    // Multi-select picklist conversion
    //

    public List<String> getSplitPicklistField(String values) {
        return values == null ? new List<String>() : values.split(';');
    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList)
            selectOptionList.add(new SelectOption(p.Value, p.Label));

        return selectOptionList;
    }

    public void setSelectOptionsValuesToField(String fieldName, List<String> valuesList) {
        String field = '';

        for(String value : valuesList) {
            if (field != '')
                field += ';';
            field += value;
        }

        getLead().put(fieldName, field);
    }

    // Industry focus

    public List<SelectOption> getIndustryFocusOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Industry_Focus__c'));
    }

    public List<SelectOption> getPublicSectorMarketOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Public_Sector_Market__c'));
    }

    public List<String> getPublicSectorMarket() {
        return getSplitPicklistField(getLead().Public_Sector_Market__c);
    }

    public void setPublicSectorMarket(List<String> valuesList) {
        setSelectOptionsValuesToField('Public_Sector_Market__c', valuesList);
    }

    public List<String> getIndustryFocus() {
        return getSplitPicklistField(getLead().Industry_Focus__c);
    }

    public void setIndustryFocus(List<String> valuesList) {
        setSelectOptionsValuesToField('Industry_Focus__c', valuesList);
    }

    // Additional Countries Of Operations

    public List<SelectOption> getAdditionalCountriesOfOperationsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Countries_Of_Operations__c'));
    }

    public List<String> getAdditionalCountriesOfOperations() {
        return getSplitPicklistField(getLead().Additional_Countries_Of_Operations__c);
    }

    public void setAdditionalCountriesOfOperations(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Countries_Of_Operations__c', valuesList);
    }

    // Target Market Size

    public List<SelectOption> getTargetMarketSizeOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Target_Market_Size__c'));
    }

    public List<String> getTargetMarketSize() {
        return getSplitPicklistField(getLead().Target_Market_Size__c);
    }

    public void setTargetMarketSize(List<String> valuesList) {
        setSelectOptionsValuesToField('Target_Market_Size__c', valuesList);
    }

    // Software Focus

    public List<SelectOption> getSoftwareFocusOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Software_Focus__c'));
    }

    public List<String> getSoftwareFocus() {
        return getSplitPicklistField(getLead().Software_Focus__c);
    }

    public void setSoftwareFocus(List<String> valuesList) {
        setSelectOptionsValuesToField('Software_Focus__c', valuesList);
    }

    // Operating System Supported

    public List<SelectOption> getOperatingSystemSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Operating_System_Supported__c'));
    }

    public List<String> getOperatingSystemSupported() {
        return getSplitPicklistField(getLead().Operating_System_Supported__c);
    }

    public void setOperatingSystemSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Operating_System_Supported__c', valuesList);
    }

    // Middleware Supported

    public List<SelectOption> getMiddlewareSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Middleware_Supported__c'));
    }

    public List<String> getMiddlewareSupported() {
        return getSplitPicklistField(getLead().Middleware_Supported__c);
    }

    public void setMiddlewareSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Middleware_Supported__c', valuesList);
    }

    // Application Types

    public List<SelectOption> getApplicationTypesOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Application_Types__c'));
    }

    public List<String> getApplicationTypes() {
        return getSplitPicklistField(getLead().Application_Types__c);
    }

    public void setApplicationTypes(List<String> valuesList) {
        setSelectOptionsValuesToField('Application_Types__c', valuesList);
    }

    // Additional Partnerships

    public List<SelectOption> getAdditionalPartnershipsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Partnerships__c'));
    }

    public List<String> getAdditionalPartnerships() {
        return getSplitPicklistField(getLead().Additional_Partnerships__c);
    }

    public void setAdditionalPartnerships(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Partnerships__c', valuesList);
    }

}