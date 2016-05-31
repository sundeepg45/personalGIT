public with sharing class LeadCreateReferralController
{
    public String error {get; set;}

    public LeadCreateReferralController() {
    }
    
    public PageReference populateLead()
    {
        User me = [select SSI_User__c, Profile.Name, FirstName, LastName from User where Id = :UserInfo.getUserId()];
        
        if (me.SSI_User__c || String.valueOf(me.Profile.Name).contains('Administrator - Level')){
            
            Id oppId = ApexPages.currentPage().getParameters().get('oppId');
            Opportunity opp = [
                    select
                        Id,
                        AccountId,
                        Account.Name,
                        Super_Region__c,
                        Account.OracleAccountNumber__c,
                        ContractNumber__c,
                        Billing_Street__c,
                        Billing_City__c,
                        Billing_State__c,
                        Billing_Zip__c,
                        Billing_Country__c
                    from
                        Opportunity
                    where
                        Id = :oppId
                ];
            
            Lead l = new Lead();
            RecordType rt = [select Id from RecordType where Name = 'Partner Led Lead'];
            l.RecordType = rt;
            l.RecordTypeId = rt.Id;
            l.LastName = opp.Account.Name;
            l.Company = opp.Account.Name;
            l.Status = 'New';
            l.LeadSource = 'SSI Referral';
            l.Customer_ID__c = opp.AccountId;
            l.Original_Renewal_Opportunity__c = opp.Id;
            l.Partner_Led_Lead__c = True;
            l.Oracle_Account_Number__c = opp.Account.OracleAccountNumber__c;
            l.Contract_Number__c = opp.ContractNumber__c;
            l.Street = opp.Billing_Street__c;
            l.City = opp.Billing_City__c;
            l.State = opp.Billing_State__c;
            l.PostalCode = opp.Billing_Zip__c;
            l.Country = opp.Billing_Country__c;
            insert l;
            
            return new PageReference('/' + l.Id + '/e');
        } else {
            error = 'You do not have access to this function, if this is an error please contact your system administrator';
        }
        
        return null;
    }
    
    @IsTest(SeeAllData=true)    
    private static void simpleTest() {
        LeadCreateReferralController ctrl = new LeadCreateReferralController();
        Opportunity o = [select Id from Opportunity where RecordType.Name = 'Renewal' limit 1];
        ApexPages.currentPage().getParameters().put('oppId', String.valueOf(o.Id));
        ctrl.populateLead();
    }
    
}