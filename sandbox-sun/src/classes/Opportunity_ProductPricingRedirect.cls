public with sharing class Opportunity_ProductPricingRedirect {
	
	private final String opportunityId;
	
	//
	// constructor
	//
	
	public Opportunity_ProductPricingRedirect(ApexPages.StandardController stdController) {
		
		OpportunityLineItem lineItem = (OpportunityLineItem) stdController.getRecord();
		
		//
		// get the opportunity id for this line item
		//
		
		OpportunityLineItem oli = [SELECT OpportunityId 
			FROM OpportunityLineItem
		   WHERE Id = :lineItem.id
		];
		
		opportunityId = oli.OpportunityId;
	}
	
	
	//
	// redirects to the managed products page
	//
	
	public PageReference managedProducts() {
        PageReference page = new PageReference( '/apex/Opportunity_ProductPricing?id=' + opportunityId );
        page.setRedirect(true);
        
        return page;
    }
}