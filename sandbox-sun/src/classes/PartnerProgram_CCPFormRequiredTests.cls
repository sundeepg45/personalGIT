/**
 * Tests for the PartnerProgram_CCPFormRequired trigger to ensure that a CCP has been sufficiently
 * completed (as indicated by the CCP Form's Is_Complete__c field) before the Partner Program record
 * can move beyond the 1st level of approval.
 */
@isTest(SeeAllData=true)
private class PartnerProgram_CCPFormRequiredTests {

    static testMethod void myUnitTest() {
        Account testPartner = new Account(Name = 'Test Partner');
        insert(testPartner);
        
        Partner_Program_Definition__c ccpProgramDef = [select id from Partner_Program_Definition__c where Program_Category__c = 'Certified Cloud Provider' limit 1];
        
        Partner_Program__c testProgram = new Partner_Program__c(
        	Status__c = 'Pending First Approver', 
        	Program__c = ccpProgramDef.Id, 
        	Account__c = testPartner.Id
        );
        insert(testProgram);
        
        Partner_CCP_Form__c testForm = new Partner_CCP_Form__c(
        	Website__c = 'www.somesite.com', 	// req'd for Is_Complete__c formula to be true
        	Expected_Contract_Close_Date__c = Date.today().addMonths(3), // req'd for Is_Complete__c formula to be true
        	Regions__c = 'NA', 							// req'd for Is_Complete__c formula to be true
        	Type_of_Service__c = 'IaaS',			
        	Description_of_Services__c = 'Test', 
        	Cloud_Type_Details__c = 'Test', 
        	Cloud_Infrastructure_Details__c = 'Test'        
        );
        insert(testForm);
        
        //system.assertEquals(true, testForm.Is_Complete__c);
        
        test.startTest();
        	testProgram.Status__c = 'Pending Second Approver';
        	update(testProgram);
        test.stopTest();
        
        system.assertEquals('Pending Second Approver', testProgram.Status__c);
    }
    
    
    static testMethod void ccpFormIncompleteTest() {
    	
    	/*
    	In this test we are not filling out all the fields on the CCP form that make it complete, when we simulate moving the 
    	partner program approval to the 2nd level, we should get an error telling us the ccp form needs to be completed
    	first.
    	*/
    	
        Account testPartner = new Account(Name = 'Test Partner');
        insert(testPartner);
        
        Partner_Program_Definition__c ccpProgramDef = [select id from Partner_Program_Definition__c where Program_Category__c = 'Certified Cloud Provider' limit 1];
        
        Partner_Program__c testProgram = new Partner_Program__c(
        	Account__c = testPartner.Id,
        	Name = 'Certified Cloud Provider',
        	Program__c = ccpProgramDef.Id, 
        	Status__c = 'Pending First Approver'
        );
        insert(testProgram);
        
        Partner_CCP_Form__c incompleteTestForm = new Partner_CCP_Form__c(
        	//Website__c = 'www.somesite.com', 	// req'd for Is_Complete__c formula to be true
        	Expected_Contract_Close_Date__c = Date.today().addMonths(3),		// req'd for Is_Complete__c formula to be true
        	//Regions__c = 'NA', 							// req'd for Is_Complete__c formula to be true
        	Description_of_Services__c = 'Test', 
        	Cloud_Type_Details__c = 'Test', 
        	Cloud_Infrastructure_Details__c = 'Test'        
        );
        insert(incompleteTestForm);
        
        system.assertEquals(false, incompleteTestForm.Is_Complete__c);
        
        test.startTest();
        	testProgram.Status__c = 'Pending Second Approver';
        	try{
        		update(testProgram);
        	} catch (DmlException d){
       			system.assert(d.getDmlMessage(0).contains('The CCP Form must be completed'));
        	}
        test.stopTest();
        
        system.assertEquals('Pending Second Approver', testProgram.Status__c);
    }
    
    
    
    static testMethod void unsupportedStatusTest() {
    	
    	/*
    	In this test we are setting the program's status to 'Approved', which the trigger should not care about, to make
    	sure everything works and the update dml is not blocked by the trigger.
    	*/
    	
        Account testPartner = new Account(Name = 'Test Partner');
        insert(testPartner);
        
        Partner_Program_Definition__c ccpProgramDef = [select id from Partner_Program_Definition__c where Program_Category__c = 'Certified Cloud Provider' limit 1];
        
        Partner_Program__c testProgram = new Partner_Program__c(
        	Account__c = testPartner.Id,
        	Name = 'Certified Cloud Provider',
        	Program__c = ccpProgramDef.Id, 
        	Status__c = 'Pending First Approver'
        );
        insert(testProgram);
        
        Partner_CCP_Form__c incompleteTestForm = new Partner_CCP_Form__c(
        	//Website__c = 'www.somesite.com', 	// req'd for Is_Complete__c formula to be true
        	Expected_Contract_Close_Date__c = Date.today().addMonths(3),		// req'd for Is_Complete__c formula to be true
        	//Regions__c = 'NA', 							// req'd for Is_Complete__c formula to be true
        	Description_of_Services__c = 'Test', 
        	Cloud_Type_Details__c = 'Test', 
        	Cloud_Infrastructure_Details__c = 'Test'        
        );
        insert(incompleteTestForm);
        
        system.assertEquals(false, incompleteTestForm.Is_Complete__c);
        
        test.startTest();
        	testProgram.Status__c = 'Approved';
        	update(testProgram);
        test.stopTest();
        
        system.assertEquals('Approved', testProgram.Status__c);
    }
    
}