@isTest(SeeAllData=true)
private class PartnerRegistration_AllocateMDFTests {
	static private Boolean isApprovalsDisabled = PartnerTestUtils.isApprovalTestingDisabled();

    static testMethod void registrationApprovedShouldCreateNewFundRequestTest() {

		if (isApprovalsDisabled) {
			return;
		}

        Account testCustomer = new Account(Name = 'Test Customer',
                                            CurrencyIsoCode = 'USD'
                                            //,RecordTypeId = [select Id
                                            //                from RecordType
                                            //                where SObjectType = 'Account'
                                            //                and Name = 'NA Partner'].Id
                                                            );
        insert(testCustomer);

        Account testPartner = new Account(
            Name = 'Test Partner',
            CurrencyIsoCode = 'USD',
            Global_Region__c = 'NA',
            Subregion__c = 'Southeast',
            RecordTypeId = '012600000004yfa');
        insert(testPartner);

        Contact testPartnerContact = PartnerTestUtils.makeContact(testPartner.Id, 'par.testing@redhat.com'); // new Contact(FirstName = 'Bob', LastName = 'Young', Email='testing@redhat.com', Phone='919-333-4444', AccountId = testPartner.Id);
        insert(testPartnerContact);

        User testPartnerUser = PartnerTestUtils.makeUser(testPartner, testPartnerContact);
        insert(testPartnerUser);

        User adminUser = [select Id, Name from User where IsActive = true and Profile.Name LIKE '%Administrator%' LIMIT 1];

        // Set the primary partner contact (req'd)
        testPartner.PrimaryPartnerContact__c = testPartnerContact.Id;
        update(testPartner);

        Account partnerCheck = [select PrimaryPartnerContact__c from Account where id = :testPartner.Id];
        system.assertEquals(testPartnerContact.id, partnerCheck.PrimaryPartnerContact__c);

        Opportunity testOpp = new Opportunity(Name = 'Test PAR Opportunity', Amount = 25000, AccountId = testCustomer.Id, StageName = 'Closed Won', CloseDate = Date.today());
        insert(testOpp);

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Opportunity_Actual_Amount__c = 10000.00,
            Partner__c = testPartner.Id,
            Product_Family__c = 'Platform', //'RHEL;JBOSS',
            Project_Budget__c = 150000.00,
            Status__c = 'Pending'
        );

        system.runAs(adminUser){ // testPartnerUser){
            insert(testReg);
        }

        // Create the MDF associated with this Registration
        String PAR_MDF_RECORD_TYPE_ID = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and Name = 'PAR'].Id;
        SFDC_Budget__c mdf = new SFDC_Budget__c(
           Account_master__c =  testPartner.Id,
           Active__c = true,
           RecordTypeId = PAR_MDF_RECORD_TYPE_ID,
           Allocated_Budget__c = 0.00,
           Is_PAR__c = true
        );
        insert(mdf);

        // Simulate final approval of the registration so we can see if the MDF was updated with a new Allocated Funds amount
        testReg.Status__c = 'Approved';
        testReg.Opportunity_Actual_Amount__c = 10000.00;


        // 2. Execute
        test.startTest();

         system.runAs(adminUser){
            update(testReg); // Fire the trigger
        }

        test.stopTest();


        // 3. Test - was an MDF budget and line item created?
        List<SFDC_Budget__c> mdfBudgetResults = [select Account_master__c, Active__c, RecordTypeId, Partner_Manager__c, Start_Date__c, End_Date__c FROM SFDC_Budget__c WHERE Account_master__c = :testPartner.Id];
        system.assertEquals(1, mdfBudgetResults.size());
        SFDC_Budget__c mdfResult = mdfBudgetResults[0];
        system.assertEquals(true, mdfResult.Active__c);
        system.assert(mdfResult.Start_Date__c != null);
        system.assert(mdfResult.End_Date__c != null);

        List<SFDC_MDF__c> mdfRequestResults = [select Id, Approval_Status__c, Amount__c, Partner_Registration__c, Total_Expenditure_of_Activity__c from SFDC_MDF__c where Partner_Registration__c = :testReg.Id];
        system.assertEquals(1, mdfRequestResults.size());
        SFDC_MDF__c requestResult = mdfRequestResults[0];
        system.assertEquals(testReg.Id, requestResult.Partner_Registration__c);
        system.assertEquals('Approved', requestResult.Approval_Status__c);
        //system.assertEquals(600.00, requestResult.Total_Expenditure_of_Activity__c);

    }



/*

    static testMethod void registrationApprovedShouldUpdateExistingMDFBudgetTest() {

        Account testCustomer = new Account(Name = 'Test Customer', CurrencyIsoCode = 'USD');
        insert(testCustomer);
        Account testPartner = new Account(Name = 'Test Partner', CurrencyIsoCode = 'USD', Global_Region__c = 'NA');
        insert(testPartner);
        Opportunity testOpp = new Opportunity(Name = 'Test PAR Opportunity', Amount = 25000, AccountId = testCustomer.Id, StageName = 'Closed Won', CloseDate = Date.today());
        insert(testOpp);

        // Important for this test: create an MDF record so we can make sure the trigger doesn't create a new one each time
        String PAR_MDF_RECORD_TYPE_ID = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and Name = 'PAR'].Id;

        SFDC_Budget__c mdf = new SFDC_Budget__c(
           Account_master__c =  testPartner.Id,
           Active__c = true,
           RecordTypeId = PAR_MDF_RECORD_TYPE_ID,
           Allocated_Budget__c = 40000.00,
           Is_PAR__c = true
        );
        insert(mdf);


        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'RHEL', //'RHEL;JBOSS',
            Project_Budget__c = 150000.00,
            Status__c = 'Pending Proof of Performance Approval'
        );
        insert(testReg);

        testReg.Status__c = 'Approved';
        testReg.Opportunity_Actual_Amount__c = 10000.00;

        // 2. Execute
        test.startTest();
            update(testReg); // Fire the trigger
        test.stopTest();


        // 3. Test - was an MDF budget and line item created?
        List<SFDC_Budget__c> mdfBudgetResults = [select Account_master__c, Active__c, RecordTypeId, Partner_Manager__c, Start_Date__c, End_Date__c FROM SFDC_Budget__c WHERE Account_master__c = :testPartner.Id];
        system.assertEquals(1, mdfBudgetResults.size());
        SFDC_Budget__c mdfResult = mdfBudgetResults[0];
        system.assertEquals(true, mdfResult.Active__c);
        system.assertEquals(Date.today(), mdfResult.Start_Date__c);
        system.assertEquals(Date.today().addDays(360), mdfResult.End_Date__c);
        system.assertEquals(50000.00, mdfResult.Available_Budget__c);


        //List<SFDC_Budget_Item__c> lineItemResults = [SELECT Amount__c, Budget__c, Expiration_Date__c, Registration__c, Status__c FROM SFDC_Budget_Item__c where Budget__c = :mdfBudgetResults[0].Id];
        //system.assertEquals(1, lineItemResults.size());
        //system.assertEquals(600.00, lineItemResults[0].Amount__c);

        List<SFDC_MDF__c> mdfRequestResults = [select Id, Amount__c, Partner_Registration__c from SFDC_MDF__c where Partner_Registration__c = :testReg.Id];
        system.assertEquals(1, mdfRequestResults.size());
        SFDC_MDF__c requestResult = mdfRequestResults[0];
        system.assertEquals(testReg.Id, requestResult.Partner_Registration__c);
        system.assertEquals( (testReg.Opportunity_Actual_Amount__c * 0.06), requestResult.Amount__c);
    }


 */


/*
    static testMethod void mdfIsOnlyAddedOncePerOpp(){
        Account testCustomer = new Account(Name = 'Test Customer', CurrencyIsoCode = 'USD');
        insert(testCustomer);
        Account testPartner = new Account(Name = 'Test Partner', CurrencyIsoCode = 'USD');
        insert(testPartner);
        Opportunity testOpp = new Opportunity(Name = 'Test PAR Opportunity', Amount = 25000, AccountId = testCustomer.Id, StageName = 'Closed Won', CloseDate = Date.today());
        insert(testOpp);

        String PAR_MDF_RECORD_TYPE_ID = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and Name = 'PAR'].Id;

        SFDC_Budget__c mdf = new SFDC_Budget__c(
           Account_master__c =  testCustomer.Id,
           Active__c = true,
           RecordTypeId = PAR_MDF_RECORD_TYPE_ID,
           Allocated_Budget__c = 40000.00,
           Is_PAR__c = true
        );
        insert(mdf);

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'RHEL', //'RHEL;JBOSS',
            Project_Budget__c = 150000.00,
            Status__c = 'Pending Proof of Performance Approval'
        );
        insert(testReg);



        testReg.Status__c = 'Approved';
        testReg.Opportunity_Actual_Amount__c = 10000.00;
        update(testReg);

        // 2. Execute
        test.startTest();
            testReg.Proof_of_Performance_Docs_Uploaded__c = Date.today();
            update(testReg); // Fire the trigger
            update(testReg); // fire it again
        test.stopTest();

        // 3. Test - was an MDF budget and line item created?
        List<SFDC_Budget__c> mdfBudgetResults = [select Account_master__c, Active__c, RecordTypeId, Partner_Manager__c FROM SFDC_Budget__c WHERE Account_master__c = :testPartner.Id];
        system.assertEquals(1, mdfBudgetResults.size());
        List<SFDC_Budget_Item__c> lineItemResults = [SELECT Amount__c, Budget__c, Expiration_Date__c, Registration__c, Status__c FROM SFDC_Budget_Item__c where Budget__c = :mdfBudgetResults[0].Id];
        system.assertEquals(1, lineItemResults.size());
        system.assertEquals(600.00, lineItemResults[0].Amount__c);
    }

*/

}