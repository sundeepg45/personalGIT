trigger User_UniqueFieldCheck on User (before insert, before update) {
	Set<String> fedIdList = new Set<String>();
	if (Trigger.isInsert){
		for (User u : Trigger.new){
			if (u.Federation_Id__c != null){
				fedIdList.add(u.Federation_Id__c);
			}
		}
	} else {
		for (User u : Trigger.new){
			if (u.Federation_Id__c != Trigger.oldMap.get(u.Id).Federation_Id__c && u.Federation_Id__c != u.FederationIdentifier && u.Federation_Id__c != null){
				fedIdList.add(u.Federation_Id__c);
			}
		}
	}
	if (fedIdList.size() > 0){
		List<User> conflicts = [select Id, Federation_Id__c, FederationIdentifier from User where Federation_Id__c in :fedIdList or FederationIdentifier in :fedIdList];
		if (conflicts.size() > 0){
			Set<String> conflictingFedIds = new Set<String>();
			for (User u : conflicts){
				if (u.Federation_Id__c != null){
					conflictingFedIds.add(u.Federation_Id__c);
				}
				if (u.FederationIdentifier != null){
					conflictingFedIds.add(u.FederationIdentifier);
				}
			}
			for (User u : Trigger.new){
				if (u.Federation_Id__c != null && conflictingFedIds.contains(u.Federation_Id__c)){
					u.addError('Duplicate Federation Id "' + u.Federation_Id__c + '"". This Federation Id is already used.');
				}
			}			
		}
	}
}