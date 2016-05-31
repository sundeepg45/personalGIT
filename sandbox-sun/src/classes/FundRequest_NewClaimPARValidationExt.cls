public with sharing class FundRequest_NewClaimPARValidationExt {

    //private ID    regId;
    private ID  fundRequestId;

    public FundRequest_NewClaimPARValidationExt(ApexPages.StandardController controller) {
        fundRequestId = controller.getId();
        //regId = fundRequest.Partner_Registration__c;
    }

    public SFDC_MDF__c fundRequest {
        set;
        get {
            if (fundRequest == null)
                fundRequest = [
                    select Name
                         , Account_Master__r.Name
                         , Account_Master__r.OwnerId
                         , Account_Master__r.Owner.Name
                         , Account_Master__c
                         , Approval_Status_Partner__c
                         , Partner_Registration__c
                         , Budget__r.Name
                         , Budget__c
                         , (select Id from Fund_Claims__r)
                      from SFDC_MDF__c 
                     where Id = :fundRequestId
                ];
            return fundRequest;
        }
    }

    public PageReference confirmCreate() {
        if (fundRequest.Approval_Status_Partner__c != 'Approved')
           return null;
        
        PageReference pageReference = new PageReference('/a1C/e');
        pageReference.getParameters().put('CF00N60000001f68g_lkid', fundRequest.Budget__c);
        pageReference.getParameters().put('CF00N60000001f68g', fundRequest.Budget__r.Name);
        pageReference.getParameters().put('CF00N60000001f67h_lkid', fundRequest.Account_Master__c);
        pageReference.getParameters().put('CF00N60000001f67h', fundRequest.Account_Master__r.Name);
        
        pageReference.getParameters().put('CF00N60000001f690', fundRequest.Account_Master__r.Owner.Name);
        pageReference.getParameters().put('CF00N60000001f690_lkid', fundRequest.Account_Master__r.OwnerId);
        
        pageReference.getParameters().put('CF00N60000001f68u_lkid', fundRequest.Id);
        pageReference.getParameters().put('CF00N60000001f68u', fundRequest.Name);
        pageReference.getParameters().put('retURL', '/' + fundRequest.Id);
        pageReference.getParameters().put('cancelURL', '/' + fundRequest.Id);
        pageReference.getParameters().put('nooverride', '1');
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancelCreate() {
        PageReference pageReference = new PageReference('/' + fundRequestId);
        pageReference.setRedirect(true);
        return pageReference;
    }


}