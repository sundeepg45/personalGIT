/****************************************************************************************
Modification Log:
-----------------------------------------------------------------------------------------
 Developer              Date                Description
-----------------------------------------------------------------------------------------
 Jonathan Garrison      10-Apr-2015         Modified way in which partner accounts are
                                            identified. Instead of using the IsPartner
                                            field, the account record type is checked.
 Jonathan Garrison      10-Apr-2015         Modified the way in which partner types are
                                            compared. Instead of comparing the names
                                            of the partner types, the classification
                                            Ids are compared.
 Jonathan Garrison      16-Apr-2015         Fixed problem where the onboarding record
                                            partner type was being displayed when the
                                            matched partner account type should have
                                            been displayed (data match, convert to join).
****************************************************************************************/
public with sharing class OnboardingSearchBeforeCreateController {

    public String partyId { get; set; }
    public String DUNSNumber { get; set; }
    public String accountName { get; set; }
    public String address { get; set; }
    public String city { get; set; }
    public String country { get; set; }
    public String state { get; set; }
    public String postalCode { get; set; }
    public String selectedRecord { get; set; }
    public String errorMessage { get; private set; }
    public String finalOutcomeMessage { get; private set; }
    public boolean alternativeName { get; set; }
    public boolean searchConducted { get; private set; }
    public boolean finalized { get; private set; }
    public Partner_Onboarding_Registration__c onboardingRegistration { get; private set; }
    public List<FullResult> searchResults { get; private set; }
    public FullResult matchedData { get; private set; }
    public CDHTools.SearchResult[] CDHResults { get; private set; }
    public List<SelectOption> countrySelectionList { get; private set; }
    public List<SelectOption> stateSelectionList { get; private set; }

    private String selectedCountryName;
    private String selectedCountryCode;
    private String onboardingRegistrationId;
    private String oldCountry;
    private String selectedCDHPartyNumber;
    private String selectedPartnerType;
    private String selectedPartnerTier;
    private Id selectedPartnerAccount;
    private Id selectedSalesAccount;
    //private Map<String, RH_CountryCode_CountryName__c> countries;
    private Map<String, List<State__c>> countryStateMap;
    private Map<String, States_ISO_Codes__c> stateISOCodes;
    public List<Country__c> selectableCountryList;

    public OnboardingSearchBeforeCreateController() {
        alternativeName = false;
        matchedData = null;
        finalized = false;
        selectedRecord = '-1';
        oldCountry = '';
        selectedCountryName = '';
        selectedCountryCode = '';
        selectedPartnerType = '';
        stateISOCodes = new Map<String, States_ISO_Codes__c>();
        countryStateMap = new Map<String, List<State__c>>();
        searchResults = new List<FullResult>();
        stateSelectionList = new List<SelectOption>();
        countrySelectionList = new List<SelectOption>();
        countrySelectionList.add(new SelectOption('--None--', '--None--'));

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
        //        List<String> countryNames = new List<String>();
        //countryNames.addAll(countries.keySet());
        //countryNames.sort();
        stateISOCodes = States_ISO_Codes__c.getAll();
        //for (String countryName : countryNames) {
        //    RH_CountryCode_CountryName__c tempCountry = countries.get(countryName);
        //    countrySelectionList.add(new SelectOption(tempCountry.RH_Territory_Code__c + ',' + tempCountry.Name, tempCountry.Name));
        //}
        for (Country__c currentCountry : selectableCountryList) {
            countrySelectionList.add(new SelectOption(currentCountry.Abbreviation__c + ',' + currentCountry.Name, currentCountry.Name));
            List<State__c> stateList = new List<State__c>();
            for (State__c stateName : currentCountry.States__r) {
                stateList.add(stateName);
            }
            countryStateMap.put(currentCountry.Name.toUpperCase(), stateList);
        }
    }

    public void onLoad() {

        searchConducted = false;
        onboardingRegistrationId = ApexPages.currentPage().getParameters().get('id');

        if (!String.isEmpty(onboardingRegistrationId)) {
            onboardingRegistration = [
                select  Id,
                        Company__c,
                        Address1__c,
                        City__c,
                        Country__r.Name,
                        Country__r.Abbreviation__c,
                        State_Province__r.Name,
                        Postal_Code__c,
                        SBC_Initiated__c,
                        CDH_Party_Number__c,
                        DUNSNumber__c,
                        Sales_Account__c,
                        Account__c,
                        RHNLogin__c,
                        Partner_Type__c,
                        Partner_Type__r.Name,
                        Partner_Tier__r.Name,
                        Partner_Onboarding_Status__c,
                        Manual_Onboard__c,
                        Contact_CDH_Party__c
                from    Partner_Onboarding_Registration__c
                where   Id = :onboardingRegistrationId
                limit   1
            ];

            if (onboardingRegistration != null) {
                if (onboardingRegistration.Partner_Onboarding_Status__c.equalsIgnoreCase('Approved')) {
                    errorMessage = 'Partner Onboarding Status is "Approved".';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                } else if (onboardingRegistration.Partner_Onboarding_Status__c.equalsIgnoreCase('Converted to Join')) {
                    errorMessage = 'Partner Onboarding Status is "Converted to Join".';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                } else if (onboardingRegistration.Partner_Onboarding_Status__c.equalsIgnoreCase('Rejected')) {
                    errorMessage = 'Partner Onboarding Status is "Rejected".';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                } else {
                    partyId = onboardingRegistration.CDH_Party_Number__c;
                    DUNSNumber = onboardingRegistration.DUNSNumber__c;
                    accountName = onboardingRegistration.Company__c;
                    address = onboardingRegistration.Address1__c;
                    city = onboardingRegistration.City__c;
                    state = onboardingRegistration.State_Province__r.Name;
                    postalCode = onboardingRegistration.Postal_Code__c;
                    //RH_CountryCode_CountryName__c tempCountry = countries.get(onboardingRegistration.Country__r.Name);
                    selectedCountryName = onboardingRegistration.Country__r.Name;
                    selectedCountryCode = onboardingRegistration.Country__r.Abbreviation__c;
                    country = selectedCountryCode + ',' + selectedCountryName;
                    oldCountry = country;
                    if (state != null) {
                        if (stateISOCodes.get(state) != null) {
                            state = stateISOCodes.get(state).ISO_Code__c;
                        }
                    }
                }
            }
        }

        updateStatesList();
    }

    public void search(CDHTools.SearchParams params) {

        selectedRecord = '-1';
        searchResults.clear();

        try {
            CDHResults = new CDHTools().searchCDHParty(params);
            if (CDHResults != null && CDHResults.size() > 0) {
                List<String> partyIds = new List<String>();
                for (CDHTools.SearchResult CDHResult : CDHResults) {
                    String pId = CDHResult.partyNumber;
                    if (!String.isEmpty(pId)) {
                        partyIds.add(pId);
                    }
                }
                Account[] sfAccounts = [
                    select  Name,
                            BillingStreet,
                            BillingCity,
                            BillingState,
                            BillingPostalCode,
                            BillingCountry,
                            ShippingStreet,
                            ShippingCity,
                            ShippingState,
                            ShippingPostalCode,
                            ShippingCountry,
                            Global_Region__c,
                            Subregion__c,
                            PartnerStatuses__c,
                            Owner.Name,
                            Finder_Partner_Type__c,
                            Finder_Partner_Type__r.Name,
                            Finder_Partner_Tier__r.Name,
                            CDHPartyNumber__c,
                            RecordTypeId
                    from    Account
                    where   CDHPartyNumber__c in :partyIds
                ];
                Integer indexCounter = 0;
                for (CDHTools.SearchResult CDHResult : CDHResults) {
                    List<Account> accounts = new List<Account>();
                    String CDHPartyId = CDHResult.partyNumber;
                    for (Account sfAccount : sfAccounts) {
                        String sfPartyId = sfAccount.CDHPartyNumber__c;
                        if (CDHPartyId.equalsIgnoreCase(sfPartyId)) {
                            accounts.add(sfAccount);
                        }
                    }
                    FullResult fullResult = new FullResult(CDHResult, accounts, indexCounter);
                    indexCounter = fullResult.indexCounter;
                    searchResults.add(fullResult);
                }
            }
            searchConducted = true;
        } catch (Exception e) {
            String message = 'Exception: ' + e.getTypeName() + ': ' + e.getMessage() + ' -- ' + e.getCause();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
            System.debug(message);
        }
    }

    public void updateStatesList() {
        if (country != null) {
            if (!oldCountry.equalsIgnoreCase(country)) {
                state = '';
                oldCountry = country;
            }
            String[] countryNameParts = country.split(',');
            selectedCountryCode = countryNameParts[0];
            selectedCountryName = countryNameParts[1];
        }
        stateSelectionList.clear();
        if (countryStateMap.get(selectedCountryName) != null) {
            stateSelectionList.add(new SelectOption('', '--None--'));
            for (State__c stateName : countryStateMap.get(selectedCountryName)) {
                if (stateISOCodes.get(stateName.Name) == null) {
                    stateSelectionList.add(new SelectOption(stateName.Name, stateName.Name));
                } else {
                    stateSelectionList.add(new SelectOption(stateISOCodes.get(stateName.Name).ISO_Code__c, stateName.Name));
                }
            }
            stateSelectionList.sort();
        }
    }

    public PageReference cancel() {
        return onboardingRegistrationId != null ? new PageReference('/' + onboardingRegistrationId) : null;
    }

    public PageReference cancelFinalization() {
        finalized = false;
        selectedRecord = '-1';
        matchedData = null;
        return null;
    }

    private ID getContactParty(String loginName) {
        CDHTools.ContactSearchResult cdhContact = (new CDHTools()).searchContacts(loginName);
        if (cdhContact == null || cdhContact.cdhPartyNumber == null || cdhContact.cdhPartyNumber.length() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find CDH Contact for RHN Login ' + loginName + '. If you are unable to correct this problem please contact the Customer Data team'));
            return null;
        }
        CDH_Party__c[] cdhParty = [select Id from CDH_Party__c where CDH_Party_Number_Ext__c = :cdhContact.cdhPartyNumber];
        if (cdhParty.size() == 0) {
            CDH_Party__c party = new CDH_Party__c();
            party.CDH_Party_Type__c = 'PERSON';
            party.Name = cdhContact.cdhPartyNumber;
            insert party;
            return party.Id;
//            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find CDH Party record for Party Number ' + cdhContact.cdhPartyNumber + '. If you are unable to correct this problem please contact the Customer Data team'));
//            return null;
        }
        return cdhParty.get(0).Id;
    }

    public PageReference noMatchFound() {
        if (!onboardingRegistration.Manual_Onboard__c && onboardingRegistration.Contact_CDH_Party__c == null) {
            ID contactParty = getContactParty(onboardingRegistration.RHNLogin__c);
            if (contactParty == null) {
                return null;
            }
            onboardingRegistration.Contact_CDH_Party__c = contactParty;
        }
        finalized = true;
        selectedRecord = '-1';
        getSelectedData();
        finalOutcomeMessage = composeFinalOutcomeMessage();
        return null;
    }

    public PageReference finalize() {
        onboardingRegistration.SBC_Initiated__c = true;
        if (selectedPartnerAccount != null && onboardingRegistration.Manual_Onboard__c) {
            onboardingRegistration.Partner_Onboarding_Status__c = 'Rejected';
            ProcessInstanceWorkItem[] wilist = [
                select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
                from    ProcessInstanceWorkitem p
                where   p.ProcessInstance.TargetObjectId = :onboardingRegistrationId
                and     p.ProcessInstance.Status = 'Pending'
            ];
            if (wilist.isEmpty()) {
                System.debug('*****[debug]***** Expected to find an approval process item for Onboarding registration ' + onboardingRegistrationId);
            }
            ProcessInstanceWorkItem wi = wilist.get(0);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Reject');
            req.setComments('Onboarding registration rejected');
            req.setWorkitemId(wi.Id);
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' onboarding registration');

            System.debug('*****[debug]***** Onboarding registration ' + req.getAction());
        }
        update onboardingRegistration;
        return cancel();
    }

    public PageReference matchFound() {
        if (!onboardingRegistration.Manual_Onboard__c && onboardingRegistration.Contact_CDH_Party__c == null) {
            ID contactParty = getContactParty(onboardingRegistration.RHNLogin__c);
            if (contactParty == null) {
                return null;
            }
            onboardingRegistration.Contact_CDH_Party__c = contactParty;
        }
        finalized = true;
        getSelectedData();

        finalOutcomeMessage = composeFinalOutcomeMessage();
        return null;
    }

    private String composeFinalOutcomeMessage() {
        if (String.isEmpty(selectedCDHPartyNumber)) {
            return 'No match was found. A CDH record, Sales account and Partner account (' + onboardingRegistration.Partner_Tier__r.Name + ' ' + onboardingRegistration.Partner_Type__r.Name + ') for ' + onboardingRegistration.Company__c + ' will be created. If this is the desired outcome, please click Proceed.';
        } else if (selectedSalesAccount == null && selectedPartnerAccount == null) {
            return 'A Sales account and Partner account (' + onboardingRegistration.Partner_Tier__r.Name + ' ' + onboardingRegistration.Partner_Type__r.Name + ') will be created for ' + onboardingRegistration.Company__c + ' and associated with CDH Party Number ' + selectedCDHPartyNumber + '. If this is the desired outcome, please click Proceed.';
        }
        else if (onboardingRegistration.Zombie_Account__c != null) {
            return 'An Unaffiliated partner account was selected.  This account will be used for the remainder of the onboarding process';
        }
        else if (selectedSalesAccount != null && selectedPartnerAccount == null) {
            return 'A Sales account was matched (see below). A Partner account (' + onboardingRegistration.Partner_Tier__r.Name + ' ' + onboardingRegistration.Partner_Type__r.Name + ') will be created for ' + onboardingRegistration.Company__c + ' and associated with CDH Party Number ' + selectedCDHPartyNumber + '. If this is the desired outcome, please click Proceed.';
        } else if (selectedPartnerAccount != null && onboardingRegistration.Manual_Onboard__c) {
            return 'Because you are manually onboarding and an existing Partner account was selected, no accounts will be created and the associated onboarding registration record will be Rejected. If this is the desired outcome, please click Proceed.';
        }

        return 'A Sales account (see below) and Partner account (' + selectedPartnerType + '), with CDH Party Number ' + selectedCDHPartyNumber + ', were matched. The onboarding will take place as a join to the matched Partner account for ' + onboardingRegistration.Company__c + '. If this is the desired outcome, please click Proceed.';
    }

    public boolean resultsAvailable {
        get {
            return (searchResults != null && searchResults.size() > 0);
        }
    }

    public void searchPIOrDUNS() {
        if (String.isEmpty(partyId) && String.isEmpty(DUNSNumber)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must specify either a Party Id or a DUNS Number.'));
        } else {
            CDHTools.SearchParams params = new CDHTools.SearchParams();
            params.PartyNo = partyId;
            params.DUNSNumber = DUNSNumber;
            search(params);
        }
    }

    public void searchName() {
        if (String.isEmpty(accountName.trim()) || String.isEmpty(city.trim()) || String.isEmpty(country.trim()) || country.trim().equalsIgnoreCase('--None--')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must specify, at least, a Party Name, City and Country.'));
        } else {
            CDHTools.SearchParams params = new CDHTools.SearchParams();
            params.accName = accountName;
            params.AliasFlag = alternativeName;
            params.Street = address;
            params.city = city;
            params.postalcode = postalCode;
            params.country = selectedCountryCode;
            params.state = state;
            search(params);
        }
    }

    public void changeSelectedRecord() {
        System.debug('Selected record: ' + selectedRecord);
    }

    private void getSelectedData() {
        selectedCDHPartyNumber = '';
        selectedPartnerAccount = null;
        selectedSalesAccount = null;
        matchedData = null;
        for (FullResult result : searchResults) {
            if (result.index.equalsIgnoreCase(selectedRecord)) {
                selectedCDHPartyNumber = result.CDHResult.partyNumber;
                matchedData = result;
                if (result.hasAccounts) {
                    for (SFAccount account : result.sfAccounts) {
                        if (!account.isPartner && selectedSalesAccount == null) {
                            selectedSalesAccount = account.account.Id;
                        }
                        if (account.isPartner) {
                            System.debug('Finder Partner Type Name: ' + account.account.Finder_Partner_Type__r.Name);
                            System.debug('Onboarding Partner Type: ' + onboardingRegistration.Partner_Type__r.Name);
                        }
                        if (account.isPartner && account.account.Finder_Partner_Type__c.equals(onboardingRegistration.Partner_Type__c)) {
                            selectedPartnerAccount = account.account.Id;
                            selectedPartnerType = account.account.Finder_Partner_Type__r.Name;
                            selectedPartnerTier = account.account.Finder_Partner_Tier__r.Name;
                        }
                    }
                }
            }
        }
        onboardingRegistration.CDH_Party_Number__c = selectedCDHPartyNumber;
        if (selectedPartnerTier != null && selectedPartnerTier.startsWith('Unaffiliated')) {
            onboardingRegistration.Zombie_Account__c = selectedPartnerAccount;
        }
        else {
            onboardingRegistration.Account__c = selectedPartnerAccount;
        }
        onboardingRegistration.Sales_Account__c = selectedSalesAccount;
    }

    public class FullResult {

        public CDHTools.SearchResult    CDHResult           { get; private set; }
        public List<SFAccount>          sfAccounts          { get; private set; }
        public boolean                  hasAccounts         { get; private set; }
        public Integer                  indexCounter        { get; private set; }
        public String                   index               { get; private set; }

        public FullResult(CDHTools.SearchResult CDHResult, List<Account> accounts, Integer indexCounter) {
            this.indexCounter = indexCounter;
            this.index = '';
            this.CDHResult = CDHResult;
            this.sfAccounts = new List<SFAccount>();
            for (Account account : accounts) {
                this.sfAccounts.add(new SFAccount(account, isPartnerAccount(account)));
            }
            this.hasAccounts = (this.sfAccounts != null && this.sfAccounts.size() > 0);
            this.index = String.valueOf(this.indexCounter);
            this.indexCounter++;
        }
    }

    public class SFAccount {

        public Account account      { get; private set; }
        public boolean isPartner    { get; private set; }

        public SFAccount(Account account, boolean isPartner) {
            this.account = account;
            this.isPartner = isPartner;
        }
    }

    private static boolean isPartnerAccount(Account account) {
        return (account.RecordTypeId == PartnerConst.APAC_PARTNER ||
                account.RecordTypeId == PartnerConst.EMEA_PARTNER ||
                account.RecordTypeId == PartnerConst.LATAM_PARTNER ||
                account.RecordTypeId == PartnerConst.NA_PARTNER);
    }
}