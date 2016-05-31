public with sharing class Account_RequalDateChange {

	public static void runupdate(Set<String> accountidlist) {
		if (!accountidlist.isEmpty()) {
			Account[] acctlist = [select Id, StatusExpirationDate__c from Account where Id in :accountidlist];

			PartnerStatus__c[] statuslist = [
				select	Id, ExpirationDate__c, ActivationDate__c, Partner__c
				from	PartnerStatus__c
				where	Partner__c in :accountidlist
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
	}
}