@isTest(SeeAllData= true)
private class Contract_AttachmentRequiredTest
{
	@isTest
	static void attachmentAttachedTest()
    {
        /*
            Test the positive scenario: attachment presend on the contract when its approved
        */
        //create a Partner account and sis. sales-acc on which the contract needs to be created.
        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Test`');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;

        //create embedded program on partner account
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];
        //System.assert(pgm.Program__r.Legacy_Partner_Type__c != null, 'Legacy Partner Type for ' + PartnerConst.SCP + ' is null');
        Partner_Program__c pgm2 = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm2.Is_Primary__c = false;
        insert pgm2;

        User owner = PartnerTestUtils.getAdminUser();

        Test.startTest();
        Contract con = PartnerTestUtils.makeContract('conName', sales.Id, owner.Id);
        insert con;

        //
        // attach dummy document
        //

        Attachment attach = PartnerTestUtils.makeAttachment(con.Id);

        //
        // fire the trigger
        //
        con.Status = 'Completed';
        update con;
        Test.stopTest();

	}

    @isTest
    static void attachmentRequiredTest()
    {
        /*
            Test Error Scenarios: Trigger should stop Changing the contract status to 'Completed' without attaching an attachment.
        */

        //create a Partner account and sis. sales-acc on which the contract needs to be created.
        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Test`');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;

        //create embedded program on partner account
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];
        //System.assert(pgm.Program__r.Legacy_Partner_Type__c != null, 'Legacy Partner Type for ' + PartnerConst.SCP + ' is null');
        Partner_Program__c pgm2 = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm2.Is_Primary__c = false;
        insert pgm2;

        User owner = PartnerTestUtils.getAdminUser();

        Contract con = PartnerTestUtils.makeContract('conName', sales.Id, owner.Id);
        insert con;

        //
        // fire the trigger
        //

        Test.startTest();
        con.Status = 'Completed';

        try {
            update con;
        } catch(DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Contract can not be Approved'));
        }
        Test.stopTest();

    }

    @isTest
    static void triggerSholdNotFireOnNonEmbeddedContractsTest()
    {
        /*
            Test Trigger doesn't care non-Embedded contracts
        */

        //create a Partner account and sis. sales-acc on which the contract needs to be created.
        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Test`');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;

        //create embedded program on partner account
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];
        //System.assert(pgm.Program__r.Legacy_Partner_Type__c != null, 'Legacy Partner Type for ' + PartnerConst.SCP + ' is null');
        Partner_Program__c pgm2 = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm2.Is_Primary__c = false;
        insert pgm2;

        User owner = PartnerTestUtils.getAdminUser();

        Contract con = PartnerTestUtils.makeContract('conName', sales.Id, owner.Id);
        con.Contract_Type__c = 'Cloud Deal';
        insert con;

        //
        // fire the trigger
        //

        Test.startTest();
        con.Status = 'Completed';
        update con;
        Test.stopTest();

        system.assertEquals(con.Status, 'Completed');
    }



    @isTest
    static void rejectionReasonsRequiredTest()
    {
        /*
            Test Error Scenarios: Trigger should stop the rejection when rejection reason is not selected
        */

        //create a Partner account and sis. sales-acc on which the contract needs to be created.
        Account acct = PartnerTestUtils.newMakeBasicAccount('Embedded_Terms_Test');
        Account sales = PartnerTestUtils.addSalesAccount(acct);
        insert acct;

        //create embedded program on partner account
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.ISV, PartnerConst.UNAFFILIATED);
        insert pgm;
        pgm = [select Id, Program__r.Legacy_Partner_Type__c from Partner_Program__c where Id = :pgm.Id];
        //System.assert(pgm.Program__r.Legacy_Partner_Type__c != null, 'Legacy Partner Type for ' + PartnerConst.SCP + ' is null');
        Partner_Program__c pgm2 = PartnerTestUtils.makeProgram(acct.Id, PartnerConst.EMBED, PartnerConst.UNAFFILIATED);
        pgm2.Is_Primary__c = false;
        insert pgm2;

        User owner = PartnerTestUtils.getAdminUser();

        Contract con = new Contract();
        con.AccountId = sales.Id;
        con.OwnerId = owner.Id;
        con.Description = 'Embedded custom terms requested';
        con.Contract_Type__c = 'Embedded Deal';
        con.Stage__c = 'New';
        con.Status = 'Draft';
        con.Requesting_User__c = PartnerTestUtils.getAdminUser().Id;
        con.Global__c = true;
        con.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
            and     IsActive = true
        ].Id;
        insert con;

        //
        // fire the trigger
        //

        Test.startTest();
        con.Status = 'Rejected';

        try {
            update con;
        } catch(DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please set the Contract Rejection Reason field before rejecting the contract.'));
        }
        Test.stopTest();

    }

}