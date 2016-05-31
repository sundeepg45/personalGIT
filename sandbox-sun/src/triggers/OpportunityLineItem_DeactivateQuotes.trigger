/**
 * OpportunityLineItem_DeactivateQuotes
 *
 * This trigger deactivates active quotes on Opportunities when new OpportunityLineItems are added
 *
 * @package Single Year Bookings
 * @author Bryan Bosely <bbosely@redhat.com>
 * @version 1.0
 */

trigger OpportunityLineItem_DeactivateQuotes on OpportunityLineItem (after insert) {

    //
    // set to hold the ids of opportunities on which to deactive quotes
    //
    
    Set<Id> opportunityIds = new Set<Id>();


    //
    // Loop through each opportunity line item (aka opportunity product)
    //
    
    for (OpportunityLineItem lineItem : Trigger.New) {
        System.debug ('Starting OpportunityLineItem: ' + lineItem.Id);

        //
        // Sanity checks
        //

        System.assert (lineItem.OpportunityId != null);
            
        //
        // Determine which opportunties need to have quotes deactivated
        // do not update quotes imported from Quote Builder
        //
        
        if (lineItem.ScheduleLocked__c != true) {
            opportunityIds.add(lineItem.OpportunityId); 
        }   
    }
    

    //
    // Get the opportunities on which to deactive quotes
    //
    
    List<Opportunity> opportunities = [
          SELECT QuoteNumber__c
            FROM Opportunity
           WHERE Id in : opportunityIds 
             AND QuoteNumber__c != null
    ];
     
            
    //
    // see if the quote was created with Quote Builder
    //
    
    List<Quote__c> quotes = [
          SELECT Id 
            FROM Quote__c 
           WHERE OpportunityId__c in : opportunityIds 
             AND IsActive__c != false 
    ];
       
            
    //
    // see if the quote was created with Big Machines
    //
    
    List<BigMachines__Quote__c> bmQuotes = [
    		SELECT Id
    		FROM BigMachines__Quote__c
    		WHERE BigMachines__Opportunity__c in :opportunityIds
    ];
    
    
    List <Opportunity> OpportunityBatches = new List<Opportunity>();
    List<Quote__c> quoteBatches = new List<Quote__c>();
    List<BigMachines__Quote__c> bmQuoteBatches = new List<BigMachines__Quote__c>(); 
    
    System.debug ('- attempt to deactivate quotes on ' + opportunities.size() + ' Opportunities');
    
    
    //
    // clear the quote number and deactivate quotes for the these opportunites
    //
    
    for (Opportunity opportunity : opportunities) {    
        opportunity.QuoteNumber__c = null;
    }
    
        
    //
    // update the quote active quote and put the quotes in their own collection
    //
    
    for (Quote__c quote : quotes) 
    {
        quote.IsActive__c = false;
    }
    
    for ( BigMachines__Quote__c quote : bmQuotes )
    {
    	quote.BigMachines__Is_Primary__c = false;	
    }
    
    
    //
    // Push the updates in groups of 200 records
    //
    
    for (Opportunity opportunity : opportunities) 
    {
        if (opportunityBatches.size() >= 200) 
        {
            update opportunityBatches;
            opportunityBatches.clear();
        }
        
        opportunityBatches.add (opportunity);
    }


	for (Quote__c quote : quotes) 
	{
        if (quoteBatches.size() >= 200) 
        {
            update quoteBatches;
            quoteBatches.clear();
        }
        
        quoteBatches.add (quote);
    }
    
    
    for (BigMachines__Quote__c quote : bmQuotes) 
    {
        if (bmQuoteBatches.size() >= 200) 
        {
            update bmQuoteBatches;
            bmQuoteBatches.clear();
        }
        
        bmQuoteBatches.add (quote);
    }
    
    
    //
    // Push any remaining updates
    //
    
    if (opportunityBatches.size() > 0)
        update opportunityBatches;
        
    
    if (quoteBatches.size() > 0)
        update quoteBatches;
        
        
    if (bmQuoteBatches.size() > 0)
        update bmQuoteBatches;    
}