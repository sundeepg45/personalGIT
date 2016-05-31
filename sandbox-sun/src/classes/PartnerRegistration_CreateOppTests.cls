@isTest(SeeAllData=true)
private class PartnerRegistration_CreateOppTests {
	static private Boolean isApprovalsDisabled = PartnerTestUtils.isApprovalTestingDisabled();

    static final string TRIGGER_REG_STATUS = 'Pending Opportunity Close'; // This is the registration status that should trigger the creation of a new Opp
    
    static testMethod void approvedRegistrationCreatesOppTest() {
    	
    	if (isApprovalsDisabled) {
    		return;
    	}

    	// 1. Setup
    	User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
    	
        /*Account testPartner = new Account(
            Name = 'Test Partner', 
            Global_Region__c = 'NA');
        insert(testPartner);*/
        
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null and isActive = true LIMIT 1];
        Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];
        
        
        Account testCustomer = new Account(
            Name = 'Test Customer', 
            OwnerId = testUser.Id); // This will determine the new opp's ownership
        insert(testCustomer);
        
        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street', 
            Company_City__c = 'Raleigh', 
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartnerUser.AccountId, // testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Pending'
        );
        
       //system.runAs(testPartnerUser){
            insert(testReg);
      // }
        
        List<Opportunity> oppsBeforeTest = [select Id, Name from Opportunity where AccountId = :testCustomer.Id];
        system.assertEquals(0, oppsBeforeTest.size());
        
        
        // 2. Execute 
        test.startTest();
            testReg.Status__c = TRIGGER_REG_STATUS; //'Approved';
            testReg.Opportunity_Actual_Amount__c = 500.00;
            system.runAs(testUser){ // run as a normal internal user
                update(testReg); // Fire the trigger
            }
        test.stopTest();
        
         
        // 3. Test 
        List<Opportunity> oppsAfterTest = [select Id, Is_PAR__c, Name, OwnerId, ShippingAddress__c, ShippingCity__c, ShippingState__c, ShippingZipPostalCode__c, ShippingCountry__c from Opportunity where AccountId = :testCustomer.Id];
        system.assertEquals(1, oppsAfterTest.size());
        Opportunity oppResult = oppsAfterTest[0];
        system.assertEquals(testUser.Id, oppResult.OwnerId);
        system.assertEquals(oppResult.ShippingAddress__c, testReg.Company_Street_1__c);
        system.assertEquals(oppResult.ShippingCity__c, testReg.Company_City__c);
        system.assertEquals(oppResult.ShippingState__c, testReg.Company_Postal_Code__c);
        system.assertEquals(oppResult.ShippingZipPostalCode__c, testReg.Company_Postal_Code__c);
        system.assertEquals(oppResult.ShippingCountry__c, testReg.Company_Country__c);
        system.assertEquals(true, oppResult.Is_PAR__c);
        
    }
    
    
    
     static testMethod void endCustomerWithoutAccountOwnerStillCreatesOppTest() {
    	if (isApprovalsDisabled) {
    		return;
    	}

        // 1. Setup
        User testUser = [select Id from User where Profile.Name = 'Channel Sales' and IsActive = true LIMIT 1];
        User testPartnerUser = [Select u.Region__c, u.ContactId, u.AccountId From User u where AccountId != null and ContactId != null and isActive = true LIMIT 1];
        Contact testPartnerContact = [select Id, AccountId from Contact where Id = :testPartnerUser.ContactId];
        
        Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);
        
        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street', 
            Company_City__c = 'Raleigh', 
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartnerUser.AccountId, // testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00,
            Status__c = 'Pending'
        );
        insert(testReg);
        
        List<Opportunity> oppsBeforeTest = [select Id, Name from Opportunity where AccountId = :testCustomer.Id];
        system.assertEquals(0, oppsBeforeTest.size());
        
        // 2. Execute 
        test.startTest();
            testReg.Status__c = TRIGGER_REG_STATUS; //'Approved';
            testReg.Opportunity_Actual_Amount__c = 500.00;
            update(testReg); // Fire the trigger
        test.stopTest();
        
        
        // 3. Test 
        List<Opportunity> oppsAfterTest = [select Id, Name, OwnerId from Opportunity where AccountId = :testCustomer.Id];
        system.assertEquals(1, oppsAfterTest.size());
        system.assert( oppsAfterTest[0].OwnerId != null );
    }
    
    
}