public with sharing class FundRequest_Cancel {
    public FundRequest_Cancel(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public Integer getClaimsCount() {
        return [
            select COUNT()
              from SFDC_MDF_Claim__c
             where SFDC_MDF_Claim__c.Fund_Request__c = :controller.getId()
        ];
    }
    
    public PageReference save() {
        try {
         for(SFDC_MDF__c FR : [select id,Approval_Status__c  from SFDC_MDF__c where id = :controller.getId()]){
         FR.Approval_Status__c = 'Pending Cancellation';
         update FR;
         }
       
        
            // Create an approval request for the fund request 
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Submitting fund request for cancellation.');
            approvalRequest.setObjectId(controller.getId());
    
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            system.assert(approvalResult.isSuccess(), 'Unable to submit a cancellation request for the fund request.');

            PageReference pageReference = new PageReference('/' + controller.getId());
            pageReference.setRedirect(true);
            return pageReference;
        } catch (Exception pException) {
            ApexPages.addMessages(pException);
            return null;
        }
    }
}