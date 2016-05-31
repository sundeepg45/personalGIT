/*
 * If screenshot attachment deleted from anti-corruption record, uncheck the checkbox
 */
trigger AntiCorruptionAttachment on Attachment (before delete) {

    String keyPrefix =  Anti_Corruption__c.sObjectType.getDescribe().keyPrefix;

    Set<ID> parentIdList = new Set<ID>();
    for (Attachment attach : Trigger.oldMap.values()) {
        String pid = attach.ParentId;
        if (pid.startsWith(keyPrefix)) {
            parentIdList.add(attach.ParentId);
        }
    }

    if (parentIdList.isEmpty()) {
        return;
    }

    Anti_Corruption__c[] acList = [
        select    Id, Screenshot_Attached__c
        from      Anti_Corruption__c
        where     Id in :parentIdList
    ];

    if (aclist.isEmpty()) {
        return;
    }

    for (Anti_Corruption__c ac : acList) {
        ac.Screenshot_Attached__c = false;
    }

    update acList;
}