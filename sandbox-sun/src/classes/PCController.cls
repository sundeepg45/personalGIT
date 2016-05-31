public without sharing class PCController {
    public PCSearchForm__c searchForm  {get; set;}

    public PCSearchResult           result {get; private set; }
    public List<PCProductMatch> resultPage {get; private set; }
    public PCProductDetailsMatch product {get; private set; }
    private PCSearch srch;


    public PCController() {
        init();
    }

    private void init() {
        searchForm = new PCSearchForm__c();
        srch = new PCSearch();
    }

    public PageReference OnLoadAction() {
        Id partnerId = ApexPages.currentPage().getParameters().get('partnerId');
        if (partnerId != null) {
            searchForm.NameOrKeywords__c = [select Name from Account where Id = :partnerId].Name;
            searchForm.PartnerId__c = partnerId;
            return ExecuteSearch();
        }
        return null;
    }

    public PageReference ClearSearch() {
        searchForm = new PCSearchForm__c();
        result = null;
        resultPage = null;
        return null;
    }

    public PageReference ExecuteSearch() {
//      System.debug('------>' + searchForm.NameOrKeywords__c);

        srch = new PCSearch();
        PCSearchContext ctx = new PCSearchContext(searchForm);
        result = srch.productSearch(ctx);
        resultPage = result.getPage(0);
        return null;
    }

    public PageReference BackToResultsPage() {
        return Page.Product_Catalog;
    }

    public PageReference DetailsPage() {
        return Page.PCProductDetail;
    }

    public void loadDetails() {
        Id productId = ApexPages.currentPage().getParameters().get('id');
//      System.debug('[PF]-------------------------------- productId=' + productId);
        if (productId != null){
        	try{
                product = srch.productDetails(productId);
        	} catch (Exception e){
        		// Failed to load details
        		product = null;
        	}

        }
    }

    public PageReference ChangePage() {
        Integer page = Integer.valueOf(ApexPages.currentPage().getParameters().get('currentPage'));
        resultPage = result.getPage(page - 1);
        return null;
    }

}