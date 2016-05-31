trigger Account_RequalDateChange on Account (after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	if (!ThreadLock.lock('Account_RequalDateChange')) {
		return;
	}
	Account[] acctlist = new List<Account>();
	for (Account acct : Trigger.new) {
		Account old = Trigger.oldMap.get(acct.Id);
        System.debug('*****[debug]***** new=' + acct.StatusExpirationDate__c + ', old=' + old.StatusExpirationDate__c);
		if (acct.StatusExpirationDate__c != old.StatusExpirationDate__c) {
			acctlist.add(acct);
		}
	}
    if (!acctlist.isEmpty()) {
        PartnerStatus__c[] statuslist = [
            select	Id, ExpirationDate__c, ActivationDate__c, Partner__c
            from	PartnerStatus__c
            where	Partner__c in :PartnerUtil.getIdSet(acctlist)
            and		ActivationStatus__c = 'Active'
            and		ExpirationDate__c != null
        ];
        Map<ID,PartnerStatus__c> statusMap = new Map<ID,PartnerStatus__c>();
        for (PartnerStatus__c ps : statuslist) {
            statusMap.put(ps.Partner__c, ps);
        }
        
        for (Account acct : acctlist) {
            if (statusMap.containsKey(acct.id)) {
                statusMap.get(acct.id).ExpirationDate__c = acct.StatusExpirationDate__c;
                System.debug('****[debug]**** activation_date=' + statusMap.get(acct.Id).ActivationDate__c);
            }
        }
        
        update statusMap.values();
    }

/*
	if (!acctlist.isEmpty()) {
		Account_RequalDateChange.runupdate(PartnerUtil.getIdSet(acctlist));
	}
*/
}