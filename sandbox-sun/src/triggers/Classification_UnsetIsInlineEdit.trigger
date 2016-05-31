trigger Classification_UnsetIsInlineEdit on Classification__c (before insert, before update) {
    for(Classification__c classification : Trigger.new)
        classification.IsInlineEdit__c = false;
}