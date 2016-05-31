trigger ChangePartnerStatus on PartnerStatus__c (before update) {
/*
    Set<Id> previousPartnerIDs = new Set<Id>();
    for(PartnerStatus__c partnerStatus : Trigger.new) {
        PartnerStatus__c oldPartnerStatus = Trigger.oldMap.get(partnerStatus.Id);
        System.debug('Old PartnerStatus:::'+ oldPartnerStatus.ApprovalStatus__c);
        System.debug('New PartnerStatus :::'+ partnerStatus.ApprovalStatus__c);
        if (!partnerStatus.ApprovalStatus__c.equals(oldPartnerStatus.ApprovalStatus__c) && partnerStatus.ApprovalStatus__c.equals('Approved')) {
            partnerStatus.ActivationDate__c = System.today();
            //partnerStatus.ExpirationDate__c = System.today() + 364;
            partnerStatus.ExpirationDate__c = null;
            if (partnerStatus.Previous_Partner_Status__c != null) {
                previousPartnerIDs.add(partnerStatus.Previous_Partner_Status__c);
            }
        }
    }
    System.debug('Previous Partner IDs :::'+ previousPartnerIDs);
    if (previousPartnerIDs.size() > 0) {
        PreviousPartnerInfo.inactivate(previousPartnerIDs);
    }
*/
}