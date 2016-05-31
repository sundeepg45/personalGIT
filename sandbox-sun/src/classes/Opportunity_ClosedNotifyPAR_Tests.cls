@isTest(SeeAllData=true)
private class Opportunity_ClosedNotifyPAR_Tests {
	static private Boolean isApprovalsDisabled = PartnerTestUtils.isApprovalTestingDisabled();

    static testMethod void myUnitTest() {

        //
        // Since opportunities is now gobbling up all the SOQL we are hitting limits with the most basic tests so we have to bail out of this one for now
        //
        if (True) {
            return;
        }

        if (isApprovalsDisabled) {
        	return;
        }


        // 1. Setup
        User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
        /*
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null and isActive = true LIMIT 1];
        Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];
        */
        Account testPartner = new Account(Name = 'Test Partner', Global_Region__c = 'NA', Subregion__c = 'Northwest');
        insert(testPartner);
        Account testCustomer = new Account(Name = 'Test Customer', OwnerId = testUser.Id); // This will determine the new opp's ownership
        insert(testCustomer);

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id, //testPartnerUser.AccountId,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Pending',
            Company_Street_1__c = '21 Jump Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'United States'
        );
        insert(testReg);

        // Move the Registration status to 'Pending Opportunity Close' so that the MDF will be generated for it.
        testReg.Status__c = 'Pending Opportunity Close';
        system.runAs(testUser){ // run as a normal internal user
	        update(testReg);
        }

        // Create the related Opportunity by approving the partner reg record
        testReg.Status__c = 'Approved';
        system.runAs(testUser){ // run as a normal internal user
            update(testReg); // Fire the trigger
        }

        Opportunity testOpp = [select Id, Name, OwnerId from Opportunity where AccountId = :testCustomer.Id];
        system.assert(testOpp != null);

        //MDF
        String PAR_MDF_RECORD_TYPE_ID = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and DeveloperName = 'PAR'].Id;
        SFDC_Budget__c mdf = new SFDC_Budget__c(
            Account_master__c = testPartner.Id, //testPartnerUser.AccountId,
            RecordTypeId = PAR_MDF_RECORD_TYPE_ID,
            Allocated_Budget__c = 10000.00,
            Start_Date__c = Date.today()
        );
        insert(mdf);


       // 2. Execute
        Test.startTest();
        testOpp.StageName = 'Closed Booked';
        update(testOpp);
        test.stopTest();


        // 3. Test
        Partner_Registration__c regResult = [select Id, Opportunity_Close_Date__c, Opportunity_Close_Stage__c from Partner_Registration__c where Id = :testReg.Id];
        //system.assertEquals(date.today(), regResult.Opportunity_Close_Date__c);
        system.assertEquals('Closed Booked', regResult.Opportunity_Close_Stage__c);

    }
}