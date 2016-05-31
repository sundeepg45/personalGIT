trigger Account_UpdatePartnerRequalification on Account (after update) {
    private static Id partnerCenterAPIUserId;

    if (!ThreadLock.lock('Account_UpdatePartnerRequalification')) {
        return;
    }

    Account[] accounts = new List<Account>();
    for (Account acct : Trigger.new) {
        if (PartnerUtil.isPartner(acct.RecordTypeId)) {
            accounts.add(acct);
        }
    }
    if (accounts.isEmpty()) {
        return;
    }

    //
    // use caching for subsequent calls to this trigger in the same transaction
    //
    if (partnerCenterAPIUserId == null) {
    	partnerCenterAPIUserId = [
    		select  Id,
    				Name
    		from    User
            where   Name
            in      ('Partner Center API User', 'API User Partner Center')
    		limit   1
    	].Id;
    }
	List<Account> partnerRequalAccounts = new List<Account>();

    // Get all of the process instance work items for the account in
    // question whose original actor is the partner center api user, which
    // means that the approval process is at the anti-corruption holding
    // queue step.
    List<ProcessInstanceWorkItem> pIWIs = [
        select  p.Id,
                p.OriginalActorId,
                p.ProcessInstanceId,
                p.ProcessInstance.TargetObjectId
        from    ProcessInstanceWorkItem p
        where   p.ProcessInstance.TargetObjectId in :PartnerUtil.getIdSet(accounts)
        and     p.OriginalActorId = :PartnerCenterAPIUserId
    ];

	for (Account account : accounts){
        ProcessInstanceWorkItem piwi = null;
        for (ProcessInstanceWorkItem tmp : pIWIs) {
            if (tmp.ProcessInstance.TargetObjectId == account.Id) {
                piwi = tmp;
                break;
            }
        }
		// If we're at the anti-corruption holding queue step of
		// the approval process and we haven't come here through
		// code (APPROVED_BY_API is false), raise an error.

		if (piwi != null && !AccountControllerExt.APPROVED_BY_API) {
			account.addError('This approval step must be completed through the anti-corruption record.');
		}

		if (	account.RequalStatus__c != 'Overdue' &&
				account.RequalStatus__c != 'Removed' &&
				account.RequalStatus__c != 'Eligible' &&
				account.RequalStatus__c != Null
		){
			partnerRequalAccounts.add(account);
		}
	}

	if (partnerRequalAccounts.size() > 0){
		List<PartnerRequalification__c> requals = [select id from PartnerRequalification__c where AccountId__c in :partnerRequalAccounts and PartnerRequalification__c.Status__c != 'Archived'];
		for (PartnerRequalification__c prq : requals){
			prq.PopulateMetVsSet__c = True;
		}
		if (requals.size() > 0){
			update requals;
		}
	}
}