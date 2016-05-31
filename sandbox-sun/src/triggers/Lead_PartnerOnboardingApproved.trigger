trigger Lead_PartnerOnboardingApproved on Lead (after update) {
/***
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    //
    // Build a list of only the leads that were just approved and need to be converted
    //

    List<Lead> leadApprovedList = new List<Lead>();
    //Set<Id> nfrLeadList = new Set<Id>();

    for(Lead lead : Trigger.new) {
        if (lead.Partner_Onboarding_Status__c != 'Approved')
            continue; // wrong entry criteria
        if (Trigger.oldMap.get(lead.Id).Partner_Onboarding_Status__c == 'Approved')
            continue; // no change to onboarding status
        if (lead.IsConverted == true)
            continue; // already through the conversion process.

        leadApprovedList.add(lead);
        //if (lead.Account__c == null) {
        //    System.debug('[DEBUG]------- added lead.id to nfrleadlist');
        //    nfrLeadList.add(lead.Id);
        //}
    }

    if (leadApprovedList.size() == 0)
        return;

    //
    // Pre-fetch the lead oconverted status ID
    //

    // LeadStatus convertedStatus = [
    //    select MasterLabel
    //      from LeadStatus
    //     where IsConverted = true
    //     limit 1
    //];

    //
    // Build the conversions. This also merges into existing accounts.
    //

    List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();

    for(Lead lead : leadApprovedList) {
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setConvertedStatus('Converted');
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setLeadId(lead.Id);
        leadConvert.setSendNotificationEmail(false);
        leadConvert.setAccountId(lead.Account__c); // merge into account
        leadConvertList.add(leadConvert);
    }

    //
    // Execute the conversion
    //

    List<Database.LeadConvertResult> leadConvertResultList = Database.convertLead(leadConvertList);

    //
    // Record failures
    //

    Map<Id, Lead> leadMapping = new Map<Id, Lead>(leadApprovedList);

    for(Database.LeadConvertResult leadConvertResult : leadConvertResultList) {
        if (leadConvertResult.isSuccess())
            continue;
        if (leadMapping.containsKey(leadConvertResult.getLeadId()) == false)
            system.assert(false, 'Lead Mapping is missing a required lead Id for a failed conversion attempt: ' + leadConvertResult);

        leadMapping.get(leadConvertResult.getLeadId()).addError('Lead conversion failed: '
           + leadConvertResult.getLeadId()
           + ': '
           + leadConvertResult.getErrors());
    }

    //
    // Pre-fetch the partner record types and map by name
    //

    Map<String, Id> recordTypeMap = new Map<String, Id> {
        'NA Partner' => '012600000004yfaAAA',
        'EMEA Partner' => '012600000004yfVAAQ',
        'LATAM Partner' => '0126000000053LWAAY',
        'APAC Partner' => '012600000004yfQAAQ'
    };

    // for(RecordType recordType : [
    //     select Name
    //       from RecordType
    //      where SobjectType = 'Account'
    //        and Name in ('NA Partner', 'EMEA Partner', 'APAC Partner', 'LATAM Partner')
    // ]) recordTypeMap.put(recordType.Name, recordType.Id);

    //
    // Pre-fetch the list of countries and their associated global region
    //

    Map<String, String> globalRegionMap = new Map<String, String>();

    for(Country__c country : [
        select Abbreviation__c
             , Global_Region__c
          from Country__c
    ]) globalRegionMap.put(country.Abbreviation__c, country.Global_Region__c);


    //
    // Build the list of converted accounts that need to be enabled as partners
    //

    Set<Id> accountIds = new Set<Id>();

    Set<ID> leadIdList = new Set<ID>();
    for(Database.LeadConvertResult leadConvertResult : leadConvertResultList) {
        if (leadConvertResult.isSuccess() == false)
            continue;
        accountIds.add(leadConvertResult.getAccountId());
        leadIdList.add(leadConvertResult.getLeadId());
    }

    if (accountIds.size() == 0)
        return;

    //
    // Update each account with the correct record type, and enable as a partner
    //

    Map<Id, Account> accountMap = new Map<Id, Account>();
    for (Account a : [Select Id, IsPartner from Account where Id in :accountIds]){
        accountMap.put(a.Id, a);
    }

    Anti_Corruption__c[] aclist = [select Id, Partner_Account__c, Lead__c from Anti_Corruption__c where Lead__c in :leadIdList and Review_Status__c = 'Approved and Archived'];
    Map<ID, Anti_Corruption__c> leadACMap = new Map<ID, Anti_Corruption__c>();
    for (Anti_Corruption__c ac : aclist) leadACMap.put(ac.Lead__c, ac);

    List<Account> accountList = new List<Account>();
    for(Database.LeadConvertResult leadConvertResult : leadConvertResultList) {
        if (leadConvertResult.isSuccess() == false)
            continue;

        // Save a reference to the lead
        Lead lead = Trigger.newMap.get(leadConvertResult.getLeadId());

        Account account = accountMap.get(leadConvertResult.getAccountId());

        if (leadACMap.get(lead.Id) != null) {
            leadACMap.get(lead.Id).Partner_Account__c = account.Id;
        }

        if (account.IsPartner)
            continue;


        // Unmap the global region
        String globalRegion = globalRegionMap.get(lead.Country);

        // Build the account
        account.AccountClassification__c = 'Partner - Ready Partner';
        account.IsPartner = true;
        account.MigrationSource__c = 'Onboarded';
        account.Data_Status__c = 'Locked';
        account.Partner_Type__c = lead.Partner_Type_Name__c;
        account.RecordTypeId = recordTypeMap.get(globalRegion + ' Partner');
        account.Is_Primary_Public_Sector__c = lead.Is_Primary_Public_Sector__c;
        account.Public_Sector_Market__c = lead.Public_Sector_Market__c;
        account.Is_Partner_Published__c = False;

        //
        // EMEA does not want new partners to be visible by default
        //
        if (lead.Global_Region__c == 'EMEA') {
            account.VATNumber__c = lead.VATNumber__c;
        }

        //
        // Populate initially with owner email domain
        //
        System.debug('***** [debug] ***** email=' + lead.Email);
        String[] parts = lead.Email.split('@');
        if (parts.size() == 2) {
            System.debug('***** [debug] ***** setting domain to ' + parts[1]);
            account.AllowedEmailDomains__c = parts[1];
        }

        // add to the update list
        accountList.add(account);
    }

    if (leadACMap.size() > 0) {
        update leadACMap.values();
    }
    if (accountList.size() != 0)
        update accountList;

    // Cached list to add parter statuses (programs)
    //List<PartnerStatus__c> partnerStatusList = new List<PartnerStatus__c>();
    List<Partner_Program__c> partnerProgramsList = new List<Partner_Program__c>();
    Set<Id> leadConvertedIds = new Set<Id>();
    //Set<Id> leadConvertedAccountIds = new Set<Id>();
    Set<Id> updateAccountList = new Set<Id>();

    for(Database.LeadConvertResult leadConvertResult : leadConvertResultList) {
        if (leadConvertResult.isSuccess() == false)
            continue;

        Lead lead = Trigger.newMap.get(leadConvertResult.getLeadId());
        leadConvertedIds.add(lead.Id);


        //
        // At this point, stop the process if joining to an exiting partner
        //

        if (lead.Account__c != null) {
            System.debug('[DEBUG]------- skipping partner status step');
            continue;
        }

        ////
        //// Sync : Insert Partner Statuses
        ////

        //PartnerStatus__c partnerStatus = new PartnerStatus__c();
        //partnerStatus.ActivationDate__c = Date.today();
        ////partnerStatus.ExpirationDate__c = Date.today().addYears(1);
        //partnerStatus.ExpirationDate__c = null;
        //partnerStatus.ApprovalStatus__c = 'Approved';
        //partnerStatus.Partner__c = leadConvertResult.getAccountId();
        //partnerStatus.PartnerTier__c = lead.Partner_Tier__c;
        //partnerStatus.PartnerType__c = lead.Partner_Type__c;
        //partnerStatus.Partner_Role__c = lead.Partner_Role__c;

        //partnerStatusList.add(partnerStatus);
        //updateAccountList.add(partnerStatus.Partner__c);

        //
        // Sync : Insert Partner Programs
        //

        Partner_Program__c partnerProgram = new Partner_Program__c();
        partnerProgram.Account__c = leadConvertResult.getAccountId();
        partnerProgram.Enroll_Date__c = Date.today();
        partnerProgram.Is_Primary__c = true;
        partnerProgram.Status__c = 'Active';
        partnerProgram.Tier__c = lead.Partner_Tier_Name__c;
        partnerProgram.Program__c = [
            select Id, Legacy_Partner_Type__c
            from   Partner_Program_Definition__c
            where  Legacy_Partner_Type__r.Name = :lead.Partner_Type_Name__c limit 1
        ].Id;

        partnerProgramsList.add(partnerProgram);
        updateAccountList.add(partnerProgram.Account__c);
    }

    //if (partnerStatusList.size() != 0) {
    //    insert partnerStatusList;
    //    PartnerStatus_UpdateAccount.updateAccountFields(updateAccountList);
    //}

    if (partnerProgramsList.size() != 0) {
        insert partnerProgramsList;
        PartnerStatus_UpdateAccount.updateAccountFields(updateAccountList);
    }

    //
    // Future : Convert the Lead/Contact to a Partner User
    //

    OnboardingExecuteConversion.convertContactToUserFuture(leadConvertedIds);

    //
    // Future : Update the agreement to use the current account
    //

    OnboardingExecuteConversion.convertPartnerAgreements(leadConvertedIds);

    //NFRCreateOnOnboarding.createNFRNotFuture(leadConvertedAccountIds);

***/
}