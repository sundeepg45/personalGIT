trigger LeadPartnerOptIn on Lead (after update)
{
    if( Trigger.isUpdate)
    {
        if(Trigger.isAfter)
        {
            List<Lead> leads = new List<Lead>();
            for(Integer i=0;i<Trigger.new.size();i++)
            {
                try {
                    if(Trigger.new[i].Partner_Opt_In__c != Trigger.old[i].Partner_Opt_In__c && Trigger.new[i].Partner_Opt_In_Last_Modified_By__c == null) {
                        Lead lead = [select Id from Lead  where Id=: Trigger.new[i].id limit 1];
                        lead.Partner_Opt_In_Last_Modified_By__c = Trigger.new[i].LastModifiedById;
                        lead.Partner_Opt_In_Last_Modified_Date__c = Trigger.new[i].LastModifiedDate;
                        leads.add(lead);
                    }
                }
                catch(Exception e){}
            }
            if(leads.size() > 0) {
                update leads;
            }
        }
    }
}