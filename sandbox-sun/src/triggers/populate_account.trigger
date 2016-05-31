trigger populate_account on Contract (before update,before insert)
{
    if(Trigger.isBefore)
    {
        for(Integer i=0;i<Trigger.new.size();i++)
        {
            if(Trigger.new[i].Opportunity__c != null)
            {
                Opportunity opp = [select Id,AccountId from Opportunity where Id = :Trigger.new[i].Opportunity__c ];
                if(opp != null)
                {
                    Trigger.new[i].AccountId = opp.AccountId;
                }
            }
        }
    }
}