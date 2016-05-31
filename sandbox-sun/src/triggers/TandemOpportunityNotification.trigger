trigger TandemOpportunityNotification on Opportunity (after Insert,before update)
{
    if(Util.adminByPass()) return;
    if(Trigger.isInsert)
    {
        for(Integer i=0;i<Trigger.size;i++ )
        {
            String oppid=Trigger.new[i].id;
            Opportunity opp=Util.getOpportunityData(oppid);

            if(Trigger.new[i].EMEA_SE_Required__c || opp.account.EMEA_SE_Required__c)
            {
                new TandemNotifcationMail().createMail(Trigger.new[i]);
            }
        }
    }

    if(Trigger.isUpdate && Trigger.isBefore)
    {
        for(Integer i=0;i<Trigger.size;i++ )
        {
            Opportunity opp= null;

            opp= Util.getOpportunityData(Trigger.new[i].id);

            if(Trigger.old[i].stageName != Trigger.new[i].stageName || Trigger.old[i].closedate != Trigger.new[i].closedate || Trigger.old[i].amount != Trigger.new[i].amount )
            {
                if(Trigger.new[i].EMEA_SE_Required__c || opp.account.EMEA_SE_Required__c)
                {
                    new TandemNotifcationMail().createMailOnTandemOppUpdate(Trigger.old[i],Trigger.new[i]);
                }
            }
        }
    }
}