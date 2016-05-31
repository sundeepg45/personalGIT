@isTest (seealldata=true)
private class AudienceInputTest {

	static void test_method_one() {
        PageReference pr = Page.AudienceInput;
        test.setCurrentPage(pr);

        Audience__c testAud = new Audience__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(testaud);
        AudienceInput ai = new AudienceInput(sc);
        system.debug('***audience after initiation with uninserted audience: ' + ai.audience);

        // Testing the validation to ensure that incomplete/malformed records can not be saved.

        // Including a partner status item and a profile item should be blocked.
        ai.SelectedRoles.add(ai.roleSelectOptions[0].getValue());
        ai.SelectedRoles.add(ai.roleSelectOptions[1].getValue());
        ai.SelectedProfiles.add(ai.profileSelectOptions[0].getValue());
        ai.SelectedProfiles.add(ai.profileSelectOptions[1].getValue());
        try {
            ai.save();
        }catch(Exception e){
            system.assert(e!=null);
        }

        // Partner status item and Target Account should be blocked

        Account a = new Account(name='test');
        insert a;
        testAud = new Audience__c();
        testAud.Target_Account__c = a.id;
        insert testAud;
        Audience__c aud = [SELECT Id, Name, Target_Account__c FROM Audience__c where id = :testaud.id];
        system.debug('***queried audience before initializing class: ' + aud);
        sc = new ApexPages.StandardController(aud);
        ai = new AudienceInput(sc);
        system.debug('***audience after initializing class, should have target_account: ' + ai.audience);
        ai.selectedProfiles.add(ai.profileSelectOptions[0].getValue());
        try {
            ai.save();
        }catch(Exception e){
            system.assert(e!=null);
        }

        // Partner Program and Target Account should be blocked

        test.setCurrentPage(pr);
        testAud = new Audience__c();
        testAud.Target_Account__c = a.id;
        insert testAud;
        aud = [SELECT Id, Name, Target_Account__c FROM Audience__c where id = :testaud.id];
        sc = new ApexPages.StandardController(aud);
        ai = new AudienceInput(sc);
        system.debug('***audience after initializing class, should have target_account: ' + ai.audience);
        ai.selectedPrograms.add(ai.programSelectOptions[0].getValue());
        try {
            ai.save();
        }catch(Exception e){
            system.assert(e!=null);
        }

        // Partner Status only, but with incomplete fields should be blocked

        testAud = new Audience__c(Partner_Tier__c = 'Ready');
        insert testAud;
        aud = [SELECT Id, Name, Partner_Tier__c FROM Audience__c where id = :testaud.id];
        sc = new ApexPages.StandardController(aud);
        ai = new AudienceInput(sc);

        
       

        try {
            ai.save();
        }catch(Exception e){
            system.assert(e!=null);
        }

        // Correct save
        testAud = new Audience__c();
        insert testAud;
        sc = new ApexPages.StandardController(testAud);
        ai = new AudienceInput(sc);
        ai.selectedTiers.add(ai.tierSelectOptions[0].getValue());
        ai.selectedTypes.add(ai.typeSelectOptions[0].getValue());
        ai.selectedRegions.add(ai.regionSelectOptions[1].getValue());
        ai.resetSubregions();
        ai.selectedSubregions.add(ai.subregionSelectOptions[0].getValue());
        ai.selectedRoles.add(ai.roleSelectOptions[0].getValue());
        try {
            ai.save();
        }catch(Exception e){
            system.assert(e==null);
        }
        ai.audience = new Audience__c();
        try {
            ai.save();
        }catch(Exception e){
            system.assert(e==null);
        }

        // Testing the various region/sub-region parameters
        sc = new ApexPages.StandardController(new Audience__c());
        ai = new AudienceInput(sc);
        ai.selectedRegions.add('All');
        ai.resetSubregions();
        ai.selectedRegions.remove(0);
        ai.selectedREgions.add('EMEA');
        ai.resetSubregions();
        ai.selectedRegions.remove(0);
        ai.selectedRegions.add('APAC');
        ai.resetSubregions();
        ai.selectedRegions.remove(0);
        ai.selectedRegions.add('LATAM');
        ai.resetSubregions();
    }
    
    
    
    
    static TestMethod void targetAudienceTest(){
    	
    	// Set the page context for the test..
    	PageReference pr = Page.AudienceInput;
        test.setCurrentPage(pr);

        // Create test data
        Audience__c testAud = new Audience__c();
        //testAud.Name = 'Test Audience';
        
        Account testAccount1 = new Account(Name = 'Target Account 1', CurrencyIsoCode = 'USD');
        insert(testAccount1);
        
        
        // Initialize the controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testaud);
        AudienceInput con = new AudienceInput(sc);
        
        con.audience.Name = 'Test Audience';
        
        // Execute
        Test.startTest();
	        con.targetAccounts.add(testAccount1);
	        con.save();
        Test.stopTest();
        
        system.assertEquals(false, ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());
        
        // Test - was an aud acct (target account) record created? 
    	List<Audience_Account__c> resultsAfter = [select Audience__c, Account__c from Audience_Account__c where Account__c = :testAccount1.Id];
    	System.assertEquals(1, resultsAfter.size());
    	
    	
    	// Set the page context and pass the id value of the new audience record..
    	//PageReference pr = Page.AudienceInput;
    	//Test.setCurrentPage(pr);
    	pr.getParameters().put('id',resultsAfter[0].Audience__c);
    	
    	// re-initialize the controller now that there is an existing target account
    	sc = new ApexPages.StandardController(testaud);
    	con = new AudienceInput(sc);
    	//system.assertEquals(1, con.targetAccounts.size());
    	
    	con.audience.Partner_Type__c = 'Reseller';
    	con.save();
    	system.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR), 'There should be a validation error because only one filter was specified.');
       
       con.selectedRegions = new List<String>{ 'EMEA'};
       con.resetRegions();
       con.resetSubRegions();
       con.selectedSubRegions = new List<String>{'SEMEA'};
       con.resetCountries();
       con.selectedCountries = new List<String>{'FRANCE'};
       
       
       con.selectedRegions = new List<String>{'NA'};
       con.resetSubregions();
       
       // Search
       pr.getParameters().put('accountName','NA');
       con.doAccountSearch();
       con.selectedAccountId = testAccount1.Id;
       con.selectAccount();
       //system.assertEquals(1, con.targetAccounts.size());
       
    }
    
}