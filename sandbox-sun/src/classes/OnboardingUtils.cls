public class OnboardingUtils {

    public static Boolean APPROVED_BY_API = false;


    public static String[] getLanguageTranslations(String userLanguage) {
      Language_Names__c languageNames = [
          select  Name,
                  Language__c,
                  list__c
          from    Language_Names__c
          where   Language_Code__c = :userLanguage
      ];
      String[] pairs = languageNames.list__c.split(';');
      String[] sortingList = new List<String>();
      for (String pair : pairs) {
          String[] kv = pair.split('=');
          System.assert(kv.size() == 2, 'Bad formatting in language_names for ' + userLanguage);
          sortingList.add(kv[1] + '=' + kv[0]);  // reversing the order for easier sort
      }
      sortingList.sort();
      return sortingList;
    }

    public static List<SelectOption> getLanguageXnAsSelect(String userLanguage) {
      SelectOption[] languageSelectionList = new List<SelectOption>();
      String[] sortedList = getLanguageTranslations(userLanguage);
      for (String pair : sortedList) {
          String[] kv = pair.split('=');
          languageSelectionList.add(new SelectOption(kv[1], kv[0]));
      }
      return languageSelectionList;
    }

    public static User getUserWithFederationId(String fedid) {
        if (fedid == null) {
            return null;
        }
        User[] user = [
            select id
                 , Name
                 , IsActive
                 , Email
                 , Compliant_Email_Notices__c
                 , FederationIdentifier
                 , contactId
                 , contact.accountId
                 , migratedOverride__c
                 , LanguageLocaleKey
                 , Contact.Id
                 , Contact.MailingCountry
                 , Contact.Account.BillingCountry
                 , Contact.Account.PartnerStatuses__c
                 , Contact.Account.AllowedEmailDomains__c
                 , Contact.Account.Global_Region__c
                 , Contact.Account.IsPartner
                 , AccountId
                 , ConsumerUserCreated__c
              from User
             where FederationIdentifier = :fedid
               and profile.name like '%Partner Portal%'
               //and isPortalEnabled = true
               and ContactId != null
             limit 1
        ];
        if (user.size() == 1) {
            User u = user[0];
            if (u.Contact.Account.PartnerStatuses__c == null ||
                u.Contact.Account.PartnerStatuses__c == '' ||
                u.Contact.Account.PartnerStatuses__c.toLowerCase().contains('unaffiliated -')){
                u.IsActive = false;
            }
            return u;
        }
        return null;
    }


    public static Contact getContactWithFederationId(String federationId) {
        if (federationId == null) {
            return null;
        }
        Contact[] contact = [
            select id
                 , LoginName__c
                 , AccountId
                 , Name
                 , Email
                 , Account.BillingCountry
                 , Account.Global_Region__c
                 , Account.IsPartner
                 , Account_Record_Type__c
              from Contact
             where LoginName__c = :federationId
               and Contact.Account_Record_Type__c in (  :PartnerConst.NA_PARTNER_DN,
                                                        :PartnerConst.EMEA_PARTNER_DN,
                                                        :PartnerConst.APAC_PARTNER_DN,
                                                        :PartnerConst.LATAM_PARTNER_DN)
             limit 1
        ];
        if (contact.size() == 1) {
            return contact[0];
        }
        return null;
    }

    public static Partner_Onboarding_Registration__c getLeadWithFederationId(String federationId) {
        system.debug('FederationID ====> '+federationId);
        Partner_Onboarding_Registration__c[] lead = [
            select id
                 , partner_onboarding_status__c
                 , partner_type__c
                 , partner_type__r.Name
                 , account__c
                 , email__c
                 , company__c
                 , address1__c
                 , city__c
                 , state_province__c
                 , country__c
                 , postal_code__c
                 , global_region__c
                 , subregion__c
                 , RHNLogin__c
                 , Is_Primary_Public_Sector__c
                 , Public_Sector_Market__c
                 , Other_Countries__c
                 , Onboarding_Language_Preference__c
                 , HasCustomTerms__c
                 , Agree_To_Partner_TC__c
                 , Subtype__c
                 , Onb_As_Adv_Or_Prem__c
                 , User_Declined_Custom_Terms__c
              from Partner_Onboarding_Registration__c
             where RHNLogin__c = :federationId
               and RecordType.DeveloperName = 'Business_Partner_Registration'
          order by createdDate desc
             limit 1
        ];
        if (lead != null && lead.size() > 0) {
            return lead.get(0);
        }
        return null;
    }


    public static final Map<String,String> CASE_OWNER_QUEUE_EMAIL = new Map<String,String>{
        'Partner Support Cases - NA' => 'na-partner-helpdesk@redhat.com',
        'Partner Support Cases - APAC' => 'apac-partner-helpdesk@redhat.com',
        'Partner Support Cases - EMEA' => 'emea-partner-helpdesk@redhat.com',
        'Partner Support Cases - LATAM' => 'latam-partner-helpdesk@redhat.com'
    };

    public static final Map<String,String> CASE_OWNER_QUEUE_REGION = new Map<String,String>{
        'NA' => 'na-partner-helpdesk@redhat.com',
        'APAC' => 'apac-partner-helpdesk@redhat.com',
        'EMEA' => 'emea-partner-helpdesk@redhat.com',
        'LATAM' => 'latam-partner-helpdesk@redhat.com'
    };

    public static Country__c getCountryByAbbreviation(String abbr) {
        return [
            select    Id, Abbreviation__c, Country_of_Order__c, Name
            from      Country__c
            where     Abbreviation__c = :abbr
        ];
    }

    public static String getCaseEmailByRegion(string regionName){
    	return CASE_OWNER_QUEUE_REGION.get(regionName);
    }

    public static Case getOnboardingCase(String federationId){

        User user = OnboardingUtils.getUserWithFederationId(federationId);
        String actId = '';
        if (user != null){
            actId = user.Contact.AccountId;
        }

        return getOnboardingCaseForAccountOrUser(actId, federationId);
    }

    public static Case getOnboardingCaseForAccountOrUser(String accountId, String federationId) {
        List<Case> existingCases = [
            select  id
                    , Issue_Type__c
                    , Status
                    , CaseNumber
                    , CreatedDate
                    , Owner.Name
            from    Case
            where   recordType.name = 'Partner General Issues'
            and     Status != 'Closed'
            and
              ((redhatLoginName__c = :federationId and issue_type_classification__c = 'Partner Onboarding')
              or
              (issue_type_classification__c = 'Requalification Access Request' and AccountId = :accountId))
            order by createdDate desc
            limit 1
        ];
        system.debug('Existing cases: ' + existingCases.size());
        if (existingCases.isEmpty()) {
            return null;
        }
        return existingCases[0];
    }

    public static Account createSalesAccount(ID onboardingRecId) {
        Partner_Onboarding_Registration__c reg = [
            select  Id, Global_Region__c, Company__c, Phone__c, DUNSNumber__c, VATNumber__c, CDH_Party_Number__c, Address1__c, Address2__c,
                    City__c, County__c, State_Province__r.Abbreviation__c, Country__r.Abbreviation__c, Postal_Code__c, CDH_Party_Site_Number__c, OwnerId
            from    Partner_Onboarding_Registration__c
            where   Id = :onboardingRecId
        ];

        String developerName = reg.Global_Region__c + 'Account';
        ID recordTypeId = [select Id from RecordType where DeveloperName = :developerName and SObjectType = 'Account'].Id;
        String CDHPartyNumber = reg.CDH_Party_Number__c;
        List<CDH_Party__c> CDHPartyList = null;
        if (CDHPartyNumber != null) {
            CDHPartyList = [select Id,Name from CDH_Party__c where CDH_Party_Number_Ext__c = :CDHPartyNumber];
        }

        String CDHPartyId;
        String CDHPartyName;
        if (CDHPartyNumber != null && CDHPartyList.size() > 0) {
            CDHPartyId = string.valueOf(CDHPartyList[0].id);
            CDHPartyName = CDHPartyList[0].Name;
        } else {
            System.debug('***** [debug] ***** cdhpartynumber=' + CDHPartyNumber);
            CDH_Party__c newCDHRecord = new CDH_Party__c(Name = CDHPartyNumber,CDH_Party_Number_Ext__c = CDHPartyNumber,CDH_Party_Type__c = 'ORGANIZATION');
            insert newCDHRecord;
            CDHPartyName = CDHPartyNumber;
            CDHPartyId = string.valueOf(newCDHRecord.id);
        }

        Savepoint sp = Database.setSavepoint();
        Account accountRecord = new Account(Name = reg.Company__c,
                                            phone = reg.Phone__c,
                                            DunsNumber = reg.DUNSNumber__c,
                                            D_U_N_S__c = reg.DUNSNumber__c,
                                            VATNumber__c = reg.VATNumber__c,
                                            recordTypeId = recordTypeId,
                                            OwnerId = reg.OwnerId,
                                            CDH_Party_Number__c = reg.CDH_Party_Number__c,
                                            CDH_Party_Name__c = Id.valueOf(CDHPartyId),
                                            BillingCountry = reg.Country__r.Abbreviation__c
                                );
        try {
            insert accountRecord;
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        }

        if (accountRecord.Id != null) {
            Address__c addressRecord = new Address__c(Address_Line1__c = reg.Address1__c,
                                                      Address_Line2__c= reg.Address2__c,
                                                      City__c = reg.City__c,
                                                      County__c = reg.County__c,
                                                      State__c = reg.State_Province__r.Abbreviation__c,
                                                      Province__c = reg.State_Province__r.Abbreviation__c,
                                                      Country__c = reg.Country__r.Abbreviation__c,
                                                      Zip_Postal_Code__c = reg.Postal_Code__c,
                                                      Sales_Account__c = accountRecord.Id,
    //                                                      CDH_Party__c =  Id.valueOf(CDHPartyId),
    //                                                      CDH_Party_Site_Number__c = reg.CDH_Party_Site_Number__c,
                                                      Identifying_Address__c = true,
                                                      Bill_To_Address__c = true,
                                                      Status__c = 'Active'
                                                     );
             System.debug('----------------addressRecord '+addressRecord);
            try {
                insert addressRecord;
            } catch(Exception e) {
                Database.rollback(sp);
                throw e;
            }
        }
    //        reg.Sales_Account__c = accountRecord.Id;
    //        update reg;
        return accountRecord;
    }

}