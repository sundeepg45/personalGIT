/**
 * This trigger sets the currency on an Account Profile to match its
 * parent account on creation or reparenting.
 * 
 * @version 2013-09-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-09-05 - created
 */
trigger AccountProfile_SetCurrency on Account_Profile__c (before insert, before update) {
//create a set of account ids for new profiles or profiles that have been reparented
	Set<Id> accountIds = new Set<Id>();
	List<Account_Profile__c> accountProfiles = new List<Account_Profile__c>();
	for(Account_Profile__c accountProfile : Trigger.new) {
		if(Trigger.oldMap == null 
			|| (Trigger.oldMap.keySet().contains(accountProfile.Id)
				&& accountProfile.Account__c != null
				&& accountProfile.Account__c != Trigger.oldMap.get(accountProfile.Id).Account__c)) {
			accountIds.add(accountProfile.Account__c);
			accountProfiles.add(accountProfile);
		}
	}
	//get the account currency for all new or reparented profiles
	if(!accountIds.isEmpty()) {
		List<Account> accounts = [select Id, CurrencyIsoCode from Account where Id in :accountIds];
		Map<Id,Account> accountMap = new Map<Id,Account>();
		for(Account account : accounts) {
			accountMap.put(account.Id,account);
		}
		for(Account_Profile__c accountProfile : accountProfiles) {
			if(accountMap.keySet().contains(accountProfile.Account__c)) {
				accountProfile.CurrencyIsoCode = accountMap.get(accountProfile.Account__c).CurrencyIsoCode;
			}
		}
	}
}