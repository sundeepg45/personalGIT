trigger PartnerStatus_CalcSortingHint on PartnerStatus__c (before insert, before update) {
    /*  DEFUNCT, IN PartnerSTtatus_UpdateAccount

    Map<ID,Classification__c> tierMap = null;

    //
    // get list of visible accounts
    //
    ID[] partnerIds = new List<ID>();
    for (PartnerStatus__c ps : Trigger.new) {
        if (ps.ActivationStatus__c != 'Active') continue;
        partnerIds.add(ps.Partner__c);
    }

    if (partnerIds.size() > 0) {
        Map<ID, Account> accounts = new Map<ID, Account>([
                select  Id,
                        Finder_Sort_Hint__c
                  from  Account
                 where  Id in :partnerIds]);

        if (tierMap == null) {
            tierMap = new Map<ID,Classification__c>([
                    select  Id,
                            HierarchyKey__c
                      from  Classification__c
                     where  HierarchyKey__c like 'PARTNER_TIER.%']);
        }

        for (PartnerStatus__c ps : Trigger.new) {
            if (ps.ActivationStatus__c != 'Active') continue;
            if (PFUtils.isEmpty(ps.PartnerTier__c)) continue;
            if (accounts.containsKey(ps.Partner__c)) {
                Account acct = accounts.get(ps.Partner__c);
                if (tierMap.get(ps.PartnerTier__c).HierarchyKey__c == 'PARTNER_TIER.READY') {
                    acct.Finder_Sort_Hint__c = 3;
                }
                else
                if (tierMap.get(ps.PartnerTier__c).HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                    acct.Finder_Sort_Hint__c = 2;
                }
                else
                if (tierMap.get(ps.PartnerTier__c).HierarchyKey__c == 'PARTNER_TIER.PREMIER') {
                    acct.Finder_Sort_Hint__c = 1;
                }
            }
        }
        update accounts.values();
    }
    */
}