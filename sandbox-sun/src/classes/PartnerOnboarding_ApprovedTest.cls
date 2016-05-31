@isTest(SeeAllData=true)
private class PartnerOnboarding_ApprovedTest {

    @isTest static void testApproved() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_approved');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'thedarklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Umbrella Corp';
        ctrl.theLead.City__c = 'Raleigh';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLead.Partner_Type__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'].Id;
        ctrl.setLeadCountry('US');
        ctrl.selectedState = 'NC';
        ctrl.theLead.Postal_Code__c = '27610';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'Purveyors of specialized DNA';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'Yes';
        ctrl.submitApplication();
        ctrl.theLead.SBC_Initiated__c = True;

        Test.startTest();

        Partner_Onboarding_Registration__c reg = ctrl.getLead();
        reg.Partner_Onboarding_Status__c = 'Approved';
        update reg;
        Test.stopTest();
        ID accountId = [select ConvertedAccount__c from Partner_Onboarding_Registration__c where Id = :reg.Id].ConvertedAccount__c;

        reg = [select ConvertedAccount__c, Email__c, Sales_Account__c from Partner_Onboarding_Registration__c where Id = :reg.Id];
        System.assert(reg.ConvertedAccount__c != null, 'Converted account ID is missing');

        Contact c = [select Id, AccountId, Email from Contact where AccountId = :reg.ConvertedAccount__c];
        System.assert(c.Email == reg.Email__c, 'Email not converted');

        PartnerAgreement__c[] agreements = [select Id from PartnerAgreement__c where Partner__c = :accountId];
        System.assert(agreements.size() > 0, 'no agreements converted');

        System.assert(reg.Sales_Account__c != null, 'Sales_Account__c is null');

        //
        // Now test that a CDH inbound flow will cause the new partyid to be populated in the partner record
        //

        //
        // make the sales account and cdh_party look like they were updated from the inbound CDH flow
        CDH_Party__c newCDHRecord = new CDH_Party__c(Name = '111122223333', CDH_Party_Number_Ext__c = '111122223333',CDH_Party_Type__c = 'ORGANIZATION');
        insert newCDHRecord;
        Account salesAccount = new Account(Id = reg.Sales_Account__c, CDH_Party_Name__c = newCDHRecord.Id);
        update salesAccount;
        salesAccount = [select Id, CDHPartyNumber__c from Account where Id = :salesAccount.Id];

        Account partner = [select Id, CDHPartyNumber__c from Account where Id = :reg.ConvertedAccount__c];
        System.assert(partner.CDHPartyNumber__c == salesAccount.CDHPartyNumber__c, 'Partner account party number ' + partner.CDHPartyNumber__c + ' does not match sales account party number ' + salesAccount.CDHPartyNumber__c);

    }

    @isTest static void testPartnerAlreadyExists() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        OnboardingApplyController ctrl = new OnboardingApplyController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'HeWhoShallNotBeNamed_approved');
        pmap.put('rhn-company-name', 'Hogwarts');
        pmap.put('rhn-email', 'thedarklord@diagonalley.com');
        pmap.put('rhn-salutation', 'The');
        pmap.put('rhn-first-name', 'Tom');
        pmap.put('rhn-last-name', 'Riddle');
        PageReference ref = ctrl.init();
        System.assert(ref == null, 'unexpected redirect to another page');

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';

        //
        // step 2
        //
        ctrl.theLead.Company__c = 'Umbrella Corp';
        ctrl.theLead.City__c = 'Raleigh';
        ctrl.theLead.Address1__c = '100 E Davie St';
        ctrl.theLead.Partner_Type__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'].Id;
        ctrl.setLeadCountry('US');
        ctrl.selectedState = 'NC';
        ctrl.theLead.Postal_Code__c = '27610';
        ctrl.theLead.Email__c = 'masmith@redhat.com';
        ctrl.theLead.Phone__c = '919-555-1212';
        ctrl.theLead.Website__c = 'http://www.redhat.com';
        ctrl.setAdditionalCountriesOfOperations(new String[] { 'None' });
        ctrl.theLead.Is_Primary_Public_Sector__c = 'No';
        ctrl.theLead.Do_they_act_in_any_government_position__c = 'No';
        ctrl.theLead.Have_they_been_convicted__c = 'No';

        //
        // step 3
        //
        ctrl.theLead.Company_Description__c = 'Purveyors of specialized DNA';
        ctrl.theLead.Number_of_Employees__c = '>1000';
        ctrl.theLead.Total_Annual_Revenue__c = '> $100 Million';
        ctrl.setTargetMarketSize(new String[] { 'Enterprise' });
        ctrl.setSoftwareFocus(new String[] {'None'});
        ctrl.setOperatingSystemSupported(new String[] { 'RHEL' });
        ctrl.setMiddlewareSupported(new String[] { 'None' });
        ctrl.setApplicationTypes(new String[] { 'None' });
        ctrl.setAdditionalPartnerships(new String[] { 'None' });

        //
        // step 4
        //
        ctrl.agreeTerms = 'Yes';
        ctrl.submitApplication();

        Partner_Onboarding_Registration__c reg = ctrl.getLead();

        // assign any existing partner account to simulate customer data selecting a match
        reg.Account__c = [select Id from Account where isPartner = true and Finder_Partner_Type__c = :ctrl.theLead.Partner_Type__c and RequalStatus__c in ('','Completed') limit 1].Id;
        reg.CDH_Party_Number__c = '111122223334';
        reg.Partner_Onboarding_Status__c = 'Approved';
        reg.Channel_Ops_Approved__c = true;
        reg.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        update reg;

        reg = [select ConvertedAccount__c, Email__c, Sales_Account__c, Partner_Onboarding_Status__c from Partner_Onboarding_Registration__c where Id = :reg.Id];
        System.assert(reg.ConvertedAccount__c == null, 'Converted account ID should be null - duplicate partner possibly created');
        System.assert(reg.Partner_Onboarding_Status__c == 'Converted to Join', 'Expected onboarding status to be "Converted to Join"');
    }

    @isTest static void testZombiePartner() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account zombie = PartnerTestUtils.newMakeBasicAccount('testZombiePartner');
        insert zombie;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(zombie.Id, PartnerConst.RESELLER, PartnerConst.READY);
        pgm.Tier__c = 'Unaffiliated';
        insert pgm;
/*
        Account zombie = [  select Id
                            from Account
                            where Finder_Partner_Type__r.HierarchyKey__c = 'PARTNER_TYPE.RESELLER'
                            and Global_Region__c = 'NA'
                            and RequalStatus__c in ('','Completed')
                            limit 1];
        Partner_Program__c pgm = [select Id from Partner_Program__c where Account__c = :zombie.Id and Is_Primary__c = true limit 1];
        pgm.Tier__c = 'Unaffiliated';
        update pgm;
*/

        Partner_Onboarding_Registration__c reg = new Partner_Onboarding_Registration__c();
        reg.FirstName__c = 'Rick';
        reg.LastName__c = 'Grimes';
        reg.Company__c = 'Terminus';
        reg.RHNLogin__c = 'rick.grimes.terminus';
        reg.City__c = 'Raleigh';
        reg.Address1__c = '100 E Davie St';
        reg.Partner_Type__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'].Id;
        reg.Partner_Tier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.UNAFFILIATED'].Id;
        reg.Country__c = [select Id from Country__c where Abbreviation__c = 'US' limit 1].Id;
        reg.State_Province__c = [select Id from State__c where Abbreviation__c = 'NC' and Country__c = :reg.Country__c limit 1].Id;
        reg.Postal_Code__c = '27610';
        reg.Email__c = 'masmith@redhat.com';
        reg.Phone__c = '919-555-1212';
        reg.Website__c = 'http://www.redhat.com';
        reg.Is_Primary_Public_Sector__c = 'No';
        reg.Do_they_act_in_any_government_position__c = 'No';
        reg.Have_they_been_convicted__c = 'No';
        reg.Global_Region__c = 'NA';
        reg.Company_Description__c = 'Purveyors of specialized DNA';
        reg.Number_of_Employees__c = '>1000';
        reg.Total_Annual_Revenue__c = '> $100 Million';
        reg.RecordTypeId = [
            select Id
              from RecordType
             where DeveloperName = 'Business_Partner_Registration'
               and SObjectType = 'Partner_Onboarding_Registration__c'
             limit 1
        ].Id;
        reg.Manual_Onboard__c = false;
        reg.CDH_Party_Number__c = '111122223335';
        insert reg;

        Test.startTest();

        reg = new Partner_Onboarding_Registration__c(Id = reg.Id);
        reg.Requalification_Date__c = System.today().addDays(365);
        reg.SBC_Initiated__c = True;
        reg.Zombie_Account__c = zombie.Id;
        reg.Partner_Onboarding_Status__c = 'Approved';
        reg.Channel_Ops_Approved__c = true;
        reg.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        update reg;
        Test.stopTest();

        reg = [select ConvertedAccount__c, Email__c, Sales_Account__c, Partner_Onboarding_Status__c from Partner_Onboarding_Registration__c where Id = :reg.Id];
        System.assert(reg.ConvertedAccount__c == zombie.Id, 'Converted account ID should be same as Zombie');
        System.assert(reg.Partner_Onboarding_Status__c != 'Converted to Join', 'Did not expect onboarding status to be "Converted to Join"');

    }

}