@isTest(seeAllData=true)
private without sharing class Lead_PartnerOnboardingApprovedTest {

/****
    private static Map<String, ID> tierMap = PFUtils.buildFieldIDMap(
        'HierarchyKey__c', [select Id, HierarchyKey__c from Classification__c where HierarchyKey__c like 'PARTNER_TIER.%']);
    private static Map<String, ID> typeMap = PFUtils.buildFieldIDMap(
        'HierarchyKey__c', [select Id, HierarchyKey__c from Classification__c where HierarchyKey__c like 'PARTNER_TYPE.%']);

     public static Map<String, Object> CONFIG_TEMPLATE = new Map<String, Object> {
        'Lead.FirstName' => 'FirstName',
        'Lead.LastName' => 'LastName',
        'Lead.Company' => 'Company',

        'Lead.Street' => '1801 Varsity Dr',
        'Lead.Country' => 'US',
        'Lead.City' => 'Raleigh',
        'Lead.State' => 'NC',
        'Lead.PostalCode' => '27606',
        'Lead.Phone' => '9195551212',

        'Lead.Industry_Focus__c' => 'Aerospace',
        'Lead.Do_they_act_in_any_government_position__c' => 'No',
        'Lead.Have_they_been_convicted__c' => 'No',

        'Lead.Email' => 'Email@Example.com',
        'Lead.Global_Region__c' => 'NA',
        'Lead.Country' => 'US',
        'Lead.Partner_Onboarding_Profile__c' => 'NA Partner Portal – Strategic License',
        'Lead.Partner_Onboarding_Status__c' => 'Submitted',
        'Lead.Onboarding_Language_Preference__c' => 'en',
        'Lead.RecordTypeId' => [
            select Id
              from RecordType
             where SobjectType = 'Lead'
               and Name = 'Partner Onboarding'
             limit 1
        ].Id,
        'Lead.RHNLogin__c' => String.valueOf(Crypto.getRandomInteger()),
        'ConvertedAccount.PartnerStatuses__c' => 'Ready - Reseller'
    };

    private Lead_PartnerOnboardingApprovedTest() {
        System.debug('[debug]------ tier=' + tierMap.size());
        System.debug('[debug]------ type=' + typeMap.size());
    }

    public static testMethod void testDefaults() {
        tierMap = PFUtils.buildFieldIDMap(
        'HierarchyKey__c', [select Id, HierarchyKey__c from Classification__c where HierarchyKey__c like 'PARTNER_TIER.%']);
        typeMap = PFUtils.buildFieldIDMap(
        'HierarchyKey__c', [select Id, HierarchyKey__c from Classification__c where HierarchyKey__c like 'PARTNER_TYPE.%']);
        System.debug('[debug]------ tier=' + tierMap.size());
        System.debug('[debug]------ type=' + typeMap.size());

        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Partner_Tier__c', tierMap.get('PARTNER_TIER.READY'));
        config.put('Lead.Partner_Type__c', typeMap.get('PARTNER_TYPE.RESELLER'));
        executeTest(config);
    }

    public static testMethod void testForRegion_NA() {
        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Global_Region__c', 'NA');
        config.put('Lead.Partner_Onboarding_Profile__c', 'NA Partner Portal – Strategic License');
        config.put('Lead.Country', 'US');
        config.put('Lead.Partner_Tier__c', tierMap.get('PARTNER_TIER.READY'));
        config.put('Lead.Partner_Type__c', typeMap.get('PARTNER_TYPE.RESELLER'));
        executeTest(config);
    }

    public static testMethod void testForRegion_EMEA() {
        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Global_Region__c', 'EMEA');
        config.put('Lead.Partner_Onboarding_Profile__c', 'EMEA Partner Portal – Strategic License');
        config.put('Lead.Country', 'DK'); // Denmark
        config.put('Lead.Partner_Tier__c', tierMap.get('PARTNER_TIER.READY'));
        config.put('Lead.Partner_Type__c', typeMap.get('PARTNER_TYPE.RESELLER'));
        executeTest(config);
    }

    public static testMethod void testForRegion_APAC() {
        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Global_Region__c', 'APAC');
        config.put('Lead.Partner_Onboarding_Profile__c', 'APAC Partner Portal – Strategic License');
        config.put('Lead.Country', 'JP'); // Japan
        config.put('Lead.Partner_Tier__c', tierMap.get('PARTNER_TIER.READY'));
        config.put('Lead.Partner_Type__c', typeMap.get('PARTNER_TYPE.RESELLER'));
        executeTest(config);
    }

    public static testMethod void testForRegion_LATAM() {
        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Global_Region__c', 'LATAM');
        config.put('Lead.Partner_Onboarding_Profile__c', 'LATAM Partner Portal – Strategic License');
        config.put('Lead.Country', 'AR'); // Argentina
        config.put('Lead.Partner_Tier__c', tierMap.get('PARTNER_TIER.READY'));
        config.put('Lead.Partner_Type__c', typeMap.get('PARTNER_TYPE.RESELLER'));
        executeTest(config);
    }

    public static testMethod void testForPartnerStatuses_ReadyReseller() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER']);
    }

    public static testMethod void testForPartnerStatuses_AdvancedReseller() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.ADVANCED'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER']);

    }

    public static testMethod void testForPartnerStatuses_PremierReseller() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.PREMIER'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER']);

    }

    public static testMethod void testForPartnerStatuses_ReadyISV() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV']);
    }

    public static testMethod void testForPartnerStatuses_AdvancedISV() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.ADVANCED'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV']);
    }

    public static testMethod void testForPartnerStatuses_PremierISV() {
        testForPartnerStatuses( [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TIER.PREMIER'],
                                [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV']);
    }

    public static void testForPartnerStatuses(Classification__c partnerTier, Classification__c partnerType) {
        Map<String, Object> config = CONFIG_TEMPLATE.clone();
        config.put('Lead.Partner_Tier__c', partnerTier.Id);
        config.put('Lead.Partner_Type__c', partnerType.Id);
        config.put('Lead.FirstName', partnerTier.Name);
        config.put('Lead.LastName', partnerType.Name);
        config.put('ConvertedAccount.PartnerStatuses__c', partnerTier.Name + ' - ' + partnerType.Name);
        executeTest(config);
    }


    public static void executeTest(Map<String, Object> config) {
        Lead lead = new Lead();

        for(String name : config.keySet()) {
            if (name.startsWith('Lead.')) {
                if (config.get(name) == null) {
                    lead.put(name.substring(5), null);
                } else {
                    lead.put(name.substring(5), config.get(name));
                }
            }
        }

       lead.RHNLogin__c = String.valueOf(Crypto.getRandomInteger());

        insert lead;

        // add an agreement
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Agreement';
        agreement.Version__c = 1.0;
        agreement.ActivationDate__c = Date.today();
        agreement.ExpirationDate__c = Date.today().addDays(1);
        agreement.ApprovalStatus__c = 'Draft';
        agreement.PartnerType__c = [select id, Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'].Id;
        insert agreement;

        insert new Agreement_Country__c(Agreement__c = agreement.Id, Country__c = [select Id from Country__c where Abbreviation__c = 'US'].Id);
        agreement.ApprovalStatus__c = 'Approved';
        update agreement;

        PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
        partnerAgreement.ActivationDate__c = Date.today();
        partnerAgreement.ExpirationDate__c = Date.today().addDays(1);
        partnerAgreement.Agreement__c = agreement.Id;
        partnerAgreement.PartnerLead__c = lead.Id;
        insert partnerAgreement;

        // pre-conversion sanity check


        // push to the approved stage
        lead.Partner_Onboarding_Status__c = 'Approved';

        //ROhit - 5/20/2010
        APPR_DGRP.DynamicGroupUtil.isTest = true;
        Test.startTest();
        update lead;

        // Refresh lead object
        lead = [
            select Partner_Onboarding_Status__c
                 , IsConverted
                 , ConvertedAccount.Global_Region__c
                 , ConvertedAccount.PartnerStatuses__c
                 , ConvertedAccountId
                 , ConvertedContactId
                 , RHNLogin__c
              from Lead
             where Id = :lead.Id
        ];



        // Finally, explicitly call a extra onboarding conversion methods to
        // generate additional code coverage.
      //  Test.startTest();
      //  OnboardingExecuteConversion.insertPartnerStatusesFuture(new Set<Id> { lead.Id });
    }
***/

}