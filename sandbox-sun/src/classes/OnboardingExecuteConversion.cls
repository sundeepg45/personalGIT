global class OnboardingExecuteConversion {

    //
    // Convert the new partner contact to a portal-enabled user.
    //

    @future
    global static void convertContactToUserFuture(Set<Id> convertedLeadIds) {
        OnboardingExecuteConversion.convertContactToUser(convertedLeadIds);
    }

    global static void convertContactToUser(Set<Id> convertedLeadIds) {
        // Setup the instance
        OnboardingExecuteConversion onboarding = new OnboardingExecuteConversion();

        // Loop over the generated user list
        Map<Id, User> acountIdAndUserMap = new Map<Id,User>();
        List<Account> updateAccountList = new List<Account>();
        for(Lead lead : onboarding.getConvertedLeadList(convertedLeadIds)) {
            User user = onboarding.getPartnerUser(lead.ConvertedContact);
            if (lead.Onboarding_Profile_Id__c == null) {
            	user.ProfileId = onboarding.getPartnerPortalProfileIdByName(lead.Partner_Onboarding_Profile__c);
            } else {
            	user.ProfileId = lead.Onboarding_Profile_Id__c;
            }
            System.debug('Lead Converted Account ID------->'+ lead.ConvertedAccountId);
            acountIdAndUserMap.put(lead.ConvertedAccountId, user);

        }

      APPR_DGRP.DynamicGroupUtil.isAsync = True;
        insert acountIdAndUserMap.values();
    }

    //
    // Update the partner agreements
    //

    @future
    global static void convertPartnerAgreementsFuture(Set<Id> convertedLeadIds) {
        OnboardingExecuteConversion.convertPartnerAgreements(convertedLeadIds);
    }

    global static void convertPartnerAgreements(Set<Id> convertedLeadIds) {
        // Setup the instance
        OnboardingExecuteConversion onboarding = new OnboardingExecuteConversion();

        // All accounts relevant to these leads
        List<Lead> convertedLeadList = onboarding.getConvertedLeadList(convertedLeadIds);
        Map<Id, Id> convertedLeadMap = onboarding.getConvertedLeadToAccountMap(convertedLeadList);

        // Find and update agreements
        List<PartnerAgreement__c> partnerAgreementList = [
            select PartnerLead__c
              from PartnerAgreement__c
             where PartnerLead__c in :convertedLeadIds
        ];

        for(PartnerAgreement__c partnerAgreement : partnerAgreementList) {
            partnerAgreement.Partner__c = convertedLeadMap.get(partnerAgreement.PartnerLead__c);
        }

        update partnerAgreementList;
    }

    //
    // Insert related partner status records
    //

    @future
    global static void insertPartnerStatusesFuture(Set<Id> convertedLeadIds) {
        OnboardingExecuteConversion.insertPartnerStatuses(convertedLeadIds);
    }

    global static void insertPartnerStatuses(Set<Id> convertedLeadIds) {
        // Setup the instance
        OnboardingExecuteConversion onboarding = new OnboardingExecuteConversion();

        // Fetch the converted lead objects
        List<Lead> convertedLeadList = onboarding.getConvertedLeadList(convertedLeadIds);

        // Fetch the ID for a 'Ready' partner tier
        Id partnerTierId = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.READY'
             limit 1
        ].Id;

        // Add partner status objects for each new account successfully created
        List<PartnerStatus__c> partnerStatusList = new List<PartnerStatus__c>();

        for(Lead lead : convertedLeadList) {
            // Ignore leads merged into existing accounts
            if (lead.Account__c != null)
                continue;

            PartnerStatus__c partnerStatus = new PartnerStatus__c();
            partnerStatus.Partner__c = lead.ConvertedAccountId;
            partnerStatus.PartnerTier__c = partnerTierId;
            partnerStatus.PartnerType__c = lead.Partner_Type__c;
            partnerStatus.ExpirationDate__c = null;
            //partnerStatus.ExpirationDate__c = Date.Today().addYears(1) - 1;
            partnerStatus.ApprovalStatus__c = 'Approved';
            partnerStatusList.add(partnerStatus);
        }

        //
        // Add the statuses
        //

        // 2010-04-09 Commented out so we can deploy to QA. There are mismatched version of Dynamic Groups
        // in QA and POC.
        //APPR_DGRP.DynamicGroupUtil.isAsync = true;

        insert partnerStatusList;

        //
        // Now that the statuses are present, call the NFR creation process.
        //
        /* US52486 - NFR creation removed from partner onboarding process
        Set<Id> leadConvertedAccountIds = new Set<Id>();

        for(Lead lead : convertedLeadList)
            leadConvertedAccountIds.add(lead.ConvertedAccountId);

        //NFRCreateOnOnboarding.createNFR(leadConvertedAccountIds);
        List<NFR_Request__c> nfrList = NFRCreateOnOnboarding.createNFR(leadConvertedAccountIds);
        //submit it for auto approval
        for (NFR_Request__c nfrRequest : nfrList) {
            //move text to custom label
            NFRCreateOnOnboarding.submitForApproval(nfrRequest.Id, 'Submitting for Approval.');
        }
        */
    }

    //
    // private vars
    //

    private static Map<String, Id> partnerProfileMap = null; // starts uninitialized.

    //
    // Object conversion method
    //

    public Map<Id, Id> getConvertedLeadToAccountMap(List<Lead> leadList) {
        Map<Id, Id> leadMap = new Map<Id, Id>();

        for(Lead lead : leadList)
            leadMap.put(lead.Id, lead.ConvertedAccountId);

        return leadMap;
    }

    public List<Lead> getConvertedLeadList(Set<Id> convertedLeadIds) {
        return [
            select ConvertedContact.FirstName
                 , ConvertedContact.LastName
                 , ConvertedContact.Email
                 , ConvertedContact.LoginName__c
                 , ConvertedContact.LanguageCode__c
                 , ConvertedContactId
                 , ConvertedAccountId
                 , Onboarding_Language_Preference__c
                 , Partner_Onboarding_Profile__c
            	 , Onboarding_Profile_Id__c
                 , Partner_Type__c
                 , Account__c
              from Lead
             where Id in :convertedLeadIds
        ];
     }

    public Id getPartnerPortalProfileIdByName(String profileName) {
        if (partnerProfileMap == null) {
            partnerProfileMap = new Map<String, Id>();

            for(Profile profile : [
                select Name
                  from Profile
                 where Name like '%Partner Portal %'
            ]) partnerProfileMap.put(profile.Name, profile.Id);
        }

        return partnerProfileMap.get(profileName);
    }

    public User getPartnerUser(Contact contact) {
        system.assert(contact.LoginName__c != null, 'The "Contact.RHN Entitlement Login" field is missing but required for the SSO login process to function.');

        User partnerUser = new User();
        partnerUser.FirstName = contact.FirstName;
        partnerUser.LastName = contact.LastName;
        partnerUser.Email = contact.Email;
        partnerUser.ContactId = contact.Id;

        //
        // The way we are dealing with language preferences is laughable.
        // Please excuse the mess.
        //

        String LanguageCode = 'en_US';
        //
        // Bring over the preferred language from lead to contact
        //
        List<Lead> leadList = [select Onboarding_Language_Preference__c from Lead where ConvertedContactId = :contact.Id];
        if (leadList.size() > 0) {
            Lead lead = leadList.get(0);
            if (lead.Onboarding_Language_Preference__c != null) {
                String lang = 'English';
                if (lead.Onboarding_Language_Preference__c == 'en'){
                    lang = 'English';
                } else if (lead.Onboarding_Language_Preference__c == 'fr'){
                    lang = 'French';
                    LanguageCode = 'fr';
                } else if (lead.Onboarding_Language_Preference__c == 'de'){
                    lang = 'German';
                    LanguageCode = 'de';
                } else if (lead.Onboarding_Language_Preference__c == 'it'){
                    lang = 'Italian';
                    LanguageCode = 'it';
                } else if (lead.Onboarding_Language_Preference__c == 'es'){
                    lang = 'Spanish';
                    LanguageCode = 'es';
                } else if (lead.Onboarding_Language_Preference__c == 'ja'){
                    lang = 'Japanese';
                    LanguageCode = 'ja';
                } else if (lead.Onboarding_Language_Preference__c == 'zh'){
                    lang = 'Chinese (Simplified)';
                    LanguageCode = 'zh_CN';
                } else if (lead.Onboarding_Language_Preference__c == 'ko'){
                    lang = 'Korean';
                    LanguageCode = 'ko';
                } else if (lead.Onboarding_Language_Preference__c == 'ru'){
                    lang = 'Russian';
                    LanguageCode = 'ru';
                } else if (lead.Onboarding_Language_Preference__c == 'pt'){
                    lang = 'Portuguese (Brazilian)';
                    LanguageCode = 'pt_BR';
                }
                contact.LanguagePreference__c = lang;
//              update contact;
            }
        }

        // Regionalized fields
        partnerUser.EmailEncodingKey = 'UTF-8';
        partnerUser.LanguageLocaleKey = LanguageCode;
        partnerUser.LocalesIdKey = LanguageCode;
        partnerUser.TimeZoneSidKey = 'America/New_York';

        // Generated username
        partnerUser.Username = getPartnerUserUsername(contact);

        // Generated alias
        partnerUser.Alias = getPartnerUserAlias(contact);

        // SSO federation ID login
        partnerUser.FederationIdentifier = contact.LoginName__c;
        return partnerUser;
    }

    public String getPartnerUserAlias(Contact contact) {
        system.assert(null != contact, 'Contact reference is null.');
        system.assert(null != contact.Id, 'Contact.Id reference is null.');
        return getSimplifiedId(contact.Id).substring(8);
    }

    public String getPartnerUserUsername(Contact contact) {
        system.assert(null != contact, 'Contact reference is null.');
        system.assert(null != contact.Id, 'Contact.Id reference is null.');
        if (Test.isRunningTest()) {
            return contact.LoginName__c + getSimplifiedId(contact.Id) + '@partner.redhat.com';
        }
        else {
            return getSimplifiedId(contact.Id) + '@partner.redhat.com';
        }
    }

    public String getSimplifiedId(String selectedId) {
        if (selectedId == null)
            return null;
        if (selectedId.length() > 15)
            selectedId = selectedId.substring(0, 15);
        return selectedId.toLowerCase();
    }


}