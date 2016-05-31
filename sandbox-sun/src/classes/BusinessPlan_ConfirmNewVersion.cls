public with sharing class BusinessPlan_ConfirmNewVersion {
    public BusinessPlan_ConfirmNewVersion(ApexPages.StandardController controller) {
    	this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
    	set;
    	get;
    }
    
    public PageReference confirmUpdate() {
    	Id recordId = CloneBizPlan.BizPlan(controller.getId());
    	
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