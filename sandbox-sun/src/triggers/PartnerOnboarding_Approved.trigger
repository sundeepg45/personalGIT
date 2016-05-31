trigger PartnerOnboarding_Approved on Partner_Onboarding_Registration__c (before update) {

    Map<String, Id> recordTypeMap = new Map<String, Id> {
        'NA Partner' => '012600000004yfaAAA',
        'EMEA Partner' => '012600000004yfVAAQ',
        'LATAM Partner' => '0126000000053LWAAY',
        'APAC Partner' => '012600000004yfQAAQ'
    };

    Map<ID,ID> onbAccountMap = new Map<ID,ID>();

    Map<Partner_Onboarding_Registration__c, PARF_Form__c> leadPARFMap = new Map<Partner_Onboarding_Registration__c, PARF_Form__c>();

    if (BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    //
    // Build a list of only the s that were just approved and need to be converted
    //

    List<Partner_Onboarding_Registration__c> leadApprovedList = new List<Partner_Onboarding_Registration__c>();
    List<Partner_Onboarding_Registration__c> joinList = new List<Partner_Onboarding_Registration__c>();

    RecordType bprType = null;

    User me = [
        select  Id,
                Email
        from    User
        where   Id = :UserInfo.getUserId()
    ];

    //
    // Filter out stuff we're not interested in
    //
    for (Partner_Onboarding_Registration__c lead : Trigger.new) {
        if (lead.ConvertedAccount__c != null) {
            System.debug('already converted');
            continue;
        }
        if (lead.Partner_Onboarding_Status__c != 'Approved') {
            System.debug('not approved');
            continue; // wrong entry criteria
        }
        if (Trigger.oldMap.get(lead.Id).Partner_Onboarding_Status__c == 'Approved') {
            System.debug('already approved');
            continue; // no change to onboarding status
        }

        if (bprType == null) {
            bprType = [select Id from RecordType where DeveloperName = 'Business_Partner_Registration' and SObjectType = 'Partner_Onboarding_Registration__c'];
        }
        if (lead.RecordTypeId != bprType.Id) {
            System.debug('not Business Partner Registration record type: ' + lead.RecordTypeId);
            continue;
        }
        if (lead.Account__c != null && lead.Zombie_Account__c == null) {
            // this is probably a user onboard, ignore. Could also be an onboardingapply where an existing account was detected by SBC
            joinList.add(lead);
            continue;
        }
        if (!lead.SBC_Initiated__c) {
            lead.addError('Unable to convert to a Partner Account until Search Before Create step is completed');
            continue;
        }

        System.debug('adding ' + lead.Company__c);
        leadApprovedList.add(lead);
    }

    if (leadApprovedList.size() == 0 && joinList.size() == 0) {
        return;
    }

    //
    // We need country abbreviations during account conversion
    //
    Map<ID,Country__c> countryMap = new Map<ID,Country__c>([
        select  Id, Abbreviation__c
        from    Country__c
    ]);

    Map<ID, State__c> stateMap = new Map<ID, State__c>([
        select  Id, Abbreviation__c
        from    State__c
    ]);

    Map<ID, Account> accountMap = new Map<ID, Account>();
    Anti_Corruption__c[] acupdates = new List<Anti_Corruption__c>();
    Set<ID> contactIdList = new Set<ID>();

    Partner_Onboarding_Registration__c[] ccspList = new List<Partner_Onboarding_Registration__c>();
    // Partner_Onboarding_Registration__c[] embedList = new List<Partner_Onboarding_Registration__c>();

    //
    // Do the conversions.  NOTE that this is NOT batch friendly and I could not help that since we are no longer using Salesforce ConvertLeads functionality.
    //
    if (leadApprovedList != null) {
        System.debug('Lead approved list size: ' + leadApprovedList.size());
    }
    for (Partner_Onboarding_Registration__c lead : leadApprovedList) {
        System.debug('converting ' + lead.Company__c);

        //
        // Build the account
        //
        Account account = new Account();

        if (lead.Zombie_Account__c != null) {
            account = new Account(Id = lead.Zombie_Account__c);
        }

        account.Additional_Countries_of_Operation__c = lead.Additional_Countries_of_Operations__c;
        if (lead.Zombie_Account__c == null) {
            // a prod validation rule won't allow updating of name field on existing account
            account.Name                        = lead.Company__c;
        }
        account.Additional_Partnerships__c  = lead.Additional_Partnerships__c;
        account.Application_Types__c        = lead.Application_Types__c;
        account.Description_of_Business__c  = lead.Company_Description__c;
        account.Global_Region__c            = lead.Global_Region__c;
        account.Hardware_Focus__c           = lead.Hardware_Focus__c;
        account.Hardware_Platform__c        = lead.Hardware_Platform__c;
        account.Have_they_been_convicted__c = lead.Have_they_been_convicted__c;
        account.Do_they_act_in_any_government_position__c = lead.Do_they_act_in_any_government_position__c;
        account.If_Other_Middleware__c      = lead.If_Other_Middleware__c;
        account.Industry_Focus__c           = lead.Industry_Focus__c;
        account.Middleware_Supported__c     = lead.Middleware_Supported__c;
        account.Operating_System_Supported__c = lead.Operating_System_Supported__c;
        account.Other_Partnerships__c       = lead.Other_Partnerships__c;
        account.Ownership_Type__c           = lead.Ownership_Type__c;
        account.RequalificationDate__c      = lead.Requalification_Date__c;
        account.Software_Focus__c           = lead.Software_Focus__c;
        account.BillingStreet               = lead.Address1__c;
        if (lead.State_Province__c != null) {
            account.BillingState                = stateMap.get(lead.State_Province__c).Abbreviation__c;
        }
        account.BillingCity                 = lead.City__c;
        account.BillingPostalCode           = lead.Postal_Code__c;
        account.BillingCountry              = countryMap.get(lead.Country__c).Abbreviation__c;
        account.State_Province__c           = lead.State_Province__c;
        account.Phone                       = lead.Phone__c;
        account.NumberOfEmployeesInWWOrg__c = lead.Number_of_Employees__c;
        account.SubRegion__c                = lead.SubRegion__c;
        account.Target_Market_Size__c       = lead.Target_Market_Size__c;
        account.Total_Annual_Revenue__c     = lead.Total_Annual_Revenue__c;
        account.Website                     = lead.Website__c;
        account.AccountClassification__c    = 'Partner - Ready Partner';
        account.MigrationSource__c          = lead.Manual_Onboard__c == true ? 'Manual' : 'Onboarded';
        account.Data_Status__c              = 'Locked';
        account.Partner_Type__c             = lead.Partner_Type_Formula__c;
        account.RecordTypeId = recordTypeMap.get(lead.Global_Region__c + ' Partner');
        account.Is_Primary_Public_Sector__c = lead.Is_Primary_Public_Sector__c;
        account.Public_Sector_Market__c     = lead.Public_Sector_Market__c;
        account.Is_Partner_Published__c     = false;
        account.OwnerId                     = lead.OwnerId;
        account.DUNSNumber                  = lead.DUNSNumber__c;
        account.D_U_N_S__c                  = lead.DUNSNumber__c;
        account.CDH_Party_Number__c         = lead.CDH_Party_Number__c;
        account.Partner_Onboarding_Application__c = lead.Id;
        account.AntiCorruption_Review_By_RedHat_Internal__c = lead.AntiCorruption_Review_Channel_Ops__c;

        if (lead.Sales_Account__c != null) {
            Account salesAcct = [select CDH_Party_Name__c from Account where Id = :lead.Sales_Account__c];
            if (salesAcct.CDH_Party_Name__c != null) account.CDH_Party_Name__c = salesAcct.CDH_Party_Name__c;
        }

        if (lead.Global_Region__c == 'EMEA') {
            account.VATNumber__c = lead.VATNumber__c;
        }

        //
        // Populate initially with owner email domain
        //
        String[] parts = lead.Email__c.split('@');
        if (parts.size() == 2) {
            System.debug('***** [debug] ***** setting domain to ' + parts[1]);
            account.AllowedEmailDomains__c = parts[1];
        }

        upsert account; // must be upsert - not insert

        //
        // Create the initial contact
        //
        Contact contact = new Contact();
        if (lead.Manual_Onboard__c == false) {
            contact.AccountId = account.Id;
            contact.Title = lead.Title__c;
            contact.FirstName = lead.FirstName__c;
            contact.LastName = lead.LastName__c;
            contact.LoginName__c = lead.RHNLogin__c;
            contact.Onboarding_Country__c = lead.Country__c;
            contact.LanguagePreference__c = lead.Onboarding_Language_Preference__c;
            contact.Email = lead.Email__c;
            contact.Phone = lead.Phone__c;
            contact.MailingStreet = account.BillingStreet;
            contact.MailingState = account.BillingState;
            contact.MailingCity = account.BillingCity;
            contact.MailingPostalCode = account.BillingPostalCode;
            contact.MailingCountry = account.BillingCountry;
            contact.OwnerId = lead.OwnerId;
            contact.CDH_Party__c = lead.Contact_CDH_Party__c;
            insert contact;
            contactIdList.add(contact.Id);
        }

        //
        // create the user
        //
        OnboardingConversion onboarding = new OnboardingConversion();
        if (!lead.Manual_Onboard__c) {
            User user = onboarding.getPartnerUser(contact, lead);
            user.ProfileId = onboarding.getPartnerPortalProfileIdByName(lead.Partner_Onboarding_Profile__c);
            System.assert(user.ProfileId != null, 'No profile found for ' + lead.Partner_Onboarding_Profile__c);
            insert user;
            account.PrimaryPartnerUser__c = user.Id;
        }

        //
        // final updates to the account
        //
        account.IsPartner = true;
        if (!lead.Manual_Onboard__c) {
            account.PrimaryPartnerContact__c = contact.Id;
        }

        if (lead.Created_By_User_Type__c.equalsIgnoreCase('Distributor')) {
            account.MigrationSource__c = 'Disti-Led Onboarding';
        }

        if (lead.Created_By_User_Type__c.equalsIgnoreCase('Internal')) {
            account.MigrationSource__c = 'Manual';
        }

        //
        // CDH handling
        //
        if (lead.Sales_Account__c == null) {
            // no existing party id was specified so create a new sales account
            Account sa = OnboardingUtils.createSalesAccount(lead.Id);
            lead.Sales_Account__c = sa.Id;
            account.CDH_Party_Name__c = sa.CDH_Party_Name__c;
        }

        update account;

        //
        // update the onboarding record fields we'll need later
        //
        lead.ConvertedAccount__c = account.Id;
        if (!lead.Manual_Onboard__c) {
            lead.ConvertedContact__c = contact.Id;
        }
        onbAccountMap.put(lead.Id, account.Id);
        accountMap.put(account.Id, account);

        //
        // Collect all the CC&SP's for email notification later
        // and to update the converted account reference on
        // the CCSP form.
        //
        if (lead.Partner_Type_Formula__c == PartnerConst.SCP) {
            ccspList.add(lead);
            CCSP_Form__c ccspForm = [
                select  Id,
                        CCSPOnboardingRegistration__c,
                        Account__c,
                        Distributor_Directed__c
                from    CCSP_Form__c
                where   CCSPOnboardingRegistration__c = :lead.Id
                limit   1
            ];
            ccspForm.Account__c = lead.ConvertedAccount__c;
            update ccspForm;
        }

        System.debug('Lead subtype: ' + lead.SubType__c);

        if (lead.SubType__c != null && lead.SubType__c.equalsIgnoreCase(OnboardingApplyController.EMBEDDED)) {
            System.debug('Subtype is Embedded.');
            // embedList.add(lead);
            PARF_Form__c parf = [
                select  Id,
                        Custom_Terms_Required__c,
                        Distributor_Directed__c,
                        Account__c
                from    PARF_Form__c
                where   Partner_Onboarding_Record__c = :lead.Id
                limit   1
            ];
            parf.Account__c = lead.ConvertedAccount__c;
            update parf;
            leadPARFMap.put(lead, parf);
        }

        //
        // check if there is an approved FCPA on this lead so we can fix the account reference on it after the fact (for good data integrity).
        //

        Anti_Corruption__c[] aclist = [
            select      Id, Partner_Account__c, Partner_Onboarding__c
            from        Anti_Corruption__c
            where       Partner_Onboarding__c in :onbAccountMap.keyset()
            and         Review_Status__c = 'Approved and Archived'
        ];
        if (aclist.size() > 0) {
            aclist.get(0).Partner_Account__c = account.Id;
            acupdates.add(aclist.get(0));
        }
        else {
            // no FCPA, create one as a placeholder
            Anti_Corruption__c ac = new Anti_Corruption__c();
            ac.Partner_Account__c = account.Id;
            ac.Review_Status__c = 'Approved and Archived';
            ac.Auto_Approved__c = true;
            ac.Anti_Corruption_Confirmed_By__c = UserInfo.getUserId();
            ac.Anti_Corruption_Confirmed_Date_Time__c = System.now();
            ac.Origin__c = 'Onboarding';
            ac.Partner_Onboarding__c = lead.Id;
            ac.Internal_Review__c = lead.AntiCorruption_Review_Channel_Ops__c;
            acupdates.add(ac);
        }

    }
    if (acupdates.size() > 0) {
        upsert acupdates;
    }


    //
    // Cached list to add partner programs
    //
    List<Partner_Program__c> partnerProgramsList = new List<Partner_Program__c>();
    Set<Id> updateAccountList = new Set<Id>();

    for (Partner_Onboarding_Registration__c lead : leadApprovedList) {
        ID accountId = onbAccountMap.get(lead.Id);

        Partner_Program__c partnerProgram = new Partner_Program__c();
        partnerProgram.Account__c = accountId;
        partnerProgram.Enroll_Date__c = Date.today();
        partnerProgram.Is_Primary__c = true;
        partnerProgram.Status__c = 'Active';
        partnerProgram.Tier__c = lead.Partner_Tier_Name__c;
        partnerProgram.Program__c = [
            select Id, Legacy_Partner_Type__c
            from   Partner_Program_Definition__c
            where  Legacy_Partner_Type__r.Name = :lead.Partner_Type_Formula__c limit 1
        ].Id;

        partnerProgramsList.add(partnerProgram);

        // Add CCSP program to onboarding SCP partners.
        if (lead.Partner_Type_Formula__c == PartnerConst.SCP) {
            Partner_Program__c ccspPartnerProgram = new Partner_Program__c();
            ccspPartnerProgram.Account__c = accountId;
            ccspPartnerProgram.Enroll_Date__c = Date.today();
            ccspPartnerProgram.Is_Primary__c = false;
            ccspPartnerProgram.Status__c = 'Active';
            ccspPartnerProgram.Tier__c = PartnerConst.UNAFFILIATED;
            ccspPartnerProgram.Program__c = [
                select  Id,
                        Program_Category__c
                from    Partner_Program_Definition__c
                where   Program_Category__c = :PartnerConst.CCNSP
                limit   1
            ].Id;

            partnerProgramsList.add(ccspPartnerProgram);
        }

        // Add Embedded program to onboarding ISV Embedded partners.
        if (lead.Subtype__c != null && lead.Subtype__c.equalsIgnoreCase(OnboardingApplyController.EMBEDDED)) {
            Partner_Program__c embeddedPartnerProgram = new Partner_Program__c();
            embeddedPartnerProgram.Account__c = accountId;
            embeddedPartnerProgram.Enroll_Date__c = Date.today();
            embeddedPartnerProgram.Is_Primary__c = false;
            embeddedPartnerProgram.Status__c = 'Active';
            embeddedPartnerProgram.Tier__c = PartnerConst.UNAFFILIATED;
            embeddedPartnerProgram.Program__c = [
                select  Id,
                        Program_Category__c
                from    Partner_Program_Definition__c
                where   Program_Category__c = :PartnerConst.EMBED
                limit   1
            ].Id;

            partnerProgramsList.add(embeddedPartnerProgram);

            // Get the products.
            List<PARF_Product__c> parfProducts = [
                select  Id,
                        PARF_Form__c,
                        Product_Description__c,
                        Product_Name__c,
                        Product_URL__c
                from    PARF_Product__c
                where   PARF_Form__r.Partner_Onboarding_Record__c = :lead.Id
            ];

            if (parfProducts.size() > 0) {
                for (PARF_Product__c product : parfProducts) {
                    product.Account__c = accountId;
                }
                update parfProducts;
            }
        }
    }

    if (partnerProgramsList.size() != 0) {
        insert partnerProgramsList;

        for (Partner_Program__c program : partnerProgramsList) {
            List<PARF_Product__c> parfProducts = [
                select  Id,
                        Product_Description__c,
                        Product_Name__c,
                        Product_URL__c,
                        Desired_RH_Prod_Desc__c
                from    PARF_Product__c
                where   Account__c = :program.Account__c
            ];
            if (parfProducts.size() > 0) {
                List<Partner_Program_Product__c> programProducts = new List<Partner_Program_Product__c>();
                for (PARF_Product__c parfProduct : parfProducts) {
                    Partner_Program_Product__c product = new Partner_Program_Product__c();
                    product.Program__c = program.Id;
                    product.Product_Description__c = parfProduct.Product_Description__c;
                    product.Product_Name__c = parfProduct.Product_Name__c;
                    product.Product_URL__c = parfProduct.Product_URL__c;
                    product.Requested_Descriptions__c = parfProduct.Desired_RH_Prod_Desc__c;
                    programProducts.add(product);
                }
                if (programProducts.size() > 0) {
                    insert programProducts;
                }
            }
        }
    }

    //
    // Future : Convert the Lead/Contact to a Partner User
    //

//    OnboardingConversion.convertContactToUserFuture(onbAccountMap.keyset());


    //
    //Build a list of registrations with existing account filled-in and are supposed to be Join as part of implementing SBC for ONB
    //Reference -Story in rally: US62603
    //

    //
    //find the registrations which are associated with an existing account that's being approved
    //
    for (Partner_Onboarding_Registration__c reg : joinList) {
        if (Trigger.oldMap.get(reg.Id).Partner_Onboarding_Status__c != reg.Partner_Onboarding_Status__c &&
            reg.Partner_Onboarding_Status__c == 'Approved' &&
            reg.Account__c != null &&
            reg.Channel_Ops_Approved__c == true) {

            Partner_Onboarding_Registration__c registration = new Partner_Onboarding_Registration__c();

            registration.Account__c         = reg.Account__c;
            registration.RecordTypeId       = reg.RecordTypeId;
            registration.Partner_Type__c    = reg.Partner_Type__c;
            registration.Partner_Tier__c    = reg.Partner_Tier__c;
            registration.Company__c         = reg.Company__c;
            registration.FirstName__c       = reg.FirstName__c;
            registration.LastName__c        = reg.LastName__c;
            registration.Email__c           = reg.Email__c;
            registration.RHNLogin__c        = reg.RHNLogin__c;
            registration.Address1__c        = reg.Address1__c;
            registration.Address2__c        = reg.Address2__c;
            registration.City__c            = reg.City__c;
            registration.State_Province__c  = reg.State_Province__c;
            registration.Country__c         = reg.Country__c;
            registration.Postal_Code__c     = reg.Postal_Code__c;
            registration.Global_Region__c   = reg.Global_Region__c;
            registration.SubRegion__c       = reg.SubRegion__c;
            registration.OwnerId            = reg.OwnerId;
            registration.Partner_Onboarding_Application__c = reg.Id;
            registration.Partner_Onboarding_Status__c = 'Submitted';
            System.debug('registration tied to an existing account found');

            insert registration;

            //generate token and send email to partner to join onboard
            PartnerEmailUtils.sendLeadEmail(registration.Id, registration.email__c);

            //set the status flag on the current record
            reg.Partner_Onboarding_Status__c = 'Converted to Join';
        }
    }


    //
    // Update the agreement to use the current account
    //

    OnboardingConversion.convertPartnerAgreements(onbAccountMap);


    //
    // Send out the CC&SP t&c link
    //
    for (Partner_Onboarding_Registration__c lead : ccspList) {
        PartnerEmailUtils.sendCCSPTermsEmail(lead.Id, lead.Email__c, lead.Onboarding_Language_Preference__c);
    }
    //
    // Send out the Embed t&c link
    //
    // for (Partner_Onboarding_Registration__c lead : embedList) {
    for (Partner_Onboarding_Registration__c lead : leadPARFMap.keyset()) {
        if (lead == null) {
            System.debug('Lead is null.');
        }
        if (leadPARFMap.get(lead) == null) {
            System.debug('PARF is null with this lead: ' + lead.Id);
        }
        PARF_Form__c parf = leadPARFMap.get(lead);
        if (parf.Custom_Terms_Required__c != 'Yes') { // If custom terms are required, don't send the terms email. US71992
            PartnerEmailUtils.sendEmbedTermsEmail(lead.Id, lead.Email__c, lead.Onboarding_Language_Preference__c);
        }
        // Create contract for custom terms and submit for approval. US71992
        if (parf.Custom_Terms_Required__c == 'Yes') {
            Country__c country = [
                select  Id,
                        Name
                from    Country__c
                where   Id = :lead.Country__c
            ];
            User requestingUser = [
                select  Id,
                        Federation_ID__c
                from    User
                where   Federation_ID__c = :lead.RHNLogin__c
                limit   1
            ];
            Id partnerAccountId = onbAccountMap.get(lead.Id);
            Account partnerAccount = accountMap.get(partnerAccountId);
            Contract con = new Contract();
            con.AccountId = lead.Sales_Account__c;
            con.OwnerId = partnerAccount.OwnerId;
            con.CreatedById = partnerAccount.OwnerId;
            con.Description = 'Embedded standard terms declined';
            con.Super_Region__c = partnerAccount.Global_Region__c;
            con.SubRegion__c = partnerAccount.Subregion__c;
            con.CountryOfOrder__c = country.Name;
            con.Contract_Type__c = Embedded_Terms_Controller.CONTRACT_TYPE;
            con.Stage__c = 'New';
            // con.Requesting_User__c = me.Id;
            con.Requesting_User__c = requestingUser.Id;
            con.Reason_Partner_Declined_Terms__c = lead.CustomTerms__c;
            con.RecordTypeId = [
                select  Id
                from    RecordType
                where   SObjectType = 'Contract'
                and     DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
                and     IsActive = true
            ].Id;
            insert con;
            System.assert(con.Id != null);
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Submitting custom contract request');
            approvalRequest.setObjectId(con.Id);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        }
    }

}