@isTest(SeeAllData=true)
public class Partner_RegistrationControllerExtTests {
	static private Boolean isApprovalsDisabled = PartnerTestUtils.isApprovalTestingDisabled();

    private static final string logTag = '[Partner_RegistrationControllerExtTests]';


    static testMethod void newRegistrationTest(){

		if (isApprovalsDisabled) {
			return;
		}
        Account testPartner = new Account(Name = 'Test Partner', CurrencyIsoCode = 'USD');
        insert(testPartner);
        Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);

        User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null and IsActive = true LIMIT 1];
        Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Open'
        );
        //insert(testReg);

        Test.startTest();
        Partner_RegistrationControllerExt con;
        system.runAs(testPartnerUser) {
            ApexPages.StandardController stdCon = new ApexPages.StandardController(testReg);
            con = new Partner_RegistrationControllerExt(stdCon);
        }

        con.getIsEnrolled();
        con.getIsFinancesApproved();
        con.save();
        con.cancel();
        con.isReadyForFinalApproval();
//        con.submitForApproval();
//   	    con.attachPopDocuments();
        Test.stopTest();

    }

    static testMethod void allocateMdfFundsTest(){

        Account testPartner = new Account(Name = 'Test Partner', CurrencyIsoCode = 'USD');
        insert(testPartner);
        Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);


        User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null  LIMIT 1];
        //Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Pending'
        );
        insert(testReg);

        Pricebook2 testPricebook2 = [Select p.Name, p.IsStandard, p.IsActive, p.Id, p.Description, p.CurrencyIsoCode From Pricebook2 p where  IsActive = true and Name = 'Global Price Book' and CurrencyIsoCode = 'USD'];//[Select p.Name, p.IsStandard, p.IsActive, p.Id, p.Description, p.CurrencyIsoCode From Pricebook2 p where  Id = '01s3000000012TtAAI']; //IsActive = true and IsStandard = true and CurrencyIsoCode = 'USD' LIMIT 1];


        Opportunity testOpp = new Opportunity(
           AccountId = testCustomer.Id,
           Amount = 100000.00,
           CloseDate = Date.today().addDays(120),
           Name = 'Test Opp',
           StageName = 'Preparing',
           Pricebook2Id = testPricebook2.Id
        );
        insert(testOpp);

        testReg.Opportunity__c = testOpp.Id;
        update(testReg);

        // Add some line items to the opportunity (important for this test)
        List<OpportunityLineItem> newOppLineItems = new List<OpportunityLineItem>();
        for(PricebookEntry pbe: [Select p.UnitPrice, p.ProductCode, p.Product2Id, p.Pricebook2Id, p.Name, p.Id From PricebookEntry p where p.Pricebook2Id = :testOpp.Pricebook2Id and IsActive = true and CurrencyIsoCode = 'USD' and UseStandardPrice = true LIMIT 5]){

                newOppLineItems.add(new OpportunityLineItem(
                    OpportunityId = testOpp.Id,
                    ActualStartDate__c = Date.today(),
                    ActualEndDate__c = Date.today().addDays(365),
                    ActualTerm__c = 365,
                    PricebookEntryId = pbe.Id,
                    Quantity = 2,
                    UnitPrice = 2000.00,
                    ScheduleLocked__c = true));
        }
        system.assert(newOppLineItems.size() > 0);
        insert(newOppLineItems);

        ApexPages.StandardController stdCon = new ApexPages.StandardController(testReg);
        Partner_RegistrationControllerExt con = new Partner_RegistrationControllerExt(stdCon);
        //system.assertEquals(false, con.isReadyForFinalApproval());
        con.loadRegLineItems();
        system.assert(con.regLineItems.size() > 0);

        // Update the allocation for each regLineItem
        for(Partner_Registration_Line_Item__c li:con.regLineItems){
            li.Influenced_Amount__c = 1000.00;
        }

        con.saveRegLineItems();
        //system.assertEquals(true, con.saveComplete);


        con.loadRegLineItems();
        system.assertEquals(true,con.hasProducts);

    }


    static testMethod void existingRegistrationTest(){

        Account testPartner = new Account(Name = 'Test Partner', Global_Region__c = 'NA', SubRegion__c = 'SouthEast', CurrencyIsoCode = 'USD');
        insert(testPartner);
        Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);

        User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null  LIMIT 1];
        Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Open'
        );
        insert(testReg);

        system.assert(testReg.Id != null);
        system.debug(logTag + 'testReg record saved. Registration ID: [' + testReg.Id + ']');

        Test.startTest();
            Partner_RegistrationControllerExt con;
           //system.runAs(testPartnerUser){

                PageReference pageRef = New PageReference(Page.PAR_Registration_Edit + '/' + testReg.Id);
                Test.setCurrentPage(pageRef);
                // Add parameters to page URL
                //ApexPages.currentPage().getParameters().put('id', testReg.Id);

                ApexPages.StandardController stdCon = new ApexPages.StandardController(testReg);
                con = new Partner_RegistrationControllerExt(stdCon);
            //}

            con.getIsEnrolled();
            con.getIsFinancesApproved();
            con.cancel();
            con.isReadyForFinalApproval();
            if (isApprovalsDisabled) {
            	return;		// can't go any further
            }
            con.submitForApproval();
            /*
            con.attachPopDocuments();
            con.cancelAttachment();

            // Create mdf
            ID parType = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and DeveloperName = 'PAR'].Id;
            SFDC_Budget__c newmdf = new SFDC_Budget__c(
                RecordTypeId = parType,
                Name = 'PAR Budget',
                Account_master__c = testPartner.Id,
                Active__c = true,
                Is_PAR__c = true,
                I_Agree_to_the_Terms_and_Conditions__c = true
            );
            insert(newmdf);


            // isReadyForFinalApproval tests
            testReg.Opportunity_Close_Date__c = Date.today();
            testReg.Opportunity_Close_Stage__c = 'Closed Booked';
            update(testReg);

            testReg.Status__c = 'Approved';
            //testReg.Opportunity_Actual_Amount__c = 10000.00;
            update(testReg);
            stdCon = new ApexPages.StandardController(testReg);
            con = new Partner_RegistrationControllerExt(stdCon);
            system.assertEquals(false, con.isReadyForFinalApproval());


            testReg.Status__c = 'Pending Proof of Performance Approval';
            testReg.Proof_of_Performance_Docs_Uploaded__c = null;
            update(testReg);
            stdCon = new ApexPages.StandardController(testReg);
            con = new Partner_RegistrationControllerExt(stdCon);
            system.assertEquals(false, con.isReadyForFinalApproval());


            testReg.Status__c = 'Pending Proof of Performance Approval';
            testReg.Proof_of_Performance_Docs_Uploaded__c = null;
            update(testReg);
            system.assertEquals(false, con.isReadyForFinalApproval());


            // Upload attachment test
            PageReference attachmentPage =  Page.PAR_Registration_Attachment;
            Test.setCurrentPage(attachmentPage);
            Attachment testAtt = new Attachment();
            testAtt.Name = 'FileName.pdf';
            testAtt.ContentType = 'document/pdf';
            testAtt.Body = blob.valueOf('Hello there!');
            stdCon = new ApexPages.StandardController(testReg);
            con = new Partner_RegistrationControllerExt(stdCon);
            con.proofOfPerf = testAtt;
            con.attachPopDocuments();
            system.assertEquals(true, con.attachmentComplete);

            if (!isApprovalsDisabled) {
	            try {
	                con.submitForApproval();		// this will lock the registration record
	                con.attachPopDocuments();		// this should raise a DML exception because the record is locked
	            } catch (DmlException d) {
	                system.debug(logTag + 'ERROR SUBMITTING FOR APPROVAL: ' + d);
	            }
            }
            */
        Test.stopTest();
    }


}