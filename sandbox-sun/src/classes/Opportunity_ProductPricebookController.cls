public class Opportunity_ProductPricebookController {

	public String opportunityId { get; set; }
	public String pricebookId { get; set; }
	public String oldPricebookId { get; set; }
	public Opportunity opportunity { get; set; }

    //
    // Constructor
    //
        
    public Opportunity_ProductPricebookController() {    
    	opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
    	pricebookId = ApexPages.currentPage().getParameters().get('pricebookId');
    	oldPricebookId = ApexPages.currentPage().getParameters().get('pricebookId');
    	
    	if (opportunityId != null && opportunityId != '')
    		opportunity = getOpportunity();
    }
    
    
    //
    // Methods
    //
        
   	public List<SelectOption> getPricebookOptions() {
    	
    	//
    	// query SFDC for the pricebooks
    	//	
    	
    	List<Pricebook2> pricebooks = [SELECT Id
    		, Name 
    	FROM Pricebook2 
    	WHERE IsStandard = false 
    	ORDER BY Name];
    	
    	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('0000','-- NONE --'));
            
    	for (Pricebook2 priceBook :pricebooks)
        	options.add(new SelectOption(priceBook.Id, priceBook.Name));
                    
    	return options;
    }
    
    
    public Opportunity getOpportunity() {
    	String query = 'SELECT Name, HasOpportunityLineItem FROM Opportunity WHERE Id = :opportunityId';
    	Opportunity opportunity = Database.query(query);
    	return opportunity;
    }
    
    
    public PageReference save() {
    	
    	//
    	// delete the opportunity line items if the price book is changing
    	//
    	
    	if (pricebookId != oldPricebookId && pricebookId != '0000')
    		deleteLineItems();
    	
    	//
    	// update the pricebook if None is not selected
    	//
    	
    	if (pricebookId != '0000') {
    		opportunity.Pricebook2Id = pricebookId;
    		update opportunity;
    	}
    	
    	//
    	// redirect to product pricing page
    	//
    	
    	PageReference page = new PageReference('/apex/Opportunity_ProductPricing?id=' + opportunityId);
    	page.setRedirect(true);
    	
    	return page;
    }
    
    
    public PageReference cancel() {
		PageReference page = new PageReference('/apex/Opportunity_ProductPricing?id=' + opportunityId);
    	page.setRedirect(true);
    	
    	return page;	
    }
 
    
    public void deleteLineItems() {
    	List<OpportunityLineItem> lineItems = [SELECT
    		Id
    		FROM OpportunityLineItem
    		WHERE OpportunityId = :opportunityId
    	];
    	
    	if (lineItems.size() > 0)
    		delete lineItems;
    }
}