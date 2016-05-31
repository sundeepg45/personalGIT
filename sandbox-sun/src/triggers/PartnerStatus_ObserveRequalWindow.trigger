trigger PartnerStatus_ObserveRequalWindow on PartnerStatus__c (before insert) {
	List<Id> partnerIds = new List<Id>();
	for (PartnerStatus__c status : Trigger.new) partnerIds.add(status.Partner__c);
	
	List<Account> partners = [select Id, Enrollment_Date__c, RequalStatus__c, RequalificationDate__c from Account where Id in :partnerIds];
	
	//
	// now using requalstatus flag -- much simpler
	//
	for (PartnerStatus__c status : Trigger.new) {
		for (Account partner : partners) {
			if (partner.id == status.Partner__c) {
				if (partner.RequalStatus__c == 'Eligible' || partner.RequalStatus__c == 'In Progress' || partner.RequalStatus__c == 'Submitted') {
	            	status.addError('A status may not be added while partner re-qualification is in progress');
				}
				break;
			}
		}
	}

}