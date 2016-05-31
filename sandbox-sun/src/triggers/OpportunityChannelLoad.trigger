trigger OpportunityChannelLoad on Opportunity (before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    // Ignore everything but channel load and unit tests
    if(! (Util.channelLoadByPass(true)||Util.isTesting())) return;

    if(Trigger.isAfter && Trigger.isUpdate)
    {
        for(Integer i=Trigger.new.size();i-- > 0;)
        {
            if(Trigger.new[i].Super_Region__c=='NA')
            {
                Trigger.new[i].Type = Trigger.old[i].Type;
            }
        }
    }
}