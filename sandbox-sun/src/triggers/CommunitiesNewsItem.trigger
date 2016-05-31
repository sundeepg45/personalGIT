trigger CommunitiesNewsItem on Communities_News_Item__c (before update, before insert) {
    if(trigger.isBefore){
        if(trigger.isUpdate){
            Map<Id,Communities_News_Item__c> oldMap = trigger.oldMap;
            Map<Id, Communities_News_Item__c> idsToTriggeredRecords = new Map<Id, Communities_News_Item__c>();
            for(Communities_News_Item__c cni : trigger.new){
                idsToTriggeredRecords.put(cni.id, cni);
            }
            List<Communities_News_Item__c> itemsToCheck = [SELECT Id, Name, Status__c, (SELECT Label__c, Language_Code__c
                                                            FROM Communities_News_Item_Labels__r) FROM Communities_News_Item__c WHERE id in :idsToTriggeredRecords.keyset()];
            for(Communities_News_Item__c cni : itemsToCheck){
                if(cni.Status__c=='Published' && oldMap.get(cni.id).Status__c!='Published'){
                    if(cni.Communities_News_Item_Labels__r == null || cni.Communities_News_Item_Labels__r.size()==0){
                        idsToTriggeredRecords.get(cni.id).addError('You can not publish a News Item unless it has at least one News Item Label associated with it.')
;                    }else{
                        if(cni.Communities_News_Item_Labels__r[0].Language_Code__c == null || cni.Communities_News_Item_Labels__r[0].Label__c == null){
                            idsToTriggeredRecords.get(cni.id).addError('One of your labels does not have a language assigned or has a blank label.  You must have some text in the label field and an assigned language before publishing a News Item.');
                        }
                    }
                }
            }
        }
        if(trigger.isInsert){
            for(Communities_News_Item__c cni : trigger.new){
                if(cni.Status__c=='Published'){
                    cni.addError('You can not set a News Item\'s status to published when creating the record, because it will not have any News Item Labels.  Create some News Item Labels and then set the status.');
                }
            }
        }
    }
}