/**
 * Test class for WS_PricingService
 *
 * @author Kalidass Gujar
 * @version 2012-07-12
 *
 * Bill Riemers <briemers@redhat.com>
 * 2012-07-12 - Added support for custom setting
 * Kalidass Gujar
 * 2011-09-08 - Created - No Test class available for source apex class which was generated from WSDL.
 */
@isTest
private class WS_PricingServicesTest
{
	@isTest
	static void customSettingTest() {
		System.assertNotEquals(null,StringSetting__c.getInstance('Pricing Service'),'"Pricing Service" StringSetting__c value needs to be set.');
	}

	@isTest
	static void PricingTest() {
		WS_PricingServices wsp = new WS_PricingServices();
		String retval_psurl = WS_PricingServices.pricingServiceUrl;
		String request = '<?xml version="1.0" encoding="UTF-8"?><ProposalbuilderMessage xmlns=""><Header><System>SFDC</System><Operation>Sync</Operation><Type>Quote</Type><InstanceId>006P0000003P0quIAC_2011-09-09T15:11:42</InstanceId><Timestamp>2011-09-09T15:11:42</Timestamp></Header><Payload><Quote><QuoteHeader><QuoteNumber>006P0000003P0quIAC</QuoteNumber><QuoteSource>ProposalBuilder</QuoteSource><SuperRegion>none</SuperRegion><CountryOfOrder>United States</CountryOfOrder><CurrencyIso3Code>USD</CurrencyIso3Code><SalesRepEmail type="WORK" recipient-type="TO"><Name>Kalidass Gujar</Name><EmailAddress>kalidass.gujar@accenture.com.am</EmailAddress></SalesRepEmail><OpportunityType>Standard</OpportunityType><OpportunityNumber>1093337</OpportunityNumber></QuoteHeader><QuoteLineItem><LineNumber>00kP00000041SNEIA2</LineNumber><Product><Sku>HFB007</Sku><ConfigSku>Configured_sku</ConfigSku><ConfigSkuDescription>Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.</ConfigSkuDescription></Product><Quantity uom="EA">2.00</Quantity><StartDate>2009-11-11T00:00:00</StartDate><EndDate>2010-11-10T00:00:00</EndDate><ServiceDuration>1</ServiceDuration><ServicePeriod>YR</ServicePeriod><UnitPrice>2000.00</UnitPrice><ListPrice>2000.00</ListPrice><PricingEffectiveDate></PricingEffectiveDate></QuoteLineItem><Account><AccountTransactionRole>END_CUSTOMER</AccountTransactionRole><PartyName>Red Hat</PartyName><AccountNumber>12345</AccountNumber><Address><Address1>1801 Varsity Drive</Address1><City>Raleigh</City><State>North Carolina</State><PostalCode>27606</PostalCode><Country>United States</Country></Address><Address><Address1>1801 Varsity Drive</Address1><City>Raleigh</City><State>North Carolina</State><PostalCode>27606</PostalCode><Country>United States</Country></Address></Account></Quote></Payload></ProposalbuilderMessage>';
		WS_PricingServices.PricingFacadePort pfp = New WS_PricingServices.PricingFacadePort();

		test.startTest();

		String retval_cP = pfp.calculatePrice(request);
		String retval_qP = pfp.getQuotePrice(request);
		String retval_cPtest = pfp.calculatePriceTest(request);
		String retval_pInfo = pfp.getProductInfo(request);
		WS_PricingServices.getProductInfoResponse prInfo = New WS_PricingServices.getProductInfoResponse();
		WS_PricingServices.getProductInfo pInfo = New WS_PricingServices.getProductInfo();
		WS_PricingServices.getQuotePrice  qInfo = New WS_PricingServices.getQuotePrice();
		WS_PricingServices.calculatePriceResponse cprInfo = New WS_PricingServices.calculatePriceResponse();
		WS_PricingServices.calculatePriceTestResponse cpInfo = New WS_PricingServices.calculatePriceTestResponse();
		WS_PricingServices.getQuotePriceResponse qrInfo = New WS_PricingServices.getQuotePriceResponse();
		WS_PricingServices.PricingWSException prex = New WS_PricingServices.PricingWSException();

		test.stopTest();
	 }
}