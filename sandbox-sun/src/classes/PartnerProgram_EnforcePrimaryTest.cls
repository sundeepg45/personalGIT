@isTest(SeeAllData=true)
private class PartnerProgram_EnforcePrimaryTest {

	@isTest static void testNewPrimary() {

        //Account acct = [
        //        select  Id,
        //                RequalStatus__c
        //        from    Account
        //        where   IsPartner = true
        //        and     RequalStatus__c != 'Eligible'
        //        and     RequalStatus__c != 'In Progress'
        //        and     RequalStatus__c != 'Submitted'
        //        limit 1
        //];

/*
        Account acct = [
                select  Id
                from    Account
                where   IsPartner = true
                and     RequalStatus__c = 'Eligible'
                limit 1
        ];
*/

        Account acct = PartnerTestUtils.quickGenericAccountSetup('PartnerProgram_EnforcePrimaryTest');
        Partner_Program_Definition__c pdef = [select Id from Partner_Program_Definition__c where Program_Category__c like 'Solution Provider%' limit 1];

        Test.startTest();

        Partner_Program__c pgm = new Partner_Program__c();
        pgm.Is_Primary__c = true;
        pgm.Account__c = acct.Id;
        pgm.Program__c = pdef.Id;
        pgm.Tier__c = 'Ready';
        insert pgm;

        Partner_Program__c npgm = new Partner_Program__c();
        pdef = [select Id from Partner_Program_Definition__c where Program_Category__c like 'Independent Software Vendor%' limit 1];
        npgm.Account__c = acct.Id;
        npgm.Is_Primary__c = true;
        npgm.Program__c = pdef.Id;
        npgm.Tier__c = 'Ready';
        insert npgm;

        pgm = [select Id, Is_Primary__c from Partner_Program__c where Id = :pgm.Id];
        System.assert(pgm.Is_Primary__c == false, 'Expected old primary program to be false');
        Test.stopTest();

	}


}