/**
 * This is the test class for OpportunityLineItemTriggerBefore.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-07-15
 * 2012-09-27 - changed to public
 * Scott Coleman <scoleman@redhat.com>
 * 2013-07-15 - implemented Opp Lock
 */
@isTest
private class OpportunityLineItemTriggerBeforeTest {
//depreciated	public static Id standardPricebookId { get {
//depreciated		if(standardPriceBookId == null) {
//depreciated			// get the id of the standard price book
//depreciated			standardPriceBookId = [SELECT Id FROM PriceBook2 WHERE isStandard = true].Id;
//depreciated		}
//depreciated		return standardPriceBookId;
//depreciated	}}

//depreciated	public static Id renewalRecordTypeId { get {
//depreciated		if(renewalRecordTypeId == null) {
//depreciated			// get the id of the renewal record type
//depreciated			renewalRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Renewal' AND SObjectType = 'Opportunity' AND IsActive = true].Id;
//depreciated		}
//depreciated		return renewalRecordTypeId;
//depreciated	}}

//depreciated	public static Account account { get {
//depreciated		if(account == null) {
//depreciated			// create an account
//depreciated			account = new Account(
//depreciated				BillingCity = 'Raleigh',
//depreciated				BillingCountry = 'US',
//depreciated				BillingPostalCode = '27606',
//depreciated				BillingState = 'North Carolina',
//depreciated				BillingStreet = '1801 Varsity Drive',
//depreciated				Name = 'Red Hat',
//depreciated				OracleAccountNumber__c = '12345',
//depreciated				ShippingCity = 'Raleigh',
//depreciated				ShippingCountry = 'US',
//depreciated				ShippingPostalCode = '27606',
//depreciated				ShippingState = 'North Carolina',
//depreciated				ShippingStreet = '1801 Varsity Drive',
//depreciated				VATNumber__c = '67890');
//depreciated			insert account;
//depreciated		}
//depreciated		return account;
//depreciated	}}

//depreciated	public static Product2 product { get {
//depreciated		if(product == null) {
//depreciated			// create a product
//depreciated			product = new Product2(
//depreciated				Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.',
//depreciated				IsActive = true,
//depreciated				Name = 'Happy Fun Ball',
//depreciated				ProductCode = 'HFB007');
//depreciated			insert product;
//depreciated		}
//depreciated		return product;
//depreciated	}}

//depreciated	public static PricebookEntry createPriceBookEntry(Id priceBookId) {
//depreciated		// create a pricebook entry for the standard pricebook
//depreciated		return new PricebookEntry(
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			isActive = true,
//depreciated			Pricebook2Id = priceBookId,
//depreciated			Product2Id = product.Id,
//depreciated			UnitPrice = 2000.00);
//depreciated	}

//depreciated	public static PricebookEntry priceBookEntry_sp { get {
//depreciated		if(priceBookEntry_sp == null) {
//depreciated			// create a pricebook entry for the standard pricebook
//depreciated			priceBookEntry_sp = createPriceBookEntry(standardPriceBookId);
//depreciated			insert priceBookEntry_sp;
//depreciated		}
//depreciated		return priceBookEntry_sp;
//depreciated	}}

//depreciated	public static PricebookEntry priceBookEntry { get {
//depreciated		if(priceBookEntry == null  && priceBookEntry_sp != null) {
//depreciated			// create a pricebook entry for the global pricebook
//depreciated			priceBookEntry = createPriceBookEntry(Renewal_Coterm.globalPriceBookId);
//depreciated			insert priceBookEntry;
//depreciated		}
//depreciated		return priceBookEntry;
//depreciated	}}

//depreciated	public static Opportunity createOpportunity(String name,String refName,String reason) {
//depreciated		return new Opportunity(
//depreciated			AccountId = account.Id,
//depreciated			CloseDate = Date.newInstance(2010, 11, 10),
//depreciated			Country_Of_Order__c = 'US',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			Name = name,
//depreciated			Opportunity_Reference_Name__c = refName,
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'NA Purchase Order',
//depreciated			Pricebook2Id = Renewal_Coterm.globalPriceBookId,
//depreciated			RecordTypeId = renewalRecordTypeId,
//depreciated			ReasonWonLostSalesProcess__c = reason,
//depreciated			StageName = 'Prepare'); //changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
//depreciated	}

//depreciated	static Opportunity opportunity { get {
//depreciated		if(opportunity == null) {
//depreciated			// create the source renewal opportunity
//depreciated			opportunity = createOpportunity('Renewal Source Opportunity',null,null);
//depreciated			insert opportunity;
//depreciated		}
//depreciated		return opportunity;
//depreciated	}}

//depreciated	public static OpportunityLineItem createLineItem(Id oppId) {
//depreciated		// create an opportunity line item for the source opportunity
//depreciated		return new OpportunityLineItem(
//depreciated			OpportunityId = oppId,
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2010, 11, 10),
//depreciated			ActualTerm__c = 365,
//depreciated			PricebookEntryId = priceBookEntry.Id,
//depreciated			Quantity = 2,
//depreciated			UnitPrice = 2000.00,
//depreciated			ScheduleLocked__c = true);
//depreciated	}

//depreciated	static OpportunityLineItem lineItem { get {
//depreciated		if(lineItem == null) {
//depreciated			// create an opportunity line item for the source opportunity
//depreciated			lineItem = createLineItem(opportunity.Id);
//depreciated		}
//depreciated		return lineItem;
//depreciated	}}

//depreciated	@isTest (SeeAllData=true)
//depreciated	static void oppLockTest() {
//depreciated		OpportunityLineItem xlineItem = lineItem;
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			null);
//depreciated		triggerBefore.oppLock();
//depreciated		System.assert(!triggerBefore.hasErrors);
//depreciated	}

//depreciated	@isTest
//depreciated	static void calculateActualTest() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(ScheduleLocked__c=false);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(null,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(null,xlineItem.ActualEndDate__c);
//		System.assertEquals(365.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = null;
//depreciated		Date testDate1 = Date.newInstance(2012,1,1);
//depreciated		xlineItem.ActualStartDate__c = testDate1;
//depreciated		// the item has been removed from the list, so this is a do nothing operation
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(null,xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(null,xlineItem.ActualTerm__c);
//depreciated		// now try again with a fresh object
//depreciated		triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>(),
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addYears(1).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(365.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 730.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addYears(2).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(730.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 760.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addYears(2).addMonths(1).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(760.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 60.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(60.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 90.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(3).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(90.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 335.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(11).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(335.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 58.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addDays(57),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(58.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ActualTerm__c = 59.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(59.0,xlineItem.ActualTerm__c);
//depreciated		xlineItem.ScheduleLocked__c = true;
//depreciated		xlineItem.ActualTerm__c = 100.0;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(59.0,xlineItem.ActualTerm__c);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = testDate1.addDays(-1);
//depreciated		xlineItem.ActualStartDate__c = null;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(testDate1,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(testDate1.addMonths(2).addDays(-1),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(59.0,xlineItem.ActualTerm__c);
//depreciated		// try an error scenario
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = null;
//depreciated		xlineItem.ActualStartDate__c = null;
//depreciated		xlineItem.ActualEndDate__c = null;
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(null,xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(null,xlineItem.ActualEndDate__c);
//depreciated		// lets try some locked schedule tests
//depreciated		xlineItem.ScheduleLocked__c=true;
//depreciated		xlineItem.ActualStartDate__c = Date.newInstance(2012,1,1);
//depreciated		xlineItem.ActualEndDate__c = Date.newInstance(2012,12,31);
//depreciated		triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(Date.newInstance(2012,1,1),xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2012,12,31),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(365.0,xlineItem.ActualTerm__c);
//depreciated		// new lets try a non-leap year
//depreciated		xlineItem.ActualStartDate__c = Date.newInstance(2013,1,1);
//depreciated		xlineItem.ActualEndDate__c = Date.newInstance(2013,12,31);
//depreciated		triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateActual();
//depreciated		System.assertEquals(Date.newInstance(2013,1,1),xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2013,12,31),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(365.0,xlineItem.ActualTerm__c);
//depreciated		// new lets try an error condition
//depreciated		xlineItem.ActualStartDate__c = Date.newInstance(2014,1,1);
//depreciated		triggerBefore.calculateActual();
//depreciated		// nothing should have changed
//depreciated		System.assertEquals(Date.newInstance(2014,1,1),xlineItem.ActualStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2013,12,31),xlineItem.ActualEndDate__c);
//depreciated		System.assertEquals(365.0,xlineItem.ActualTerm__c);
//depreciated	}

//depreciated	@isTest
//depreciated	static void calculateScheduleTest() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2012,1,1),
//depreciated			ActualEndDate__c = Date.newInstance(2014,12,31),
//depreciated			ActualTerm__c = 1095.0,
//depreciated			UnitPrice = 365.0,
//depreciated			Quantity = 3.0);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		// close date one day before start of term - the normal case
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2011,12,31);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated		// close date one month minus a day into the term
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2012,1,31);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(396.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(334.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated		// close date one month one day before the start of the term
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2011,11,30);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(334.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(31.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated		// close date one year one month one day before the stat of the term
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2010,11,30);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(334.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(31.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated		// close date one year minus one day after the start of the term
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2012,12,31);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(730.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(365.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated		// close date many years before the start of the term
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2001,12,31);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
//depreciated		// test error conditions, values should not update
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = null;
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
//depreciated		// assign a date, values should still not update because
//depreciated		// the line item was removed from the list
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2012,2,1);
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
//depreciated		// try an error on the date sequence
//depreciated		xlineItem.ActualStartDate__c = xlineItem.ActualEndDate__c.addDays(1);
//depreciated		triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(365.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(1095.0,xlineItem.Year6Amount__c);
//depreciated		// try with quantity and unit price as null
//depreciated		xlineItem.ActualStartDate__c = OpportunityLineItemTriggerBefore.testingCloseDate.addDays(-1);
//depreciated		xlineItem.Quantity = null;
//depreciated		xlineItem.UnitPrice = null;
//depreciated		triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//		System.assertEquals(0.0,xlineItem.YearlySalesPrice__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year1Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year2Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year3Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0.0,xlineItem.Year6Amount__c);
//depreciated	}

//depreciated	//
//depreciated	// These tests validate standard 1,2,3,4,5,6 year term scenarios.
//depreciated	// The start date is exactly 1 day after the close date, while the end
//depreciated	// date is exactly 1,2,3,4,5, or 6 years after the close date.
//depreciated	//	
//depreciated	@isTest
//depreciated	static void testStandard1YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2010, 11, 10),
//depreciated			ActualTerm__c = 365.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		// close date one day before start of term - the normal case
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testStandard2YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2011, 11, 10),
//depreciated			ActualTerm__c = 730.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 2.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testStandard3YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2012, 11, 10),
//depreciated			ActualTerm__c = 1095.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 3.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testStandard4YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2013, 11, 10),
//depreciated			ActualTerm__c = 1460.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 4.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testStandard5YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2014, 11, 10),
//depreciated			ActualTerm__c = 1825.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 5.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testStandard6YearTerm() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2015, 11, 10),
//depreciated			ActualTerm__c = 2190.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 6.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(2000.00,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	// These tests validate scenarios where the start date is before the close date (contract in progress)
//depreciated	@isTest
//depreciated	static void testContractInProgress1() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 05, 12),
//depreciated			ActualEndDate__c = Date.newInstance(2010, 11, 10),
//depreciated			ActualTerm__c = 548.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 2000.00,
//depreciated			Quantity = 2.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(4000.0,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testContractInProgress2() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 05, 12),
//depreciated			ActualEndDate__c = Date.newInstance(2011, 05, 11),
//depreciated			ActualTerm__c = 730.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 365.00,
//depreciated			Quantity = 2.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(548.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(182.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	// These tests validate scenarios where the start date is after the close date (Delayed Contract)
//depreciated	@isTest
//depreciated	static void testDelayedContract1() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2010, 05, 13),
//depreciated			ActualEndDate__c = Date.newInstance(2011, 05, 12),
//depreciated			ActualTerm__c = 365.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 365.00,
//depreciated			Quantity = 2.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(364.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(366.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testDelayedContract2() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2010, 11, 12),
//depreciated			ActualEndDate__c = Date.newInstance(2011, 11, 11),
//depreciated			ActualTerm__c = 365.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 365.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(0.00,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(364.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(1.0,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testDelayedContract3() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2010, 11, 12),
//depreciated			ActualEndDate__c = Date.newInstance(2012, 05, 13),
//depreciated			ActualTerm__c = 548.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 548.00,
//depreciated			Quantity = 3.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(0,round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(1092.00,round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(552.00,round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year4Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year5Amount__c));
//depreciated		System.assertEquals(0,round(xlineItem.Year6Amount__c));
//depreciated	}

//depreciated	@isTest
//depreciated	static void testLeapYear() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 05, 12),
//depreciated			ActualEndDate__c = Date.newInstance(2012, 08, 11),
//depreciated			ActualTerm__c = 1187.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 1187.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(548.00, round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(274.00, round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0, xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year6Amount__c);
//depreciated	}

//depreciated	@isTest
//depreciated	static void testLeapYear2() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2009, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(2012, 11, 10),
//depreciated			ActualTerm__c = 1095.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 1095.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(365.00, round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(365.00, round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0, xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year6Amount__c);
//depreciated	}

//depreciated	@isTest
//depreciated	static void testLeapYear3() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2007, 12, 21),
//depreciated			ActualEndDate__c = Date.newInstance(2011, 03, 20),
//depreciated			ActualTerm__c = 1185.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 1185.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(1055.00, round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(130.00, round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(0, round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0, xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year6Amount__c);
//depreciated	}

//depreciated	@isTest
//depreciated	static void testLeapYear4() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			ActualStartDate__c = Date.newInstance(2008, 02, 29),
//depreciated			ActualEndDate__c = Date.newInstance(2012, 07, 30),
//depreciated			ActualTerm__c = 1613.0,
//depreciated			ScheduleLocked__c = true,
//depreciated			UnitPrice = 1613.00,
//depreciated			Quantity = 1.0);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2009, 11, 10);
//depreciated		OpportunityLineItemTriggerBefore triggerBefore = new OpportunityLineItemTriggerBefore(
//depreciated			new Map<Id,OpportunityLineItem>{null=>xlineItem},
//depreciated			new List<OpportunityLineItem>{xlineItem});
//depreciated		triggerBefore.calculateSchedule();
//depreciated		System.assertEquals(986.00, round(xlineItem.Year1Amount__c));
//depreciated		System.assertEquals(365.00, round(xlineItem.Year2Amount__c));
//depreciated		System.assertEquals(262.00, round(xlineItem.Year3Amount__c));
//depreciated		System.assertEquals(0, xlineItem.Year4Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year5Amount__c);
//depreciated		System.assertEquals(0, xlineItem.Year6Amount__c);
//depreciated	}

//depreciated	@isTest(SeeAllData=true) // need all data to access custom settings
//depreciated	static void processTriggerTest() {
//depreciated		OpportunityLineItem xlineItem = new OpportunityLineItem(
//depreciated			Quantity = 3.0,
//depreciated			UnitPrice = 1095.0,
//depreciated			ScheduleLocked__c = false);
//depreciated		OpportunityLineItemTriggerBefore.testingCloseDate = Date.newInstance(2011,12,31);
//depreciated		// Turn on all the triggers, and make sure xlineItemerything is tested.
//depreciated		AbstractTrigger.setBooleanSettings('LineItem_Before.',true);
//depreciated		// insert
//depreciated		OpportunityLineItemTriggerBefore.processTrigger(null,new List<OpportunityLineItem>{xlineItem});
//depreciated		// update
//depreciated		OpportunityLineItemTriggerBefore.processTrigger(new Map<Id,OpportunityLineItem>{xlineItem.Id=>xlineItem.clone(true)},new List<OpportunityLineItem>{xlineItem});
//depreciated		// delete
//depreciated		OpportunityLineItemTriggerBefore.processTrigger(new Map<Id,OpportunityLineItem>{xlineItem.Id=>xlineItem},null);
//depreciated		// If there were any missing values, our test is invalid
//depreciated		AbstractTriggerTest.validateSettings('LineItem_Before.');
//depreciated	}

//depreciated	@isTest(SeeAllData=true) // need all data to access the global price book
//depreciated	static void deployTest() {
//depreciated		AbstractTriggerTest.deployTest('OpportunityLineItem_Before.',new List<OpportunityLineItem>{lineItem});
//depreciated	}

//depreciated	static Decimal round(Decimal value) {
//depreciated		return value.divide(1, 2, System.RoundingMode.HALF_EVEN);
//depreciated	} 
}