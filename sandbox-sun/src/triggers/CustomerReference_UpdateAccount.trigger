trigger CustomerReference_UpdateAccount on Customer_Reference__c (after delete, after insert, after update, after undelete) {
	Map<Id,Account> accounts = new Map<Id,Account>();
	if (Trigger.isDelete){
		for (Customer_Reference__c cr : Trigger.old){
			if (cr.Account__c != null && accounts.get(cr.Account__c) == null){
				accounts.put(cr.Account__c, new Account(Id=cr.Account__c));
			}
		}
	} else {
		for (Customer_Reference__c cr : Trigger.new){
			if (cr.Account__c != null && accounts.get(cr.Account__c) == null){
				accounts.put(cr.Account__c, new Account(Id=cr.Account__c));
			}
		}
	}
	if (accounts.size() > 0){
		// Causes the Requalification object to update
		update accounts.values();
	}
}