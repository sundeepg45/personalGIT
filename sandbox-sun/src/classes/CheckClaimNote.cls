public class CheckClaimNote
{
    public static void validateClaimNote(SFDC_MDF_Claim__c claimuser)
{ 
    List<Attachment> att= new List<Attachment>();
    String errorMessage='';
    try 
    { 
        
        SFDC_MDF_Claim__c claim=[Select Id,Account__c,Fund_Request__c,Fund_Claim_Number_new__c,Name,Accounting_Type__c, Activity_Type__c,Partner_Type__c from SFDC_MDF_Claim__c where Id =:claimuser.Id];
        SFDC_MDF__c req=[Select Accounting_Type__c, Activity_Type__c, Id, Partner_Type__c from SFDC_MDF__c where Id =:claim.Fund_Request__c];

            if(!(req.Activity_Type__c=='Achieving Revenue or Invoicing Targets' && req.Accounting_Type__c=='Revenue Reversal' && req.Partner_Type__c=='Distributor'))
            {
                    
                    
                            att=[Select Id, Name,ParentId from Attachment where ParentId =:claim.Id];
                                                        
                            if(att.size()==0)
                            {
                                    
                                    errorMessage = System.Label.FundRequest_ErrorNoProofOfPerformance;
                                                                }
                           
         
             if(errorMessage !=''){
    
                errorMessage = errorMessage + '\n'+'\n'+'\n'+System.Label.FundRequest_ErrorUseBackButton;
                claimuser.addError(errorMessage);
                
              }

    }
    } 
 catch(Exception e) 
        { 

        } 
    }


 }