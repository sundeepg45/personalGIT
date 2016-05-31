trigger Classification_DeleteTranslations on Classification__c (before delete) {
    for(List<ClassificationTranslation__c> classificationTranslationList : [
        select Id
          from ClassificationTranslation__c
         where Classification__c in :Trigger.old
    ]) delete classificationTranslationList;
}