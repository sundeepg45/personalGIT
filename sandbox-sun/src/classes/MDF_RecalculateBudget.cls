public with sharing class MDF_RecalculateBudget {

    public MDF_RecalculateBudget() {}
    
    public MDF_RecalculateBudget(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public Id budgetId {
        set;
        get {
            if (budgetId == null && controller != null)
               return controller.getId();
            return budgetId;
        }
    }

    public SFDC_Budget__c budget {
        set;
        get {
            if (budget == null && controller != null)
                budget = (SFDC_Budget__c) controller.getRecord();
            if (budget == null && budgetId != null)
                budget = [
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
                                 , Total_Approved_Claims__c
                              from R00NR0000000QJRyMAO__r)
                              
                         // Find fund claims
                         , (select Requested_Amount__c
                                 , CurrencyIsoCode
                                 , Approval_Status__c
                              from R00NR0000000QJSkMAO__r)
                         
                      from SFDC_Budget__c
                     where Id = :budgetId
                ];
                
            return budget;
        }
    }
    
    public PageReference confirmUpdate() {
        if (budget.End_Date__c < Date.today())
           return null;

        RecalculateBudget.calculate(controller.getId());
        
        PageReference pageReference = new PageReference('/' + controller.getId()); 
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancelUpdate() {
        PageReference pageReference = new PageReference('/' + controller.getId());
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    public void recalculate() {
        // Fetch the temporary budget to use in the related list loops
        SFDC_Budget__c relatedListBudget = [
            select Approved_Requests__c
                 , Approved_Claims__c
                 , Requests_Submitted__c
                 , Requests_Awaiting_Approval__c
                 , Claims_Submitted__c
                 , Claims_Awaiting_Approval__c
                 , Unclaimed_Requests2__c
                 , Last_Refresh_Date__c
                 , CurrencyIsoCode
                 , RecordType.DeveloperName
                 , Is_PAR__c
                        
                 // Find fund requests
                 , (select Estimated_Red_Hat_Funding_Requested__c
                         , CurrencyIsoCode
                         , Approval_Status__c
                         , Total_Approved_Claims__c
                 
                      from R00NR0000000QJRyMAO__r)
                      
                 // Find fund claims
                 , (select Requested_Amount__c
                         , CurrencyIsoCode
                         , Approval_Status__c
                         , Fund_Request__c
                      from R00NR0000000QJSkMAO__r)
                 
              from SFDC_Budget__c
             where Id = :budget.Id
        ];
        
        // Do the cross-currency conversions here
        CurrencyConverter converter = new CurrencyConverter();
            
        if (relatedListBudget != null && relatedListBudget.R00NR0000000QJRyMAO__r != null) {
            for (SFDC_MDF__c fundRequest : relatedListBudget.R00NR0000000QJRyMAO__r) {
                if (relatedListBudget.CurrencyIsoCode == fundRequest.CurrencyIsoCode)
                    continue;
                if (fundRequest.Estimated_Red_Hat_Funding_Requested__c == null)
                    continue;

                converter.setSourceAmount(fundRequest.Estimated_Red_Hat_Funding_Requested__c);
                converter.setSourceCurrency(fundRequest.CurrencyIsoCode); 
                converter.setTargetCurrency(relatedListBudget.CurrencyIsoCode); 
                converter.setLegacyConversion(true);
                fundRequest.Estimated_Red_Hat_Funding_Requested__c = converter.getTargetAmount();
            }
        }

        if (relatedListBudget != null && relatedListBudget.R00NR0000000QJSkMAO__r != null) {
            for (SFDC_MDF_Claim__c fundClaim : relatedListBudget.R00NR0000000QJSkMAO__r) {
                if (relatedListBudget.CurrencyIsoCode == fundClaim.CurrencyIsoCode)
                    continue;
                if (fundClaim.Requested_Amount__c == null)
                    continue;
                    
                converter.setSourceAmount(fundClaim.Requested_Amount__c);
                converter.setSourceCurrency(fundClaim.CurrencyIsoCode);
                converter.setTargetCurrency(relatedListBudget.CurrencyIsoCode);
                converter.setLegacyConversion(true);
                fundClaim.Requested_Amount__c = converter.getTargetAmount();
            }
        }

        // Zero out values on actual budget
        budget.Approved_Requests__c = 0;
        budget.Requests_Submitted__c = 0;
        budget.Requests_Awaiting_Approval__c = 0;

        budget.Approved_Claims__c = 0;
        budget.Claims_Submitted__c = 0;
        budget.Claims_Awaiting_Approval__c = 0;
        budget.Unclaimed_Requests2__c = 0;
        
        // Requests approved
        for (SFDC_MDF__c fundRequest : relatedListBudget.R00NR0000000QJRyMAO__r)
           if (fundRequest.Approval_Status__c == 'Approved'
            || fundRequest.Approval_Status__c == 'Pending Cancellation'){
                
                budget.Approved_Requests__c += fundRequest.Estimated_Red_Hat_Funding_Requested__c;
                
            }
                
        
        // Requests submitted
        for (SFDC_MDF__c fundRequest : relatedListBudget.R00NR0000000QJRyMAO__r)
           if (fundRequest.Approval_Status__c == 'Pending First Approval'
            || fundRequest.Approval_Status__c == 'Pending Final Approval'
            || fundRequest.Approval_Status__c == 'Approved'
            || fundRequest.Approval_Status__c == 'Pending Cancellation')
               budget.Requests_Submitted__c += fundRequest.Estimated_Red_Hat_Funding_Requested__c;
        
        // Requests awaiting approval
        for (SFDC_MDF__c fundRequest : relatedListBudget.R00NR0000000QJRyMAO__r)
           if (fundRequest.Approval_Status__c == 'Pending First Approval'
            || fundRequest.Approval_Status__c == 'Pending Final Approval')
               budget.Requests_Awaiting_Approval__c += fundRequest.Estimated_Red_Hat_Funding_Requested__c;
        
        // Approved claims
        for (SFDC_MDF_Claim__c fundClaim : relatedListBudget.R00NR0000000QJSkMAO__r)
           if (fundClaim.Approval_Status__c == 'Approved')
               budget.Approved_Claims__c += fundClaim.Requested_Amount__c;
        
        // Claims submitted
        for (SFDC_MDF_Claim__c fundClaim : relatedListBudget.R00NR0000000QJSkMAO__r)
           if (fundClaim.Approval_Status__c == 'Pending First Approval'
            || fundClaim.Approval_Status__c == 'Pending Second Approval'
            || fundClaim.Approval_Status__c == 'Pending Final Approval'
            || fundClaim.Approval_Status__c == 'Approved')
               budget.Claims_Submitted__c += fundClaim.Requested_Amount__c;
        
        // Claims awaiting approval
        for (SFDC_MDF_Claim__c fundClaim : relatedListBudget.R00NR0000000QJSkMAO__r)
           if (fundClaim.Approval_Status__c == 'Pending First Approval'
            || fundClaim.Approval_Status__c == 'Pending Second Approval'
            || fundClaim.Approval_Status__c == 'Pending Final Approval')
               budget.Claims_Awaiting_Approval__c += fundClaim.Requested_Amount__c;
        
        // Unclaimed requests
        Map<Id, SFDC_MDF__c> unclaimedFundRequests = new Map<Id, SFDC_MDF__c>(relatedListBudget.R00NR0000000QJRyMAO__r);
        
        
        if(budget.Is_PAR__c != true){
              // Regular MDF
            for (SFDC_MDF_Claim__c fundClaim : relatedListBudget.R00NR0000000QJSkMAO__r) {
                if (fundClaim.Approval_Status__c != 'Approved') 
                    continue;
                unclaimedFundRequests.remove(fundClaim.Fund_Request__c);
            }
            
            for (SFDC_MDF__c fundRequest : unclaimedFundRequests.values()) {
                if (fundRequest.Approval_Status__c != 'Approved'
                 && fundRequest.Approval_Status__c != 'Pending Cancellation')
                   continue;
                budget.Unclaimed_Requests2__c += fundRequest.Estimated_Red_Hat_Funding_Requested__c;
            }
        } else {
            // PAR MDF
            for (SFDC_MDF__c fundRequest : unclaimedFundRequests.values()) {
                if (fundRequest.Approval_Status__c != 'Approved' && fundRequest.Approval_Status__c != 'Pending Cancellation'){
                   continue;
                }
                
                // Update unclaimed requests total..
                budget.Unclaimed_Requests2__c += (fundRequest.Estimated_Red_Hat_Funding_Requested__c - fundRequest.Total_Approved_Claims__c);
                
            }
        }
        
        
        // Last refresh
        budget.Last_Refresh_Date__c = System.now();
    }
}