/**
 * Class Name:Opportunity_UpdateLineItems
 * Modificaton History: 9/19/2011 - Created new test class for getting proper coverage of associated business logic class.
 * Created By : Nitesh Dokania
 * Created date : 9/19/2011
 * Reason for Craetion: Created new test class for getting proper coverage of associated business logic class.
 */

@isTest
private class Opportunity_UpdateLineItemsTest{
    public static Account account;
    public static Opportunity  OPPORTUNITY;
    public static OpportunityLineItem  LINE_ITEM;
    public static List<OpportunityLineItem>  LINE_ITEM_List;
    
    public static testmethod void oppUpdateLineItemsTest() 
    {
    	account = new Account(Name='Test Account');
    	insert account;
    	
    	// get the id of the standard price book
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
        String priceBookId = priceBook.Id;
        
        // create a product
        Product2 product = new Product2();
        product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
        product.IsActive = true;
        product.Name = 'Happy Fun Ball';
        product.ProductCode = 'HFB007';
        insert product;
        
        // create a pricebook entry for the standard pricebook
        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.CurrencyIsoCode = 'USD';
        priceBookEntry.isActive = true;
        priceBookEntry.Pricebook2Id = priceBookId;
        priceBookEntry.Product2Id = product.Id;
        priceBookEntry.UnitPrice = 2000.00;
        insert priceBookEntry;
        String priceBookEntryId = priceBookEntry.Id;
        
        // create an opportunity
        OPPORTUNITY = new Opportunity();
        OPPORTUNITY.AccountId = account.Id;
        OPPORTUNITY.CloseDate = Date.newInstance(2009, 11, 10);
        OPPORTUNITY.Country_Of_Order__c = 'US';
        OPPORTUNITY.CurrencyIsoCode = 'USD';
        OPPORTUNITY.Name = 'Opportunity';
        OPPORTUNITY.OpportunityType__c = 'Standard';
        OPPORTUNITY.PaymentType__c = 'NA Purchase Order';
        OPPORTUNITY.StageName = 'Test Stage';
        insert OPPORTUNITY;
        
        // create an opportunity line item
        LINE_ITEM = new OpportunityLineItem();
        LINE_ITEM.OpportunityId = OPPORTUNITY.Id;
        LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
        LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
        LINE_ITEM.ActualTerm__c = 365;
        LINE_ITEM.PricebookEntryId = priceBookEntryId;
        LINE_ITEM.Quantity = 2;
        LINE_ITEM.UnitPrice = 2000.00;
        LINE_ITEM.ScheduleLocked__c = true;
        insert LINE_ITEM;
        //LINE_ITEM_ID = LINE_ITEM.Id;
        
        test.startTest();
        
        OPPORTUNITY.CloseDate = System.today();
        OPPORTUNITY.Close_Date_Moved_Reason__c = 'Control';
        update OPPORTUNITY;
        
        LINE_ITEM_List = new List<OpportunityLineItem>();
        for(Integer i=0;i<100;i++)
        {
			LINE_ITEM = new OpportunityLineItem();
	        LINE_ITEM.OpportunityId = OPPORTUNITY.Id;
	        LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
	        LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
	        LINE_ITEM.ActualTerm__c = 365;
	        LINE_ITEM.PricebookEntryId = priceBookEntryId;
	        LINE_ITEM.Quantity = 2;
	        LINE_ITEM.UnitPrice = 2000.00;
	        LINE_ITEM.ScheduleLocked__c = true;
	        LINE_ITEM_List.add(LINE_ITEM); 
        }
        insert LINE_ITEM_List;
        
        Opportunity opp = new Opportunity();
        opp = [Select CurrencyIsoCode from Opportunity where PaymentType__c = 'NA Purchase Order'limit 1];
        System.assertEquals('USD',opp.CurrencyIsoCode);
        
        OPPORTUNITY.CloseDate = System.today()+4;
        update OPPORTUNITY;
        
        test.stopTest();
    }
}