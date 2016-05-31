trigger Contract_CCSPOnboarding on Contract (after update) {

    LogSwarm log = new LogSwarm('Onboarding', 'Contract');

    Contract[] completed = new List<Contract>();
    for (Contract con : Trigger.new) {
        Contract oldcon = Trigger.oldMap.get(con.Id);
        ID recType = con.Account.RecordTypeId;
        if (con.Contract_Type__c == 'Cloud Deal' && oldcon.Status != con.Status && con.Status == 'Completed') {
            completed.add(con);
            log.push('accountId', con.AccountId);
        }
    }

    if (completed.isEmpty()) {
        return;
    }

    Map<ID,Account> salesToPartnerMap = PartnerUtil.getPartnerAccountsForSales(PartnerUtil.getStringFieldSet(completed, 'AccountId'));
    if (salesToPartnerMap.isEmpty()) {
        log.fatal('No partner accounts found');
        completed.get(0).addError('No partner account found via CDH Party Number for Sales account ' + completed.get(0).AccountId);
    }

    Set<String> partnerIds = PartnerUtil.getIdSet(salesToPartnerMap.values());

    //
    // Associate partner accounts to dummy agreement for CCSP
    //
    // Tiaan confirmed there will only be 1 dummy agreement entry global, not regional or by country
    Agreement__c[] tmplist = [select Id from Agreement__c where PartnerType__r.HierarchyKey__c = 'PARTNER_TYPE.SERVICECLOUD_PROVIDER' and Type__c = 'Custom' and ActivationStatus__c = 'Active'];
    if (tmplist.isEmpty()) {
        log.error('Missing active Custom agreement type for PARTNER_TYPE.SCP');
    }
    else {
        Agreement__c agreement = tmplist.get(0);

        PartnerAgreement__c[] partnerAgreementList = new List<PartnerAgreement__c>();
        for (Account acct : salesToPartnerMap.values()) {
            PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
            partnerAgreement.Partner__c = acct.Id;
            partnerAgreement.Agreement__c = agreement.Id;
            partnerAgreement.ActivationDate__c = System.today();
            partnerAgreementList.add(partnerAgreement);
        }
        if (!partnerAgreementList.isEmpty()) {
            insert partnerAgreementList;
        }
    }

    //
    // Update program tier to Advanced
    //
    Partner_Program__c[] proglist = [
        select   Id, Account__c, Program__r.Program_Category__c, Tier__c, Status__c, Is_Primary__c
        from     Partner_Program__c
        where    Account__c in :partnerIds
        and      (Program__r.Program_Category__c = :PartnerConst.SCP
        or       Program__r.Program_Category__c = :PartnerConst.CCNSP)
        and      Tier__c = :PartnerConst.UNAFFILIATED
        and      Status__c != 'Rejected'

    ];
    Map<ID,Partner_Program__c> scpAccounts = new Map<ID,Partner_Program__c>();
    for (Partner_Program__c prog : proglist) {
        if (prog.Is_Primary__c == True && prog.Program__r.Program_Category__c == PartnerConst.SCP) {
            scpAccounts.put(prog.Account__c, prog);
        }
    }
    Partner_Program__c[] progupdates = new List<Partner_Program__c>();
    for (Partner_Program__c prog : proglist) {
        prog.Tier__c = 'Advanced';
        prog.IsVisible__c = true;
        prog.Status__c = 'Active';
        //prog.Status__c = 'Active';
        if (scpAccounts.containsKey(prog.Account__c) == false) {
            // only set agreements flags on membership if enrolling
            prog.HasCustomTerms__c = true;
            prog.Agree_to_Partner_T_C__c = True;
        }
        for (Contract con : completed) {
            if (con.AccountId == prog.Account__c) {
                prog.Termination_Date__c = con.EndDate;
                break;
            }
        }
        progupdates.add(prog);
    }
    if (!progupdates.isEmpty()) {
        update progupdates;
    }
    else {
        log.error('No partner programs found to update');
    }


    //
    // Get original onboarding registration ID for the agreement record
    //
    Partner_Onboarding_Registration__c[] reglist = [select Id, ConvertedAccount__c from Partner_Onboarding_Registration__c where ConvertedAccount__c in :partnerIds];
    Map<ID,Partner_Onboarding_Registration__c> acctToRegMap = new Map<ID,Partner_Onboarding_Registration__c>();
    for (Partner_Onboarding_Registration__c reg : reglist) {
        acctToRegMap.put(reg.ConvertedAccount__c, reg);
    }

    for (Contract contract : completed) {
        Account partnerAcct = salesToPartnerMap.get(contract.AccountId);
        ID accountId = partnerAcct.Id;
        if (scpAccounts.containsKey(accountId)) {
            Partner_Onboarding_Registration__c reg = acctToRegMap.get(accountId);
            if (reg != null) reg.HasCustomTerms__c = true;
        }
    }
    if (!acctToRegMap.values().isEmpty()) {
        update acctToRegMap.values();
    }
}