public with sharing class FundRequest_Edit {
    public FundRequest_Edit(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public Boolean isPartnerUser {
        get {
            return [
              select Name
                from Profile
               where Id = :UserInfo.getProfileId()
            ].Name.contains('Partner Portal');
        }
    }
    
    public PageReference initializeFundRequest() {
        Map<String,String> params = ApexPages.currentPage().getParameters();
        SFDC_MDF__c fundRequest = (SFDC_MDF__c) controller.getRecord();

        // Pay attention to new records only
        if (fundRequest.Id == null) {
            System.assert(null != params.get('recordTypeId'), 'The recordTypeId parameter is missing.');
            System.assert(null != params.get('budgetId'), 'The budgetId parameter is missing.');
        	
            fundRequest.RecordTypeId = params.get('recordTypeId');
            fundRequest.Budget__c = params.get('budgetId');
        }
        
        if (fundRequest.Account_Master__c == null && params.containsKey('accountName')) {
            fundRequest.Account_Master__r = [
                select RecordType.Name
                     , Global_Region__c
                     , Subregion__c
                  from Account
                 where Name = :params.get('accountName')
                 limit 1
            ];

            fundRequest.Account_Master__c = fundRequest.Account_Master__r.Id;
        }

        if (fundRequest.Account_Master__c == null && params.containsKey('accountId')) {
        	fundRequest.Account_Master__r = [
                select RecordType.Name
                     , Global_Region__c
                     , Subregion__c
                  from Account
                 where Id = :params.get('accountId')
                 limit 1
            ];

            fundRequest.Account_Master__c = fundRequest.Account_Master__r.Id;
        }
        
        return null;
    }
    
    public PageReference upsertRecord() {
    	try {
            SFDC_MDF__c fundRequest = (SFDC_MDF__c) controller.getRecord();
    	    upsert fundRequest;
    	   
    	    PageReference pageReference = new PageReference('/' + fundRequest.Id);
    	    pageReference.setRedirect(true);
    	    return pageReference;
    	} catch (Exception e) {
    		ApexPages.addMessages(e);
    		return null;
    	}
    }
}