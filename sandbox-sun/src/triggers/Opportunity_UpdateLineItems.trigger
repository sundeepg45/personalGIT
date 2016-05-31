/**
 * Opportunity_UpdateLineItems
 *
 * @see Opportunity
 * @version 1.0
 * @author Ian Zepp <izepp@redhat.com>
 */
trigger Opportunity_UpdateLineItems on Opportunity (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    List <Id> opportunityIds = new List <Id> ();

    for (Opportunity opportunity : Trigger.new) {
        //
        // Do not recalculate if the previous lastModified time is less than 2 seconds
        //
        if (opportunity.LastModifiedDate != null) {
            if (opportunity.LastModifiedDate.addSeconds (2) < DateTime.now ())
                continue;
        }
        
        if (Trigger.isInsert)
            opportunityIds.add (opportunity.id);
        else if (opportunity.CloseDate != Trigger.oldMap.get (opportunity.Id).CloseDate)
            opportunityIds.add (opportunity.id);
    }
    
    if (opportunityIds.size () == 0)
        return;

    //
    // Pull in all of the related opportunity line items. This call could potentially
    // return tens of thousands of records. Fortunately, governor limits will scale 
    // up based on the original batch size of triggered opportunities. 
    //
    List <OpportunityLineItem> opportunityBatches = new List <OpportunityLineItem> (); 
    List <OpportunityLineItem> opportunityLineItems = [select Id, 
               ActualTerm__c,
               ActualStartDate__c,
               ActualEndDate__c,
               OpportunityCloseDate__c,
               OpportunityId,
               ProductDefaultTerm__c,
               Quantity,
               ScheduleLocked__c,
               TotalPrice,
               UnitPrice
          from OpportunityLineItem
         where OpportunityId in : opportunityIds
    ];
    
    //
    // Push the update in groups of 100 records
    //
    for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
        if (opportunityBatches.size() >= 100) {
            update opportunityBatches;
            opportunityBatches.clear();
        }
        
        opportunityBatches.add (opportunityLineItem);
    }
    
    //
    // Push any remaining line item updates
    //
    if (opportunityBatches.size() > 0)
        update opportunityBatches;
}