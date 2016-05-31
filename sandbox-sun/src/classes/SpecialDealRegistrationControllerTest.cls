@isTest(SeeAllData = true)
public with sharing class SpecialDealRegistrationControllerTest {

    @isTest
    static void  testOpenStackDealRegistrationNonDealRegUser() {
        String dealType = 'OpenStack';
        Account testAccount = PartnerTestUtils.basicAccountSetup('SpecialDealRegistrationControllerTestPartner');
        String nonDealRegProfileName = testAccount.Global_Region__c + ' Partner Portal – Strategic License';
        Contact testContact = PartnerTestUtils.makeContact(testAccount.Id, 'NonDealRegUserTestContact');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :nonDealRegProfileName
                                LIMIT 1].Id;
        insert testUser;

        System.runAs(testUser) {
            ApexPages.currentPage().getParameters().put('dealType', dealType);
            SpecialDealRegistrationController controller = new SpecialDealRegistrationController();
            controller.cancel();
            System.assertEquals(false, controller.getHasDealRegAccess());
        }
    }

    @isTest
    static void  testOpenStackDealRegistrationDealRegUser() {
        String dealType = 'OpenStack';
        Account testAccount = PartnerTestUtils.basicAccountSetup('SpecialDealRegistrationControllerTestPartner');
        String dealRegProfileName = testAccount.Global_Region__c + ' Partner Portal - Strategic License - Deal Registration';
        Contact testContact = PartnerTestUtils.makeContact(testAccount.Id, 'DealRegUserTestContact');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :dealRegProfileName
                                LIMIT 1].Id;
        insert testUser;

        System.runAs(testUser) {
            ApexPages.currentPage().getParameters().put('dealType', dealType);
            SpecialDealRegistrationController controller = new SpecialDealRegistrationController();
            System.assertEquals(true, controller.getHasDealRegAccess());
            controller.lead.LastName = 'LastName';
            controller.lead.Decision_Role__c = 'Decision Maker';
            controller.lead.Company = 'Company';
            controller.lead.Email = 'test@email.com';
            controller.lead.Deal_Type__c = 'New';
            controller.lead.Deal_Registration_Classification__c = 'JBoss';
            controller.lead.Red_Hat_Subscription_Revenue__c = 50000.0;
            controller.lead.Distributor__c = 'Ingram Micro';
            controller.lead.Estimated_Close_Date__c = System.today();
            controller.lead.Do_they_have_funding_for_this_quarter__c = 'Yes';
            controller.lead.Does_customer_have_an_open_source_strate__c = 'Yes';
            controller.lead.Are_you_the_Sales_Rep_for_this_Lead__c = 'Yes';
            controller.lead.Project_Description__c = 'Project Description';
            controller.lead.Value_Added_Sales_Activity_Description__c = 'Value Added Sales Activity Description';
            controller.lead.Value_Added_Services_Proposed_Desc__c = 'Value Added Services Proposed Description';
            controller.lead.Products_of_Interest__c = 'JBoss';
            controller.lead.OEM_hardware_options__c = 'OEM';
            controller.lead.State = 'NC';
            controller.save();
            controller.lead.Country = 'US';
            controller.save();
            Lead newLead = [SELECT Special_Deal_Type__c
                            FROM Lead
                            WHERE Id = :controller.lead.Id];
            System.assertEquals(dealType, newLead.Special_Deal_Type__c);
        }
    }

    @isTest
    static void  testOpenStackDealRegistrationNoAccount() {
        String dealType = 'OpenStack';
        String nonDealRegProfileName = 'NA Partner Portal – Strategic License';
        ApexPages.currentPage().getParameters().put('dealType', dealType);
        SpecialDealRegistrationController controller = new SpecialDealRegistrationController();
        controller.cancel();
        System.assertEquals(true, controller.getHasDealRegAccess());
    }

    @isTest
    static void  testOpenStackDealRegistrationFedSledDealRegUser() {
        String dealType = 'OpenStack';
        Account testAccount = PartnerTestUtils.basicAccountSetup('SpecialDealRegistrationControllerTestPartner');
        String fedsledDealRegProfileName = testAccount.Global_Region__c + ' Partner Portal - Strategic License - Deal Registration Fed/Sled';
        Contact testContact = PartnerTestUtils.makeContact(testAccount.Id, 'FedSledDealRegUserTestContact');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :fedsledDealRegProfileName
                                LIMIT 1].Id;
        insert testUser;

        System.runAs(testUser) {
            ApexPages.currentPage().getParameters().put('dealType', dealType);
            SpecialDealRegistrationController controller = new SpecialDealRegistrationController();
            controller.cancel();
            System.assertEquals(true, controller.getHasDealRegAccess());
        }
    }

    @isTest
    static void  testOpenStackDealRegistrationEMEANonDealRegUser() {
        String dealType = 'OpenStack';
        Account testAccount = PartnerTestUtils.basicAccountSetup('SpecialDealRegistrationControllerTestPartner');
        testAccount.Global_Region__c = 'EMEA';
        String emeaNonDealRegProfileName = testAccount.Global_Region__c + ' Partner Portal – Strategic License';
        Contact testContact = PartnerTestUtils.makeContact(testAccount.Id, 'EMEANonDealRegUserTestContact');
        insert testContact;
        User testUser = PartnerTestUtils.makeUser(testAccount, testContact);
        testUser.ProfileId = [SELECT Name
                                FROM Profile
                                WHERE Name LIKE :emeaNonDealRegProfileName
                                LIMIT 1].Id;
        insert testUser;

        System.runAs(testUser) {
            ApexPages.currentPage().getParameters().put('dealType', dealType);
            SpecialDealRegistrationController controller = new SpecialDealRegistrationController();
            controller.cancel();
            controller.global_region = 'EMEA';
            System.assertEquals(false, controller.getHasDealRegAccess());
        }
    }
}