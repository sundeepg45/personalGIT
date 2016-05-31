public without sharing class PartnerStatus_UpdateAccount {

    @future
    static public void updateAccountFieldsFuture(Set<ID> partnerIds) {
    	updateAccountFields(partnerIds);
    }

    @future
    static public void updateAccountFieldsFuture(Set<String> partnerIds) {
        Set<ID> idlist = new Set<ID>();
        for (String s : partnerIds) idlist.add((ID) s);
        updateAccountFields(idlist);
    }

    static public void updateAccountFields(Set<String> partnerIds) {
        Set<ID> idlist = new Set<ID>();
        for (String s : partnerIds) {
            idlist.add((ID) s.substring(0,15));
        }
        updateAccountFields(idlist);
    }

    static public void updateAccountFields(Set<ID> partnerIds) {

	    //
	    // Get accounts and update finder fields
	    //
	    Map<ID, Account> acctmap = new Map<ID, Account>([
	            select  Id,
	                    Finder_Partner_Type__c,
	                    Finder_Partner_Tier__c,
	                    Finder_Sort_Hint__c
	              from  Account
	             where  Id in :partnerIds]);

    	Map<ID, PartnerStatus__c> statusList = new Map<ID, PartnerStatus__c>([
    	      select  Id,
    	              ActivationStatus__c,
    	              PartnerTier__c,
    	              PartnerType__c,
    	              Partner__c,
    	              CombinedName__c,
    	              Global__c

	             , Partner__r.Global_Region__c
	             , Partner__r.Subregion__c
	             , Partner__r.BillingCountry
	             , Partner__r.OwnerId

    	      from    PartnerStatus__c
    	      where   Partner__c in :partnerIds
    	      and     ActivationStatus__c = 'Active'
    	      order by Partner__c, CombinedName__c
    	]);

        //
        // Calculate the new sorting hint
        //
        if (partnerIds.size() > 0) {
            for (PartnerStatus__c ps : statusList.values()) {
                if (PFUtils.isEmpty(ps.PartnerTier__c)) continue;
                if (acctmap.containsKey(ps.Partner__c)) {
                    Account acct = acctmap.get(ps.Partner__c);
                    performUpdateOnAccount(acct, ps);
                }
            }
        }

	    // RollupPartnerStatuses code
	    Map<Id, List<Boolean>> accountPartnerStatusMapGlobal = new Map<Id, List<Boolean>>();
        Map<Id, List<String>> accountPartnerStatusMap = new Map<Id, List<String>>();


	    for(Account account : acctmap.values()){
	        accountPartnerStatusMap.put(account.Id, new List<String>());
	        accountPartnerStatusMapGlobal.put(account.Id, new List<Boolean>());
	    }

	    for(Account account : acctmap.values()) {
	        account.PartnerStatuses__c = 'None';
	    }

	    for (PartnerStatus__c partnerStatus : statusList.values()) {
            accountPartnerStatusMap.get(partnerStatus.Partner__c).add(partnerStatus.CombinedName__c);
            accountPartnerStatusMapGlobal.get(partnerStatus.Partner__c).add(partnerStatus.Global__c);
	    }

	    for(Account account : acctmap.values()) {
	        if (accountPartnerStatusMap.get(account.Id).size() == 0) {
	            account.PartnerStatuses__c = '';        // Partner Finder depends on this field being blank to indicate inactive
	            continue;
	        }

	        for(String combinedName : accountPartnerStatusMap.get(account.Id)) {
	            if (combinedName == null || combinedName == '')
	                continue;

	            if (account.PartnerStatuses__c == 'None') {
	                account.PartnerStatuses__c = combinedName;
                    account.Global__c = true;
	            }
	            else {
	                account.PartnerStatuses__c += ';';
	                account.PartnerStatuses__c += combinedName;
	            }
	        }

	        for (Boolean globalStatus : accountPartnerStatusMapGlobal.get(account.Id)) {
	            account.Global__c = globalStatus;
	        }

	    }

		AccountTeamRulesUtils.updateRules(acctmap.values(), statusList.values());

	    //////////////

	    update acctmap.values();

    }

    static public void performUpdateOnAccount(Account acct, PartnerStatus__c ps) {
        acct.Finder_Partner_Type__c = ps.PartnerType__c;
        acct.Finder_Partner_Tier__c = ps.PartnerTier__c;

        if (RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c) {
            acct.Finder_Sort_Hint__c = 3;
        }
        else
        if (RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c) {
            acct.Finder_Sort_Hint__c = 2;
        }
        else
        if (RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c) {
            acct.Finder_Sort_Hint__c = 1;
        }

    }
}