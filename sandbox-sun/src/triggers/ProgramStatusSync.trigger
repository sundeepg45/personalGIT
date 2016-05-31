trigger ProgramStatusSync on Partner_Program__c (after insert, after update) {
    if (BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    if (BooleanSetting__c.getInstance('DeactivateProgramStatusSync.trigger') != null && BooleanSetting__c.getInstance('DeactivateProgramStatusSync.trigger').Value__c == true) return;


    //
    // This entire design predicated on the fact that there is only 1 primary program per account, otherwise it fails.
    //

    Partner_Program__c[] primaries = new List<Partner_Program__c>();
    for (Partner_Program__c pgm : Trigger.new) {
        if (Trigger.isInsert) {
            if (pgm.Is_Primary__c) primaries.add(pgm);
        }
        else {
            Partner_Program__c oldpgm = Trigger.oldMap.get(pgm.Id);
            if (pgm.Is_Primary__c) {
                if (pgm.Tier__c != oldpgm.Tier__c) {
                    primaries.add(pgm);
                }
                else if (pgm.Program__c != oldpgm.Program__c) {
                    primaries.add(pgm);
                }
                else if (oldpgm.Is_Primary__c == false) {
                    primaries.add(pgm);
                }
            }
        }
    }
    //
    // We only care about syncing primary program to partner_status, bail out if we have none
    if (primaries.isEmpty()) {
        System.debug('no primary programs to process');
        return;
    }

    Set<String> partnerIdList = PartnerUtil.getStringFieldSet(primaries, 'Account__c');
    PartnerStatus__c[] statusList = [
        select  Id, Partner__c, Is_Partner_Finder_Ready__c, IsVisible__c, Global__c
        from    PartnerStatus__c
        where   ActivationStatus__c = 'Active'
        and     Partner__c in :partnerIdList
    ];
    Map<ID,PartnerStatus__c> statusMap = new Map<ID,PartnerStatus__c>();
    for (PartnerStatus__c ps : statusList) {
        statusMap.put(ps.Partner__c, ps);
    }

    Partner_Program__c[] programs = [
        select  Id, Account__c, Tier__c, Program__r.Legacy_Partner_Type__c, Global__c, IsVisible__c
        from    Partner_Program__c
        where   Id in :PartnerUtil.getIdSet(primaries)
    ];

    Classification__c[] tiers = [select Id, Name from Classification__c where Parent__r.HierarchyKey__c = 'PARTNER_TIER'];
    Map<String,ID> tierMap = new Map<String,ID>();
    for (Classification__c tier : tiers) {
        tierMap.put(tier.Name, tier.Id);
    }

    //
    // Deactive all active statuses for affected partners
    // Create new statuses
    //
    PartnerStatus__c[] synced = new List<PartnerStatus__c>();
    for (PartnerStatus__c ps : statusList) {
        ps.ApprovalStatus__c = 'Expired';
        ps.ExpirationDate__c = System.today();
    }

    for (Partner_Program__c pgm : programs) {
        PartnerStatus__c currentStatus = statusMap.get(pgm.Account__c);
        ID partnerType = pgm.Program__r.Legacy_Partner_Type__c;
        ID partnerTier = tierMap.get(pgm.Tier__c);

        PartnerStatus__c nps = new PartnerStatus__c();
        nps.Partner__c          = pgm.Account__c;
        nps.ApprovalStatus__c   = 'Approved';
        nps.ActivationDate__c   = System.today();
        nps.Global__c           = pgm.Global__c; //(currentStatus != null) ? currentStatus.Global__c : false;
        nps.IsVisible__c        = pgm.IsVisible__c;
        nps.PartnerType__c      = partnerType;
        nps.PartnerTier__c      = partnerTier;
        if (currentStatus != null) {
            nps.IsVisible__c               = currentStatus.IsVisible__c;
            nps.Is_Partner_Finder_Ready__c = currentStatus.Is_Partner_Finder_Ready__c;
            nps.Previous_Partner_Status__c = currentStatus.Id;
        }
        else {
            nps.IsVisible__c = true;
        }

        // just always force this
        nps.IsVisible__c = true;
        synced.add(nps);
    }

    update statusList;
    insert synced;

    Set<String> acctidlist = PartnerUtil.getStringFieldSet(synced, 'Partner__c');
    PartnerStatus_UpdateAccount.updateAccountFields(acctidlist);

}