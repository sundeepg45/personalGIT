/**
* Class Name:BookingScheduleControllerExtensionTest
* Author:Accenture
* Date:4/11/2011
* Description:Test Class created for BookingScheduleControllerExtension business Class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Last Modified By : Abhijeet Anand
* Last Modified date :9/20/2011
* Reason for Modification: Enhancement of code coverage
*/

@isTest
private class BookingScheduleControllerExtensionTest
{
    public static testmethod void testBookingScheduleControllerExtension() 
    {
        Account account = new Account(Name='Test Account');
        insert account;
        
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
        String priceBookId = priceBook.Id;
        
        Product2 product = new Product2();
        product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
        product.IsActive = true;
        product.Name = 'Happy Fun Ball';
        product.ProductCode = 'HFB007';
        insert product;
        
        Opportunity OPP = new Opportunity();
        OPP.AccountId = account.Id;
        OPP.CloseDate = Date.newInstance(2009, 11, 10);
        OPP.Country_Of_Order__c = 'US';
        OPP.CurrencyIsoCode = 'USD';
        OPP.Name = 'Opportunity';
        OPP.OpportunityType__c = 'Standard';
        OPP.PaymentType__c = 'NA Purchase Order';
        OPP.StageName = 'Test Stage';
        OPP.Year1Amount__c = 500;
        OPP.Year2Amount__c = 1000;
        OPP.Year3Amount__c = 1500;
        OPP.Year4Amount__c = 2000;
        OPP.Year5Amount__c = 2500;
        OPP.Year6Amount__c = 3000;
        insert OPP; 
        
        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.CurrencyIsoCode = 'USD';
        priceBookEntry.isActive = true;
        priceBookEntry.Pricebook2Id = priceBookId;
        priceBookEntry.Product2Id = product.Id;
        priceBookEntry.UnitPrice = 2000.00;
        insert priceBookEntry;
        String priceBookEntryId = priceBookEntry.Id;
        
        OpportunityLineItem LINE_ITEM = new OpportunityLineItem();
        LINE_ITEM.OpportunityId = OPP.Id;
        LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
        LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
        LINE_ITEM.ActualTerm__c = 365;
        LINE_ITEM.Quantity = 2;
        LINE_ITEM.UnitPrice = 2000.00;
        LINE_ITEM.PricebookEntryId = priceBookEntryId;
        LINE_ITEM.ScheduleLocked__c = true;
        LINE_ITEM.Configured_SKU__c = null;
        insert LINE_ITEM;  
        
        OpportunityLineItem LINE_ITEMS = new OpportunityLineItem();
        LINE_ITEMS.OpportunityId = OPP.Id;
        LINE_ITEMS.ActualStartDate__c = Date.newInstance(2009, 11, 11);
        LINE_ITEMS.ActualEndDate__c = Date.newInstance(2010, 11, 10);
        LINE_ITEMS.ActualTerm__c = 365;
        LINE_ITEMS.Quantity = 2;
        LINE_ITEMS.UnitPrice = 2000.00;
        LINE_ITEMS.PricebookEntryId = priceBookEntryId;
        LINE_ITEMS.ScheduleLocked__c = true;
        LINE_ITEMS.Configured_SKU__c = 'test';
        insert LINE_ITEMS;  
                 
       	test.startTest();
       	
       	ApexPages.StandardController standardController = new ApexPages.StandardController(OPP);
        BookingScheduleControllerExtension controller = new BookingScheduleControllerExtension(standardController);
        
        controller.getOpportunityProductList();

        System.assertEquals('USD 500', controller.getYear1Amount());
        System.assertEquals('USD 1,000', controller.getYear2Amount());
        System.assertEquals('USD 1,500', controller.getYear3Amount());
        System.assertEquals('USD 2,000', controller.getYear4Amount());
        System.assertEquals('USD 2,500', controller.getYear5Amount());
        System.assertEquals('USD 3,000', controller.getYear6Amount());
        System.assertEquals('USD 0', controller.formatCurrency(null));
        
        test.stopTest();
        		           			
    }
}