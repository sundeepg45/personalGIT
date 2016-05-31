trigger FundClaim_CreateClaimNotification on SFDC_MDF_Claim__c (after update)
{
    if(Trigger.isAfter)
    {
         if(Trigger.isUpdate)
          {
             set<ID> accountIds = new set<ID>();
             for(SFDC_MDF_Claim__c c: Trigger.new)
                accountIds.add(c.Account__c); 
            
            List<Account> accountList = new List<Account>([select id, Subregion__c from Account where Id in:accountIds]);   
            Map<Id, String> accountIdMap = new Map<id, String>(); 
            for(Account a: accountList)
                accountIdMap.put(a.Id, a.Subregion__c);
           
           
           
           
            for( Integer i=0; i<Trigger.new.size(); i++ )
                {
                   if((Trigger.old[i].Approval_Status__c != 'Pending Final Approval')&& (Trigger.new[i].Approval_Status__c =='Pending Final Approval'))
                    {
                       if(Trigger.new[i].Partner_Type__c !='Distributor' || accountIdMap.get(Trigger.new[i].Account__c) == 'Fed Sled')
                        {    ClaimNotification.createClaimMail(Trigger.new[i]);  
                        }                        
                    }
                }
          }

    }
}