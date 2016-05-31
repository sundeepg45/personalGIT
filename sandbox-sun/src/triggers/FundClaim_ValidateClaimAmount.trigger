trigger FundClaim_ValidateClaimAmount on SFDC_MDF_Claim__c (before insert, before update) {
    //
    // Initialize a fudge factor
    //
    // - This is also found in the 
    //
    final Decimal FUDGE_FACTOR = 0.0001;
    final String logTag = '[FundClaim_ValidateClaimAmount]';
    
    //
    // Initialize the currency conversion map
    // - use the legacy CurrencyType table for now.
    //
    
    DatedCurrencyRate_Converter currencyConverter = new DatedCurrencyRate_Converter();
    currencyConverter.setLegacyConversion(true);

    //
    // Fetch a list of all fund requests associated with any claims in this trigger batch
    //
    
    Set<Id> fundRequestIds = new Set<Id>();
    for(SFDC_MDF_Claim__c fundClaim : Trigger.new){
        fundRequestIds.add(fundClaim.Fund_Request__c);
    }

    Map<Id, SFDC_MDF__c> fundRequestMap = new Map<Id, SFDC_MDF__c>([
        select Estimated_Red_Hat_Funding_Requested__c 
             , CurrencyIsoCode
             , Total_Approved_Claims__c
             , RecordType.DeveloperName
          from SFDC_MDF__c 
         where Id in :fundRequestIds 
    ]);



    List<SFDC_MDF__c> updatedFundRequests = new List<SFDC_MDF__c>();


    // NEW (for PAR): Existing fund claims. What other claims have been approved for the Fund Request
    Map<Id,List<SFDC_MDF_Claim__c>> reqClaimsMap = new Map<Id,List<SFDC_MDF_Claim__c>>();
    for(SFDC_MDF_Claim__c claim:[SELECT Id, Approved_Amount__c, Budget__c, Fund_Request__c, Requested_Amount__c,CurrencyIsoCode FROM SFDC_MDF_Claim__c WHERE Fund_Request__c IN :fundRequestIds and Approval_Status__c = 'Approved']){
        String reqId = claim.Fund_Request__c;
        List<SFDC_MDF_Claim__c> claimsList = new List<SFDC_MDF_Claim__c>();
        if(reqClaimsMap.containsKey(reqId)){
            claimsList = reqClaimsMap.get(reqId);
        }       
        claimsList.add(claim);
        reqClaimsMap.put(reqId, claimsList);
    }
    



    //
    // Loop triggers
    //

    for(SFDC_MDF_Claim__c fundClaim : Trigger.new) {
        //
        // We only care about fund claim validation when they are entering the approval process.
        //

        if (fundClaim.Approval_Status__c == 'Draft')
            continue; // draft claims are still a work in progress
        if (fundClaim.Approval_Status__c == 'Rejected')
            continue; // rejected claims are still a work in progress
        if (fundClaim.Approval_Status__c == 'Expired')
            continue; // don't care: funds have already been disbursed.

        //
        // Unmap the associated fund request
        //
        SFDC_MDF__c fundRequest = fundRequestMap.get(fundClaim.Fund_Request__c);
        
        
        // Total approved Fund Claims already approved for this Fund Request
        decimal existingClaimsAmt = 0.00;
        List<SFDC_MDF_Claim__c> otherClaims = reqClaimsMap.get(fundRequest.Id);
        //system.debug(logTag + 'There are [' + otherClaims.size() + '] approved claims already for this Fund Request.');
        if(otherClaims != null){
            for(SFDC_MDF_Claim__c c:otherClaims){
                currencyConverter.setSourceAmount(c.Requested_Amount__c);
                currencyConverter.setSourceCurrency(c.CurrencyIsoCode);
                currencyConverter.setTargetCurrency(fundRequest.CurrencyIsoCode);
                existingClaimsAmt += currencyConverter.getTargetAmountByCurrencyType();
            }
        }
        system.debug(logTag + 'Total existing (approved) claims for fund request [' + fundRequest.Id + ']: ' + existingClaimsAmt);
        
        
        //
        // Setup currency conversion
        //

        currencyConverter.setSourceAmount(fundClaim.Requested_Amount__c);
        currencyConverter.setSourceCurrency(fundClaim.CurrencyIsoCode);
        currencyConverter.setTargetCurrency(fundRequest.CurrencyIsoCode);

        Decimal convertedAmount = currencyConverter.getTargetAmountByCurrencyType();

        //
        // Does it exceed the limit? 
        //
        // If the source and target currencies match, no fudge factor allowed.
        //
        
        Decimal multiplier = 1.0; 
    
        if (fundClaim.CurrencyIsoCode != fundRequest.CurrencyIsoCode)
            multiplier += FUDGE_FACTOR;
    
        decimal fundsAvailable = (fundRequest.Estimated_Red_Hat_Funding_Requested__c * multiplier) - existingClaimsAmt;
        system.debug(logTag + 'fundsAvailable: [' + fundsAvailable + ']');
        
        //if (convertedAmount > (fundRequest.Estimated_Red_Hat_Funding_Requested__c * multiplier))
        //if ( (convertedAmount + existingClaimsAmt) > (fundRequest.Estimated_Red_Hat_Funding_Requested__c * multiplier)){
        if ( convertedAmount > fundsAvailable){
            
            system.debug(logTag + 'WARNING: Claim [' + convertedAmount + '] is greater than Funds Available [' + fundsAvailable + '].');
            
            if(fundRequest.RecordType.DeveloperName != 'PAR'){
                fundClaim.addError(System.Label.FundClaim_ErrorRequestAmountExceedsAvailableFunds
                   // Show estimated red hat funding amount 
                   + '\n ' + Schema.Sobjecttype.SFDC_MDF__c.Label 
                   + ' : ' + Schema.Sobjecttype.SFDC_MDF__c.Fields.Estimated_Red_Hat_Funding_Requested__c.Label
                   + ' = ' + fundRequest.CurrencyIsoCode + ' ' + convertedAmount
                   
                   // Show requested claim amount
                   + '\n ' + Schema.Sobjecttype.SFDC_MDF_Claim__c.Label 
                   + ' : ' + Schema.Sobjecttype.SFDC_MDF_Claim__c.Fields.Requested_Amount__c.Label
                   + ' = ' + fundClaim.CurrencyIsoCode + ' ' + fundClaim.Requested_Amount__c
                   
                   // Show fudge factor currency amount
                   + '\n ' + 'Fudge Factor: '
                   + ' = ' + fundRequest.CurrencyIsoCode + ' ' + (fundRequest.Estimated_Red_Hat_Funding_Requested__c * multiplier)
                   
                );
                
            } else {
                   
                   //
                   // PAR Claim
                   //
                   List<String> args = new String[]{'0','number','###,###,##0.00'};
                   fundClaim.addError(System.Label.Fund_Claim_exceeds_Available_Budget + String.format(fundsAvailable.format(), args));
                   
            } 
                
                
                
        }  else {  
            system.debug(logTag + 'Claim is less than the Est Red Hat Funding Requested. Ok to proceed.');
            // Claim was not greater than the remaining Fund Request amount
            if(fundClaim.Approval_Status__c == 'Approved' && fundClaim.Is_PAR_Claim__c == true  ){
                system.debug(logTag + 'Updating fund request Total Approved Claim amount to [' + convertedAmount + ']');
                // Update the Fund_Request__c.Total_Approved_Claims__c amount
                fundRequest.Total_Approved_Claims__c += convertedAmount;
                updatedFundRequests.add(fundRequest);
            } 
            
        }
    }
    
    
    // Update any Fund Requests that have been changed
    if(!updatedFundRequests.isEmpty()){
        update(updatedFundRequests);
    }
   
}