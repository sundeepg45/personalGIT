public with sharing class Contact_ConvertToUser {
    private ApexPages.StandardController controller;

    public Contact_ConvertToUser(ApexPages.StandardController controller) {
        this.controller = controller;
    }

    public Contact getContact() {
        return (Contact) controller.getRecord();
    }

    public PageReference convertToUser() {
        // Ensure the user hasn't already been converted
        PageReference pageReference = null;

        List<User> existingUserList = [
           select Id
             from User
            where ContactId = :controller.getId()
              and IsActive = true
              and IsPortalEnabled = true
            limit 1
        ];

        if (existingUserList.size() != 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partner user is already enabled for this contact.'));
        } else if (getContact().Account.Global_Region__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is missing an "Account.Global Region" value.'));
        } else if (getContact().LoginName__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is missing an "RHN Entitlement Login" value. This field is required for the "User.Federation ID" field and the SSO login process.'));
        } else try {
            List<Partner_Onboarding_Registration__c> existingLeadList = [
               select Partner_Onboarding_Profile__c
                    , Onboarding_Language_Preference__c
                    , Onboarding_Profile_Id__c
                 from Partner_Onboarding_Registration__c
                where ConvertedContact__c = :controller.getId()
                  and IsConverted__c = true
                  and Partner_Onboarding_Profile__c != null
                limit 1
            ];

            // If the contact was via onboarding, and the approved profile was set, then
            // try to use that value for the profile. Otherwise, choose a profile based on
            // the account's global region (and partner type whenever applicable).

            String profileName = null;
            String profileId = null;
            String preferredLanguage = null;
            Profile p;

            if (existingLeadList.size() != 0) {
                profileName = existingLeadList[0].Partner_Onboarding_Profile__c;
                profileId = existingLeadList[0].Onboarding_Profile_Id__c;
                preferredLanguage = existingLeadList[0].Onboarding_Language_Preference__c;
            }
            else {
                Account a = [select PartnerStatuses__c, Global_Region__c, Finder_Partner_Type__r.HierarchyKey__c from Account where Id = :getContact().AccountId];
                if (a.PartnerStatuses__c.equals('None')){
                    throw new DataRequiredException('Partner type not yet set, so we cannot create the user with the right profile');
                } else if (a.Global_Region__c == null || a.Finder_Partner_Type__r.HierarchyKey__c == null) {
                    throw new DataRequiredException('Global Region and/or Finder Partner Type (Hierarchy Key) are missing.');
                } else {
                    p = partnerUtil.onboardingProfile(a.Global_Region__c, a.Finder_Partner_Type__r.HierarchyKey__c);
                    profileId = p.Id;
                }
            }

            // Create and insert the user
            Contact copy = [
                select Id
                     , LanguageCode__c
                     , LanguagePreference__c
                     , FirstName
                     , LastName
                     , Email
                     , LoginName__c
                  from Contact
                 where Id = :controller.getId()
            ];

//            User user = new OnboardingExecuteConversion().getPartnerUser(getContact());
            User user = new OnboardingConversion().getPartnerUser(copy);
            if (profileId == null) {
                profileId = [SELECT Id
                             FROM Profile
                             WHERE Name = : profileName].Id;
            }
            user.ProfileId = profileId;
            insert user;

            pageReference = new PageReference('/' + user.Id);
            pageReference.setRedirect(true);
        } catch (Exception pageException) {
            ApexPages.addMessages(pageException);
        }

        return pageReference;
    }
}