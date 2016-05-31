@isTest(SeeAllData=true)
private class PartnerRegistration_AutoApproveTest {
	static private Boolean isApprovalsDisabled = PartnerTestUtils.isApprovalTestingDisabled();

    static testMethod void testEndCustomerAutoApprove(){
    	
		if (isApprovalsDisabled) {
			return;
		}

        Account testCustomer = new Account(Name = 'Midgard, Inc.', Global_Region__c = 'NA', CurrencyIsoCode = 'USD');
        insert testCustomer;
        //Account testPartner = PartnerTestUtils.quickFinderAccountSetup('Asgard, Inc');
    	Account testPartner = [select Id, Global_Region__c from Account where Global_Region__c = 'NA' limit 1];
  //      Opportunity testOpp = new Opportunity(Name = 'Someone set us up the bomb', Amount = 25000, AccountId = testCustomer.Id, StageName = 'Closed Won', CloseDate = System.today());
  //      insert testOpp;
  		testPartner.Is_Financials_Approved__c = true;
  		update testPartner;
        Contact c = PartnerTestUtils.makeContact(testPartner.Id, 'minime');
        insert c;
        User u = PartnerTestUtils.makeUser(testPartner, c);
        u.ManagerId = [select Id from User where email like 'masmith@redhat.com%' limit 1].Id;
        insert u;

        Test.startTest();
        
        Partner_Registration__c reg = new Partner_Registration__c(
            End_Customer__c = testCustomer.Id,
            Company_Name__c = 'Midgard, Inc',
            Company_Street_1__c = '100 E Davie St',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            Product_Family__c = 'Platform',
            Estimated_Close_Date__c = System.today().addDays(60),
            /*
            Opportunity__c = testOpp.Id,
            Opportunity_Close_Date__c = Date.today(),
            Opportunity_Close_Stage__c = 'Closed Won',
            Opportunity_Actual_Amount__c = 17000.00,
            */
            Partner__c = testPartner.Id,
            Status__c = 'Open',
            Account_Manager__c = u.Id,
            End_Customer_Manager__c = u.Id
        );
        insert reg;

        //
        // put in Pending Channel Operations Approval and approve
        //
        PartnerTestUtils.setApproval(reg.Id);
        PartnerTestUtils.autoApprove(reg.Id);
        
        //
        // in Pending Partner Account Owner Approval, approve
        //
        PartnerTestUtils.autoApprove(reg.Id);

        ProcessInstanceWorkItem[] wilist = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from    ProcessInstanceWorkitem p
            where   p.ProcessInstance.TargetObjectId = :reg.Id
            and     p.ProcessInstance.Status = 'Pending'
        ];
        System.assert(wilist.size() > 0, 'No approval process found for registration object');
        //
        // should be in Pending End Customer Owner Approval now - fake out the timed workflow auto approval
        //
        reg.Status__c = 'Pending End Customer Owner Approval';
        reg.Auto_Approved__c = true;
        reg.Status__c = 'Pending Opportunity Close';
        update reg;
        
        reg = [select Status__c from Partner_Registration__c where Id = :reg.Id];
        System.assert(reg.Status__c == 'Pending Opportunity Close', 'Expected opportunty to be in Pending Opportunity Close state, found ' + reg.Status__c);
    	Test.stopTest();
    }}