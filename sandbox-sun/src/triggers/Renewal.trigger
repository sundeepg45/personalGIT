/**
* This functionality is deactivated as part of Opp Form March 23rd Release.
*
*/


trigger Renewal on Opportunity (after update)
{
   /* if(Util.channelLoadByPass()) return;
    if(Trigger.isAfter)
    {
        if(Trigger.isUpdate)
        {
            for(Integer i=0;i<Trigger.new.size();i++)
            {
                if(Trigger.new[i].StageName == 'Closed Booked'
                    && Trigger.new[i].Renewable__c== 'Yes'
                    && (Trigger.old[i].StageName != 'Closed Booked'
                        || Trigger.old[i].Renewable__c == 'Deferred')
                        && (Trigger.old[i].RecordTypeId != Util.OpportunityBookedOppRecordTypeId))
                {
                    Opportunity opp = null;
                    try
                    {
                        opp =  [select Id from Opportunity where Source_Opportunity__c = :Trigger.new[i].Id limit 1];
                    }
                    catch(Exception ignored) {}

                    if(opp == null)
                    {
                        //create renewal opportunity
                        Renewal.renew(Trigger.new[i],Trigger.old[i].RecordTypeId,false);
                    }
                }
            }
        }
    }*/
}