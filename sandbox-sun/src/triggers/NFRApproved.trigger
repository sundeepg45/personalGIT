/*
* Name : NFRApproved
* Author : Rohit Mehta
* Date : 03222010
* Usage : Util class Used by the NFR Classes/Triggers
*/
trigger NFRApproved on NFR_Request__c (before insert, after insert, after update) {

    if (Trigger.isInsert && Trigger.isBefore) {
        User u = null;
        if  (Userinfo.getUserType().equalsIgnoreCase('powerpartner')){
            u = [Select Contact.AccountId from User where Id = :UserInfo.getUserId()];
        }
        Set<Id> accountIds = new Set<Id>();
        for (NFR_Request__c nfr : trigger.new) {
            if  (Userinfo.getUserType().equalsIgnoreCase('powerpartner')){
                nfr.Partner__c = u.Contact.AccountId;
            }
            accountIds.add(nfr.Partner__c);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([Select PartnerStatuses__c from Account
            where Id In :accountIds]);

        for (NFR_Request__c nfr : trigger.new) {
            Account a = accountMap.get(nfr.Partner__c);
            nfr.Partner_Status__c = a.PartnerStatuses__c;
        }
    } else if (Trigger.isUpdate) {
        Set<Id> nfrIds = new Set<Id>();

        for (NFR_Request__c nfr : trigger.new) {
            String status = nfr.Status__c;
            if (status.equalsIgnoreCase('Approved') && NFRUtil.hasChanges('Status__c', trigger.oldMap.get(nfr.Id), nfr)) {
                nfrIds.add(nfr.Id);
            }
        }

        if (! nfrIds.isEmpty()) {
            NFRCreateOnOnboarding.createNFROpportunity(nfrIds);
        }
    }

    //create shares if after
    if (Trigger.isAfter) {
        //map - NFRId => PartnerId
        Map<Id, Id> sObject_partner_map = new Map<Id, Id>();
        //map - NFRId => Old PartnerId
        Map<Id, Id> sObject_oldPartner_map = new Map<Id, Id>();

        for (NFR_Request__c sObj : trigger.new) {

            Boolean partnerChanged = trigger.isUpdate && NFRUtil.hasChanges('Partner__c',
                trigger.oldMap.get(sObj.Id), sObj);
            if (partnerChanged) {
                sObject_oldPartner_map.put(sObj.Id, trigger.oldMap.get(sObj.Id).Partner__c);
            }

            if (trigger.isInsert || partnerChanged) {
                sObject_partner_map.put(sObj.Id, sObj.Partner__c);
            }
        }

        if (! sObject_oldPartner_map.isEmpty()) {
            CreatePartnerShareForNFR.removeNFRShare(sObject_oldPartner_map);
        }

        if (! sObject_partner_map.isEmpty()) {
            CreatePartnerShareForNFR.createNFRShare(sObject_partner_map);
        }
    }


}