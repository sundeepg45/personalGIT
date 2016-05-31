trigger FundClaim_RecalculateBudget on SFDC_MDF_Claim__c (after insert, after update, after delete) {
    Set<Id> budgetIds = new Set<Id>();

    if (Trigger.isDelete) {
        for(SFDC_MDF_Claim__c fundClaim : Trigger.old) {
            budgetIds.add(fundClaim.Budget__c);
        }
    } else {
	    for(SFDC_MDF_Claim__c fundClaim : Trigger.new) {
	        SFDC_MDF_Claim__c fundClaimOld = Trigger.isUpdate ? Trigger.oldMap.get(fundClaim.Id) : null;
	
	        // Expired requests used to be in either Draft or Rejected, neither of which are
	        // included in calculations. Ignore.
	        if (fundClaim.Approval_Status__c == 'Expired')
	            continue; 
	
	        if (Trigger.isInsert || fundClaimOld == null)
	            budgetIds.add(fundClaim.Budget__c);
	        else if (fundClaim.Approval_Status__c != fundClaimOld.Approval_Status__c)
	            budgetIds.add(fundClaim.Budget__c);
	        else if (fundClaim.Requested_Amount__c != fundClaimOld.Requested_Amount__c)
	            budgetIds.add(fundClaim.Budget__c);
	    }
    }
    
    if (budgetIds.size() == 0)
        return;

    for(SFDC_Budget__c[] budgetList : [
        select Approved_Requests__c
             , Approved_Claims__c
             , Requests_Submitted__c
             , Requests_Awaiting_Approval__c
             , Claims_Submitted__c
             , Claims_Awaiting_Approval__c
             , Unclaimed_Requests2__c
             , Last_Refresh_Date__c
             , CurrencyIsoCode
             
             // Find fund requests
             , (select Estimated_Red_Hat_Funding_Requested__c
                     , CurrencyIsoCode
                     , Approval_Status__c
                  from R00NR0000000QJRyMAO__r)
                  
             // Find fund claims
             , (select Requested_Amount__c
                     , CurrencyIsoCode
                     , Approval_Status__c
                  from R00NR0000000QJSkMAO__r)
             
          from SFDC_Budget__c
         where Id in :budgetIds
    ]) update budgetList;
}