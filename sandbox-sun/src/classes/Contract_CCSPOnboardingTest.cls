@isTest(SeeAllData=true)
private class Contract_CCSPOnboardingTest {

	@isTest static void testOnboard() {

        Partner_Onboarding_Registration__c reg = [select Id, RHNLogin__c, ConvertedAccount__c, ConvertedAccount__r.OwnerId from Partner_Onboarding_Registration__c where ConvertedAccount__c != null and Country__r.Name = 'united states' limit 1];

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Test`');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];
        //System.assert(pgm.Program__r.Legacy_Partner_Type__c != null, 'Legacy Partner Type for ' + PartnerConst.SCP + ' is null');
        Partner_Program__c pgm2 = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.CCNSP, PartnerConst.UNAFFILIATED);
        pgm2.Is_Primary__c = false;
        insert pgm2;

        reg.ConvertedAccount__c = acct.Id;
        reg.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c;
        reg.Agree_to_Partner_TC__c = false;
        reg.HasCustomTerms__c = false;
        update reg;

        Test.startTest();


        Contract con = new Contract();
        con.AccountId = sales.Id;
        con.OwnerId = reg.ConvertedAccount__r.OwnerId;
        con.CreatedById = reg.ConvertedAccount__r.OwnerId;
        con.Description = 'Service/Cloud Provider (Certified Cloud & Service Provider) custom terms requested';
        con.CountryOfOrder__c = reg.Country__r.Name;
        con.Contract_Type__c = 'Cloud Deal';
        con.Stage__c = 'New';
        con.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = 'Customer_or_Partner_Contract'
            and     IsActive = true
        ].Id;
        insert con;

        //
        // attach dummy document
        //
        Attachment attach = new Attachment();
        attach.ParentId = con.Id;
        attach.Body = EncodingUtil.base64Decode('a fake document body');
        attach.ContentType = 'text/text';
        attach.Description = 'test attachment';
        attach.Name = 'fakery.pdf';
        insert attach;


        //
        // fire the trigger
        //
        con.Status = 'Completed';
        update con;

        pgm = [select Id, Tier__c from Partner_Program__c where Id = :pgm.Id];
        System.assert(pgm.Tier__c == 'Advanced', 'Expected Advanced tier, got ' + pgm.Tier__c);

        acct = [select Id, Finder_Partner_Tier__c from Account where Id = :acct.Id];
        Classification__C tier = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.ADVANCED'];
        System.assert(acct.Finder_Partner_Tier__c == tier.Id, 'Expected Advanced partner tier');

        PartnerAgreement__c pa = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];

        PartnerStatus__c ps = [
            select  Id, IsVisible__c
            from    PartnerStatus__c
            where   Partner__c = :acct.Id
            and     ApprovalStatus__c = 'Approved'
        ];
        System.assert(ps.IsVisible__c == true, 'Expected partner status to be visible');
	}

    @isTest static void testApply() {

        Account acct = PartnerTestUtils.newMakeBasicAccount('CCSP_Terms_Test2');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;
        acct = [select Id, OwnerId, Country__c from Account where Id = :acct.Id];
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.RESELLER, PartnerConst.READY);
        pgm.Is_Primary__c = true;
        insert pgm;
        pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.SCP, PartnerConst.UNAFFILIATED);
        pgm.Status__c = 'Pending Terms';
        pgm.Is_Primary__c = false;
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];

        Test.startTest();

        Contract con = new Contract();
        con.AccountId = sales.Id;
        con.OwnerId = acct.OwnerId;
        con.CreatedById = acct.OwnerId;
        con.Description = 'Service/Cloud Provider (Certified Cloud & Service Provider) custom terms requested';
        con.CountryOfOrder__c = acct.Country__c;
        con.Contract_Type__c = 'Cloud Deal';
        con.Stage__c = 'New';
        con.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = 'Customer_or_Partner_Contract'
            and     IsActive = true
        ].Id;
        insert con;

        //
        // attach dummy document
        //
        Attachment attach = new Attachment();
        attach.ParentId = con.Id;
        attach.Body = EncodingUtil.base64Decode('a fake document body');
        attach.ContentType = 'text/text';
        attach.Description = 'test attachment';
        attach.Name = 'fakery.pdf';
        insert attach;


        //
        // fire the trigger
        //
        con.Status = 'Completed';
        update con;

        pgm = [select Id, Tier__c from Partner_Program__c where Account__c = :acct.Id and Is_Primary__c = false];
        System.assert(pgm.Tier__c == 'Advanced', 'Expected Advanced tier, got ' + pgm.Tier__c);

        //
        // make sure new program doesn't change account primary
        //
        acct = [select Id, Finder_Partner_Tier__c from Account where Id = :acct.Id];
        Classification__C tier = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'];
        System.assert(acct.Finder_Partner_Tier__c == tier.Id, 'Expected Ready partner tier');

        PartnerAgreement__c pa = [select Id from PartnerAgreement__c where Partner__c = :acct.Id];

    }


}