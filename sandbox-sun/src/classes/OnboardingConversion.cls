global  class OnboardingConversion {
   //
    // Convert the new partner contact to a portal-enabled user.
    //

    @future
    global static void convertContactToUserFuture(Set<Id> convertedLeadIds) {
        OnboardingConversion.convertContactToUser(convertedLeadIds);
    }

    global static void convertContactToUser(Set<Id> convertedLeadIds) {
        // Setup the instance
        OnboardingConversion onboarding = new OnboardingConversion();

        // Loop over the generated user list
        Map<Id, User> accountIdAndUserMap = new Map<Id,User>();
        Partner_Onboarding_Registration__c[] leads = onboarding.getConvertedLeadList(convertedLeadIds);
        Map<ID, Contact> contactMap = new Map<ID, Contact>([
            select  Id, FirstName, LastName, LoginName__c, Email, AccountId
            from    Contact
            where   Id in :PartnerUtil.getStringFieldSet(leads, 'ConvertedContact__c')
        ]);
        for (Partner_Onboarding_Registration__c lead : leads) {
            Contact contact = contactMap.get(lead.ConvertedContact__c);
            User user = onboarding.getPartnerUser(contact);
            if (lead.Onboarding_Profile_Id__c == null) {
                user.ProfileId = onboarding.getPartnerPortalProfileIdByName(lead.Partner_Onboarding_Profile__c);
            } else {
                user.ProfileId = lead.Onboarding_Profile_Id__c;
            }
            System.debug('Lead Converted Account ID------->'+ lead.ConvertedAccount__c);
            accountIdAndUserMap.put(lead.ConvertedAccount__c, user);

        }

        APPR_DGRP.DynamicGroupUtil.isAsync = True;
        //
        // insert users
        //
        insert accountIdAndUserMap.values();
    }

    //
    // Update the partner agreements
    //

    //@future
    //global static void convertPartnerAgreementsFuture(Set<Id> convertedLeadIds) {
    //    OnboardingConversion.convertPartnerAgreements(convertedLeadIds);
    //}

    global static void convertPartnerAgreements(Map<ID,ID> convertedLeadAccountIds) {
        // Setup the instance
//        OnboardingConversion onboarding = new OnboardingConversion();

        // All accounts relevant to these leads
//        List<Partner_Onboarding_Registration__c> convertedLeadList = onboarding.getConvertedLeadList(convertedLeadIds);
//        Map<Id, Id> convertedLeadMap = onboarding.getConvertedLeadToAccountMap(convertedLeadList);

        // Find and update agreements
        List<PartnerAgreement__c> partnerAgreementList = [
            select Id, Partner_Onboarding__c
              from PartnerAgreement__c
             where Partner_Onboarding__c in :convertedLeadAccountIds.keyset()
        ];

        System.debug('*****[debug]***** agreements=' + partnerAgreementList.size());
        for(PartnerAgreement__c partnerAgreement : partnerAgreementList) {
            //partnerAgreement.Partner__c = convertedLeadMap.get(partnerAgreement.Partner_Onboarding__c);
            partnerAgreement.Partner__c = convertedLeadAccountIds.get(partnerAgreement.Partner_Onboarding__c);
            if (partnerAgreement.Partner__c == null) {
                System.debug('*****[debug]***** Account not found for onboarding ' + partnerAgreement.Partner_Onboarding__c);
            }
        }

        update partnerAgreementList;
    }

    //
    // private vars
    //

    private static Map<String, Id> partnerProfileMap = null; // starts uninitialized.

    //
    // Object conversion method
    //

    public Map<Id, Id> getConvertedLeadToAccountMap(List<Partner_Onboarding_Registration__c> leadList) {
        Map<Id, Id> leadMap = new Map<Id, Id>();

        for(Partner_Onboarding_Registration__c lead : leadList)
            leadMap.put(lead.Id, lead.ConvertedAccount__c);

        return leadMap;
    }

    public List<Partner_Onboarding_Registration__c> getConvertedLeadList(Set<Id> convertedLeadIds) {
        System.debug(convertedLeadIds);
        return [
            select FirstName__c
                 , LastName__c
                 , Email__c
                 , RHNLogin__c
                 , Onboarding_Language_Preference__c
                 , Partner_Type__c
                 , ConvertedAccount__c
                 , ConvertedContact__c
                 , Onboarding_Profile_Id__c
                 , Partner_Onboarding_Profile__c
              from Partner_Onboarding_Registration__c
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
        return getPartnerUser(contact, null);
    }

    public User getPartnerUser(Contact contact, Partner_Onboarding_Registration__c lead) {
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
        if (lead == null) {
            List<Partner_Onboarding_Registration__c> leadList = [select Onboarding_Language_Preference__c from Partner_Onboarding_Registration__c where ConvertedContact__c = :contact.Id];
            if (leadList.size() > 0) {
                lead = leadList.get(0);
            }
        }
        if (lead != null) {
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

    static public String getPartnerUserAlias(Contact contact) {
        system.assert(null != contact, 'Contact reference is null.');
        system.assert(null != contact.Id, 'Contact.Id reference is null.');
        return getSimplifiedId(contact.Id).substring(8);
    }

    static public String getPartnerUserUsername(Contact contact) {
        system.assert(null != contact, 'Contact reference is null.');
        system.assert(null != contact.Id, 'Contact.Id reference is null.');
        return getSimplifiedId(contact.Id) + '@partner.redhat.com';
    }

    static public String getSimplifiedId(String selectedId) {
        if (selectedId == null)
            return null;
        if (selectedId.length() > 15)
            selectedId = selectedId.substring(0, 15);
        return selectedId.toLowerCase();
    }
}