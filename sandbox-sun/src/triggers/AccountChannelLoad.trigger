trigger AccountChannelLoad on Account (before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    // Ignore everything but channel load
    if(! Util.channelLoadByPass(true)) return;

    if(Trigger.isBefore && Trigger.isUpdate)
    {
        for(Integer i=0;i<Trigger.new.size();i++)
        {
            // If PrimaryBillToAcct is set, do not allow the update of a
            // non-empty Oracle Account Number
            if(Trigger.new[i].PrimaryBillToAcct__c && Trigger.old[i].OracleAccountNumber__c != null && Trigger.old[i].OracleAccountNumber__c.length() > 0)
            {
                Trigger.new[i].OracleAccountNumber__c = Trigger.old[i].OracleAccountNumber__c;
            }
        }
    }
}