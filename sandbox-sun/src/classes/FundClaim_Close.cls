public with sharing class FundClaim_Close {
    public FundClaim_Close(ApexPages.StandardController controller) {
    	this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
    	set;
    	get;
    }

    public PageReference upsertClosedClaim() {
        upsert new SFDC_MDF_Claim__c(
            Id = controller.getId(),
            Approval_Status__c = 'Expired',
            Approval_Status_Partner__c = 'Expired'
        );
        
        PageReference pageReference = new PageReference('/' + controller.getId());
        pageReference.setRedirect(true);
    	return pageReference;
    }
}