@isTest(SeeAllData=true)
private class ProgramStatusSyncTest {

    static private ID resellerId;
    static private ID isvId;
    static private ID premierId;

    static private Partner_Program__c setupProgram(ID accountId) {
        resellerId = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'].Id;
        premierId = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.PREMIER'].Id;

        Partner_Program_Description__c ddesc = null;
        Partner_Program_Definition__c thedef = new Partner_Program_Definition__c();
        thedef.Legacy_Partner_Type__c = resellerId;
        insert thedef;

        ddesc = new Partner_Program_Description__c();
        ddesc.Name = 'Solution Provider';
        ddesc.Language_Code__c = 'en_US';
        ddesc.Definition__c = thedef.Id;
        insert ddesc;

        Partner_Program__c pgm = new Partner_Program__c();
        pgm.Account__c = accountId;
        pgm.Tier__c = 'Premier';
        pgm.Program__c = ddesc.Definition__c;
        pgm.Status__c = 'Active';
        return pgm;
    }

    static private Partner_Program__c setupProgramISV(ID accountId) {
        isvId = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
        premierId = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.PREMIER'].Id;

        Partner_Program_Description__c ddesc = null;
        Partner_Program_Definition__c thedef = new Partner_Program_Definition__c();
        thedef.Legacy_Partner_Type__c = isvId;
        insert thedef;

        ddesc = new Partner_Program_Description__c();
        ddesc.Name = 'Independent Software Vendor';
        ddesc.Language_Code__c = 'en_US';
        ddesc.Definition__c = thedef.Id;
        insert ddesc;

        Partner_Program__c pgm = new Partner_Program__c();
        pgm.Account__c = accountId;
        pgm.Tier__c = 'Premier';
        pgm.Program__c = ddesc.Definition__c;
        pgm.Status__c = 'Active';
        return pgm;
    }

	@isTest static void testNonPrimaryProgram() {
        System.runAs(intadmin) {
            DeactivateAllTestUtil.setDeactivateAll(false);

            Account acct = PartnerTestUtils.quickGenericAccountSetup('Program Status Sync Test');
            Partner_Program__c def = setupProgram(acct.Id);
            insert def;
            PartnerStatus__c[] ps = [select Id from PartnerStatus__c where Partner__c = :acct.Id and PartnerType__c = :resellerId and PartnerTier__c = :premierId];
            System.assert(ps.size() == 0, 'Expected no Partner Status, found ' + ps.size());
        }
	}

    @isTest static void testNewProgram() {
        System.runAs(intadmin) {
            DeactivateAllTestUtil.setDeactivateAll(false);

            Account acct = PartnerTestUtils.quickGenericAccountSetup('Program Status Sync Test');

            Test.startTest();
            Partner_Program__c def = setupProgram(acct.Id);
            def.Is_Primary__c = true;
            insert def;
            PartnerStatus__c[] ps = [select Id from PartnerStatus__c where Partner__c = :acct.Id and PartnerType__c = :resellerId and PartnerTier__c = :premierId];
            System.assert(ps.size() == 1, 'Expected 1 Partner Status, found ' + ps.size());

            ps = [select Id from PartnerStatus__c where ApprovalStatus__c = 'Expired' and Partner__c = :acct.Id];
            System.assert(ps.size() == 1, 'Expected 1 expired Partner Status, found ' + ps.size());

            acct = [select Id, Finder_Partner_Type__c from Account where Id = :acct.Id];
            System.assert(acct.Finder_Partner_Type__c == resellerId, 'Finder Partner Type not set');
            Test.stopTest();
        }
    }

    @isTest static void testNewProgramISV() {
        System.runAs(intadmin) {
            DeactivateAllTestUtil.setDeactivateAll(false);

            Account acct = PartnerTestUtils.quickGenericAccountSetup('Program Status Sync Test ISV');
            PartnerTestUtils.makeAccountISV(acct.Id);

            Test.startTest();
            Partner_Program__c def = setupProgramISV(acct.Id);
            def.Is_Primary__c = true;
            insert def;
            PartnerStatus__c[] ps = [select Id from PartnerStatus__c where Partner__c = :acct.Id and PartnerType__c = :isvId and PartnerTier__c = :premierId];
            System.assert(ps.size() == 1, 'Expected 1 Partner Status, found ' + ps.size());

            ps = [select Id from PartnerStatus__c where ApprovalStatus__c = 'Expired' and Partner__c = :acct.Id];
            System.assert(ps.size() == 2, 'Expected 2 expired Partner Status, found ' + ps.size());

            acct = [select Id, Finder_Partner_Type__c from Account where Id = :acct.Id];
            System.assert(acct.Finder_Partner_Type__c == isvId, 'Finder Partner Type not set');
            Test.stopTest();
        }
    }

	static User intadmin {
		get {
			if(intadmin == null) {
				intadmin = [select Id, ProfileId from User where Alias = 'intadmin' and IsActive = true limit 1];
			}
			return intadmin;
		}
	}
}