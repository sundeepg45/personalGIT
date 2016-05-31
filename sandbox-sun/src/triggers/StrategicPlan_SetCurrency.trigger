/**
 * This trigger sets the currency on a Strategic Plan to match its
 * parent account on creation or reparenting.
 * 
 * @version 2013-08-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-08-05 - created
 */
trigger StrategicPlan_SetCurrency on StrategicPlan__c (before insert, before update) {
	//create a set of account ids for new plans or plans that have been reparented
	Set<Id> accountIds = new Set<Id>();
	List<StrategicPlan__c> strategicPlans = new List<StrategicPlan__c>();
	for(StrategicPlan__c strategicPlan : Trigger.new) {
		if(Trigger.oldMap == null 
			|| (Trigger.oldMap.keySet().contains(strategicPlan.Id)
				&& strategicPlan.Account__c != null
				&& strategicPlan.Account__c != Trigger.oldMap.get(strategicPlan.Id).Account__c)) {
			accountIds.add(strategicPlan.Account__c);
			strategicPlans.add(strategicPlan);
		}
	}
	//get the account currency for all new or reparented plans
	if(!accountIds.isEmpty()) {
		List<Account> accounts = [select Id, CurrencyIsoCode from Account where Id in :accountIds];
		Map<Id,Account> accountMap = new Map<Id,Account>();
		for(Account account : accounts) {
			accountMap.put(account.Id,account);
		}
		for(StrategicPlan__c strategicPlan : strategicPlans) {
			if(accountMap.keySet().contains(strategicPlan.Account__c)) {
				strategicPlan.CurrencyIsoCode = accountMap.get(strategicPlan.Account__c).CurrencyIsoCode;
			}
		}
	}
}