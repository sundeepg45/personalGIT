/**
 * This is the test class for OpportunityLineItemTriggerBefore2.
 *
 * @version 2015-11-24
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-11-24 - Updated not to need to see all data for pricebooks
 * 2012-09-27 - changed to public
 * Scott Coleman <scoleman@redhat.com>
 * 2013-08-09 - Renamed to avoid release conflicts, implemented Embedded
 * 2013-07-15 - implemented Opp Lock
 */
public class OpportunityLineItemTriggerBefore2Test {
	public static Id standardPricebookId { get {
		if(standardPricebookId == null) {
			// get the id of the standard price book
			standardPricebookId = Test.getStandardPricebookId();
		}
		return standardPricebookId;
	}}

	public static Id globalPricebookId { get {
		if(globalPriceBookId == null) {
			try {
				globalPriceBookId = Renewal_Coterm.globalPriceBookId;
			}
			catch(Exception ignored) {
				Pricebook2 globalPricebook = new Pricebook2(Name='Global Price Book', isActive=true);
				Database.insert( globalPricebook,false);
				Renewal_Coterm.globalPriceBookId = globalPriceBookId = globalPricebook.Id;
			}
		}
		return globalPricebookId;
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
			priceBookEntry = createPriceBookEntry(globalPricebookId);
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
			Embedded__c = false,
			Name = name,
			Opportunity_Reference_Name__c = refName,
			OpportunityType__c = 'Standard',
			PaymentType__c = 'NA Purchase Order',
			Pricebook2Id = globalPriceBookId,
			RecordTypeId = renewalRecordTypeId,
			ReasonWonLostSalesProcess__c = reason,
			StageName = 'Prepare'); //changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
	}

	public static Opportunity opportunity { get {
		if(opportunity == null) {
			// create the source renewal opportunity
			opportunity = createOpportunity('Renewal Source Opportunity',null,null);
			AbstractTrigger.setBooleanSettings('Opp_After.',false);
			AbstractTrigger.setBooleanSettings('Opp_Before.',false);
			insert opportunity;
			AbstractTrigger.setBooleanSettings('Opp_After.',true);
			AbstractTrigger.setBooleanSettings('Opp_Before.',true);
		}
		return opportunity;
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

	public static OpportunityLineItem lineItem { get {
		if(lineItem == null) {
			// create an opportunity line item for the source opportunity
			lineItem = createLineItem(opportunity.Id);
		}
		return lineItem;
	}}

	@isTest
	static void oppLockTest() {
		OpportunityLineItem xlineItem = lineItem;
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			null);
		triggerBefore.oppLock();
		System.assert(!triggerBefore.hasErrors);
	}

	@isTest
	static void setEmbeddedTest() {
		OpportunityLineItem xlineItem = lineItem;
		xlineItem.Configured_SKU__c = 'RHT123';
		xlineItem.Description = 'description embedded test test test';
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			null,
			new List<OpportunityLineItem>{xlineItem});

		//test description substring match
		StringSetting__c embeddedDescription = StringSetting__c.getInstance('Opportunity.EmbeddedDescription');
		if(embeddedDescription == null) {
			embeddedDescription = new StringSetting__c(Name='Opportunity.EmbeddedDescription',Value__c='embedded');
			insert embeddedDescription;
		}
		else {
			embeddedDescription.Value__c = 'embedded';
			update embeddedDescription;
		}
		triggerBefore.setEmbedded();
		List<Opportunity> embeddedOpportunity = [SELECT Id, Embedded__c, EmbeddedOverridden__c FROM Opportunity WHERE Id = :opportunity.Id];
		System.assert(embeddedOpportunity[0].Embedded__c);
		delete embeddedDescription;

		//test sku list match - config sku
		opportunity.Embedded__c = false;
		opportunity.EmbeddedOverridden__c = OpportunityLineItemTriggerBefore2.EMBEDDED_TRIGGER_KEY;
		update opportunity;
		EmbeddedSku__c embeddedConfigSku = new EmbeddedSku__c(Name='RHT123');
		insert embeddedConfigSku;
		triggerBefore.setEmbedded();
		embeddedOpportunity = [SELECT Id, Embedded__c, EmbeddedOverridden__c FROM Opportunity WHERE Id = :opportunity.Id];
		System.assert(embeddedOpportunity[0].Embedded__c);
		delete embeddedConfigSku;

		//test sku list match - standard sku
		opportunity.Embedded__c = false;
		opportunity.EmbeddedOverridden__c = OpportunityLineItemTriggerBefore2.EMBEDDED_TRIGGER_KEY;
		update opportunity;
		EmbeddedSku__c embeddedStandardSku = new EmbeddedSku__c(Name='HFB007');
		insert embeddedStandardSku;
		triggerBefore.setEmbedded();
		embeddedOpportunity = [SELECT Id, Embedded__c, EmbeddedOverridden__c FROM Opportunity WHERE Id = :opportunity.Id];
		System.assert(embeddedOpportunity[0].Embedded__c);
		delete embeddedStandardSku;	
	}

	@isTest
	static void calculateActualTest() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(ScheduleLocked__c=false);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateActual();
		System.assertEquals(null,xlineItem.ActualStartDate__c);
		System.assertEquals(null,xlineItem.ActualEndDate__c);
//		System.assertEquals(365.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = null;
		Date testDate1 = Date.newInstance(2012,1,1);
		xlineItem.ActualStartDate__c = testDate1;
		// the item has been removed from the list, so this is a do nothing operation
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(null,xlineItem.ActualEndDate__c);
		System.assertEquals(null,xlineItem.ActualTerm__c);
		// now try again with a fresh object
		triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>(),
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addYears(1).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(365.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 730.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addYears(2).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(730.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 760.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addYears(2).addMonths(1).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(760.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 60.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(60.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 90.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(3).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(90.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 335.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(11).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(335.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 58.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addDays(57),xlineItem.ActualEndDate__c);
		System.assertEquals(58.0,xlineItem.ActualTerm__c);
		xlineItem.ActualTerm__c = 59.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(59.0,xlineItem.ActualTerm__c);
		xlineItem.ScheduleLocked__c = true;
		xlineItem.ActualTerm__c = 100.0;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(59.0,xlineItem.ActualTerm__c);
		OpportunityLineItemTriggerBefore2.testingCloseDate = testDate1.addDays(-1);
		xlineItem.ActualStartDate__c = null;
		triggerBefore.calculateActual();
		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
		System.assertEquals(59.0,xlineItem.ActualTerm__c);
		// try an error scenario
		OpportunityLineItemTriggerBefore2.testingCloseDate = null;
		xlineItem.ActualStartDate__c = null;
		xlineItem.ActualEndDate__c = null;
		triggerBefore.calculateActual();
		System.assertEquals(null,xlineItem.ActualStartDate__c);
		System.assertEquals(null,xlineItem.ActualEndDate__c);
		// lets try some locked schedule tests
		xlineItem.ScheduleLocked__c=true;
		xlineItem.ActualStartDate__c = Date.newInstance(2012,1,1);
		xlineItem.ActualEndDate__c = Date.newInstance(2012,12,31);
		triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateActual();
		System.assertEquals(Date.newInstance(2012,1,1),xlineItem.ActualStartDate__c);
		System.assertEquals(Date.newInstance(2012,12,31),xlineItem.ActualEndDate__c);
		System.assertEquals(365.0,xlineItem.ActualTerm__c);
		// new lets try a non-leap year
		xlineItem.ActualStartDate__c = Date.newInstance(2013,1,1);
		xlineItem.ActualEndDate__c = Date.newInstance(2013,12,31);
		triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateActual();
		System.assertEquals(Date.newInstance(2013,1,1),xlineItem.ActualStartDate__c);
		System.assertEquals(Date.newInstance(2013,12,31),xlineItem.ActualEndDate__c);
		System.assertEquals(365.0,xlineItem.ActualTerm__c);
		// new lets try an error condition
		xlineItem.ActualStartDate__c = Date.newInstance(2014,1,1);
		triggerBefore.calculateActual();
		// nothing should have changed
		System.assertEquals(Date.newInstance(2014,1,1),xlineItem.ActualStartDate__c);
		System.assertEquals(Date.newInstance(2013,12,31),xlineItem.ActualEndDate__c);
		System.assertEquals(365.0,xlineItem.ActualTerm__c);
	}

	@isTest
	static void calculateScheduleTest() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2012,1,1),
			ActualEndDate__c = Date.newInstance(2014,12,31),
			ActualTerm__c = 1095.0,
			UnitPrice = 365.0,
			Quantity = 3.0);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		// close date one day before start of term - the normal case
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2011,12,31);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(365.0,xlineItem.Year1Amount__c);
		System.assertEquals(365.0,xlineItem.Year2Amount__c);
		System.assertEquals(365.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
		// close date one month minus a day into the term
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2012,1,31);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(396.0,xlineItem.Year1Amount__c);
		System.assertEquals(365.0,xlineItem.Year2Amount__c);
		System.assertEquals(334.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
		// close date one month one day before the start of the term
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2011,11,30);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(334.0,xlineItem.Year1Amount__c);
		System.assertEquals(365.0,xlineItem.Year2Amount__c);
		System.assertEquals(365.0,xlineItem.Year3Amount__c);
		System.assertEquals(31.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
		// close date one year one month one day before the stat of the term
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2010,11,30);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(334.0,xlineItem.Year2Amount__c);
		System.assertEquals(365.0,xlineItem.Year3Amount__c);
		System.assertEquals(365.0,xlineItem.Year4Amount__c);
		System.assertEquals(31.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
		// close date one year minus one day after the start of the term
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2012,12,31);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(730.0,xlineItem.Year1Amount__c);
		System.assertEquals(365.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
		// close date many years before the start of the term
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2001,12,31);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(0.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
		// test error conditions, values should not update
		OpportunityLineItemTriggerBefore2.testingCloseDate = null;
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(0.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
		// assign a date, values should still not update because
		// the line item was removed from the list
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2012,2,1);
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(0.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
		// try an error on the date sequence
		xlineItem.ActualStartDate__c = xlineItem.ActualEndDate__c.addDays(1);
		triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(0.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
		// try with quantity and unit price as null
		xlineItem.ActualStartDate__c = OpportunityLineItemTriggerBefore2.testingCloseDate.addDays(-1);
		xlineItem.Quantity = null;
		xlineItem.UnitPrice = null;
		triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
//		System.assertEquals(0.0,xlineItem.YearlySalesPrice__c);
		System.assertEquals(0.0,xlineItem.Year1Amount__c);
		System.assertEquals(0.0,xlineItem.Year2Amount__c);
		System.assertEquals(0.0,xlineItem.Year3Amount__c);
		System.assertEquals(0.0,xlineItem.Year4Amount__c);
		System.assertEquals(0.0,xlineItem.Year5Amount__c);
		System.assertEquals(0.0,xlineItem.Year6Amount__c);
	}

	//
	// These tests validate standard 1,2,3,4,5,6 year term scenarios.
	// The start date is exactly 1 day after the close date, while the end
	// date is exactly 1,2,3,4,5, or 6 years after the close date.
	//	
	@isTest
	static void testStandard1YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2010, 11, 10),
			ActualTerm__c = 365.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		// close date one day before start of term - the normal case
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(0,round(xlineItem.Year2Amount__c));
		System.assertEquals(0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testStandard2YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2011, 11, 10),
			ActualTerm__c = 730.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 2.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testStandard3YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2012, 11, 10),
			ActualTerm__c = 1095.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 3.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testStandard4YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2013, 11, 10),
			ActualTerm__c = 1460.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 4.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testStandard5YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2014, 11, 10),
			ActualTerm__c = 1825.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 5.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testStandard6YearTerm() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2015, 11, 10),
			ActualTerm__c = 2190.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 6.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year5Amount__c));
		System.assertEquals(2000.00,round(xlineItem.Year6Amount__c));
	}

	// These tests validate scenarios where the start date is before the close date (contract in progress)
	@isTest
	static void testContractInProgress1() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 05, 12),
			ActualEndDate__c = Date.newInstance(2010, 11, 10),
			ActualTerm__c = 548.0,
			ScheduleLocked__c = true,
			UnitPrice = 2000.00,
			Quantity = 2.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(4000.0,round(xlineItem.Year1Amount__c));
		System.assertEquals(0,round(xlineItem.Year2Amount__c));
		System.assertEquals(0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testContractInProgress2() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 05, 12),
			ActualEndDate__c = Date.newInstance(2011, 05, 11),
			ActualTerm__c = 730.0,
			ScheduleLocked__c = true,
			UnitPrice = 365.00,
			Quantity = 2.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(548.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(182.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	// These tests validate scenarios where the start date is after the close date (Delayed Contract)
	@isTest
	static void testDelayedContract1() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2010, 05, 13),
			ActualEndDate__c = Date.newInstance(2011, 05, 12),
			ActualTerm__c = 365.0,
			ScheduleLocked__c = true,
			UnitPrice = 365.00,
			Quantity = 2.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(364.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(366.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testDelayedContract2() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2010, 11, 12),
			ActualEndDate__c = Date.newInstance(2011, 11, 11),
			ActualTerm__c = 365.0,
			ScheduleLocked__c = true,
			UnitPrice = 365.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(0.00,round(xlineItem.Year1Amount__c));
		System.assertEquals(364.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(1.0,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testDelayedContract3() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2010, 11, 12),
			ActualEndDate__c = Date.newInstance(2012, 05, 13),
			ActualTerm__c = 548.0,
			ScheduleLocked__c = true,
			UnitPrice = 548.00,
			Quantity = 3.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(0,round(xlineItem.Year1Amount__c));
		System.assertEquals(1092.00,round(xlineItem.Year2Amount__c));
		System.assertEquals(552.00,round(xlineItem.Year3Amount__c));
		System.assertEquals(0,round(xlineItem.Year4Amount__c));
		System.assertEquals(0,round(xlineItem.Year5Amount__c));
		System.assertEquals(0,round(xlineItem.Year6Amount__c));
	}

	@isTest
	static void testLeapYear() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 05, 12),
			ActualEndDate__c = Date.newInstance(2012, 08, 11),
			ActualTerm__c = 1187.0,
			ScheduleLocked__c = true,
			UnitPrice = 1187.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(548.00, round(xlineItem.Year1Amount__c));
		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
		System.assertEquals(274.00, round(xlineItem.Year3Amount__c));
		System.assertEquals(0, xlineItem.Year4Amount__c);
		System.assertEquals(0, xlineItem.Year5Amount__c);
		System.assertEquals(0, xlineItem.Year6Amount__c);
	}

	@isTest
	static void testLeapYear2() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2009, 11, 11),
			ActualEndDate__c = Date.newInstance(2012, 11, 10),
			ActualTerm__c = 1095.0,
			ScheduleLocked__c = true,
			UnitPrice = 1095.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(365.00, round(xlineItem.Year1Amount__c));
		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
		System.assertEquals(365.00, round(xlineItem.Year3Amount__c));
		System.assertEquals(0, xlineItem.Year4Amount__c);
		System.assertEquals(0, xlineItem.Year5Amount__c);
		System.assertEquals(0, xlineItem.Year6Amount__c);
	}

	@isTest
	static void testLeapYear3() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2007, 12, 21),
			ActualEndDate__c = Date.newInstance(2011, 03, 20),
			ActualTerm__c = 1185.0,
			ScheduleLocked__c = true,
			UnitPrice = 1185.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(1055.00, round(xlineItem.Year1Amount__c));
		System.assertEquals(130.00, round(xlineItem.Year2Amount__c));
		System.assertEquals(0, round(xlineItem.Year3Amount__c));
		System.assertEquals(0, xlineItem.Year4Amount__c);
		System.assertEquals(0, xlineItem.Year5Amount__c);
		System.assertEquals(0, xlineItem.Year6Amount__c);
	}

	@isTest
	static void testLeapYear4() {
		OpportunityLineItem xlineItem = new OpportunityLineItem(
			ActualStartDate__c = Date.newInstance(2008, 02, 29),
			ActualEndDate__c = Date.newInstance(2012, 07, 30),
			ActualTerm__c = 1613.0,
			ScheduleLocked__c = true,
			UnitPrice = 1613.00,
			Quantity = 1.0);
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2009, 11, 10);
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{null=>xlineItem},
			new List<OpportunityLineItem>{xlineItem});
		triggerBefore.calculateSchedule();
		System.assertEquals(986.00, round(xlineItem.Year1Amount__c));
		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
		System.assertEquals(262.00, round(xlineItem.Year3Amount__c));
		System.assertEquals(0, xlineItem.Year4Amount__c);
		System.assertEquals(0, xlineItem.Year5Amount__c);
		System.assertEquals(0, xlineItem.Year6Amount__c);
	}

	@isTest
	static void restrictDeletionsTest() {
		OpportunityLineItemTriggerBefore2.adminByPass.IsIT__c = false;
		OpportunityLineItemTriggerBefore2.adminByPass.IsSalesUser__c = true;
		OpportunityLineItemTriggerBefore2 triggerBefore = new OpportunityLineItemTriggerBefore2(
			new Map<Id,OpportunityLineItem>{lineItem.Id=>lineItem},
			null);
		Test.startTest();
		triggerBefore.restrictDeletions();
		System.assert(! triggerBefore.hasErrors,'Unexpected Errors');
		opportunity.StageName = OpportunityTriggerBefore2.CLOSED_WON_PLV;
		update opportunity;
		triggerBefore.restrictDeletions();
		System.assert(triggerBefore.hasErrors,'Expected Errors');
		triggerBefore.hasErrors = false;
		OpportunityLineItemTriggerBefore2.adminByPass.IsSalesUser__c = false;
		triggerBefore.restrictDeletions();
		System.assert(! triggerBefore.hasErrors,'Unexpected Errors');
		Test.stopTest();
	}

	@isTest
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('LineItem_After.',false);
		AbstractTrigger.setBooleanSettings('LineItem_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<OpportunityLineItem> xlineItems = new List<OpportunityLineItem>{lineItem};
		Map<Id,OpportunityLineItem> oldMap = new Map<Id,OpportunityLineItem>{lineItem.Id => lineItem };
		List<OpportunityLineItem> newList = xlineItems.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('LineItem_Before.',true);
		AbstractTrigger.processTriggerComplete();
		
		AbstractTrigger.insertMissing = 0;
		OpportunityLineItemTriggerBefore2.testingCloseDate = Date.newInstance(2011,12,31);
		OpportunityLineItemTriggerBefore2.processTrigger(null,newList);
		AbstractTrigger.processTriggerComplete();
		// update
		newList = xlineItems.deepClone(true);
		OpportunityLineItemTriggerBefore2.processTrigger(oldMap,newList);
		AbstractTrigger.processTriggerComplete();
		// delete
		OpportunityLineItemTriggerBefore2.processTrigger(oldMap,null);
		AbstractTrigger.processTriggerComplete();
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('LineItem_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('OpportunityLineItem_Before.',new List<OpportunityLineItem>{lineItem});
	}

	static Decimal round(Decimal value) {
		return value.divide(1, 2, System.RoundingMode.HALF_EVEN);
	}
}