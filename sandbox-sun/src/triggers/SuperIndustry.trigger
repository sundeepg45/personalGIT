trigger SuperIndustry on Account (before insert, before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    Super_Industry__c[] superIndustries = null;
    Map<String, String> industryMap = null;
    Map<String,String> industries = new Map<String,String>();
    Boolean needCompletion = False;
    if(Trigger.isUpdate || Trigger.isInsert)
    {
        if (Trigger.isInsert) {
            needCompletion = True;
        }
        else if (Trigger.isUpdate) {
            for (Account acct : Trigger.new) {
                if (acct.Super_Industry__c == null || acct.Industry != Trigger.oldMap.get(acct.Id).Industry) {
                    needCompletion = True;
                }
            }
        }
        //
        // mls - short circuit the following SOQL and logic if not needed in order to save on our test SOQL limits
        //
        if (!needCompletion) {
            return;
        }
        for(Integer i=0;i<Trigger.new.size();i++)
        {
            if( Trigger.new[i].Industry != null )
            {
                industries.put(Trigger.new[i].Industry.trim().toUpperCase(),Trigger.new[i].Industry.trim().toUpperCase());
            }
        }
        if(!industries.isEmpty())
        {
            industryMap = new Map<String, String>();
            try
            {
                superIndustries= [select Industry__c, Super_Industry__c  from Super_Industry__c where Industry__c IN :industries.values()];
                for(Super_Industry__c industry: superIndustries)
                {
                    industryMap.put(industry.Industry__c.toUpperCase(),industry.Super_Industry__c);
                }
            }
            catch(Exception ignored) {}
        }

        for(Integer i=0;i<Trigger.new.size();i++)
        {
            //populate values in opportunity
            try
            {
                if( Trigger.new[i].Industry != null )
                {
                    Trigger.new[i].Super_Industry__c = industryMap.get(Trigger.new[i].Industry.toUpperCase());
                }
            }
            catch(Exception ignored) {}
        }
    }
}