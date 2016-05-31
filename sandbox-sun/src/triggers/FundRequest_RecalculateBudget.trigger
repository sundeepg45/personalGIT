trigger FundRequest_RecalculateBudget on SFDC_MDF__c (after insert, after update, after delete) {
    Set<Id> budgetIds = new Set<Id>();

    if (Trigger.isDelete) {
        for(SFDC_MDF__c fundRequest : Trigger.old) {
            budgetIds.add(fundRequest.Budget__c);
        }
    } else {
	    for(SFDC_MDF__c fundRequest : Trigger.new) {
	        SFDC_MDF__c fundRequestOld = Trigger.isUpdate ? Trigger.oldMap.get(fundRequest.Id) : null;
	
	        // Expired requests used to be in either Draft or Rejected, neither of which are
	        // included in calculations. Ignore.
	        if (fundRequest.Approval_Status__c == 'Expired')
	            continue; 
	
	        if (Trigger.isInsert || fundRequestOld == null)
	            budgetIds.add(fundRequest.Budget__c);
	        else if (fundRequest.Approval_Status__c != fundRequestOld.Approval_Status__c)
	            budgetIds.add(fundRequest.Budget__c);
	        else if (fundRequest.Estimated_Red_Hat_Funding_Requested__c != fundRequestOld.Estimated_Red_Hat_Funding_Requested__c)
	            budgetIds.add(fundRequest.Budget__c);
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