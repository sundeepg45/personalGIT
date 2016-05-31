/**
 * Class Name:Opportunity_ProductSearchControllerTest
 * Author : Bryan Bosely <bbosely@redhat.com>
 * Date:06/03/10
 * Description:Opportunity_ProductSearchController Class
 * Modificaton History: 
 * Modified By : Abhijeet Anand
 * Modified date :9/20/2011
 * Reason for Modification: Enhanced code coverage and assert statements added.
 */
 
@isTest
private class Opportunity_ProductSearchControllerTest
{   
    static String PRICEBOOK_ID;
    static String OPPORTUNITY_ID;
    static String OPPORTUNITY2_ID;
    static String OPPORTUNITY1_ID;
    static Opportunity_ProductSearchController CONTROLLER;
    static Opportunity_ProductSearchController CONTROLLERNEW;
    static Opportunity_ProductSearchController CONTROLLERTest;
    static PageReference PAGE_REF;
    
    static
    {
        
        //
        // get the id of the standard price book
        //
        
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
        PRICEBOOK_ID = priceBook.Id;
        
        //
        // create an account
        //
        
        Account account = new Account();
        account.BillingCity = 'Raleigh';
        account.BillingCountry = 'US';
        account.BillingPostalCode = '27606';
        account.BillingState = 'North Carolina';
        account.BillingStreet = '1801 Varsity Drive';
        account.Name = 'Red Hat';
        account.OracleAccountNumber__c = '12345';
        account.ShippingCity = 'Raleigh';
        account.ShippingCountry = 'US';
        account.ShippingPostalCode = '27606';
        account.ShippingState = 'North Carolina';
        account.ShippingStreet = '1801 Varsity Drive';
        account.VATNumber__c = '67890';
        insert account;
        
        
        //
        // create an opportunity with no price book
        //
        
        Opportunity opportunity = new Opportunity();
        opportunity.AccountId = account.Id;
        opportunity.CloseDate = Date.newInstance(2009, 11, 10);
        opportunity.Country_Of_Order__c = '0';
        opportunity.CurrencyIsoCode = 'USD';
        opportunity.Name = 'Opportunity';
        opportunity.OpportunityType__c = 'Standard';
        opportunity.PaymentType__c = 'NA Purchase Order';
        //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
        opportunity.StageName = 'Prepare';
        insert opportunity;
        OPPORTUNITY_ID = opportunity.Id;
        
        Opportunity oppty = new Opportunity();
        oppty.AccountId = account.Id;
        oppty.CloseDate = Date.newInstance(2009, 11, 10);
        oppty.Country_Of_Order__c = 'US';
        oppty.CurrencyIsoCode = 'USD';
        oppty.Name = 'Opportunity';
        oppty.OpportunityType__c = 'Standard';
        oppty.PaymentType__c = 'NA Purchase Order';
        //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
        oppty.StageName = 'Prepare';
        insert oppty;
        OPPORTUNITY1_ID = oppty.Id;
        
        
        //
        // create an opportunity with a price book
        //
        
        Opportunity opportunity2 = new Opportunity();
        opportunity2.AccountId = account.Id;
        opportunity2.CloseDate = Date.newInstance(2009, 11, 10);
        opportunity2.Country_Of_Order__c = 'US';
        opportunity2.CurrencyIsoCode = 'USD';
        opportunity2.Name = 'Opportunity';
        opportunity2.OpportunityType__c = 'Standard';
        opportunity2.PaymentType__c = 'NA Purchase Order';
        opportunity2.Pricebook2Id = PRICEBOOK_ID;
        //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
        opportunity2.StageName = 'Prepare';
        insert opportunity2;
        OPPORTUNITY2_ID = opportunity2.Id;
        
        Product2 product = new Product2();
        product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
        product.IsActive = true;
        product.Name = 'Happy Fun Ball';
        product.ProductCode = 'RHEL';
        product.Configurable__c = false;
        product.Excluded_Countries__c = 'US';
        insert product;
        
        PricebookEntry priceBookEntry_sp = new PricebookEntry();
        priceBookEntry_sp.CurrencyIsoCode = 'USD';
        priceBookEntry_sp.isActive = true;
        priceBookEntry_sp.Pricebook2Id = priceBook.Id;
        priceBookEntry_sp.Product2Id = product.Id;
        priceBookEntry_sp.UnitPrice = 2000.00;
        insert priceBookEntry_sp;
        
        //
        // set Opportunity_ProductPricing as the current page for the controller
        //
        
        PAGE_REF = Page.Opportunity_ProductSearch;
        Test.setCurrentPageReference(PAGE_REF);
        
        //
        // add the opportunity id, and search term as query string parameters
        //
        
        ApexPages.currentPage().getParameters().put('opportunityId', OPPORTUNITY1_ID);
        ApexPages.currentPage().getParameters().put('search', 'RHEL');
        
        CONTROLLERTest = new Opportunity_ProductSearchController();
        
        ApexPages.currentPage().getParameters().put('opportunityId', OPPORTUNITY_ID);
        ApexPages.currentPage().getParameters().put('search', 'RHEL');
        
        CONTROLLER = new Opportunity_ProductSearchController();
        
        ApexPages.currentPage().getParameters().put('opportunityId', OPPORTUNITY2_ID);
        ApexPages.currentPage().getParameters().put('search', 'RHEL');
        
        CONTROLLERNEW = new Opportunity_ProductSearchController();
        
        
    }
   
    
    public static testMethod void testQueryStringParams()
    {
        test.startTest();
        //
        // ensure that the member variables are being set from the query string
        //
        
        System.assertEquals(CONTROLLER.opportunityId, OPPORTUNITY_ID);
        System.assertEquals(CONTROLLER.searchTerm, 'RHEL');
        
        test.stopTest();
    }
    
    
    public static testMethod void testPriceBookName()
    {
        test.startTest();
        //
        // ensure the global price book is returned
        //
        
        System.assertEquals(CONTROLLERTest.getPricebookName(), 'Global Price Book');
        
        test.stopTest();
    }
    
    
    public static testMethod void testProductSearch()
    {
        test.startTest();
        //
        // ensure pricebook entries are returned
        //
        
        CONTROLLERNEW.search();
        
        test.stopTest();
            
    }
    
    
    public static testMethod void testNullSearchTerm()
    {
        
        //
        // clear the parameters populated by the queryString
        //
        
        CONTROLLER.searchTerm = '';
        
        //
        // ensure we still get search results when no search term is present
        //
        test.startTest();
        
        CONTROLLER.search();
        System.assert(CONTROLLER.priceBookEntries.size() > 0);
        
        test.stopTest();
    }
    
    
    public static testMethod void testNullPriceBookName()
    {
        test.startTest();
        //
        // ensure an empty value is returned when there are no search results
        //
        
        CONTROLLER.priceBookEntries.clear();
        System.assertEquals(CONTROLLER.getPricebookName(), '');
        
        test.stopTest();
    }
}