trigger LeadManagementHistory_OwnerLink on LeadManagementHistory__c (before insert, before update) {
	Set<Id> ownerIds = new Set<Id>();
	for(LeadManagementHistory__c lmh : Trigger.new) {
		LeadManagementHistory__c old_lmh = new LeadManagementHistory__c();
		if(Trigger.isUpdate) {
			old_lmh = Trigger.oldMap.get(lmh.Id);
		}
		if(lmh.Owner_From__c == null || lmh.OwnerId_From__c != old_lmh.OwnerId_From__c) {
			lmh.Group_Name_From__c = null;
			lmh.Owner_Lookup_From__c = null;
			if(lmh.Owner_From__c != null) {
				try {
					Id ownerId = lmh.OwnerId_From__c;
					lmh.OwnerId_From__c = ownerId;
					ownerIds.add(ownerId);
				}
				catch(Exception e) {
					lmh.addError('Invalid Owner_From__c='+lmh.OwnerId_From__c+': '+e);
					lmh.OwnerId_From__c = null;
				}
			}
		}
		if(lmh.OwnerId_To__c == null || lmh.OwnerId_To__c != old_lmh.OwnerId_To__c) {
			lmh.Group_Name_To__c = null;
			lmh.Owner_Lookup_To__c = null;
			if(lmh.OwnerId_To__c != null) {
				try {
					Id ownerId = lmh.OwnerId_To__c;
					lmh.OwnerId_To__c = ownerId;
					ownerIds.add(ownerId);
				}
				catch(Exception e) {
					lmh.addError('Invalid Owner_To__c='+lmh.OwnerId_To__c+': '+e);
					lmh.OwnerId_To__c = null;
				}
			}
		}
	}
	if(! ownerIds.isEmpty()) {
		Map<Id,Group> groupMap = new Map<Id,Group>([
			select Name from Group where Type= 'Queue' and Id in :ownerIds ]);
		for(LeadManagementHistory__c lmh : Trigger.new) {
			if(ownerIds.contains(lmh.OwnerId_From__c)) {
				Group g = groupMap.get(lmh.OwnerId_From__c);
				if(g != null) {
					lmh.Group_Name_From__c = g.Name;
				}
				else {
					lmh.Owner_Lookup_From__c = lmh.OwnerId_From__c;
				}
			}
			if(ownerIds.contains(lmh.OwnerId_To__c)) {
				Group g = groupMap.get(lmh.OwnerId_To__c);
				if(g != null) {
					lmh.Group_Name_To__c = g.Name;
				}
				else {
					lmh.Owner_Lookup_To__c = lmh.OwnerId_To__c;
				}
			}
		}
	}
}