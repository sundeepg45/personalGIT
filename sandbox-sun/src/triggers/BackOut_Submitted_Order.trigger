trigger BackOut_Submitted_Order on Opportunity (after update)
{  
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
            List<Id>OppIds=new List<Id>();
            List<Task>tasks=new List<Task>();
            List<Task>updatetasks=new List<Task>();

           String omTaskId = Util.omProcessingRecordTypeId;

            for(Integer i=0;i<Trigger.new.size();i++)
            { 
                if(Trigger.new[i].DateOrderBooked__c == null
                     && Trigger.new[i].DateOrderSubmitted__c != null
                    && Trigger.new[i].StageName != 'Closed Booked'
                    && Trigger.new[i].StageName != 'Closed Won' 
                    && (Trigger.old[i].StageName == 'Closed Booked'  || Trigger.old[i].StageName == 'Closed Won' )
                    && Trigger.new[i].LastModifiedById != '00530000000f8SvAAI')
                    {
                        OppIds.add(Trigger.new[i].Id);
                    }
            }
            
            if(OppIds.size()==0) return;

                    tasks = [select Id from Task where WhatId IN :OppIds and RecordTypeId =:omTaskId and Status != 'Completed' ];
                    
                    for(Task tk : tasks)
                    {
                        tk.status='Completed';
                        updatetasks.add(tk);
                    }

                    update updatetasks;

  }