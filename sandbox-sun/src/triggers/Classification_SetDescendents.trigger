trigger Classification_SetDescendents on Classification__c (before update) {
    //
    // Reset the descendents values
    //    
    
    for(Classification__c classification : Trigger.new)
        classification.Descendents__c = 0;
        
    //
    // Loop and sum
    //

    Set<Id> classificationIds = Trigger.oldMap.keySet();
    
    for(Classification__c classification : [
        select Parent__c
          from Classification__c
         where Parent__c in :Trigger.new
    ]) Trigger.newMap.get(classification.Parent__c).Descendents__c ++;

}