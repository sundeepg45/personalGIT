/** 
 * This trigger is designed to stop a user from creating more than one fund claim
 * per approved fund request.
 *
 * @author Ian Zepp <izepp@redhat.com>
 * @todo Optimize SOQL queries to do one grouped query, instead of one per claim.
 *
 * History
 * 3/21/2014 - mdemegli - Added criteria for PAR fund requests so that multiple claims
 *             can be created for a single PAR Fund Request.
 */

trigger FundClaim_RejectDuplicateClaims on SFDC_MDF_Claim__c (before insert) 
{
    for (SFDC_MDF_Claim__c claim : Trigger.new)
    {
        Integer approvedClaims = [
            select count ()
              from SFDC_MDF_Claim__c
             where Fund_Request__c = : claim.Fund_Request__c
               and Fund_Request__r.RecordType.DeveloperName != 'PAR'
               and Fund_Request__r.Approval_Status__c in ('Approved')
        ];
        
        if (approvedClaims == 0)
            continue;
        claim.addError (System.Label.FundClaim_ErrorOneClaimPerRequest);
    }
}