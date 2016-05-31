@isTest
private class PFControllerTest {

    static testMethod void myUnitTest() {
    	PFController pfc = new PFController();
    	PFSearchForm__c form = new PFSearchForm__c();
    	form.NameOrKeywords__c = 'ibm';
    	pfc.searchForm = form;

    	List<SelectOption> langs = pfc.getSelectableCountryOptionsForLang();
    	List<SelectOption> countries = pfc.SelectableCountryOptions;
    	List<SelectOption> states = pfc.SelectableStateOptions;
    	pfc.ExecuteSearch();
		ApexPages.currentPage().getParameters().put('currentPage', '1');
		pfc.ChangePage();

    	ID acctId = [select id from Account where isPartner=True limit 1].Id;
		ApexPages.currentPage().getParameters().put('id', acctId);
		pfc.loadDetails();
		pfc.DetailsPage();
		pfc.BackToResultsPage();
    	pfc.ClearSearch();
    }
}