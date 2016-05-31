trigger PartnerLocation_PropgateIsPrimary on Partner_Location__c (before insert, before update) {
	
	List<Id> affectedAccounts = new List<Id>();
	for (Partner_Location__c pl : Trigger.new){
		if (pl.Is_Primary__c){
			affectedAccounts.add(pl.Partner__c);
		}
	}
	
	// Only run if there is any affected
	if (affectedAccounts.size() > 0){
		List<Partner_Location__c> locList = new List<Partner_Location__c>();
		// Leave the list empty in case it is new locations and there is no ids in old
		if (Trigger.old != null){
			locList = Trigger.old;
		}
		 
		List<Partner_Location__c> locs = [Select Id, Is_Primary__c, Partner__c from Partner_Location__c where Partner__c in :affectedAccounts and Id not in :locList];
		for(Partner_Location__c pl : locs){
			pl.Is_Primary__c = false;
		}
		update locs;
	}

}