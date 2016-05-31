trigger PartnerStatus_UpdateAccount on PartnerStatus__c (after delete, after insert, after update) {


    Set<Id> partnerIds = new Set<Id>();
    Map<Id, PartnerStatus__c> partnerStatusByPartnerIdMap = new Map<Id, PartnerStatus__c> (); //added for May AM Release Case # RH-00138430

    if (Trigger.isInsert || Trigger.isUpdate)
        for(PartnerStatus__c partnerStatus : Trigger.new) {
            partnerIds.add(partnerStatus.Partner__c);
            partnerStatusByPartnerIdMap.put(partnerStatus.Partner__c, partnerStatus); //added for May AM Release Case # RH-00138430
        }

    if (Trigger.isDelete) {
        for(PartnerStatus__c partnerStatus : Trigger.old)
            partnerIds.add(partnerStatus.Partner__c);
    }

/* Moved to PartnerStatus_UpdateAccount.updateAccountFields and refactored to save SOQL - mls 7/30/12
    for (ID partnerId : partnerIds) {
    	AccountTeamRulesUtils.updateRules(partnerId);
    }
*/

    //System.debug('[DEBUG]-------------------------------- PartnerStatus_UpdateAccount, isFuture=' + System.isFuture());
    //if (System.isFuture()){
    if (Trigger.isUpdate) {
//    	PartnerStatus_UpdateAccount.updateAccountFields(partnerIds);

    	// Jayant - Following statement has been added for May AM Release Case # RH-00138430 - Begin
    	PartnerStatusTriggerPRL.updateOppPartnerFields(partnerStatusByPartnerIdMap);
    	// End
    }
    //} else {
    //	PartnerStatus_UpdateAccount.updateAccountFieldsFuture(partnerIds);
    //}

/*
    //
    // Get accounts and update finder fields
    //
    Map<ID, Account> acctmap = new Map<ID, Account>([
    		select	Id,
    				Finder_Partner_Type__c,
    				Finder_Partner_Tier__c,
    				Finder_Sort_Hint__c
    		  from	Account
    		 where 	Id in :partnerIds]);

    if (!Trigger.isDelete) {
	    for (PartnerStatus__c partnerStatus : Trigger.new) {
	    	if (partnerStatus.ActivationStatus__c == 'Active') {
	    		Account acct = acctmap.get(partnerStatus.Partner__c);
	    		acct.Finder_Partner_Type__c = partnerStatus.PartnerType__c;
	    		acct.Finder_Partner_Tier__c = partnerStatus.PartnerTier__c;
	    	}
	    }

		//
		// Calculate the new sorting hint
		//
		if (partnerIds.size() > 0) {
			for (PartnerStatus__c ps : Trigger.new) {
				if (ps.ActivationStatus__c != 'Active') continue;
				if (PFUtils.isEmpty(ps.PartnerTier__c)) continue;
				if (acctmap.containsKey(ps.Partner__c)) {
					Account acct = acctmap.get(ps.Partner__c);
					if (ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c) {
						acct.Finder_Sort_Hint__c = 3;
					}
					else
					if (ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c) {
						acct.Finder_Sort_Hint__c = 2;
					}
					else
					if (ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c) {
						acct.Finder_Sort_Hint__c = 1;
					}
				}
			}
		}
    }


	update acctmap.values();
*/
    //
    // We also need to trigger an update on the account, so that the partner status field updates properly.
    //

    //APPR_DGRP.DynamicGroupUtil.isAsync = true;

//    List<Account> batch = new List<Account>();
//    for (Id id : partnerIds) {
//    	batch.add(new Account(Id = id));
//    }
//    update acctmap.values();

}