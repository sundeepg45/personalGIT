trigger MDF_SetFundRequestToExpired on SFDC_Budget__c (before update) {
    Set<Id> updatedBudgetSet = new Set<Id>();
    
    for(SFDC_Budget__c budget : Trigger.new) {
    	SFDC_Budget__c budgetOld = Trigger.oldMap.get(budget.Id);
    	
    	if (budget.Active__c == false && budgetOld.Active__c == true)
            updatedBudgetSet.add(budget.Id);
    }

    List<SFDC_MDF__c> fundRequestList = [
        select Id
          from SFDC_MDF__c 
         where Budget__c in :updatedBudgetSet
           and Approval_Status__c in ('Draft', 'Rejected')
    ];

    if (fundRequestList.size() == 0)
        return;
    
    for(SFDC_MDF__c fundRequest : fundRequestList) {
    	fundRequest.Approval_Status__c = 'Expired';
        fundRequest.Approval_Status_Partner__c = 'Expired';
    }

    update fundRequestList;    
}