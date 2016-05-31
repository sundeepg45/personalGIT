public with sharing class OpportunityPartner_RedirectToManage {
    private ApexPages.StandardController controller;
    
    public OpportunityPartner_RedirectToManage(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public PageReference redirect() {
        PageReference pageReference = System.Page.Opportunity_ManagePartners;
        pagereference.getParameters().put('id', ((OpportunityPartner__c) controller.getRecord()).Opportunity__c);
        pagereference.getParameters().put('selectedId', controller.getId());
        pageReference.setRedirect(true);
        return pageReference;
    }
}