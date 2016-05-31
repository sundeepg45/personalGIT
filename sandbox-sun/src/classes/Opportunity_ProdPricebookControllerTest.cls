/**
 * Test class for Opportunity_ProdPricebookControllerTest.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @date    06/18/10    
 * @version 1.0
 */
 
@isTest
private class Opportunity_ProdPricebookControllerTest {
    
    static String OPPORTUNITY_ID;
    static String PRICEBOOK_ID;
    static String GLOBAL_PRICEBOOK_ID;
    static String PRICEBOOKENTRY_ID;
    static Opportunity_ProductPricebookController CONTROLLER;
    static PageReference PAGE_REF;
    
    static {
        
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
        // get the id of the standard price book
        //
        
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
        PRICEBOOK_ID = priceBook.Id;
        
        //
        // get the id of the global price book
        //
        
        Pricebook2 priceBook2 = [SELECT Id FROM PriceBook2 WHERE NAME = 'Global Price Book'];
        GLOBAL_PRICEBOOK_ID = priceBook2.Id;
        
        //
        // create a product
        //
        
        Product2 product = new Product2();
        product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
        product.IsActive = true;
        product.Name = 'Happy Fun Ball';
        product.ProductCode = 'HFB007';
        insert product;
        
        Product2 product2 = new Product2();
        product2.Description = 'Twice the fun of the happy fun ball';
        product2.IsActive = true;
        product2.Name = 'Happy Fun Ball XL';
        product2.ProductCode = 'HFB007XL';
        insert product2;
        
        //
        // create a pricebook entry for the standard pricebook
        //
        
        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.CurrencyIsoCode = 'USD';
        priceBookEntry.isActive = true;
        priceBookEntry.Pricebook2Id = PRICEBOOK_ID;
        priceBookEntry.Product2Id = product.Id;
        priceBookEntry.UnitPrice = 2000.00;
        insert priceBookEntry;
        String priceBookEntryId = priceBookEntry.Id;
        
        PricebookEntry priceBookEntry2 = new PricebookEntry();
        priceBookEntry2.CurrencyIsoCode = 'USD';
        priceBookEntry2.isActive = true;
        priceBookEntry2.Pricebook2Id = PRICEBOOK_ID;
        priceBookEntry2.Product2Id = product2.Id;
        priceBookEntry2.UnitPrice = 2500.00;
        insert priceBookEntry2;
        PRICEBOOKENTRY_ID = priceBookEntry2.Id;
        
        //
        // create an opportunity
        //
        
        Opportunity opportunity = new Opportunity();
        opportunity.AccountId = account.Id;
        opportunity.CloseDate = Date.newInstance(2009, 11, 10);
        opportunity.Country_Of_Order__c = 'US';
        opportunity.CurrencyIsoCode = 'USD';
        opportunity.Name = 'Opportunity';
        opportunity.OpportunityType__c = 'Standard';
        opportunity.PaymentType__c = 'NA Purchase Order';
        opportunity.StageName = 'Test Stage';
        insert opportunity;
        OPPORTUNITY_ID = opportunity.Id;
        
        //
        // create an opportunity line item
        //
        
        OpportunityLineItem lineItem = new OpportunityLineItem();
        lineItem.OpportunityId = OPPORTUNITY_ID;
        lineItem.ActualStartDate__c = Date.newInstance(2009, 11, 11);
        lineItem.ActualEndDate__c = Date.newInstance(2010, 11, 10);
        lineItem.ActualTerm__c = 365;
        lineItem.PricebookEntryId = priceBookEntryId;
        lineItem.Quantity = 2;
        lineItem.UnitPrice = 2000.00;
        lineItem.ScheduleLocked__c = true;
        insert lineItem;
        
        //
        // set Opportunity_ProductPricing as the current page for the controller
        //
        
        PAGE_REF = Page.Opportunity_ProductPricebook;
        Test.setCurrentPageReference(PAGE_REF);
        
        //
        // add the pricebook id, and opportunity id as query string parameters
        //
        
        ApexPages.currentPage().getParameters().put('pricebookId', PRICEBOOK_ID);
        ApexPages.currentPage().getParameters().put('opportunityId', OPPORTUNITY_ID);
                
        CONTROLLER = new Opportunity_ProductPricebookController();  
    }
    
    
    private static testMethod void testQueryStringParams() {
        
        //
        // ensure that the member variables are being set from the query string
        //
        
        System.assertEquals(CONTROLLER.pricebookId, PRICEBOOK_ID);
        System.assertEquals(CONTROLLER.opportunityId, OPPORTUNITY_ID);
    }
    
    
    private static testMethod void testQueryOpportunity() {
        Opportunity opp = CONTROLLER.getOpportunity();
        System.assert(opp != null);
        
        Opportunity opp2 = CONTROLLER.opportunity;
        System.assert(opp2 != null);
    }
    
    
    private static testMethod void testGetPricebookOptions() {
        List<SelectOption> options = CONTROLLER.getPricebookOptions();
        System.assert(options.size() > 0);  
    }
    
    private static testMethod void testSave() {
        
        //
        // change pricebookId to trigger deletion of line items 
        //
        
        Controller.PricebookId = GLOBAL_PRICEBOOK_ID;
        
        PageReference pageRef = CONTROLLER.save();
        System.assertEquals('/apex/Opportunity_ProductPricing?id=' + OPPORTUNITY_ID, pageRef.getUrl());
        
        Opportunity opp = CONTROLLER.getOpportunity();
        System.assertEquals(opp.HasOpportunityLineItem, false); 
        
    }
    
    private static testMethod void testCancel() {
        PageReference pageRef = CONTROLLER.cancel();
        System.assertEquals('/apex/Opportunity_ProductPricing?id=' + OPPORTUNITY_ID, pageRef.getUrl());
    }
}