trigger ContactTrack_HasOnePrimaryTrigger on Contact_Track__c (after undelete, before insert, before update) {
	Set<Id> contactIds = new Set<Id>();
	for (Contact_Track__c c : Trigger.new){
		// Only check if this is a new primary track or an existing changed track is being set to primary
		if ((Trigger.isInsert && c.Primary__c) || (c.Primary__c && !Trigger.oldMap.get(c.Id).Primary__c)){
			contactIds.add(c.Contact__c);
		}
	}
	
	List<Contact_Track__c> cList = [select Contact__c from Contact_Track__c where Contact__c in :contactIds and Primary__c = true];
	Set<Id> contactsWithPrimaryIds = new Set<Id>();
	for (Contact_Track__c c : cList){
		contactsWithPrimaryIds.add(c.Contact__c);
	}
	
	
	for (Contact_Track__c c : Trigger.new){
		// Only check if this is a new primary track or an existing changed track is being set to primary
		if ((Trigger.isInsert && c.Primary__c) || (c.Primary__c && !Trigger.oldMap.get(c.Id).Primary__c)){
			// Already has one
			if (contactsWithPrimaryIds.contains(c.Contact__c)){
				c.addError('A Contact can only have one primary Track');
			}
		}
	}
	
}