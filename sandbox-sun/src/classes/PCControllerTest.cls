@isTest
private class PCControllerTest {

    static testMethod void myUnitTest() {
        PCController pcc = new PCController();
        ID acctId = [select id from Account where IsPartner=True limit 1].Id;
        ApexPages.currentPage().getParameters().put('partnerId', acctId);
        pcc.OnLoadAction();
        PCSearchForm__c form = new PCSearchForm__c();
        pcc.searchForm = form;
        form.NameOrKeywords__c = 'ibm';
        pcc.ExecuteSearch();
        pcc.BackToResultsPage();
        pcc.DetailsPage();

		ID prodId = [select id from PartnerProduct__c limit 1].Id;
		ApexPages.currentPage().getParameters().put('id', prodId);
		pcc.loadDetails();
        pcc.ClearSearch();
    }
}