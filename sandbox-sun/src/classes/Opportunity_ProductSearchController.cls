public class Opportunity_ProductSearchController {

	public List<PriceBookEntry> priceBookEntries { get; set; }
	public Opportunity opportunity { get; set; }
	public String pricebookId { get; set; }
	public String opportunityId { get; set; }
    public String searchTerm { get; set; }

    //
    // Constructor
    //
    
    public Opportunity_ProductSearchController() {    
    	opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
    	searchTerm = ApexPages.currentPage().getParameters().get('search');
    	
    	//
    	// get the opportunity
    	//
    	
    	opportunity = queryOpportunity(opportunityId);
    	
    	//
    	// Get the appropriate pricebook. All new opportunities should use the global price book.
    	// If the opportunity already has a pricebook id, use it.
    	//
    	
    	if (opportunity.pricebook2Id == null) { 
    		Pricebook2 globalPricebook = [SELECT Id 
    			FROM Pricebook2 
    	   	   WHERE Name = 'Global Price Book'
    		];
    		
    		pricebookId = globalPricebook.Id;
    	}
    	else {
    		pricebookId = opportunity.Pricebook2Id;
    	}
    	
    	queryPriceBook();
    }
        
    //
    // Accessors
    //
        
    public String getPricebookName() {
    	if (priceBookEntries.size() > 0)
			return priceBookEntries[0].Pricebook2.Name;
			
		return '';        	
    }

        
    //
    // Methods
    //
    
    public PageReference search() {
    	queryPriceBook();
    	
    	return null;	
    }
    
    private Opportunity queryOpportunity(String opportunityId) {
    	
    	//
    	// query SFDC for opportunity details
    	//
    	
    	Opportunity opportunity = [SELECT Id
    		   , CurrencyIsoCode
    		   , Country_of_Order__c
    		   , Pricebook2Id
    		FROM Opportunity 
           WHERE Id = :opportunityId
    	];
    	
    	return opportunity;
    }
        
    private void queryPriceBook() {
    	
    	//
        // query SFDC for matching search terms
        //
        
       	List<PriceBookEntry> unfilteredPriceBookEntries = [SELECT Id
                , Name
                , Pricebook2.Name
                , Product2.Description
                , Product2.Excluded_Countries__c
                , ProductCode
                , UnitPrice
        FROM PricebookEntry
        WHERE Pricebook2Id = :pricebookId
        AND CurrencyIsoCode = :opportunity.CurrencyIsoCode
        AND IsActive = true
        AND Product2.Configurable__c = false
        AND ProductCode != null
        AND ((Name LIKE :'%' + String.escapeSingleQuotes(searchTerm) + '%') 
        OR (ProductCode LIKE :'%' + String.escapeSingleQuotes(searchTerm) + '%')
        OR (Product2.Description LIKE :'%' + String.escapeSingleQuotes(searchTerm) + '%'))
        ORDER BY ProductCode
        LIMIT 100];
        
        //
        // filter the returned results by country of order
        //
        
        String countryOfOrder = opportunity.Country_of_Order__c.toUpperCase();
        List<PriceBookEntry> filteredPriceBookEntries = new List<PriceBookEntry>();
        
        for (PriceBookEntry pbe : unfilteredPriceBookEntries) {
        	
        	if (pbe.Product2.Excluded_Countries__c == null) {
        		filteredPriceBookEntries.add(pbe);
        		continue;
        	}
        	
        	String excludedCountries = pbe.Product2.Excluded_Countries__c.toUpperCase();
        	
        	if (excludedCountries.contains(countryOfOrder))
        		continue;
        		
        	filteredPriceBookEntries.add(pbe);	
        }
   
        priceBookEntries = filteredPriceBookEntries;
    }
}