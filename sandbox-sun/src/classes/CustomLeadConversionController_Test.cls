@IsTest(SeeAllData=true) // this is required to access Custom settings.
private class CustomLeadConversionController_Test{
    static Lead testLead {
        get {
            if(testLead == null) {
                testLead = LeadTriggerAfterTest.createLead(UserInfo.getUserId());
            }
            return testLead;
        }
    }

    @isTest
    static void coverageTest() {
        User currentUser = Lead_GlobalManagement.getCurrentUser();
        currentUser.Is_Marketing_User__c = true;
        insert testLead;
        PageReference pageRef = Page.CustomLeadConversionPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testLead.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(testLead);
        CustomLeadConversionController extension = new CustomLeadConversionController(stdController);
    }

    @isTest
    static void marketingLeadDevRedirectTest() {
        User currentUser = Lead_GlobalManagement.getCurrentUser();
        currentUser.Is_Marketing_User__c = true;
        insert testLead;
        PageReference pageRef = Page.CustomLeadConversionPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testLead.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(testLead);
        CustomLeadConversionController extension = new CustomLeadConversionController(stdController);
        extension.leadobjvar.Stage__c = Lead_GlobalManagement.MARKETING_ACCEPTED;
        Test.startTest();
        PageReference ref = extension.marketingLeadDevRedirect();
        Test.stopTest();
        System.assertNotEquals(null,ref);
    }

    @isTest
    static void testAccountSearch()
    {
        //create an account
        Account acct=new Account();
        acct.Name='Test';
        //acct.BillingCountry='India';
        insert acct;

        //create a lead
        Lead lead = new Lead();
        lead.lastname = 'Test name';
        lead.company = 'test Lead';
        insert lead;
        //code coverage for extensions

        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        ApexPages.currentPage().getParameters().put('countryName','US');
        Apexpages.currentpage().getParameters().put('selectedCDHAccount','0');
        Apexpages.currentpage().getParameters().put('recordTypeId','012300000000QglAAE');
        Apexpages.currentpage().getParameters().put('id',lead.id);  //Added by Niti

        CustomLeadConversionController acctSearch=new CustomLeadConversionController(sc);

        acctSearch.selectedSearchOption='1';
        acctSearch.searchTypeSelection();
        acctSearch.selectedSearchOption='2';
        acctSearch.searchTypeSelection();
        acctSearch.selectedSearchOption='3';
        acctSearch.searchTypeSelection();


        acctSearch.AccName='Test';
        acctSearch.PartyNo='12345';
        acctSearch.Street='1st road';
        acctSearch.city='New York';
        acctSearch.postalcode='890098';
        acctSearch.StrDUNSNumber='898977';
        acctSearch.Country='US';
        acctSearch.state='New York';
        acctSearch.AliasFlag= true;

        System.debug('AccName'+acctSearch.AccName);
        System.debug('PartyNo'+acctSearch.PartyNo);
        System.debug('Street'+acctSearch.Street);
        System.debug('city'+acctSearch.city);
        System.debug('postalcode'+acctSearch.postalcode);
        System.debug('StrDUNSNumber'+acctSearch.StrDUNSNumber);
        System.debug('Country'+acctSearch.Country);
        System.debug('state'+acctSearch.state);

        // PageReference pageref = acctSearch.SearchCustomerMaster();

        acctSearch.getAllStates();
        //acctSearch.searchCDHParty();
        // acctSearch.redirectAccountUrl();             
    }
}