/*******************************************************************************
    Name    :   Contract_EmbeddedOnboarding
    Desc    :   Updates program tiers and onboarding records after ane embedded
                contract is completed.

Modification Log :
--------------------------------------------------------------------------------
 Developer                  Date            Description
--------------------------------------------------------------------------------
 Jonathan Garrison          2015.Oct.09     Created.
 Jonathan Garrison          2015.Oct.20     Added agreement creation.
 Jonathan Garrison          2015.Nov.03     Updated trigger to only fire if
                                            contract record type is Partner
                                            Agreement.
 Kiran Ravikanti            2016.Feb.24     US79750: Sending email to partner with token to
                                            faciliate initiating Std. Terms on Contract Rejection.
*******************************************************************************/
trigger Contract_EmbeddedOnboarding on Contract (after update) {

    LogSwarm log = new LogSwarm('Onboarding', 'Contract');

    Contract[] completed = new List<Contract>();
    Contract[] rejected = new List<Contract>();
    Set<String> fedIds = new Set<String>();
    Set<Id> reqUsers = new Set<Id>();
    //List<Partner_Onboarding_Registration__c> embeddedOnboards = new List<Partner_Onboarding_Registration__c>();
    List<User> pu = new List<User>();

    RecordType recordType = [
        select  Id,
                DeveloperName
        from    RecordType
        where   DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
        and     SObjectType = 'Contract'
        and     IsActive = true
        limit   1
    ];

    for (Contract con : Trigger.new) {
        Contract oldcon = Trigger.oldMap.get(con.Id);
        if (con.Contract_Type__c == 'Embedded Deal' &&
            oldcon.Status != con.Status &&
            con.Status == 'Completed' &&
            con.RecordTypeId == recordType.Id) {
            completed.add(con);
            log.push('accountId', con.AccountId);
        }

        if (con.Contract_Type__c == 'Embedded Deal' &&
            con.Status == 'Rejected' &&
            oldcon.Status != 'Rejected' &&
            con.Rejection_Reason__c == 'Initiate Standard Terms Process' &&
            con.RecordTypeId == recordType.Id &&
            con.Requesting_User__c != null &&
            con.Requesting_User_s_Federation_Id__c != null) {
            rejected.add(con);
            fedIds.add(con.Requesting_User_s_Federation_Id__c);
            reqUsers.add(con.Requesting_User__c);
            System.debug('[DEBUG****]: rejected embedded Contracts: '+con.Requesting_User_s_Federation_Id__c);
        }
    }

    //
    //US79750:
    //find the onboarding records to create tokens and send emails to relevant partners:
    //
    if (rejected.size() > 0) {
        pu = [SELECT Id, ContactId, Contact.AccountId, LanguageLocaleKey, Email
                            FROM User
                            WHERE Id in :reqUsers];

        System.debug('[DEBUG****]: rejected embedded onboarding record size: '+pu.size());

        for (User u :pu) {
            u.LanguageLocaleKey = u.LanguageLocaleKey.substring(0,2);
            PartnerEmailUtils.sendEmbedTermsEmail(u.Contact.AccountId, u.Email, u.LanguageLocaleKey);
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
    // Associate partner accounts to dummy agreement for Embedded
    //
    // Tiaan confirmed there will only be 1 dummy agreement entry global, not regional or by country
    Agreement__c[] tmplist = [
        select  Id
        from    Agreement__c
        where   Partner_Program__r.Program_Category__c = :PartnerConst.EMBED
        and     Type__c = 'Custom'
        and     ActivationStatus__c = 'Active'
    ];

    if (tmplist.isEmpty()) {
        log.error('Missing active Custom agreement type for Embedded.');
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
        select  Id,
                Account__c,
                Program__r.Program_Category__c,
                Tier__c,
                Status__c,
                Is_Primary__c
        from    Partner_Program__c
        where   Account__c in :partnerIds
        and     Program__r.Program_Category__c in (:PartnerConst.EMBED, :PartnerConst.ISV, :PartnerConst.RESELLER)
        and     Tier__c = :PartnerConst.UNAFFILIATED
        and     Status__c != 'Rejected'
    ];

    Map<ID,Partner_Program__c> isvAccounts = new Map<ID,Partner_Program__c>();
    for (Partner_Program__c prog : proglist) {
        if (prog.Is_Primary__c == True && prog.Program__r.Program_Category__c == PartnerConst.ISV) {
            isvAccounts.put(prog.Account__c, prog); // These are the onboarding accounts.
        }
    }

    Partner_Program__c[] progupdates = new List<Partner_Program__c>();
    for (Partner_Program__c prog : proglist) {
        if (prog.Program__r.Program_Category__c == PartnerConst.EMBED) {
            prog.Tier__c = 'Affiliated';
        } else {
            prog.Tier__c = 'Ready';
        }
        prog.IsVisible__c = true;
        prog.Status__c = 'Active';
        if (isvAccounts.containsKey(prog.Account__c) == false) {
            // only set agreements flags on membership if enrolling
            prog.HasCustomTerms__c = true;
            if (prog.Enroll_Date__c == null) {
				prog.Enroll_Date__c = System.today();
			}
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
    Partner_Onboarding_Registration__c[] reglist = [
        select  Id,
                ConvertedAccount__c
        from    Partner_Onboarding_Registration__c
        where   ConvertedAccount__c in :partnerIds
    ];

    Map<ID,Partner_Onboarding_Registration__c> acctToRegMap = new Map<ID,Partner_Onboarding_Registration__c>();
    for (Partner_Onboarding_Registration__c reg : reglist) {
        acctToRegMap.put(reg.ConvertedAccount__c, reg);
    }

    for (Contract contract : completed) {
        Account partnerAcct = salesToPartnerMap.get(contract.AccountId);
        ID accountId = partnerAcct.Id;
        if (isvAccounts.containsKey(accountId)) {
            Partner_Onboarding_Registration__c reg = acctToRegMap.get(accountId);
            if (reg != null) reg.HasCustomTerms__c = true;
        }
    }
    if (!acctToRegMap.values().isEmpty()) {
        update acctToRegMap.values();
    }
}