trigger FundRequest_ValidateRequestAmount on SFDC_MDF__c (before insert, before update) {
    //
    // Initialize a fudge factor
    //
    // - This is also found in the 
    //
    final Decimal FUDGE_FACTOR = 0.0001;

    //
    // Initialize the currency conversion map
    // - use the legacy CurrencyType table for now.
    //
    
    CurrencyConverter currencyConverter = new CurrencyConverter();
    currencyConverter.setLegacyConversion(true);

    //
    // Fetch all associated budgets. This is only a partial optimization...
    //

    Set<Id> associatedBudgetIds = new Set<Id>();
    
    for(SFDC_MDF__c fundRequest : Trigger.new)
        associatedBudgetIds.add(fundRequest.Budget__c);
    
    Map<Id, SFDC_Budget__c> associatedBudgetMap = new Map<Id, SFDC_Budget__c>([
        select Allocated_Budget__c
             , Available_Budget__c
             , CurrencyIsoCode
          from SFDC_Budget__c
         where Id in :associatedBudgetIds
    ]);

    //
    // Build a map of all fund requests that belong to any budgets related to any of our fund 
    // requests from the original Trigger.new. Make sense? See, it's easy!
    //
    // Oh, and make sure they are in the right approval process. This results in a list
    // that is probably larger than we need, but it is neccessary to avoid having to
    // do excessive SOQL selects later on.
    //

    List<SFDC_MDF__c> associatedFundRequestList = [
        select Estimated_Red_Hat_Funding_Requested__c 
             , CurrencyIsoCode
             , Budget__c
          from SFDC_MDF__c 
         where Budget__c in :associatedBudgetIds 
           and Approval_Status__c != 'Draft' 
           and Approval_Status__c != 'Second Stage Rejected'
           and Approval_Status__c != 'Rejected'
           and Approval_Status__c != 'Expired'
           and Approval_Status__c != 'Canceled'
    ];

    //
    // Loop triggers
    //

    for(SFDC_MDF__c fundRequest : Trigger.new) {
        //
        // We only care about fund request validation when they are entering the approval process.
        //

        if (fundRequest.Approval_Status__c == 'Draft')
            continue; // draft requests are still a work in progress
        if (fundRequest.Approval_Status__c == 'Rejected')
            continue; // rejected requests are still a work in progress
        
        /** This section should not be necessary, and may in fact be harmful 
        
        if (fundRequest.Approval_Status__c == 'Second Stage Approval')
            continue; // already been validated
        if (fundRequest.Approval_Status__c == 'Pending Final Approval')
            continue; // already been validated
        if (fundRequest.Approval_Status__c == 'Approved')
            continue; // already been validated
            
         */
         
        if (fundRequest.Approval_Status__c == 'Expired')
            continue; // don't care: MDF has been marked as expired.
        if (fundRequest.Approval_Status__c == 'Pending Cancellation')
            continue; // don't care: MDF has been marked as expired.

        //
        // Unmap the parent budget.
        //
        
        SFDC_Budget__c budget = associatedBudgetMap.get(fundRequest.Budget__c);

        //
        // Convert currency to USD
        //
        
        Boolean differingCurrencies = false;
        Decimal totalRequested = 0.0;
        
        for(SFDC_MDF__c requestItem : associatedFundRequestList) {
            if (requestItem.Id == fundRequest.Id)
                continue; // skip copies of our own record
            if (requestItem.Budget__c != fundRequest.Budget__c)
                continue; // skip requests that don't belong to the same budget.
            
            currencyConverter.setSourceAmount(requestItem.Estimated_Red_Hat_Funding_Requested__c);
            currencyConverter.setSourceCurrency(requestItem.CurrencyIsoCode);
            currencyConverter.setTargetCurrency(budget.CurrencyIsoCode);
            totalRequested += currencyConverter.getTargetAmount();
            
            // Save differing currencies for later
            if (budget.CurrencyIsoCode != requestItem.CurrencyIsoCode)
                differingCurrencies = true;
        }

        //
        // Now, handle this particular fund request
        //

        currencyConverter.setSourceAmount(fundRequest.Estimated_Red_Hat_Funding_Requested__c);
        currencyConverter.setSourceCurrency(fundRequest.CurrencyIsoCode);
        currencyConverter.setTargetCurrency(budget.CurrencyIsoCode);
        totalRequested += currencyConverter.getTargetAmount();

        // Save differing currencies for later
        if (budget.CurrencyIsoCode != fundRequest.CurrencyIsoCode)
            differingCurrencies = true;

        //
        // Does it exceed the limit? 
        //
        // If the source and target currencies match, no fudge factor allowed.
        //
        
        Decimal multiplier = 1.0; 
    
        if (differingCurrencies)
            multiplier += FUDGE_FACTOR;
    
        if (totalRequested > (budget.Allocated_Budget__c * multiplier))
            fundRequest.addError(System.Label.FundRequest_ErrorRequestAmountExceedsAvailableBudget
               // Show estimated red hat funding amount
               + '\n ' + Schema.Sobjecttype.SFDC_MDF__c.Label 
               + ' : ' + Schema.Sobjecttype.SFDC_MDF__c.Fields.Estimated_Red_Hat_Funding_Requested__c.Label
               + ' = ' + budget.CurrencyIsoCode + ' ' + totalRequested
               
               // Show allocated budget
               + '\n ' + Schema.Sobjecttype.SFDC_Budget__c.Label 
               + ' : ' + Schema.Sobjecttype.SFDC_Budget__c.Fields.Allocated_Budget__c.Label
               + ' = ' + budget.CurrencyIsoCode + ' ' + budget.Allocated_Budget__c
               
               // Show available budget
               + '\n ' + Schema.Sobjecttype.SFDC_Budget__c.Label 
               + ' : ' + Schema.Sobjecttype.SFDC_Budget__c.Fields.Available_Budget__c.Label
               + ' = ' + budget.CurrencyIsoCode + ' ' + budget.Available_Budget__c
               
               // Show fudge factor currency amount
               + '\n ' + 'Fudge Factor: '
               + ' = ' + budget.CurrencyIsoCode + ' ' + (budget.Allocated_Budget__c * multiplier)
               
            );
    }
}