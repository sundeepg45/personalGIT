public with sharing class MDF_SummaryController
{
    public String renderAs { get; set; }
    public String showHeader { get { return showHeader == null ? 'true' : showHeader; } set; }

    public PageReference actionDone() {
        PageReference PageReference = new PageReference('/' + getBudgetId());
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference actionDownloadAsPDF() {
        renderAs = 'PDF';
        showHeader = 'false';
        return null;
    }

    public PageReference actionPrintableView() {
        renderAs = '';
        showHeader = 'false';
        return null;
    }

    public class FundPair {
        public SFDC_MDF__c request { get; set; }
        public SFDC_MDF_Claim__c claim { get; set; }
        public Integer position { get; set; }
        
    }

    public String getBudgetId () {
        return ApexPages.currentPage().getParameters().get('id');
    }
    
    private List<SFDC_Budget__c> budgetList;
    private List<FundPair> fundList;
    
    public SFDC_Budget__c getBudget() {
        if (budgetList != null && budgetList.size() >= 1)
            return budgetList.get(0);
        if (budgetList != null)
            return new SFDC_Budget__c();
        
        budgetList = [
            select Name
                 , Account_Master__r.Name
                 , convertCurrency(Allocated_Budget__c)
                 , convertCurrency(Available_Budget__c)

                 // Find fund requests
                 , (select Name
                         , Activity_Description__c
                         , Activity_Start_Date__c
                         , Activity_Status__c
                         , Activity_Type__c
                         , Approval_Status__c
                         , Budget__c
                         , convertCurrency(Estimated_Red_Hat_Funding_Requested__c)
                         , Participating_Partners__c
                         , Planned_Attendees__c
                         , Planned_Leads__c
                         , Planned_Responses__c
                         , Red_Hat_Solution__c
                         , Target_Groups__c
                      from R00NR0000000QJRyMAO__r)
                      
                 // Find fund claims
                 , (select Name
                         , Activity_Result_Rating__c
                         , Actual_Attendees__c
                         , Actual_Leads__c
                         , Actual_Responses__c
                         , Additional_Feedback__c
                         , Approval_Status__c
                         , Budget__c
                         , Fund_Request__c
                         , convertCurrency(Requested_Amount__c)
                         , Should_We_Repeat__c
                      from R00NR0000000QJSkMAO__r)
              from SFDC_Budget__c
             where Id = : getBudgetId()
        ];
        
        return getBudget();
    }

    public List<FundPair> getFundPairList() {
        if (fundList != null)
            return fundList;
        
        // First build an Request Id => Claim Object map of the claims
        Map<Id, SFDC_MDF_Claim__c> claimMap = new Map<Id, SFDC_MDF_Claim__c>();
        
        for (SFDC_MDF_Claim__c fundClaim : getBudget().R00NR0000000QJSkMAO__r)
            claimMap.put(fundClaim.Fund_Request__c, fundClaim);
        
        // Now loop through the requests, and use the map to create the fund pairs
        Integer fundPosition = 1;
        fundList = new List<FundPair>();
        
        for (SFDC_MDF__c fundRequest : getBudget().R00NR0000000QJRyMAO__r) {
            FundPair fundPair = new FundPair();
            fundPair.request = fundRequest;
            fundPair.claim = claimMap.get(fundRequest.Id);
            fundPair.position = fundPosition++;
            fundList.add(fundPair);
        }
        
        return fundList;
    }
}