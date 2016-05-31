trigger PartnerOnboarding_UserApproved on Partner_Onboarding_Registration__c (before update) {

    if (BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    //
    // Build a list of only the leads that were just approved and need to be converted
    //

    List<Partner_Onboarding_Registration__c> leadApprovedList = new List<Partner_Onboarding_Registration__c>();

    RecordType bprType = null;

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
            continue; // no change to onboarding status
        }

        if (bprType == null) {
            bprType = [select Id from RecordType where DeveloperName = 'Business_Partner_Registration' and SObjectType = 'Partner_Onboarding_Registration__c'];
        }
        if (lead.RecordTypeId != bprType.Id) {
            System.debug('not Business Partner Registration record type: ' + lead.RecordTypeId);
            continue;
        }
        if (lead.Account__c == null) {
            continue; // No existing account specified.
        }

        System.debug('adding ' + lead.FirstName__c + ' ' + lead.LastName__c);
        leadApprovedList.add(lead);
    }

    if (leadApprovedList.size() == 0) {
        return;
    }

    //
    // We need country abbreviations during account conversion
    //
    Map<ID,Country__c> countryMap = new Map<ID,Country__c>([
        select  Id, Abbreviation__c
        from    Country__c
    ]);

    Set<ID> contactIdList = new Set<ID>();

    //
    // Do the conversions.  NOTE that this is NOT batch friendly and I could not help that since we are no longer using Salesforce ConvertLeads functionality.
    //
    for (Partner_Onboarding_Registration__c lead : leadApprovedList) {
        System.debug('converting ' + lead.FirstName__c + ' ' + lead.LastName__c);

        // Get the account information.
        Account account = [
            select  Id,
                    BillingStreet,
                    BillingState,
                    BillingCity,
                    BillingPostalCode,
                    BillingCountry
            from    Account
            where   Id = :lead.Account__c
            limit   1
        ];

        //
        // Create the initial contact
        //
        Contact contact                 = new Contact();
        contact.AccountId               = lead.Account__c;
        contact.FirstName               = lead.FirstName__c;
        contact.LastName                = lead.LastName__c;
        contact.LoginName__c            = lead.RHNLogin__c;
        contact.Onboarding_Country__c   = lead.Country__c;
        contact.LanguagePreference__c   = lead.Onboarding_Language_Preference__c;
        contact.Email                   = lead.Email__c;
        contact.MailingStreet           = account.BillingStreet;
        contact.MailingState            = account.BillingState;
        contact.MailingCity             = account.BillingCity;
        contact.MailingPostalCode       = account.BillingPostalCode;
        contact.MailingCountry          = account.BillingCountry;

        insert contact;
        contactIdList.add(lead.Id);

        //
        // update the onboarding record fields we'll need later
        //
        lead.ConvertedAccount__c = account.Id;
        lead.ConvertedContact__c = contact.Id;
    }

    //
    // Future : Convert the Lead/Contact to a Partner User
    //

    OnboardingConversion.convertContactToUserFuture(contactIdList);
}