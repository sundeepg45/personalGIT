trigger Opportunity_UpdateFirstYearPayment on Opportunity (before insert, before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    for(Integer i=0; i<Trigger.new.size(); i++)
    { 
        if(Trigger.isUpdate || Trigger.isInsert)
        {
            if(Trigger.new[i].Pay_Now__c=='Yes')
            {
                if(Trigger.new[i].Amount != null)
                {
                    Trigger.new[i].Year1PaymentAmount__c=Trigger.new[i].Amount; 
                }
                if(Trigger.new[i].Amount == null || Trigger.new[i].Amount == 0)
                {
                    Trigger.new[i].Year1PaymentAmount__c=null;
                }
            }
        }
    }
}