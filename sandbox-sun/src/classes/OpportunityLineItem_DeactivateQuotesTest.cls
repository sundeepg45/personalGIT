/**
*Class Name:OpportunityLineItem_DeactivateQuotesTest
*Description:TestClass for OpportunityLineItem_DeactivateQuotes trigger
*Modificaton History:
*Modified By :Abhijeet Anand
*Modification Date:09/26/2011
*Reason for Modification:Enhanced code coverage and added assert statements.
*/


@isTest
private class OpportunityLineItem_DeactivateQuotesTest
{
    public static Date myDate = date.newinstance(2011,11,20);
    
    public static testmethod void oppQu()
    {
        test.startTest();
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
        
        Product2 product = new Product2();
        product.Name = 'test';
        product.CurrencyIsoCode = 'USD';
        insert product;     
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 2000;
        pbe.IsActive = true;
        pbe.Product2Id = product.Id;
        pbe.Pricebook2Id = priceBook.Id;
        insert pbe;
        
        Opportunity oppfour = new Opportunity(name= 'closeDate',stageName = 'Prepare',closedate=myDate);
        oppfour.QuoteNumber__c = 'testdata';
        oppfour.Pricebook2Id = pricebook.Id;
        insert oppfour;
        
        System.assertEquals('testdata', oppfour.QuoteNumber__c);
        
        List <Quote__c> quotes = new List<Quote__c>();
        for(Integer i=0;i<205;i++)
        {
            Quote__c qt = new Quote__c();
            qt.IsActive__c = true;
            qt.OpportunityId__c = oppfour.Id;
            quotes.add(qt);
        }   
        insert quotes;
        
        OpportunityLineItem lineitem = new OpportunityLineItem();
        lineitem.ScheduleLocked__c = false;
        lineitem.PricebookEntryId = pbe.Id;
        lineitem.OpportunityId = oppfour.Id;
        insert lineitem;
        
        test.stopTest();
        
    } 

}