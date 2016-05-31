trigger Classification_SetDescendentsFromChild on Classification__c (after delete, after insert, after undelete) {
    Set<Id> classificationIds = new Set<Id>();
    
    if (Trigger.new != null) {
        for(Classification__c classification : Trigger.new)
            classificationIds.add(classification.Parent__c);
    }

    if (Trigger.old != null) {
        for(Classification__c classification : Trigger.old)
            classificationIds.add(classification.Parent__c);
    }

    update [
        select Id
          from Classification__c
         where Id in :classificationIds
    ];
}