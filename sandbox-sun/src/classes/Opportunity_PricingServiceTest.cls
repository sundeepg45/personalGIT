/**
 * Test class for Opportunity_PricingService.cls
 *
 * @author Bryan Bosely <bbosely@redhat.com>
 * @version 2012-06-26
 * 2010-03-31 - Created
 * Nitesh Dokania <Accenture>
 * 2011-09-14 - Enhance test coverage of the corresponding class and added assert statements.
 * Scott Coleman <scoleman@redhat.com>
 * 2012-06-26 - Updated for R12, stopped swallowing exceptions, and provided test response for getProductInfo()
 */

@isTest 
public class Opportunity_PricingServiceTest {
    static Account ACCOUNT;
    static Account PARTNER_ACCOUNT;
    static Opportunity OPPORTUNITY, OPPORTUNITY2;
    static OpportunityLineItem LINE_ITEM;

    static final String LINE_ITEM_ID;

    static final Opportunity_PricingService ops = new Opportunity_PricingService();

    //
    // create the object hierarchy
    //

    static {
        // create an account
        ACCOUNT = new Account();
        ACCOUNT.BillingCity = 'Raleigh';
        ACCOUNT.BillingCountry = 'US';
        ACCOUNT.BillingPostalCode = '27606';
        ACCOUNT.BillingState = 'North Carolina';
        ACCOUNT.BillingStreet = '1801 Varsity Drive';
        ACCOUNT.Name = 'Red Hat';
        ACCOUNT.OracleAccountNumber__c = '12345';
        ACCOUNT.ShippingCity = 'Raleigh';
        ACCOUNT.ShippingCountry = 'US';
        ACCOUNT.ShippingPostalCode = '27606';
        ACCOUNT.ShippingState = 'North Carolina';
        ACCOUNT.ShippingStreet = '1801 Varsity Drive';
        ACCOUNT.VATNumber__c = '67890';
        insert ACCOUNT;

        // create a partner account
        PARTNER_ACCOUNT = new Account();
        PARTNER_ACCOUNT.BillingCity = 'Raleigh';
        PARTNER_ACCOUNT.BillingCountry = 'US';
        PARTNER_ACCOUNT.BillingPostalCode = '27606';
        PARTNER_ACCOUNT.BillingState = 'North Carolina';
        PARTNER_ACCOUNT.BillingStreet = '1801 Varsity Drive';
        PARTNER_ACCOUNT.Name = 'Red Hat Partner';
        PARTNER_ACCOUNT.OracleAccountNumber__c = '12345';
        PARTNER_ACCOUNT.ShippingCity = 'Raleigh';
        PARTNER_ACCOUNT.ShippingCountry = 'US';
        PARTNER_ACCOUNT.ShippingPostalCode = '27606';
        PARTNER_ACCOUNT.ShippingState = 'North Carolina';
        PARTNER_ACCOUNT.ShippingStreet = '1801 Varsity Drive';
        PARTNER_ACCOUNT.VATNumber__c = '67890';
        insert PARTNER_ACCOUNT;

        // get the id of the standard price book
        /*Pricebook2 pb = new Pricebook2();
        pb.Name = 'Custom Pricebok';        
        pb.isStandard= true;
        insert pb;
        Pricebook2 priceBook= [SELECT Id FROM PriceBook2 where IsStandard = true];
        String priceBookId = priceBook.Id;*/
        String priceBookId = Test.isRunningTest() ?Test.getStandardPricebookId() :[SELECT Id From Pricebook2 WHERE IsStandard = true].Id;

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
        priceBookEntry.UseStandardPrice = false; 
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

        //OPPORTUNITY2 = new Opportunity();
        //OPPORTUNITY2.AccountId = account.Id;
        //OPPORTUNITY2.CloseDate = Date.newInstance(2009, 11, 10);
        //OPPORTUNITY2.Country_Of_Order__c = 'US';
        //OPPORTUNITY2.CurrencyIsoCode = 'USD';
        //OPPORTUNITY2.Name = 'Opportunity 2';
        //OPPORTUNITY2.OpportunityType__c = 'Standard';
        //OPPORTUNITY2.PaymentType__c = 'NA Purchase Order';
        //OPPORTUNITY2.StageName = 'Test Stage';
        //insert OPPORTUNITY2;

        // create an opportunity line item
        LINE_ITEM = new OpportunityLineItem();
        LINE_ITEM.OpportunityId = OPPORTUNITY.Id;
        LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
        LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
        LINE_ITEM.ActualTerm__c = 2000;
        LINE_ITEM.Configured_SKU__c = '1234567';
        LINE_ITEM.PricebookEntryId = priceBookEntryId;
        LINE_ITEM.Quantity = 2;
        LINE_ITEM.UnitPrice = 2000.00;
        LINE_ITEM.ScheduleLocked__c = true;
        LINE_ITEM.Pricing_Attributes__c = 'TestArea=tstArea,NiteshTest=nitTest,Rhtest=test';
        insert LINE_ITEM;
        LINE_ITEM_ID = LINE_ITEM.Id;

        // create a partner
        Classification__c tierClass = new Classification__c(Name = 'Partner Tier');
        insert tierClass;
        Classification__c tier = new Classification__c(Name = 'Test', Parent__c = tierClass.Id);
        insert tier;
        Classification__c typeClass = new Classification__c(Name = 'Partner Type');
        insert typeClass;
        Classification__c type = new Classification__c(Name = 'Test', Parent__c = typeClass.Id);
        insert type;

        OpportunityPartner__c partner = new OpportunityPartner__c();
        partner.Partner__c = PARTNER_ACCOUNT.Id;
        partner.Opportunity__c = OPPORTUNITY.Id;
        partner.RelationshipType__c = 'Financial';
        partner.PartnerTier__c = tier.Id;
        partner.PartnerType__c = type.Id;
        insert partner;
    }

    //
    // XML response for parsing
    //

    public static String RESPONSE_XML = '<?xml version="1.0" encoding="UTF-8"?>' +
        '<ProposalbuilderMessage xmlns="http://esb.redhat.com/Pricing/1">' +
        '   <Header>' +
        '      <System>SFDC</System>' +
        '      <Operation>Sync</Operation>' +
        '      <Type>Quote</Type>' +
        '      <InstanceId>006S0000003TXD9IAO_2010-05-11T12:07:31</InstanceId>' +
        '      <Timestamp>2010-05-11T12:07:31.000-04:00</Timestamp>' +
        '   </Header>' +
        '   <Payload>' +
        '      <Quote>' +
        '          <QuoteHeader>' +
        '              <QuoteNumber>006S0000003TXD9IAO</QuoteNumber>' +
        '              <QuoteSource>ProposalBuilder</QuoteSource>' +
        '              <SuperRegion>none</SuperRegion>' +
        '              <CountryOfOrder>US</CountryOfOrder>' +
        '              <CurrencyIso3Code>USD</CurrencyIso3Code>' +
        '              <SalesRepEmail type="WORK" recipient-type="TO">' +
        '                  <Name>Bryan Bosely</Name>' +
        '                  <EmailAddress>bbosely@redhat.com</EmailAddress>' +
        '              </SalesRepEmail>' +
        '              <OpportunityType>Standard</OpportunityType>' +
        '              <OpportunityNumber>699481</OpportunityNumber>' +
        '          </QuoteHeader>' +
        '          <QuoteLineItem>' +
        '              <LineNumber>' + LINE_ITEM_ID + '</LineNumber>' +
        '              <Product>' +
        '                  <Sku>MCT0917F3RN</Sku>' +
        '                  <SkuDescription>Red Hat Enterprise Linux, Standard L3 (for up to 2 sockets)</SkuDescription>' +
        '              </Product>' +
        '              <Quantity uom="EA">1</Quantity>' +
        '               <StartDate>2014-09-26T00:00:00</StartDate>' +
        '               <EndDate>2015-09-25T00:00:00</EndDate>' +
        '               <ServiceDuration>1</ServiceDuration>' +
        '                <ServicePeriod>YR</ServicePeriod>' +
        '                <UnitPrice>0.00</UnitPrice>' +
        '                <ListPrice>0.00</ListPrice>' +
        '                <UnitListPrice>0.00</UnitListPrice>' +
        '                <PricingEffectiveDate />' +
        '              <Price>' +
        '                  <Description>The unit price of the item purchased</Description>' +
        '                  <Code>UNIT_PRICE</Code>' +
        '                  <Value>2277</Value>' +
        '              </Price>' + 
        '              <Price>' +
        '                  <Description>The list price of the item purchased</Description>' +
        '                  <Code>UNIT_LIST_PRICE</Code>' +
        '                  <Value>2277</Value>' +
        '              </Price>' +
        '              <Status>' +
        '                  <Code>SUCCESS</Code>' +
        '                  <Message>End of PLSQL Proc: XXRH_QP_APPS_CALC_PRICE_PKG , return status, time  S:05/11/2010 12:07:30</Message>' +
        '              </Status>' +
        '          </QuoteLineItem>' +
        '          <Account>' +
        '              <AccountTransactionRole>END_CUSTOMER</AccountTransactionRole>' +
        '              <AccountNumber>56789</AccountNumber>' +
        '              <Address>' +
        '                  <Address1>5006 West Pico Blvd.</Address1>' +
        '                  <City>Los Angeles</City>' +
        '                  <State>CA</State>' +
        '                  <PostalCode>90019</PostalCode>' +
        '                  <Country>US</Country>' +
        '              </Address>' +
        '              <Address>' +
        '                  <Address1>5006 West Pico Blvd. &amp; &lt; &gt; "</Address1>' +
        '                  <City>篠田-奏子</City>' +
        '                  <State>CA</State>' +
        '                  <PostalCode>90019</PostalCode>' +
        '                  <Country>United States</Country>' +
        '              </Address>' +
        '          </Account>' +
        '          <Account>' +
        '              <AccountTransactionRole>Value Added Reseller</AccountTransactionRole>' +
        '              <AccountNumber>12345</AccountNumber>' +
        '              <Address>' +
        '                  <Address1>3909 Hillsborough Street</Address1>' +
        '                  <City>Raleigh</City>' +
        '                  <State>NC</State>' +
        '                  <PostalCode>27613</PostalCode>' +
        '                  <Country>US</Country>' +
        '              </Address>' +
        '              <Address>' +
        '                  <Address1>3909 Hillsborough Street</Address1>' +
        '                  <City>Raleigh</City>' +
        '                  <State>NC</State>' +
        '                  <PostalCode></PostalCode>' +
        '                  <Country>US</Country>' +
        '              </Address>' +
        '          </Account>' +
        '          <Status>' +
        '              <Code>SUCCESS</Code>' +
        '          </Status>' +
        '      </Quote>' +
        '   </Payload>' +
        '</ProposalbuilderMessage>';

    //
    // XML response for testing getProductInfo
    //

    public static String PRODUCT_RESPONSE_XML = '<?xml version="1.0" encoding="UTF-8"?>' +
        '<ProposalbuilderMessage xmlns="http://esb.redhat.com/Pricing/1">' +
        '   <Header>' +
        '      <System>SFDC</System>' +
        '      <Operation>Test</Operation>' +
        '      <Type>Test</Type>' +
        '      <InstanceId>006S0000003TXD9IAO_2010-05-11T12:07:31</InstanceId>' +
        '      <Timestamp>2010-05-11T12:07:31.000-04:00</Timestamp>' +
        '   </Header>' +
        '   <Payload>' +
        '     <Product>' +
        '          <Status>' +
        '              <Code>SUCCESS</Code>' +
        '          </Status>' +
        '          <ProductConstraint>' +
        '                  <Code>TEST</Code>' +
        '                  <Value>Test</Value>' +
        '          </ProductConstraint>' +
        '          <Sku>1234567</Sku>' +
        '          <ConfigSkuDescription>Test</ConfigSkuDescription>' +
        '     </Product>' +
        '   </Payload>' +
        '</ProposalbuilderMessage>';

    public static testMethod void testOpportunityQuery() {

        //
        // ensure that an opportunity is returned 
        //
        test.startTest();

        Map<String,String> pricingEmptyMap = new Map<String,String>();
        Map<String,String> pricingMap = new Map<String,String>();
        String unitPrice = String.valueOf(LINE_ITEM.UnitPrice);
        Opportunity opp = ops.getOpportunityDetails(OPPORTUNITY.Id);

        System.assert(opp != null);

        ops.updateLineItemPricing(pricingEmptyMap);
        pricingEmptyMap.put(LINE_ITEM.Id,unitPrice);
        ops.updateLineItemPricing(pricingEmptyMap);

        test.stopTest();
    }

    public static testMethod void testXmlRequestGeneration() {

        test.startTest();
        Opportunity opp = ops.getOpportunityDetails(OPPORTUNITY.Id);        
        String xmlRequest = ops.generateRequestXML(opp);

        test.stopTest();

        System.assert(xmlRequest != null);

        if (xmlRequest != null) {
            DOM.Document doc = new DOM.Document();
            doc.load(xmlRequest);
            DOM.XMLNode proposalBuilderMsg = doc.getRootElement();
            DOM.XMLNode payload = proposalBuilderMsg.getChildElement('Payload', null);
            DOM.XMLNode quote = payload.getChildElement('Quote', null);
            String partnerAccountName;
            for (Dom.XMLNode node : quote.getChildElements()) {
                if (node.getName() == 'Account') {
                    String accountTransactionRole = node.getChildElement('AccountTransactionRole', null).getText();
                    if (accountTransactionRole == 'Financial') {
                        partnerAccountName = node.getChildElement('PartyName', null).getText();
                        System.assertEquals('Red Hat Partner',partnerAccountName);
                    }
                }
            }          
        }
    }

    public static testMethod void testXmlResponseParsing(){

        test.startTest();

        Map<String, Opportunity_PricingService.Result> pricingMap = ops.parseResponseXML(RESPONSE_XML);

        test.stopTest();
        //
        // ensure unit price is returned 
        //
        System.assertEquals(pricingMap.get(LINE_ITEM_ID).unitPrice, 2277);
    }
    
    public static testMethod void testGetProductInfo() {

        test.startTest();

        Opportunity_PricingService opps = new Opportunity_PricingService();
        Opportunity_PricingService.ProductResult pr = ops.getProductInfo(LINE_ITEM.Configured_SKU__c);

        test.stopTest();
    }

    public static testMethod void testNoOpportunityIdException() {

        test.startTest();

        try {
            ops.getOpportunityPricing(null);
        }
        catch (Exception e) {
            System.assert(e.getMessage().contains('argument opportunityId is null'));
        }

        test.stopTest();
    }

    public static testMethod void testNoLineItemsException() {

        test.startTest();

        try {
            delete(LINE_ITEM);
            ops.getOpportunityPricing(OPPORTUNITY.Id);
        }
        catch (Exception e) {
            System.assert(e.getMessage().contains('There are no line items to price for this opportunity'));
        }
        
        test.stopTest();
    }
}