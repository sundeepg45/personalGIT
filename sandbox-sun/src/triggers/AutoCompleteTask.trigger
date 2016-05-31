trigger AutoCompleteTask on Opportunity (after update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    Map<String,String> oppIds= new Map<String,String>();
    List<Task> uptasks = new List<Task>();
    for(Integer i=0;i<Trigger.new.size();i++)
    {
        if(Trigger.old[i].StageName != 'Closed Booked' && Trigger.new[i].StageName == 'Closed Booked')
        {
            oppIds.put(Trigger.new[i].Id,Trigger.new[i].Id);
            system.debug('test*******************'+oppIds+'rererewr');
        }
    }

    if(oppIds.size() > 0)
    {
        try {
            Task[] tasks =[Select RecordTypeId,activityDate, Status, Subject, WhatId from Task
            where whatid IN: oppIds.Values()
            and Status <>'Completed' and ( RecordTypeId=:Util.omCorrectionRequestRecordTypeId OR  RecordTypeId=:Util.omProcessingRecordTypeId ) ];
            system.debug('test*****&&&&&&&&&&&**************'+tasks+tasks[0].RecordTypeId);
            for( Task tk : tasks )
            {
                tk.status='Completed';
                tk.activityDate = System.today();
                uptasks.add(tk);
                system.debug('test&&&&&&&&*****&&&&'+uptasks);
            }
        }catch(Exception ignored){}

        update uptasks;
    }
}