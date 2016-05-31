/**
 * This class will initiate the insert/update logic for copying data from legacy Opportunity Partner object to the new object.
 * As per User Story US60137
 *
 * @version 2015-10-28
 * @author Pankaj Banik   <pbanik@deloitte.com>
 * 2014-10-31 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-10-28 - Depreciated
 */
@isTest
private class opportunityLineItem_Trigger_Test {}
//depreciated @isTest(seealldata=true)
//depreciated public class opportunityLineItem_Trigger_Test{

//depreciated    @isTest
//depreciated    public static void test_method(){
//depreciated        Account account = new Account(
//depreciated        BillingCity = 'Raleigh',
//depreciated        BillingCountry = 'IN',
//depreciated        BillingPostalCode = '27606',
//depreciated        BillingState = 'North Carolina',
//depreciated        BillingStreet = '1801 Varsity Drive',
//depreciated        Name = 'Red Hat',
//depreciated        OracleAccountNumber__c = '12345',
//depreciated        ShippingCity = 'Raleigh',
//depreciated        ShippingCountry = 'US',
//depreciated        ShippingPostalCode = '27606',
//depreciated        ShippingState = 'North Carolina',
//depreciated        ShippingStreet = '1801 Varsity Drive',
//depreciated        VATNumber__c = '67890');
//depreciated        insert account;
//depreciated        
//depreciated        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
//depreciated        Pricebook2 globalPriceBook= [SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book'];
//depreciated        
//depreciated        product2 product = new Product2(
//depreciated                Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.',
//depreciated                IsActive = true,
//depreciated                Name = 'Happy Fun Ball',
//depreciated                ProductCode = 'HFB007');
//depreciated        insert product;
//depreciated        
//depreciated        PricebookEntry priceBookEntry = new PricebookEntry(
//depreciated                CurrencyIsoCode = 'USD',
//depreciated                isActive = true,
//depreciated                Pricebook2Id = priceBook.Id,
//depreciated                Product2Id = product.Id,
//depreciated                UnitPrice = 2000.00);
//depreciated        insert priceBookEntry;
//depreciated        
//depreciated        PricebookEntry priceBookEntry2 = new PricebookEntry(
//depreciated                CurrencyIsoCode = priceBookEntry.CurrencyIsoCode,
//depreciated                IsActive = priceBookEntry.IsActive,
//depreciated                Pricebook2Id = globalPriceBook.Id,
//depreciated                Product2Id = priceBookEntry.Product2Id,
//depreciated                UnitPrice = priceBookEntry.UnitPrice);
//depreciated        insert priceBookEntry2;
//depreciated        
//depreciated        Opportunity opportunity = new Opportunity(
//depreciated                AccountId = account.Id,
//depreciated                CloseDate = Date.newInstance(2009, 11, 10),
//depreciated                Country_Of_Order__c = 'US',
//depreciated                CurrencyIsoCode = 'USD',
//depreciated                Name = 'Opportunity',
//depreciated                OpportunityType__c = 'Standard',
//depreciated                PaymentType__c = 'NA Purchase Order',
//depreciated                //Pricebook2Id = globalPriceBook.Id,
//depreciated                StageName = 'Test Stage',
//depreciated                QuoteNumber__c = '3');
//depreciated        insert opportunity;

//depreciated        BigMachines__Quote__c quote = new BigMachines__Quote__c(
//depreciated            BigMachines__Opportunity__c = opportunity.Id,
//depreciated            BigMachines__Is_Primary__c = false,
//depreciated            BigMachines__Account__c = opportunity.AccountId,
//depreciated            BigMachines__Pricebook_Id__c = globalPriceBook.Id,
//depreciated            BigMachines__Is_Forced_Sync__c = false,
//depreciated            Contract_End_Date__c = Date.newInstance(Date.Today().year()+2, 11, 10),
//depreciated            Contract_Start_Date__c = Date.newInstance(Date.Today().year()+1, 11, 10),
//depreciated            Term_of_Contract__c = '365');

//depreciated        insert quote;

//depreciated        BigMachines__Quote_Product__c quoteProduct = new BigMachines__Quote_Product__c(
//depreciated            BigMachines__Quote__c = quote.Id,
//depreciated            Scheduled_Locked__c = true,
//depreciated            BigMachines__Product__c = product.Id,
//depreciated            BigMachines__Quantity__c = 2,
//depreciated            BigMachines_Contract_Number__c = 'abc123',
//depreciated            BigMachines__Sales_Price__c = priceBookEntry2.UnitPrice);

//depreciated        insert quoteProduct;

//depreciated        quote.BigMachines__Is_Primary__c = true;

//depreciated        update quote;      

//depreciated        OpportunityLineItem lineItem = new OpportunityLineItem(
//depreciated                ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated                ActualEndDate__c = Date.newInstance(2010, 11, 10),
//depreciated                ActualTerm__c = 365,
//depreciated                OpportunityId = opportunity.Id,
//depreciated                PricebookEntryId = priceBookEntry2.Id,
//depreciated                Quantity = 2,
//depreciated                UnitPrice = priceBookEntry2.UnitPrice,
//depreciated                PriceOverrideReason__c = null,
//depreciated                Description=product.Description);

//depreciated        insert lineItem ;
//depreciated        

//depreciated        Test.startTest();
//depreciated        quote = [SELECT BigMachines__Is_Primary__c FROM BigMachines__Quote__c WHERE Id = :quote.Id];
//depreciated        System.assert(quote.BigMachines__Is_Primary__c);

//depreciated        lineItem.Quantity = 4;
//depreciated        update lineItem;

//depreciated        quote = [SELECT BigMachines__Is_Primary__c FROM BigMachines__Quote__c WHERE Id = :quote.Id];
//depreciated        //System.assert(!quote.BigMachines__Is_Primary__c);
//depreciated        Test.stopTest();
//depreciated    }
//depreciated }