public without sharing class PFController {
    public PFSearchForm__c searchForm  {get; set;}
    public List<SelectOption> partnerLevelOptions  {get; set;}
    public List<SelectOption> partnerSpecializationOptions  {get; set;}
    public List<SelectOption> partnerPlatformOptions  {get; set;}
    public List<SelectOption> partnerTrainingOptions  {get; set;}

    public List<String> partnerLevelList  {get; set;}
    public List<String> partnerSpecializationList  {get; set;}
    public List<String> partnerPlatformList  {get; set;}
    public List<String> partnerTrainingList  {get; set;}
    public Boolean      searching {get; set; }

    public PFSearchResult           result {get; private set; }
    public List<PFPartnerMatch> resultPage {get; private set; }

    public List<Country__c> SelectableCountryList {get; private set; }

    public boolean moreLocations {get; private set; }

    public PFPartnerDetailsMatch partner {get; private set; }
    private PFSearch srch;

    public PFController() {
        init();
    }

    private void init(){
        moreLocations = false;
        searching = False;
        searchForm = new PFSearchForm__c();
        searchForm.DistanceMetric__c = 'Miles';
        searchForm.Distance__c = '25';
        partnerLevelOptions = PFUtils.getSelectOptionsForPicklist(Schema.Sobjecttype.PFSearchForm__c.fields.PartnerTier__c);
        partnerSpecializationOptions = PFUtils.getSelectOptionsForPicklist(Schema.Sobjecttype.PFSearchForm__c.fields.Specialization__c);
        partnerPlatformOptions = PFUtils.getSelectOptionsForPicklist(Schema.Sobjecttype.PFSearchForm__c.fields.PlatformsSupported__c);
        partnerTrainingOptions = PFUtils.getSelectOptionsForPicklist(Schema.Sobjecttype.PFSearchForm__c.fields.TrainingType__c);

        partnerLevelList = new List<String>();
        partnerSpecializationList = new List<String>();
        partnerPlatformList = new List<String>();
        partnerTrainingList = new List<String>();

        srch = new PFSearch();

        SelectableCountryList = [
	        select Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
	     , (select Name, Abbreviation__c from States__r order by Name asc)
	          from Country__c order by Name asc
	    ];

        String passProgram = ApexPages.currentPage().getParameters().get('program');
        if (passProgram != null) {
            try {
                Classification__c clfn = [select Name from Classification__c where HierarchyKey__c = :passProgram];
                searchForm.PartnerType__c = clfn.Name;
                if (searchForm.PartnerType__c == 'RESELLER') searchForm.PartnerType__c = 'Solution Provider';
            }
            catch (QueryException ex) {
                // safe to ignore
                System.debug('Invalid program type passed in');
            }
        }
    }

	public List<SelectOption> getSelectableCountryOptionsForLang(){
	    List<SelectOption> countryOptionList = new List<SelectOption>();

        //System.debug('----------[PF] SelectableCountryList = ' + SelectableCountryList);

	    Map<String, String> countryNames = new Map<String,String>();
	    for (CountryTranslation__c cT : [
            select   LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c
            from     CountryTranslation__c
            where    Country__c in :SelectableCountryList and LanguageCode__c = :UserInfo.getLanguage()
        ]) {
	        countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
        }

        for (Country__c country : SelectableCountryList) {
            String name = country.Name;
            if (countryNames.get(country.Iso3166Alpha2__c) != null) {
                name = countryNames.get(country.Iso3166Alpha2__c);
            }
            countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
        }
        return countryOptionList;
    }

    public List<SelectOption> SelectableCountryOptions {
        get {
            PFSearchContext ctx = new PFSearchContext(searchForm);
            String globalRegion = ctx.globalRegion;

            if (globalRegion != null){
                SelectableCountryList = [
                        select Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
                     , (select Name, Abbreviation__c from States__r order by Name asc)
                          from Country__c where Global_Region__c = :globalRegion order by Name asc
                ];
            } else {
                SelectableCountryList = [
                        select Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
                     , (select Name, Abbreviation__c from States__r order by Name asc)
                          from Country__c order by Name asc
                ];
            }
            for (Country__c c : SelectableCountryList) {
                if (c.Abbreviation__c == 'US') {
                    SelectableCountryList.add(0, c);
                    break;
                }
            }
            return getSelectableCountryOptionsForLang();
        }
    }

    public Integer SelectableStateOptionsSize {
        get {
            return SelectableStateOptions == null ? 0 : SelectableStateOptions.size();
        }
    }

    public List<SelectOption> SelectableStateOptions {
        get {
                System.debug('---------------------- ' + searchForm.Country__c);

                if (searchForm.Country__c == null ||  searchForm.Country__c == ''){
                        return new List<SelectOption>();
                }

            List<SelectOption> stateOptionList = new List<SelectOption>();

            for(Country__c country : SelectableCountryList) {
                if (searchForm.Country__c != country.Abbreviation__c)
                    continue;

                // add all of the states
                for(State__c state : country.States__r)
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));

                break;
            }

            return stateOptionList;
        }
    }

    public PageReference ClearSearch() {
        searchForm = new PFSearchForm__c();
        partnerLevelList = new List<String>();
        partnerSpecializationList = new List<String>();
        partnerPlatformList = new List<String>();
        partnerTrainingList = new List<String>();
        result = null;
        resultPage = null;
        searching = false;
        return null;
    }

    public PageReference ExecuteSearch() {
        searching = True;
        System.debug('------>' + searchForm.NameOrKeywords__c);

        searchForm.PartnerTier__c = PFUtils.convertListToPicklist(partnerLevelList);
        searchForm.Specialization__c = PFUtils.convertListToPicklist(partnerSpecializationList);
        searchForm.PlatformsSupported__c = PFUtils.convertListToPicklist(partnerPlatformList);
        searchForm.TrainingType__c = PFUtils.convertListToPicklist(partnerTrainingList);

        if (!String.isEmpty(searchForm.PartnerType__c) && searchForm.PartnerType__c.contains(PartnerConst.SCP)) {
            searchForm.PartnerTier__c = null;
            searchForm.Specialization__c = null;
        }

        if (PFUtils.isEmpty(searchForm.PartnerType__c) || !(searchForm.PartnerType__c.contains('Corporate Reseller') || searchForm.PartnerType__c.contains('Solution Provider'))){
	        partnerSpecializationList = new List<String>();
        }

        if (PFUtils.isEmpty(searchForm.PartnerType__c) || !searchForm.PartnerType__c.contains('ISV')){
	        partnerPlatformList = new List<String>();
        }

        if (PFUtils.isEmpty(searchForm.PartnerType__c) || !searchForm.PartnerType__c.contains('Training')){
	        partnerTrainingList = new List<String>();
        }

        srch = new PFSearch();
        PFSearchContext ctx = new PFSearchContext(searchForm);

        result = srch.partnerSearch(ctx);
        resultPage = result.getPage(0);

        if (result.ctx.boundingBox != null)
        {
	        System.debug('NE Lat ' + result.ctx.boundingBox.northeast.latitude);
	        System.debug('NE Lon ' + result.ctx.boundingBox.northeast.longitude);
	        System.debug('SW Lat ' + result.ctx.boundingBox.southwest.latitude);
	        System.debug('SW Lon ' + result.ctx.boundingBox.southwest.longitude);
        }

        return null; //Page.PFPartnerResultPage;
    }

    public PageReference BackToResultsPage() {
        return Page.Partner_Finder;
    }

    public PageReference DetailsPage() {
        return Page.PFPartnerDetail;
    }

    public void loadDetails() {
        Id partnerId = ApexPages.currentPage().getParameters().get('id');
                System.debug('[PF]-------------------------------- partnerId=' + partnerId);
        if (partnerId != null){
        	try {
                partner = srch.partnerDetails(partnerId);
        	} catch (Exception e){
        		// Failed to load details
        		System.debug('ERROR ' + e);
        		partner = null;
        	}
        }
    }

    public PageReference ChangePage() {
        Integer page = Integer.valueOf(ApexPages.currentPage().getParameters().get('currentPage'));
        resultPage = result.getPage(page - 1);
        return null;
    }

    public PageReference moreLocations() {
        moreLocations = true;
        return null;
    }
}