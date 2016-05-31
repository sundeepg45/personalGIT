trigger Opportunity_Submitted_updateOwner on Opportunity (before insert, before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    if(Trigger.isBefore)
    {
        if(Trigger.isUpdate || Trigger.isInsert)
        {
            RecordType recordType = [Select Id from RecordType where DeveloperName = 'ICC']; 
            Map<String,String> oppOwnerId= new Map<String,String>();
            for(Integer i=0;i<Trigger.new.size();i++)
            {
                if(Trigger.new[i].DateOrderSubmitted__c != null)
                {
                    if(Util.ownerUpdate.get(Trigger.new[i].Id) != null) continue;
                    
                    Util.ownerUpdate.put(Trigger.new[i].Id,'Y');
                    if(Trigger.isInsert)
                    {
                        oppOwnerId.put( String.valueOf(i),Trigger.new[i].OwnerId);
                    }
                    else if( Trigger.old[i].StageName != 'Closed Booked'
                        && Trigger.old[i].StageName != 'Closed Won' )
                    {
                        oppOwnerId.put( Trigger.new[i].Id,Trigger.new[i].OwnerId);
                    }
                }
                //Added for US64903 to populate Owner_Role_at_Close__c when stage is Booked
                if((Trigger.new[i].RecordTypeId == recordType.Id && Trigger.new[i].StageName == 'Closed Booked') || (Trigger.new[i].StageName == 'Closed Booked' && Trigger.new[i].OracleOrderNumber__c!=null && Trigger.new[i].OracleOrderNumber__c!=''))
                {
                    oppOwnerId.put( Trigger.new[i].Id,Trigger.new[i].OwnerId);
                }
                System.debug('oppOwnerId = '+oppOwnerId);
            }
            if(oppOwnerId.size()>0)
            {
                new OpportunitySubmittedupdateOwner().updateOwnerRole(oppOwnerId,Trigger.new);
            }
        }
    }
}