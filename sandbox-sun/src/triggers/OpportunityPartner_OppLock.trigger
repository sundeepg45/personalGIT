/**
 * This trigger prevents deletion of records when an opp is locked.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-07-15
 * 2013-07-15 - implemented Opp Lock
 */
trigger OpportunityPartner_OppLock on OpportunityPartner__c (before delete) {
//depreciated	AdminByPass__c bypass = AdminByPass__c.getInstance();
//depreciated	if(bypass != null && bypass.IsSalesUser__c) {
//depreciated		Map<Id,Boolean> oppLockMap = new Map<Id,Boolean>();
//depreciated		for(OpportunityPartner__c oppPartner: trigger.old) {
//depreciated			oppLockMap.put(oppPartner.Opportunity__c,false);
//depreciated		}

//depreciated		List<Opportunity> opps = [
//depreciated			SELECT IsLockedForSales__c
//depreciated			FROM Opportunity
//depreciated			WHERE Id IN :oppLockMap.keySet()];
//depreciated		for(Opportunity opp: opps) {
//depreciated			oppLockMap.put(opp.Id,opp.IsLockedForSales__c);
//depreciated		}

//depreciated		for(OpportunityPartner__c oppPartner: trigger.old) {
//depreciated			if(oppLockMap.get(oppPartner.Opportunity__c)) {
//depreciated				oppPartner.addError(System.Label.Opp_Lock_Message);
//depreciated			}
//depreciated		}
//depreciated	}
}