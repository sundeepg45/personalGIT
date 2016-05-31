public with sharing class MDF_CreateFundRequest {
    public MDF_CreateFundRequest(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public ApexPages.StandardController controller {
        set;
        get;
    }
    
    public SFDC_Budget__c budget {
        set;
        get {
            try {
                if (budget == null)
                    budget = [
                        select Name
                             , Account_Master__r.Name
                             , Account_Master__r.Global_Region__c
                             , Account_Master__r.Subregion__c
                             , Account_Master__c
                             , Active__c
                             , End_Date__c
                          from SFDC_Budget__c 
                         where Id = :controller.getId()
                    ];
            } catch (System.QueryException e) {
                ApexPages.addMessages(e);
            }
            
            return budget;
        }
    }
    
    public AccountTeamMember accountTeamMember {
        set;
        get {
            try {
                if (accountTeamMember == null)
                    accountTeamMember = [
                        select Id
                          from AccountTeamMember
                         where (AccountId = :budget.Account_Master__c)
                           and (UserId = :UserInfo.getUserId())
                           and (AccountAccessLevel = 'Read/Write' or AccountAccessLevel = 'Owner')
                         limit 1
                    ];
            } catch (System.QueryException e) {
                ApexPages.addMessages(e);
            }
            
            return accountTeamMember;
        }
    }
    
    public PageReference confirmUpdate() {
        if (budget.Active__c != true)
           return null;
        if (budget.End_Date__c < Date.today())
           return null;
        //if (accountTeamMember == null)
        //    return null;

        // Find the right record type
        RecordType recordType = null;
        
        // @todo Zepp - This is extremely fragile. !!!
        if (budget.Account_Master__r.Global_Region__c == 'NA' && budget.Account_Master__r.Subregion__c == 'Fed Sled')
            recordType = [
                select Id
                  from RecordType
                 where Name = 'Fed Sled Fund Request'
            ];
        else
            recordType = [
                select Id
                  from RecordType
                 where Name = 'Main Fund Request'
            ];

        PageReference pageReference = new PageReference('/apex/FundRequest_Edit');
        pageReference.getParameters().put('budgetId', budget.Id); 
        pageReference.getParameters().put('accountId', budget.Account_Master__c);
        pageReference.getParameters().put('recordTypeId', recordType.Id);
        pageReference.getParameters().put('retURL', '%2F' + budget.Id);
        pageReference.getParameters().put('cancelURL', '%2F' + budget.Id);
        pageReference.getParameters().put('sfdc.override', '1');
        pageReference.setRedirect(true);
        return pageReference;
    }

    public PageReference cancelUpdate() {
        PageReference pageReference = new PageReference('/' + controller.getId());
        pageReference.setRedirect(true);
        return pageReference;
    }



}