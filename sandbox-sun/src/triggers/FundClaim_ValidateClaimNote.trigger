trigger FundClaim_ValidateClaimNote on SFDC_MDF_Claim__c (before update)
{
    for( Integer i=0; i<Trigger.new.size(); i++ )
                {
                   if(Trigger.new[i].Approval_Status__c=='Pending First Approval' &&  Trigger.old[i].Approval_Status__c=='Draft')
                    {
                       CheckClaimNote.validateClaimNote(Trigger.new[i]);  
                    }
                }


}