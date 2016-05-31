public with sharing class FundRequest_CreateFundClaim {
    public FundRequest_CreateFundClaim(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public SFDC_MDF__c fundRequest {
    	set;
    	get {
    		if (fundRequest == null)
    		    fundRequest = [
                    select Name
                         , Account_Master__r.Name
                         , Account_Master__c
                         , Approval_Status_Partner__c
                         , Budget__r.Name
                         , Budget__c
                         , (select Id from Fund_Claims__r)
                      from SFDC_MDF__c 
                     where Id = :controller.getId()
                ];
            return fundRequest;
    	}
    }
    
    public PageReference confirmUpdate() {
    	if (fundRequest.Approval_Status_Partner__c != 'Approved')
    	   return null;
        if (fundRequest.Fund_Claims__r.size() > 0)
           return null;
    	
        PageReference pageReference = new PageReference('/a1C/e');
        pageReference.getParameters().put('CF00N60000001f68g_lkid', fundRequest.Budget__c);
        pageReference.getParameters().put('CF00N60000001f68g', fundRequest.Budget__r.Name);
        pageReference.getParameters().put('CF00N60000001f67h_lkid', fundRequest.Account_Master__c);
        pageReference.getParameters().put('CF00N60000001f67h', fundRequest.Account_Master__r.Name);
        pageReference.getParameters().put('CF00N60000001f68u_lkid', fundRequest.Id);
        pageReference.getParameters().put('CF00N60000001f68u', fundRequest.Name);
        pageReference.getParameters().put('retURL', '%2F' + fundRequest.Id);
        pageReference.getParameters().put('cancelURL', '%2F' + fundRequest.Id);
        pageReference.getParameters().put('nooverride', '1');
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancelUpdate() {
        PageReference pageReference = new PageReference('/' + controller.getId());
        pageReference.setRedirect(true);
        return pageReference;
    }


}