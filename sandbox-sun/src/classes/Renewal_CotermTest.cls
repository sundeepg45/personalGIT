/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *
 * @author	Bill C Riemers <briemers@redhat.com>
 * @version	  2012-09-04
 * 2012-09-04 - Depreciated Total_Price__c usage.
 * 2012-03-07 - refactored from Renewal_CotermDetailControllerTest.
 */
@isTest (SeeAllData=true)
public class Renewal_CotermTest extends Renewal_Coterm {
	private Renewal_CotermTest(Id sourceOpportunityId) {
		super(sourceOpportunityId);
	}

	public static Id standardPricebookId { get {
		if(standardPriceBookId == null) {
			// get the id of the standard price book
			//standardPriceBookId = [SELECT Id FROM PriceBook2 WHERE isStandard = true].Id;
			standardPriceBookId = Test.getStandardPricebookId();
		}
		return standardPriceBookId;
	}}

	public static Id renewalRecordTypeId { get {
		if(renewalRecordTypeId == null) {
			// get the id of the renewal record type
			renewalRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Renewal' AND SObjectType = 'Opportunity' AND IsActive = true].Id;
		}
		return renewalRecordTypeId;
	}}

	public static Account account { get {
		if(account == null) {
			// create an account
			account = new Account(
				BillingCity = 'Raleigh',
				BillingCountry = 'US',
				BillingPostalCode = '27606',
				BillingState = 'North Carolina',
				BillingStreet = '1801 Varsity Drive',
				Name = 'Red Hat',
				OracleAccountNumber__c = '12345',
				ShippingCity = 'Raleigh',
				ShippingCountry = 'US',
				ShippingPostalCode = '27606',
				ShippingState = 'North Carolina',
				ShippingStreet = '1801 Varsity Drive',
				VATNumber__c = '67890');
			insert account;
		}
		return account;
	}}

	public static Product2 product { get {
		if(product == null) {
			// create a product
			product = new Product2(
				Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.',
				IsActive = true,
				Name = 'Happy Fun Ball',
				ProductCode = 'HFB007');
			insert product;
		}
		return product;
	}}

	public static PricebookEntry createPriceBookEntry(Id priceBookId) {
		// create a pricebook entry for the standard pricebook
		return new PricebookEntry(
			CurrencyIsoCode = 'USD',
			isActive = true,
			Pricebook2Id = priceBookId,
			Product2Id = product.Id,
			UnitPrice = 2000.00);
	}

	public static PricebookEntry priceBookEntry_sp { get {
		if(priceBookEntry_sp == null) {
			// create a pricebook entry for the standard pricebook
			priceBookEntry_sp = createPriceBookEntry(standardPriceBookId);
			insert priceBookEntry_sp;
		}
		return priceBookEntry_sp;
	}}

	public static PricebookEntry priceBookEntry { get {
		if(priceBookEntry == null  && priceBookEntry_sp != null) {
			// create a pricebook entry for the global pricebook
			priceBookEntry = createPriceBookEntry(Renewal_Coterm.globalPriceBookId);
			insert priceBookEntry;
		}
		return priceBookEntry;
	}}

	public static Opportunity createOpportunity(String name,String refName,String reason) {
		return new Opportunity(
			AccountId = account.Id,
			CloseDate = Date.newInstance(2010, 11, 10),
			Country_Of_Order__c = 'US',
			CurrencyIsoCode = 'USD',
			Name = name,
			Opportunity_Reference_Name__c = refName,
			OpportunityType__c = 'Standard',
			PaymentType__c = 'NA Purchase Order',
			Pricebook2Id = Renewal_Coterm.globalPriceBookId,
			RecordTypeId = renewalRecordTypeId,
			ReasonWonLostSalesProcess__c = reason,
			StageName = 'Prepare'); //changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
	}

	static Opportunity opportunity { get {
		if(opportunity == null) {
			// create the source renewal opportunity
			opportunity = createOpportunity('Renewal Source Opportunity',null,null);
			insert opportunity;
		}
		return opportunity;
	}}

	static Id opportunityId { get {
		if(opportunityId == null) {
			insert lineItem;
			insert expiringProduct;
			opportunityId = opportunity.Id;
		}
		return opportunityId;
	}}

	public static OpportunityLineItem createLineItem(Id oppId) {
		// create an opportunity line item for the source opportunity
		return new OpportunityLineItem(
			OpportunityId = oppId,
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2010, 11, 10),
			ActualTerm__c = 365,
			PricebookEntryId = priceBookEntry.Id,
			Quantity = 2,
			UnitPrice = 2000.00,
			ScheduleLocked__c = true);
	}

	static OpportunityLineItem lineItem { get {
		if(lineItem == null) {
			// create an opportunity line item for the source opportunity
			lineItem = createLineItem(opportunity.Id);
		}
		return lineItem;
	}}

	public static Expiring_Product__c createExpiringProduct(Id oppId,String productCode) {
		// create an expiring product for the source opportunity
		return new Expiring_Product__c(
			Already_Renewed__c = false,
			Configured_Renewal_SKU__c = 'RH012345',
			CurrencyIsoCode = 'USD',
			Expiring_Product_Start_Date__c = Date.today(),
			Expiring_Product_End_Date__c = Date.today(),
			Mapped_SKU__c = 'RH01',
			Name = 'Product 2',
			Opportunity__c = oppId,
			Product_Code__c = productCode,
			Quantity__c = 1,
			Sales_Price__c = 2000.00);
	}

	static Expiring_Product__c expiringProduct { get {
		if(expiringProduct == null) {
			// create an expiring product for the source opportunity
			expiringProduct = createExpiringProduct(opportunity.Id,product.ProductCode);
		}
		return expiringProduct;
	}}

	static testMethod void testInitialization() {
		Renewal_CotermTest controller = new Renewal_CotermTest(opportunityId);
		System.assertEquals(opportunityId, controller.sourceOpportunityId);
		System.assertEquals(opportunityId, controller.sourceOpportunity.Id);
	}
}