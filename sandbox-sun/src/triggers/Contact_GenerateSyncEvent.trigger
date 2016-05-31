trigger Contact_GenerateSyncEvent on Contact (after delete, after insert, after undelete, 
after update) {
/*
    List<SyncEvent__c> events = new List<SyncEvent__c>();
    if (Trigger.isInsert || Trigger.isUnDelete){
        for(SObject o : Trigger.new){
            events.add(SyncEvent_Generator.logObjectCreate(o));
        }
    } else if (Trigger.isUpdate){
        for(SObject o : Trigger.new){
            events.add(SyncEvent_Generator.logObjectUpdate(o));
        }
    } else if (Trigger.isDelete){
        for (SObject o : Trigger.old){
            events.add(SyncEvent_Generator.logObjectDelete(o));
        }
    }
    SyncEvent_Generator.storeEvents(events);
    
*/
}