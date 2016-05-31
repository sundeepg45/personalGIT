trigger Lead_EnforceCCPCompletion on Lead (before update) {

	//
	// Filter out everything but what we want - CCP onboarding leads where an approver is trying to pass the first stage
	//
	Lead[] filtered = new List<Lead>();
	for (Lead lead : Trigger.new) {
		if (lead.Partner_Type__c == null || lead.Partner_Onboarding_Status__c == null) {
			continue;
		}
		Lead oldLead = Trigger.oldMap.get(lead.Id);
		if (lead.Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c &&
			lead.Partner_Onboarding_Status__c == 'First Approval' && oldLead.Partner_Onboarding_Status__c == 'Pending') {
				filtered.add(lead);
		}
	}
	
	if (!filtered.isEmpty()) {
		Partner_CCP_Form__c[] validforms = [
			select	Id, Lead__c
			from	Partner_CCP_Form__c
			where	Lead__c in :PartnerUtil.getIdSet(filtered)
			and		Is_Complete__c = true
		];
		System.debug('***** [debug] ***** forms found: ' + validforms.size());
		Map<ID,ID> leadFormMap = new Map<ID,ID>();
		for (Partner_CCP_Form__c form : validforms) leadFormMap.put(form.Lead__c, form.Id);
		for (Lead lead : filtered) {
			if (leadFormMap.get(lead.Id) == null) {
				lead.addError('CCP Form must be completed before proceeding');
			}
		}
	}
}