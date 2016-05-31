/**
* This functionality is deactivated as part of Opp Form March 23rd Release
*
*/

trigger clearRenewalSource on Opportunity (before insert)
{
   /* if(Trigger.isBefore && Trigger.isInsert)
    {
        String profileId = UserInfo.getProfileId();
        for(Integer i=0;i<Trigger.new.size();i++)
        {
            //if(!Trigger.new[i].fromRenewal__c )
            //{
                Trigger.new[i].Source_Opportunity__c = null;
                
                //ignore if profile is channel load
                if(profileId != '00e60000000uwVRAAY')
                {
                    Trigger.new[i].StageName = 'Unqualified';
                }
            //}
            //Trigger.new[i].fromRenewal__c = false;
        }
    }*/
}