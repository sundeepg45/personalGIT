public with sharing class ManageLocationControllerExt {
    private ApexPages.Standardcontroller controller;
    private String returnURL = null;

    public ManageLocationControllerExt(ApexPages.Standardcontroller stdController){
        returnURL = ApexPages.currentPage().getParameters().get('retURL');

        controller = stdController;

		Partner_Location__c loc = (Partner_Location__c) controller.getRecord();
		if (loc.Partner__c == null) {
	        User currentUser = [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id = :UserInfo.getUserId() ];
	        loc.Partner__c = currentUser.Contact.Account.Id;
            if (String.isEmpty(loc.Partner__c)) {
                loc.Partner__c = returnURL.substring(returnURL.indexOf('id=') + 3);
            }
		}

        SelectableCountryList = [
            select	Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
         			, (select Name, Abbreviation__c from States__r order by Name asc)
              from	Country__c order by Name asc];
    }

    public List<Country__c> SelectableCountryList {get; private set; }

    public List<SelectOption> getSelectableCountryOptionsForLang() {
       List<SelectOption> countryOptionList = new List<SelectOption>();

        Map<String, String> countryNames = new Map<String,String>();
        for (CountryTranslation__c cT : [select LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c
                                           from CountryTranslation__c where LanguageCode__c = :UserInfo.getLanguage()]) {
            countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
        }

        for(Country__c country : SelectableCountryList){
            String name = country.Name;
            if (countryNames.get(country.Iso3166Alpha2__c) != null){
                name = countryNames.get(country.Iso3166Alpha2__c);
            }
            countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
        }
        return countryOptionList;
    }

    public Partner_Location__c getLoc() {
        return (Partner_Location__c) controller.getRecord();
    }


    public List<SelectOption> SelectableCountryOptions {
        get {
                return getSelectableCountryOptionsForLang();
        }
    }

    public Integer SelectableStateOptionsSize {
        get {
            return SelectableStateOptions.size();
        }
    }

    public List<SelectOption> SelectableStateOptions {
        get {
            System.debug('---------------------- ' + getLoc().Country__c);

            if (getLoc().Country__c == null || getLoc().Country__c == ''){
                return new List<SelectOption>();
            }

            List<SelectOption> stateOptionList = new List<SelectOption>();

            for(Country__c country : SelectableCountryList) {
                if (getLoc().Country__c != country.Abbreviation__c)
                    continue;

                // add all of the states
                for(State__c state : country.States__r)
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));

                break;
            }

            return stateOptionList;
        }
    }

    public PageReference save() {
        controller.save();
        if (!String.isEmpty(returnURL)) {
            return new PageReference(returnURL);
        }
        return null;
    }

    static testMethod void mytest() {
    	Partner_Location__c loc = [select id,Partner__c,Country__c from Partner_Location__c limit 1];
        ManageLocationControllerExt ctrl = new ManageLocationControllerExt(new ApexPages.StandardController(loc));
        List<SelectOption> optlist = ctrl.SelectableCountryOptions;
        List<SelectOption> stateoptlist = ctrl.SelectableStateOptions;
        Integer i = ctrl.SelectableStateOptionsSize;
    }
}