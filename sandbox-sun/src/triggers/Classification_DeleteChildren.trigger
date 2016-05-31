trigger Classification_DeleteChildren on Classification__c (before delete) {
    Set<Id> classificationIds = Trigger.oldMap.keySet();
    
    for(List<Classification__c> classificationList : [
        select Id
          from Classification__c
         where (Parent__c in :classificationIds
            or  Parent__r.Parent__c in :classificationIds
            or  Parent__r.Parent__r.Parent__c in :classificationIds
            or  Parent__r.Parent__r.Parent__r.Parent__c in :classificationIds
            or  Parent__r.Parent__r.Parent__r.Parent__r.Parent__c in :classificationIds)
           and Id not in :classificationIds
    ]) delete classificationList;
}