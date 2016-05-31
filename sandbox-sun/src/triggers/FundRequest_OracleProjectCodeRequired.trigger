trigger FundRequest_OracleProjectCodeRequired on SFDC_MDF__c (after update) {

// The Oracle Project code is required before you can submit the Fund Request for approvals, in EMEA is only required if the fund request is > 3000 

 Set<Id> accountIds = new Set<Id>();
 for  ( SFDC_MDF__c FundRequest : Trigger.new ){
     accountIds.add(FundRequest.Account_master__c);

 // Query the Account table
    Map<Id, Account> fields = new Map<Id, Account>([select Global_Region__c from Account where id in :accountIds]);
  
 string GlobalRegion = fields.get(FundRequest.Account_master__c).Global_Region__c ; 

 
 
     if  (FundRequest.Oracle_Project_Code__c == null && (FundRequest.Approval_Status__c == 'Pending Final Approval' || FundRequest.Approval_Status__c == 'Approved') )
    {
        if (fields.get(FundRequest.Account_master__c).Global_Region__c != 'EMEA')
                    {   
                        FundRequest.addError('A fund Request could not be approved without a Oracle Project Code');
                    }
        else if  (fields.get(FundRequest.Account_master__c).Global_Region__c == 'EMEA' && FundRequest.Estimated_Red_Hat_Funding_Requested__c > 3000)            
{   
                        FundRequest.addError('A fund Request could not be approved without a Oracle Project Code if the Estimated Red Hat Funding Request is greater than 3000');
                    }

}
}
}