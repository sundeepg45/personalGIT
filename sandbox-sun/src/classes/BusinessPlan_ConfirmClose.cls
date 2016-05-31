public with sharing class BusinessPlan_ConfirmClose {
    public BusinessPlan_ConfirmClose(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public PageReference confirmUpdate() {
        Id recordId = CloseBizPlan.BizPlan(controller.getId());
        
        PageReference pageReference = new PageReference('/' + recordId + '/e?retURL=%2F' + recordId);
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancelUpdate() {
        PageReference pageReference = new PageReference('/' + controller.getId());
        pageReference.setRedirect(true);
        return pageReference;
    }

}