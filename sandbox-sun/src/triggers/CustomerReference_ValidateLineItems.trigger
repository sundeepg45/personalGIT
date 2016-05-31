trigger CustomerReference_ValidateLineItems on Customer_Reference__c (before update) {
    for(Customer_Reference__c customerReference : Trigger.new) {
        // Ignored statuses
        if (customerReference.Approval_Status__c == 'Draft')
          continue;
        if (customerReference.Approval_Status__c == 'Rejected')
            continue;
        if (customerReference.Approval_Status__c == 'Retired')
            continue;
        
        // Validate the number of line items
        if (customerReference.CRP_Count__c != 0)
            continue;
            
        customerReference.addError('Products are required for this Customer Reference. Please use your browsers \'Back\' button and add products.');
    }
}