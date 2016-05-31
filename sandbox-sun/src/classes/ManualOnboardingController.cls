/****************************************************************************************
 Modification Log:
-----------------------------------------------------------------------------------------
 Developer              Date            Description
-----------------------------------------------------------------------------------------
 Jonathan Garrison      13-Apr-2015     Added support for Corporate Reseller (EMEA
                                        only) and Service/Cloud Provider partner
                                        types.
 Jonathan Garrison      05-May-2015     Added support for Distrubtors to manually
                                        onboard CCSP partners.
 Jonathan Garrison      14-May-2015     Updated page title for partners.
 Jonathan Garrison      18-May-2015     Updated CSSP Form page reference to distiguish
                                        between an internal and external version for
                                        styling differences.
 Jonathan Garrison      19-May-2015     Updated to set the proper owner of the
                                        onboarding record for manually onboarded
                                        SCP accounts.
 Jonathan Garrison      21-May-2015     Added firstName and lastName fields to be put
                                        on the onboarding record.
 Jonathan Garrison      22-May-2015     Modified first name and last name fields to only
                                        be required if onboarding an SCP.
 Jonathan Garrison      01-Jun-2015     Added language selection for SCP partners.
 Jonathan Garrison      29-Jun-2015     Added support to allow distributors to refer
                                        existing partners to CCSP.
 Jonathan Garrison      03-Aug-2015     Now setting the anti-corruption answers to
                                        Red Hat Created for all non-SCP manually
                                        onboarded accounts.
****************************************************************************************/
public with sharing class ManualOnboardingController {

    public String partnerType { get; set; }
    public String companyName { get; set; }
    public String address { get; set; }
    public String city { get; set; }
    public String country { get; set; }
    public String state { get; set; }
    public String language { get; set; }
    public String postalCode { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String companyEmail { get; set; }
    public String phone { get; set; }
    public String website { get; set; }
    public String region { get; set; }
    public String subregion { get; set; }
    public String selectedCountryName { get; private set; }
    public String pageTitle { get; private set; }
    public boolean isPublicSector { get; set; }
    public boolean disablePublicSector { get; private set; }
    public boolean hasDistributorProfile { get; private set; }
    public List<SelectOption> partnerTypeSelectionList { get; private set; }
    public List<SelectOption> countrySelectionList { get; private set; }
    public List<SelectOption> stateSelectionList { get; private set; }
    public List<SelectOption> languageSelectionList { get; private set; }
    public Partner_Onboarding_Registration__c partnerOnboardingRegistration { get; set; }
    public List<Country__c> selectableCountryList;
    private String oldCountry;
    private String retURL;
    private String referralType;
    public Boolean isPartnerUser {get; private set;}
    private Id distributorAccountId;
    private String subtype = '';

    private static final String NONE                    = '--None--';
    private static final String CORPORATE_RESELLER      = 'Corporate Reseller';
    private static final String DISTRIBUTOR             = 'Distributor';
    private static final String SI                      = 'SI';
    private static final String TRAINING                = 'Training';
    private static final String RESELLER                = 'Reseller';
    private static final String ISV                     = 'ISV';
    private static final String OEM                     = 'OEM';
    private static final String EMEA                    = 'EMEA';
    private static final String CCNSP                   = 'PARTNER_TYPE.CCNSP';

    public static final String  DISTRIBUTOR_PROFILE     = 'Partner Portal - Strategic License - OEM - SI';

    public static final String  RED_HAT_CREATED         = 'Red Hat Created';

    private String[] partnerTypes = new String[]{
        NONE,
        CORPORATE_RESELLER,
        DISTRIBUTOR,
        SI,
        TRAINING,
        RESELLER,
        ISV,
        OEM,
        PartnerConst.SCP,
        PartnerConst.EMBEDDED
    };

    //private Map<String, RH_CountryCode_CountryName__c> countries;
    private Map<String, List<State__c>> countryStateMap;
    //private Map<String, States_ISO_Codes__c> stateISOCodes;

    public ManualOnboardingController() {
        hasDistributorProfile = false;
        retURL = Apexpages.currentpage().getParameters().get('retURL');
        referralType = Apexpages.currentpage().getParameters().get('referralType');
        partnerOnboardingRegistration = new Partner_Onboarding_Registration__c();
        isPublicSector = false;
        disablePublicSector = true;
        oldCountry = '';
        selectedCountryName = '';
        language = '';
        //stateISOCodes = new Map<String, States_ISO_Codes__c>();
        countryStateMap = new Map<String, List<State__c>>();
        partnerTypeSelectionList = new List<SelectOption>();
        stateSelectionList = new List<SelectOption>();
        countrySelectionList = new List<SelectOption>();
        countrySelectionList.add(new SelectOption(NONE, NONE));
        languageSelectionList = new List<SelectOption>();

        selectableCountryList = [
            select      Name,
                        Abbreviation__c,
                        Global_Region__c,
                        Country_Name__c,
                        Subregion__c,
                        (select     Name,
                                    Abbreviation__c
                        from        States__r
                        order by    Name asc)
            from        Country__c
            order by    Name asc
        ];

        //countries = RH_CountryCode_CountryName__c.getAll();
        //List<String> countryNames = new List<String>();
        //countryNames.addAll(countries.keySet());
        //countryNames.sort()
        //stateISOCodes = States_ISO_Codes__c.getAll();
        //for (String countryName : countryNames) {
        //    RH_CountryCode_CountryName__c tempCountry = countries.get(countryName);
        //    countrySelectionList.add(new SelectOption(tempCountry.RH_Territory_Code__c + ',' + tempCountry.Name, tempCountry.Name));
        //}
        for (Country__c currentCountry : selectableCountryList) {
            countrySelectionList.add(new SelectOption(currentCountry.Name, currentCountry.Name));
            List<State__c> stateList = new List<State__c>();
            for (State__c stateName : currentCountry.States__r) {
                stateList.add(stateName);
            }
            countryStateMap.put(currentCountry.Name.toUpperCase(), stateList);
        }

        for (String partnerTypeOption : partnerTypes) {
            partnerTypeSelectionList.add(new SelectOption(partnerTypeOption, partnerTypeOption));
        }
        //partnerTypeSelectionList.add(new SelectOption('Certified Cloud & Service Provider', 'Certified Cloud & Service Provider'));
        partnerTypeSelectionList.sort();
	}

    public void onLoad() {
        isPartnerUser = false;
        pageTitle = System.Label.Onb_Man_Title;
        User me = [
            select  Id,
                    Profile.Name,
                    Contact.AccountId,
                    LanguageLocaleKey
            from    User
            where   Id = :UserInfo.getUserId()
            limit   1
        ];
        if (me.Contact.AccountId != null) {
            Account myacct = [select Finder_Partner_Type__c from Account where Id = :me.Contact.AccountId];
            if (myacct.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.DISTRIBUTOR').ObjectId__c) {
                hasDistributorProfile = true;
                distributorAccountId = me.Contact.AccountId;
            }
            partnerType = PartnerConst.SCP;
            if (referralType != null && referralType.equalsIgnoreCase(PartnerConst.EMBEDDED)) {
                partnerType = PartnerConst.EMBEDDED;
            }
            pageTitle = System.Label.Onb_Man_Title_for_Partners;
        }
        if (me.Contact != null && me.Contact.AccountId != null) {
            isPartnerUser = true;
        }

        if (isPartnerUser && !hasDistributorProfile) {
            pageTitle = '';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Embedded_NoAccess));
        }

        updateStatesList();

        String userLanguage = UserInfo.getLanguage().substring(0, 2);
        languageSelectionList = OnboardingUtils.getLanguageXnAsSelect(userLanguage);
        languageSelectionList.add(0, new SelectOption('', NONE));
        //sortLanguages(languageNames);
        //languageSelectionList.add(new SelectOption('', NONE));
        //for (Language_Names__c tempLanguage : languageNames) {
        //    languageSelectionList.add(new SelectOption(tempLanguage.Language_Code__c, tempLanguage.Name));
        //}
    }

    public void updateStatesList() {
        if (country != null) {
            if (!oldCountry.equalsIgnoreCase(country)) {
                state = '';
                oldCountry = country;
            }
            //String[] countryNameParts = country.split(',');
            //if (countryNameParts.size() > 1) {
            //    selectedCountryName = countryNameParts[1];
            //}
            selectedCountryName = country;
            disablePublicSector = false;
            if (!selectedCountryName.equalsIgnoreCase('United States')) {
                isPublicSector = false;
                disablePublicSector = true;
            }
            System.debug('Is public sector: ' + isPublicSector);
        }
        System.debug('Selected country name: ' + selectedCountryName);
        stateSelectionList.clear();
        if (countryStateMap.get(selectedCountryName) != null) {
            stateSelectionList.add(new SelectOption('', NONE));
            for (State__c stateName : countryStateMap.get(selectedCountryName)) {
                stateSelectionList.add(new SelectOption(stateName.Name, stateName.Name));
            }
            stateSelectionList.sort();
        }
        updateRegionAndSubregion();
    }

    public void updateRegionAndSubregion() {
        for (Country__c tempCountry : selectableCountryList) {
            if (!tempCountry.Name.equalsIgnoreCase(selectedCountryName)) {
                continue;
            }
            region = tempCountry.Global_Region__c;
            subregion = tempCountry.Subregion__c;
            break;
        }
        if (isPublicSector) {
            subregion = 'Fed Sled';
        }
        else {
            try {
                // Override the subregion if the selected state has a specified subregion.
                List<State__c> stateList = [
                    select  Subregion__c
                    from    State__c
                    where   Name = :state
                    and     Country__r.Name = :selectedCountryName
                    and     Subregion__c != null
                ];

                if (stateList.size() != 0) {
                    System.debug('*****[debug]***** 2.setting subregion to ' + stateList[0].Subregion__c);
                    subregion = stateList[0].Subregion__c;
                }
            } catch (Exception pageException) {
                System.debug('*****[debug]***** ' + pageException);
            }
        }
    }

    public PageReference submit() {
        System.debug('Partner type: ' + partnerType);
        if (partnerType.equalsIgnoreCase(NONE) ||
            String.isBlank(companyName) ||
            String.isBlank(address) ||
            String.isBlank(city) ||
            country.equalsIgnoreCase(NONE) ||
            ((String.isBlank(state) ||
                state.equalsIgnoreCase(NONE))
            && stateSelectionList.size() > 1) ||
            String.isBlank(postalCode) ||
            ((String.isBlank(firstName) ||
            String.isBlank(lastName) ||
            (String.isBlank(language) ||
            language.equalsIgnoreCase(NONE))) &&
            (scpPartnerTypeChosen || embeddedPartnerTypeChosen)) ||
            String.isBlank(companyEmail) ||
            String.isBlank(phone) ||
            String.isBlank(website)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Onb_Man_Error_All_Info));
            System.debug('State failure: ' + ((String.isBlank(state) ||
                state.equalsIgnoreCase(NONE))
            && stateSelectionList.size() > 1));
        } else if (partnerType.equalsIgnoreCase(CORPORATE_RESELLER) && !region.equalsIgnoreCase(EMEA)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CORPORATE_RESELLER + ' ' + System.Label.Onb_Man_Error_Only_Avail_1 + ' ' + EMEA + ' ' + System.Label.Onb_Man_Error_Only_Avail_2));
        } else if (!validEmail(companyEmail)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Onb_Man_Error_Invalid_Email));
        } else {
            String tier = 'PARTNER_TIER.UNAFFILIATED';
            // US65571.  Everyone manual onboards Unaffiliated now. - jvervaec
            //if (partnerType.equalsIgnoreCase(OEM)) {
            //    tier = 'PARTNER_TIER.AFFILIATED';
            //}
            // Below was previously commented out, not US65571. - jvervaec
            //if (partnerType.equalsIgnoreCase('ISV') || partnerType.equalsIgnoreCase('Reseller')) {
            //    tier = 'PARTNER_TIER.UNAFFILIATED';
            //}
            //if (partnerType.equalsIgnoreCase('Training')) {
            //    tier = 'PARTNER_TIER.READY';
            //}
            //if (partnerType.equalsIgnoreCase('Certified Cloud & Service Provider')) {
                //tier = 'PARTNER_TIER.UNAFFILIATED';
            //    partnerType = 'SERVICECLOUD_PROVIDER';
            //}
            partnerOnboardingRegistration.Onb_As_Adv_Or_Prem__c = PartnerUtil.onbAsAdvancedOrPremier(partnerType);
            subtype = '';
            if (partnerType.equalsIgnoreCase(PartnerConst.SCP)) {
                partnerType = OnboardingController.HKEY_CLOUD_PROVIDER;
            } else if (partnerType.equalsIgnoreCase(PartnerConst.EMBEDDED)) {
                partnerType = OnboardingController.HKEY_ISV;
                subtype = PartnerConst.EMBEDDED;
            } else {
                partnerType = 'PARTNER_TYPE.' + partnerType.toUpperCase().replace('/', '').replace(' ', '_');
            }

            partnerOnboardingRegistration.HasCustomTerms__c = false;
            partnerOnboardingRegistration.Agree_to_Partner_TC__c = false;
            partnerOnboardingRegistration.Partner_Type__c = [
                select  Id,
                        Name
                from    Classification__c
                where   HierarchyKey__c = :partnerType
            ].Id;
            partnerOnboardingRegistration.Partner_Tier__c = [
                select  Id
                from    Classification__c
                where   HierarchyKey__c = :tier
            ].Id;
            partnerOnboardingRegistration.RecordTypeId = [
                select  Id
                from    RecordType
                where   DeveloperName = 'Business_Partner_Registration'
                and     SObjectType = 'Partner_Onboarding_Registration__c'
                limit 1
            ].Id;

            partnerOnboardingRegistration.Company__c = companyName;
            partnerOnboardingRegistration.Address1__c = address;
            partnerOnboardingRegistration.City__c = city;
            partnerOnboardingRegistration.Country__c = [
                select  Id
                from    Country__c
                where   Name = :selectedCountryName
                limit   1
            ].Id;
            if (!String.isBlank(state)) {
                List<State__c> states = new List<State__c>();
                states = [
                    select  Id
                    from    State__c
                    where   Name = :state
                    limit   1
                ];
                if (states.size() > 0) {
                    partnerOnboardingRegistration.State_Province__c = states[0].Id;
                }
            }

            partnerOnboardingRegistration.Postal_Code__c = postalCode;
            partnerOnboardingRegistration.FirstName__c = firstName;
            partnerOnboardingRegistration.LastName__c = lastName;
            partnerOnboardingRegistration.Email__c = companyEmail;
            partnerOnboardingRegistration.Phone__c = phone;
            partnerOnboardingRegistration.Website__c = website;
            partnerOnboardingRegistration.Global_Region__c = region;
            partnerOnboardingRegistration.SubRegion__c = subregion;
            if (partnerType.equalsIgnoreCase(OnboardingController.HKEY_CLOUD_PROVIDER) || subtype.equalsIgnoreCase(PartnerConst.EMBEDDED)) {
                partnerOnboardingRegistration.Onboarding_Language_Preference__c = language;
            }
            partnerOnboardingRegistration.Is_Primary_Public_Sector__c = (isPublicSector ? 'Yes' : 'No');
            if (!partnerType.equalsIgnoreCase(OnboardingController.HKEY_CLOUD_PROVIDER) && !subtype.equalsIgnoreCase(PartnerConst.EMBEDDED)) {
                partnerOnboardingRegistration.Manual_Onboard__c = !isPartnerUser || hasDistributorProfile;
            }
            partnerOnboardingRegistration.Partner_Onboarding_Status__c = 'Submitted';

            // Onboarding a CCSP partner, redirect to checklist.
            if (partnerType.equalsIgnoreCase(OnboardingController.HKEY_CLOUD_PROVIDER)) {
                partnerOnboardingRegistration.RecordTypeId = [
                    select  Id
                    from    RecordType
                    where   DeveloperName = 'Placeholder'
                    and     SObjectType = 'Partner_Onboarding_Registration__c'
                    limit   1
                ].Id;
                insert partnerOnboardingRegistration;
                Id accountOwner = getAccountOwner(partnerOnboardingRegistration);
                System.debug('Account Owner Id: ' + accountOwner);
                partnerOnboardingRegistration.Owner__c = accountOwner;
                partnerOnboardingRegistration.OwnerId = accountOwner;
                System.debug('Account Owner ID: ' + accountOwner);
                update partnerOnboardingRegistration;
                String pageReference = '/apex/CCSPForm_Internal?onboardingId=' + partnerOnboardingRegistration.Id;
                if (!String.isEmpty(retURL)) {
                    pageReference += '&retURL=' + retURL;
                }
                return new PageReference(pageReference);
            } else if (subtype.equalsIgnoreCase(PartnerConst.EMBEDDED)) {
                // Onboarding an Embedded partner, redirect to PARF.
                partnerOnboardingRegistration.RecordTypeId = [
                    select  Id
                    from    RecordType
                    where   DeveloperName = 'Placeholder'
                    and     SObjectType = 'Partner_Onboarding_Registration__c'
                    limit   1
                ].Id;
                insert partnerOnboardingRegistration;
                Id accountOwner = getAccountOwner(partnerOnboardingRegistration);
                System.debug('Account Owner Id: ' + accountOwner);
                partnerOnboardingRegistration.Owner__c = accountOwner;
                partnerOnboardingRegistration.OwnerId = accountOwner;
                partnerOnboardingRegistration.Subtype__c = subtype;
                System.debug('Account Owner ID: ' + accountOwner);
                update partnerOnboardingRegistration;
                String pageReference = '/apex/PARF_Internal?onboardingId=';
                if (hasDistributorProfile) {
                    pageReference = '/apex/PARF?onboardingId=';
                }
                pageReference += partnerOnboardingRegistration.Id;
                if (!String.isEmpty(retURL)) {
                    pageReference += '&retURL=' + retURL;
                }
                return new PageReference(pageReference);
            } else {
                // For any partner type other than SCP/CCSP or Embedded manually onboarded,
                // set the Anti-Corruption responses to Red Hat Created.
                partnerOnboardingRegistration.Have_they_been_convicted__c = RED_HAT_CREATED;
                partnerOnboardingRegistration.Do_they_act_in_any_government_position__c = RED_HAT_CREATED;
            }

            insert partnerOnboardingRegistration;

            // Submit the onboarding record for approval.
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Manual Onboarding Registration');
            req.setObjectId(partnerOnboardingRegistration.Id);

            Approval.ProcessResult result = Approval.process(req, false);

            if (result.isSuccess()) {
                return new PageReference('/' + partnerOnboardingRegistration.Id);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Onb_Man_Error_Unsuccessful));
            }
        }

        return null;
    }

    public PageReference cancel() {
        if (retURL != null) {
            return new PageReference(retURL);
        }
        if (isPartnerUser && !hasDistributorProfile) {
            return new PageReference('/');
        }
        return null;
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

    private static Id getAccountOwner(Partner_Onboarding_Registration__c pOnbRegRec) {
        Id accountOwner = null;
        String accountTeamQuery = '';
        accountTeamQuery += 'select User__c, Priority__c';
        accountTeamQuery += '  from AccountTeamRule__c';
        accountTeamQuery += ' where AccountAccessLevel__c = \'Owner\'';

        if (pOnbRegRec.Global_Region__c != null) {
            accountTeamQuery += ' and (GlobalRegion__c = null or GlobalRegion__c = \'';
            accountTeamQuery += String.escapeSingleQuotes(pOnbRegRec.Global_Region__c);
            accountTeamQuery += '\')';
        }

        if (pOnbRegRec.Subregion__c != null) {
            accountTeamQuery += ' and (Subregion__c = null or Subregion__c = \'';
            accountTeamQuery += String.escapeSingleQuotes(pOnbRegRec.Subregion__c);
            accountTeamQuery += '\')';
        }

        if (pOnbRegRec.Country__c != null) {
            accountTeamQuery += ' and (Country__c = null or Country__c = \'';
            accountTeamQuery += String.escapeSingleQuotes(pOnbRegRec.Country__c);
            accountTeamQuery += '\')';
        }

        if (pOnbRegRec.Partner_Tier__c != null) {
            accountTeamQuery += ' and (PartnerTier__c = null or PartnerTier__c = \'';
            accountTeamQuery += pOnbRegRec.Partner_Tier__c;
            accountTeamQuery += '\')';
        }

        if (pOnbRegRec.Partner_Type__c != null) {
            accountTeamQuery += ' and (PartnerType__c = null or PartnerType__c = \'';
            accountTeamQuery += pOnbRegRec.Partner_Type__c;
            accountTeamQuery += '\')';
        }

        // Finish and execute
        accountTeamQuery += ' order by Priority__c desc limit 1';
        system.debug('accountTeamQuery: [' + accountTeamQuery + ']');

        List<Sobject> objectList = Database.query(accountTeamQuery);

        if (objectList.size() != 0) {
            accountOwner = ((AccountTeamRule__c) objectList[0]).User__c;
        }

        return accountOwner;
    }

    public boolean scpPartnerTypeChosen {
        get {
            return (!String.isEmpty(partnerType) && partnerType.equalsIgnoreCase(PartnerConst.SCP));
        }
    }

    public boolean embeddedPartnerTypeChosen {
        get {
            return (!String.isEmpty(partnerType) && partnerType.equalsIgnoreCase(PartnerConst.EMBEDDED));
        }
    }

    public void sortLanguages(Language_Names__c[] languageNames) {
        Integer size = languageNames.size();
        for (Integer x = 0; x < size - 1; x++) {
            for (Integer y = x + 1; y < size; y++) {
                Language_Names__c language1 = languageNames[x];
                Language_Names__c language2 = languageNames[y];
                if (language1.Name.compareTo(language2.Name) > 0) {
                    languageNames.set(x, language2);
                    languageNames.set(y, language1);
                }
            }
        }
    }
}