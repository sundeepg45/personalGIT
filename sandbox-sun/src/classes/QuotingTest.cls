/**
 * QuotingTest.cls
 *
 * @version 2013-01-29
 * @author  Bryan Bosely <bbosely@redhat.com>
 * 2011-01-11 - Created
 * Abhijeet Anand
 * 2011-09-29 - Enhanced code coverage.
 * Scott Coleman <scoleman@redhat.com>
 * 2013-01-29 - Populating Credit__c.Opportunity_Amount__c
 */
@isTest
private class QuotingTest {

	static Quoting QUOTING = new Quoting();
	static Pricebook2 PRICEBOOK;
	static PricebookEntry PRICEBOOKENTRY;
	static Opportunity OPPORTUNITY;
	static Opportunity OPPORTUNITY_PUBLIC_SECTOR;

	static {

		//
		// get the standard and the global price books
		//

		Pricebook2 standardPriceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
		PRICEBOOK = [SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book'];

		//
		// create a product
		//

		Product2 product = new Product2();
		product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
		product.IsActive = true;
		product.Name = 'Happy Fun Ball';
		product.ProductCode = 'HFB007';
		insert product;

		//
		// create a pricebook entry for the standard pricebook
		//

		PricebookEntry sPriceBookEntry = new PricebookEntry();
		sPriceBookEntry.CurrencyIsoCode = 'USD';
		sPriceBookEntry.isActive = true;
		sPriceBookEntry.Pricebook2Id = standardPriceBook.Id;
		sPriceBookEntry.Product2Id = product.Id;
		sPriceBookEntry.UnitPrice = 2000.00;
		insert sPriceBookEntry;

		//
		// create a pricebook entry for the global pricebook
		//

		PRICEBOOKENTRY = new PricebookEntry();
		PRICEBOOKENTRY.CurrencyIsoCode = 'USD';
		PRICEBOOKENTRY.isActive = true;
		PRICEBOOKENTRY.Pricebook2Id = PRICEBOOK.Id;
		PRICEBOOKENTRY.Product2Id = product.Id;
		PRICEBOOKENTRY.UnitPrice = 2000.00;
		insert PRICEBOOKENTRY;

		//
		// create an opportunity
		//

		OPPORTUNITY = new Opportunity();
		OPPORTUNITY.Amount = 10000.00;
		OPPORTUNITY.CloseDate = Date.newInstance(2010, 01, 01);
		OPPORTUNITY.ContractEndDate__c = Date.newInstance(2011, 01, 02);
		OPPORTUNITY.ContractStartDate__c = Date.newInstance(2010, 01, 01);
		OPPORTUNITY.CurrencyIsoCode = 'USD';
		OPPORTUNITY.Name = 'QuotingTest Opportunity';
		OPPORTUNITY.Pricebook2Id = PRICEBOOK.Id;
		OPPORTUNITY.StageName = 'Prepare'; //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
		OPPORTUNITY.TermOfOpportunity__c = '365';
		OPPORTUNITY.Year1PaymentAmount__c = 10000.00;
		OPPORTUNITY.Year2PaymentAmount__c = 0;
		OPPORTUNITY.Year3PaymentAmount__c = 0;
		OPPORTUNITY.Year4PaymentAmount__c = 0;
		OPPORTUNITY.Year5PaymentAmount__c = 0;
		OPPORTUNITY.Year6PaymentAmount__c = 0;
		insert OPPORTUNITY;


		OPPORTUNITY_PUBLIC_SECTOR = new Opportunity();
		OPPORTUNITY_PUBLIC_SECTOR.Amount = 10000.00;
		OPPORTUNITY_PUBLIC_SECTOR.CloseDate = Date.newInstance(2010, 01, 01);
		OPPORTUNITY_PUBLIC_SECTOR.ContractEndDate__c = Date.newInstance(2011, 01, 02);
		OPPORTUNITY_PUBLIC_SECTOR.ContractStartDate__c = Date.newInstance(2010, 01, 01);
		OPPORTUNITY_PUBLIC_SECTOR.CurrencyIsoCode = 'USD';
		OPPORTUNITY_PUBLIC_SECTOR.FulfillmentChannel__c = 'Direct - Carahsoft';
		OPPORTUNITY_PUBLIC_SECTOR.Name = 'QuotingTest OPPORTUNITY_PUBLIC_SECTOR';
		OPPORTUNITY_PUBLIC_SECTOR.Pricebook2Id = PRICEBOOK.Id;
		OPPORTUNITY_PUBLIC_SECTOR.StageName = 'Prepare'; //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
		OPPORTUNITY_PUBLIC_SECTOR.TermOfOpportunity__c = '365';
		OPPORTUNITY_PUBLIC_SECTOR.Year1PaymentAmount__c = 10000.00;
		OPPORTUNITY_PUBLIC_SECTOR.Year2PaymentAmount__c = 0;
		OPPORTUNITY_PUBLIC_SECTOR.Year3PaymentAmount__c = 0;
		OPPORTUNITY_PUBLIC_SECTOR.Year4PaymentAmount__c = 0;
		OPPORTUNITY_PUBLIC_SECTOR.Year5PaymentAmount__c = 0;
		OPPORTUNITY_PUBLIC_SECTOR.Year6PaymentAmount__c = 0;
		insert OPPORTUNITY_PUBLIC_SECTOR;
	}


	static testMethod void testInvalidQuoteId()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		try
		{
			QUOTING.syncQuoteWithOpp('a0QP00000008VDiMAM');
		}
		catch (Exception e)
		{
			System.assert(e.getMessage().contains('Quote id: a0QP00000008VDiMAM not found'));
		}
	}


	static testMethod void testInvalidOpportunityId()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c quote = null;

		try
		{
			quote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2010, 11, 29 ), Date.newInstance( 2011, 11, 28 ), 365 );
			QUOTING.syncQuoteWithOpp(quote.Id);
		}
		catch (Exception e)
		{
			System.assert(e.getMessage().contains('Opportunity not found for quote id: ' + quote.Id));
		}
	}


	static testMethod void testOpportunityFieldCopy()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c quote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2010, 11, 29 ), Date.newInstance( 2011, 11, 28 ), 365, 50000.00, 'Yes' );
		QUOTING.syncQuoteWithOpp(quote.Id);

		Opportunity opp = [SELECT Amount
				, ContractEndDate__c
				, ContractStartDate__c
				, CurrencyIsoCode
				, Pay_Now__c
				, Pricebook2Id
				, QuoteNumber__c
				, TermOfOpportunity__c
				, Year1PaymentAmount__c
				, Year2PaymentAmount__c
				, Year3PaymentAmount__c
				, Year4PaymentAmount__c
				, Year5PaymentAmount__c
				, Year6PaymentAmount__c
			FROM Opportunity
			WHERE Id = :OPPORTUNITY.Id
		];

		system.assertEquals(opp.Amount, 50000.00);
		system.assertEquals(opp.ContractEndDate__c, Date.newInstance(2011, 11, 28));
		system.assertEquals(opp.ContractStartDate__c, Date.newInstance(2010, 11, 29));
		system.assertEquals(opp.CurrencyIsoCode, 'USD');
		system.assertEquals(opp.Pay_Now__c, 'Yes');
		system.assertEquals(opp.Pricebook2Id, PRICEBOOK.Id);
		System.assert(opp.QuoteNumber__c != '' && opp.QuoteNumber__c != null);
		system.assertEquals(opp.TermOfOpportunity__c, '365');
		system.assertEquals(opp.Year1PaymentAmount__c, 50000.00);
		system.assertEquals(opp.Year2PaymentAmount__c, null);
		system.assertEquals(opp.Year3PaymentAmount__c, null);
		system.assertEquals(opp.Year4PaymentAmount__c, null);
		system.assertEquals(opp.Year5PaymentAmount__c, null);
		system.assertEquals(opp.Year6PaymentAmount__c, null);
	}


	static testMethod void testOpportunityLineItemFieldCopy()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c quote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2010, 11, 29 ), Date.newInstance( 2011, 11, 28 ), 365, 50000.00, 'Yes' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( quote.Id, Date.newInstance( 2010, 11, 29 ), Date.newInstance( 2011, 11, 28 ), 25, 365, 50000.00, 2000.00, 2000.00, 'Subscriptions' );

		QUOTING.syncQuoteWithOpp(quote.Id);
	
		OpportunityLineItem lineItem = [SELECT Id
				, ActualEndDate__c
				, ActualStartDate__c
				, ActualTerm__c
				, Configured_SKU__c
				, Contract_Numbers__c
				, Description
				, Line_Item_Source__c
				, NewOrRenewal__c
				, OpportunityId
				, PriceBookEntryId
				, Pricing_Attributes__c
				, ScheduleLocked__c
				, Quantity
				, UnitPrice
				, YearlySalesPrice__c
			FROM OpportunityLineItem
			WHERE OpportunityId = :OPPORTUNITY.Id
		];

		system.assertEquals(lineItem.ActualEndDate__c, Date.newInstance(2011, 11, 28));
		system.assertEquals(lineItem.ActualStartDate__c, Date.newInstance(2010, 11, 29));
		system.assertEquals(lineItem.ActualTerm__c, 365);
		system.assertEquals(lineItem.Configured_SKU__c, 'RH012345');
		system.assertEquals(lineItem.Contract_Numbers__c, '12345');
		system.assertEquals(lineItem.Description, 'Happy Fun Ball');
		system.assertEquals(lineItem.Line_Item_Source__c, 'application/vnd.redhat.sforce.quotingservices');
		system.assertEquals(lineItem.NewOrRenewal__c, 'New');
		system.assertEquals(lineItem.OpportunityId, OPPORTUNITY.Id);
		system.assertEquals(lineItem.PriceBookEntryId, PRICEBOOKENTRY.Id);
		system.assertEquals(lineItem.Pricing_Attributes__c, 'a=1; b=2; c=3');
		system.assertEquals(lineItem.ScheduleLocked__c, true);
		system.assertEquals(lineItem.Quantity, 25);
		system.assertEquals(lineItem.UnitPrice, 2000.00);
		system.assertEquals(lineItem.YearlySalesPrice__c, 2000.00);
	}


	static testMethod void testCreditCreated()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c quote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2010, 11, 29 ), Date.newInstance( 2011, 11, 28 ), 365, 50000.00, 'Yes' );
			
		RecordType approvalRecordType = [SELECT Id
			FROM RecordType
			WHERE NAME = 'Payment Terms'
		];


		ApprovalCustom__c approval = new ApprovalCustom__c();
		approval.ApprovalStatus__c = 'Approved';
		approval.BillingAccountNameApprovedOn__c = 'Roscoe P Coltrane';
		approval.BillingAccountNumberApprovedOn__c = '123456';
		approval.opportunity__c = OPPORTUNITY.Id;
		approval.PaymentTermsApproved__c = '45 NET';
		approval.Quote__c = quote.Id;
		approval.RecordTypeId = approvalRecordType.Id;
		insert approval;


		QUOTING.syncQuoteWithOpp(quote.Id);

		Credit__c credit = [SELECT Id
				, BillingAccountNameUsed__c
				, BillingAccountNumberUsed__c
				, Comments__c
				, Credit_Stage__c
				, opportunity__c
				, Opportunity_Amount__c
				, Payment_Terms__c
				, RecordTypeId
			FROM Credit__c
			WHERE Opportunity__c = :OPPORTUNITY.Id
		];


		RecordType recordType = [SELECT Id
			FROM RecordType
		   WHERE NAME = 'Approval Created'
		];

		system.assertEquals(credit.BillingAccountNameUsed__c, 'Roscoe P Coltrane');
		system.assertEquals(credit.BillingAccountNumberUsed__c, '123456');
		system.assertEquals(credit.Comments__c, 'Approval Reason: Payment Term Approval Request Granted');
		system.assertEquals(credit.Credit_Stage__c, 'Approved');
		system.assertEquals(credit.Opportunity__c, OPPORTUNITY.Id);
		system.assertEquals(credit.Opportunity_Amount__c, quote.Amount__c);
		system.assertEquals(credit.Payment_Terms__c, '45 NET');
		system.assertEquals(credit.RecordTypeId, recordType.Id);
	}


	static testMethod void testStandardQuote1Year()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c standardQuote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2012, 01, 19 ), 365, 3000.00, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( standardQuote.Id, Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2012, 01, 19 ), 1, 365, 3000.00, 3000.00, 3000.00, 'Subscriptions' );
		QUOTING.calculate( standardQuote.id );

		Quote__c quote = getQuote ( standardQuote.id );
		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		QuoteLineItemSchedule__c schedule = schedules[0];

		system.assertEquals( 3000.00, quote.Amount__c );
		system.assertEquals( 3000.00, quote.Year1PaymentAmount__c );
		system.assertEquals( 'USD', schedule.currencyIsoCode );
		system.assertEquals( Date.newInstance( 2012, 01, 19), schedule.endDate__c );
		system.assertEquals( 8.2191780822, schedule.pricePerDay__c );
		system.assertEquals( 3000.00, schedule.prorateTotalPrice__c );
		system.assertEquals( 3000.00, schedule.prorateUnitPrice__c );
		system.assertEquals( 3000.00, schedule.prorateYearTotalPrice__c );
		system.assertEquals( 3000.00, schedule.prorateYearUnitPrice__c );
		system.assertEquals( Date.newInstance( 2011, 01, 20 ), schedule.startDate__c );
		system.assertEquals( 'Invoice', schedule.type__c );
		system.assertEquals( 1.0, schedule.year__c );
	}


	static testMethod void testStandardQuote3Year()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c standardQuote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 1096, 3000.00, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( standardQuote.Id, Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 1, 1096, 3000.00, 3000.00, 3000.00, 'Subscriptions' );
		QUOTING.calculate( standardQuote.id );

		Quote__c quote = getQuote ( standardQuote.id );
		system.assertEquals( 3000.00, quote.Amount__c );
		system.assertEquals( 1000.00, quote.Year1PaymentAmount__c );
		system.assertEquals( 1000.00, quote.Year2PaymentAmount__c );
		system.assertEquals( 1000.00, quote.Year3PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;	
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			system.debug('----------------------------------------------------------');
			system.debug('  Start Date: ' + schedule.StartDate__c);
			system.debug('  End Date: ' + schedule.EndDate__c);
			system.debug('  Price Per Day: ' + schedule.pricePerDay__c);
			system.debug('  Prorate Total Price: ' + schedule.prorateTotalPrice__c);
			system.debug('  Prorate Unit Price: ' + schedule.prorateUnitPrice__c);
			system.debug('  Prorate Year Total Price: ' + schedule.prorateYearTotalPrice__c);
			system.debug('  Schedule Year: ' + schedule.year__c);
			system.debug('----------------------------------------------------------');

			if ( schedule.StartDate__c == Date.newInstance( 2011, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2012, 01, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.7397260274, schedule.pricePerDay__c );
				system.assertEquals( 1000.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 1000.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2013, 01, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.7397260274, schedule.pricePerDay__c );
				system.assertEquals( 2000.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 2000.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 2.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2013, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2014, 05, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.7397260274, schedule.pricePerDay__c );
				system.assertEquals( 3000.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 3000.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 1000.00, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 3.0, schedule.year__c );
			}
		}
	}


	static testMethod void testCotermQuote1Year()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c cotermQuote = createQuote( OPPORTUNITY.Id, 'Co-Term', Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2012, 05, 04 ), 428, 1135.66, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2012, 05, 04 ), 1, 428, 887.93, 887.93, 759.00, 'Subscriptions' );
		QuoteLineItem__c quoteLineItem2 = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 08, 04 ), Date.newInstance( 2012, 05, 04 ), 1, 275, 247.73, 247.73, 330.00, 'Subscriptions' );
		QUOTING.calculate( cotermQuote.id );

		Quote__c quote = getQuote ( cotermQuote.id );
		system.assertEquals( 1135.66, quote.Amount__c );
		system.assertEquals( 1135.66, quote.Year1PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year2PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year3PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			system.debug('----------------------------------------------------------');
			system.debug('  Start Date: ' + schedule.StartDate__c);
			system.debug('  End Date: ' + schedule.EndDate__c);
			system.debug('  Price Per Day: ' + schedule.pricePerDay__c);
			system.debug('  Prorate Total Price: ' + schedule.prorateTotalPrice__c);
			system.debug('  Prorate Unit Price: ' + schedule.prorateUnitPrice__c);
			system.debug('  Prorate Year Total Price: ' + schedule.prorateYearTotalPrice__c);
			system.debug('  Schedule Year: ' + schedule.year__c);
			system.debug('----------------------------------------------------------');


			if ( schedule.StartDate__c == Date.newInstance( 2011, 03, 04 ) && schedule.EndDate__c == Date.newInstance( 2012, 05, 04 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 887.93, schedule.prorateTotalPrice__c );
				system.assertEquals( 887.93, schedule.prorateUnitPrice__c );
				system.assertEquals( 887.93, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 887.93, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 08, 04 ) && schedule.EndDate__c == Date.newInstance( 2013, 05, 04 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.9086849315, schedule.pricePerDay__c );
				system.assertEquals( 247.73, schedule.prorateTotalPrice__c );
				system.assertEquals( 247.73, schedule.prorateUnitPrice__c );
				system.assertEquals( 247.73, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 247.73, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}

		}
	}


	static testMethod void testCotermQuote3Year()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c cotermQuote = createQuote( OPPORTUNITY.Id, 'Co-Term', Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2014, 05, 04 ), 1158, 3313.66, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2014, 05, 04 ), 1, 1158, 2405.93, 2405.93, 759.00, 'Subscriptions' );
		QuoteLineItem__c quoteLineItem2 = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 08, 04 ), Date.newInstance( 2014, 05, 04 ), 1, 1005, 907.73, 907.73, 330.00, 'Subscriptions' );
		QUOTING.calculate( cotermQuote.id );

		Quote__c quote = getQuote ( cotermQuote.id );
		system.assertEquals( 3313.66, quote.Amount__c );
		system.assertEquals( 1135.66, quote.Year1PaymentAmount__c );
		system.assertEquals( 1089.00, quote.Year2PaymentAmount__c );
		system.assertEquals( 1089.00, quote.Year3PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			system.debug('----------------------------------------------------------');
			system.debug('  Start Date: ' + schedule.StartDate__c);
			system.debug('  End Date: ' + schedule.EndDate__c);
			system.debug('  Price Per Day: ' + schedule.pricePerDay__c);
			system.debug('  Prorate Total Price: ' + schedule.prorateTotalPrice__c);
			system.debug('  Prorate Unit Price: ' + schedule.prorateUnitPrice__c);
			system.debug('  Prorate Year Total Price: ' + schedule.prorateYearTotalPrice__c);
			system.debug('  Schedule Year: ' + schedule.year__c);
			system.debug('----------------------------------------------------------');

			if ( schedule.StartDate__c == Date.newInstance( 2011, 03, 04 ) && schedule.EndDate__c == Date.newInstance( 2012, 05, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 887.93, schedule.prorateTotalPrice__c );
				system.assertEquals( 887.93, schedule.prorateUnitPrice__c );
				system.assertEquals( 887.93, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 05, 05 ) && schedule.EndDate__c == Date.newInstance( 2013, 05, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 1646.93, schedule.prorateTotalPrice__c );
				system.assertEquals( 1646.93, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 2.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2013, 05, 05 ) && schedule.EndDate__c == Date.newInstance( 2014, 05, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 2405.93, schedule.prorateTotalPrice__c );
				system.assertEquals( 2405.93, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 3.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2011, 05, 04 ) && schedule.EndDate__c == Date.newInstance( 2012, 08, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem2.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.904109589, schedule.pricePerDay__c );
				system.assertEquals( 247.73, schedule.prorateTotalPrice__c );
				system.assertEquals( 247.73, schedule.prorateUnitPrice__c );
				system.assertEquals( 247.73, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 05, 05 ) && schedule.EndDate__c == Date.newInstance( 2013, 05, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem2.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.904109589, schedule.pricePerDay__c );
				system.assertEquals( 577.73, schedule.prorateTotalPrice__c );
				system.assertEquals( 577.73, schedule.prorateUnitPrice__c );
				system.assertEquals( 330.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 2.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2013, 05, 05 ) && schedule.EndDate__c == Date.newInstance( 2014, 05, 04 ) && schedule.QuoteLineItemId__c == quoteLineItem2.Id )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.904109589, schedule.pricePerDay__c );
				system.assertEquals( 907.73, schedule.prorateTotalPrice__c );
				system.assertEquals( 907.73, schedule.prorateUnitPrice__c );
				system.assertEquals( 330.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 3.0, schedule.year__c );
			}
		}
	}


	static testMethod void testNonStandardQuote()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c nonStandardQuote = createQuote( OPPORTUNITY.Id, 'Non Standard', Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2015, 08, 27 ), 1638, 3404.06, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( nonStandardQuote.Id, Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2015, 08, 27 ), 1, 1638, 3404.06, 3404.06, 759.00, 'Subscriptions' );
		QUOTING.calculate( nonStandardQuote.id );

		Quote__c quote = getQuote ( nonStandardQuote.id );
		system.assertEquals( 3404.06, quote.Amount__c );
		system.assertEquals( 1127.06, quote.Year1PaymentAmount__c );
		system.assertEquals( 759.00, quote.Year2PaymentAmount__c );
		system.assertEquals( 759.00, quote.Year3PaymentAmount__c );
		system.assertEquals( 759.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			if ( schedule.StartDate__c == Date.newInstance( 2011, 03, 04 ) && schedule.EndDate__c == Date.newInstance( 2012, 08, 27 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 1127.06, schedule.prorateTotalPrice__c );
				system.assertEquals( 1127.06, schedule.prorateUnitPrice__c );
				system.assertEquals( 1127.06, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 08, 28 ) && schedule.EndDate__c == Date.newInstance( 2013, 08, 27 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 1886.06, schedule.prorateTotalPrice__c );
				system.assertEquals( 1886.06, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 2.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2013, 08, 28 ) && schedule.EndDate__c == Date.newInstance( 2014, 08, 27 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 2645.06, schedule.prorateTotalPrice__c );
				system.assertEquals( 2645.06, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 3.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2014, 08, 28 ) && schedule.EndDate__c == Date.newInstance( 2015, 08, 27 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 3404.06, schedule.prorateTotalPrice__c );
				system.assertEquals( 3404.06, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 4.0, schedule.year__c );
			}
		}
	}


	static testMethod void testPublicSectorQuote()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c standardQuote = createQuote( OPPORTUNITY_PUBLIC_SECTOR.Id, 'Standard', Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2012, 01, 19 ), 366, 759.00, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( standardQuote.Id, Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2012, 01, 19 ), 1, 366, 759.00, 759.00, 759.00, 'Subscriptions' );
		QUOTING.calculate( standardQuote.id );

		Quote__c quote = getQuote ( standardQuote.id );
		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		QuoteLineItemSchedule__c schedule = schedules[0];

		system.assertEquals( 759.00, quote.Amount__c );
		system.assertEquals( 759.00, quote.Year1PaymentAmount__c );
		system.assertEquals( 'USD', schedule.currencyIsoCode );
		system.assertEquals( Date.newInstance( 2012, 01, 19), schedule.endDate__c );
		system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
		system.assertEquals( 759.00, schedule.prorateTotalPrice__c );
		system.assertEquals( 759.00, schedule.prorateUnitPrice__c );
		system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
		system.assertEquals( 759.00, schedule.prorateYearUnitPrice__c );
		system.assertEquals( Date.newInstance( 2011, 01, 20 ), schedule.startDate__c );
		system.assertEquals( 'Invoice', schedule.type__c );
		system.assertEquals( 1.0, schedule.year__c );
	}


	static testMethod void testTraingUnitCoTermQuote()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c cotermQuote = createQuote( OPPORTUNITY.Id, 'Co-Term', Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2012, 05, 04 ), 428, 1089.00, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 03, 04 ), Date.newInstance( 2012, 05, 04 ), 1, 428, 759.00, 759.00, 759.00, 'GLS' );
		QuoteLineItem__c quoteLineItem2 = createQuoteLineItem ( cotermQuote.Id, Date.newInstance( 2011, 08, 04 ), Date.newInstance( 2012, 05, 04 ), 1, 275, 330.00, 330.00, 330.00, 'GLS' );
		QUOTING.calculate( cotermQuote.id );

		Quote__c quote = getQuote ( cotermQuote.id );
		system.assertEquals( 1089.00, quote.Amount__c );
		system.assertEquals( 1089.00, quote.Year1PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year2PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year3PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			system.debug('----------------------------------------------------------');
			system.debug('  Start Date: ' + schedule.StartDate__c);
			system.debug('  End Date: ' + schedule.EndDate__c);
			system.debug('  Price Per Day: ' + schedule.pricePerDay__c);
			system.debug('  Prorate Total Price: ' + schedule.prorateTotalPrice__c);
			system.debug('  Prorate Unit Price: ' + schedule.prorateUnitPrice__c);
			system.debug('  Prorate Year Total Price: ' + schedule.prorateYearTotalPrice__c);
			system.debug('  Schedule Year: ' + schedule.year__c);
			system.debug('----------------------------------------------------------');


			if ( schedule.StartDate__c == Date.newInstance( 2011, 03, 04 ) && schedule.EndDate__c == Date.newInstance( 2012, 05, 04 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 2.0794520548, schedule.pricePerDay__c );
				system.assertEquals( 759.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 759.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 759.00, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 08, 04 ) && schedule.EndDate__c == Date.newInstance( 2013, 05, 04 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.9086849315, schedule.pricePerDay__c );
				system.assertEquals( 330.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 330.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 330.00, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 330.00, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
		}
	}


	static testMethod void testTrainingUnitNonStandardQuote()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c nonStandardQuote = createQuote( OPPORTUNITY.Id, 'Non Standard', Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 1096, 800, 'No' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( nonStandardQuote.Id, Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 8, 1096, 800.00, 100.00, 100.00, 'GLS' );
		QUOTING.calculate( nonStandardQuote.id );

		Quote__c quote = getQuote ( nonStandardQuote.id );
		system.assertEquals( 800.00, quote.Amount__c );
		system.assertEquals( 266.64, quote.Year1PaymentAmount__c );
		system.assertEquals( 266.64, quote.Year2PaymentAmount__c );
		system.assertEquals( 266.72, quote.Year3PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year4PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year5PaymentAmount__c );
		system.assertEquals( 0.00, quote.Year6PaymentAmount__c );

		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		for ( QuoteLineItemSchedule__c schedule : schedules )
		{
			system.debug('----------------------------------------------------------');
			system.debug('  Start Date: ' + schedule.StartDate__c);
			system.debug('  End Date: ' + schedule.EndDate__c);
			system.debug('  Price Per Day: ' + schedule.pricePerDay__c);
			system.debug('  Prorate Total Price: ' + schedule.prorateTotalPrice__c);
			system.debug('  Prorate Unit Price: ' + schedule.prorateUnitPrice__c);
			system.debug('  Prorate Year Total Price: ' + schedule.prorateYearTotalPrice__c);
			system.debug('  Schedule Year: ' + schedule.year__c);
			system.debug('----------------------------------------------------------');


			if ( schedule.StartDate__c == Date.newInstance( 2011, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2012, 01, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.0913242009, schedule.pricePerDay__c );
				system.assertEquals( 266.64, schedule.prorateTotalPrice__c );
				system.assertEquals( 33.33, schedule.prorateUnitPrice__c );
				system.assertEquals( 266.64, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 33.33, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 1.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2012, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2013, 01, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.0913242009, schedule.pricePerDay__c );
				system.assertEquals( 533.28, schedule.prorateTotalPrice__c );
				system.assertEquals( 66.66, schedule.prorateUnitPrice__c );
				system.assertEquals( 266.64, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 33.33, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 2.0, schedule.year__c );
			}
			else if ( schedule.StartDate__c == Date.newInstance( 2013, 01, 20 ) && schedule.EndDate__c == Date.newInstance( 2014, 01, 19 ) )
			{
				system.assertEquals( schedule.currencyIsoCode, 'USD' );
				system.assertEquals( 0.0913242009, schedule.pricePerDay__c );
				system.assertEquals( 800.00, schedule.prorateTotalPrice__c );
				system.assertEquals( 100.00, schedule.prorateUnitPrice__c );
				system.assertEquals( 266.72, schedule.prorateYearTotalPrice__c );
				system.assertEquals( 33.34, schedule.prorateYearUnitPrice__c );
				system.assertEquals( 'Invoice', schedule.type__c );
				system.assertEquals( 3.0, schedule.year__c );
			}
		}
	}


	static testMethod void testPayNowQuote()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Quote__c standardQuote = createQuote( OPPORTUNITY.Id, 'Standard', Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 1096, 6000.00, 'Yes' );
		QuoteLineItem__c quoteLineItem = createQuoteLineItem ( standardQuote.Id, Date.newInstance( 2011, 01, 20 ), Date.newInstance( 2014, 01, 19 ), 1, 1096, 6000.00, 6000.00, 6000.00, 'Subscriptions' );
		QUOTING.calculate( standardQuote.id );

		Quote__c quote = getQuote ( standardQuote.id );
		List<QuoteLineItemSchedule__c> schedules = quote.QuoteLineItemSchedule__r;
		QuoteLineItemSchedule__c schedule = schedules[0];

		system.assertEquals( 6000.00, quote.Amount__c );
		system.assertEquals( 6000.00, quote.Year1PaymentAmount__c );
		system.assertEquals( 'USD', schedule.currencyIsoCode );
		system.assertEquals( Date.newInstance( 2014, 01, 19), schedule.endDate__c );
		system.assertEquals( 5.4794520548, schedule.pricePerDay__c );
		system.assertEquals( 6000.00, schedule.prorateTotalPrice__c );
		system.assertEquals( 6000.00, schedule.prorateUnitPrice__c );
		system.assertEquals( 6000.00, schedule.prorateYearTotalPrice__c );
		system.assertEquals( Date.newInstance( 2011, 01, 20 ), schedule.startDate__c );
		system.assertEquals( 'Invoice', schedule.type__c );
		system.assertEquals( 1.0, schedule.year__c );
	}


	/*
	 * Temporarily disabling this test until the Quoting changes for Big Machines are moved to FTE2
	 *
	static testMethod void testCalculateXML() {

		String SALESFORCE_MSG_NAMESPACE = 'http://salesforce.redhat.com/quoting';

		//
		// create the XML for calculating quote line items schedules for a quote
		//

		String requestXML = '<?xml version="1.0" encoding="UTF-8"?>' +
		'<SalesForceMessage  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://salesforce.redhat.com/quoting" xsi:schemaLocation="http://salesforce.redhat.com/quoting calculate.xsd">' +
		'   <Header>' +
		'	   <Operation>CREATE</Operation>' +
		'	   <Type>QUOTE</Type>' +
		'	   <InstanceId>10000</InstanceId>' +
		'	   <TimeStamp>2011-05-18</TimeStamp>' +
		'   </Header>' +
		'   <Payload>' +
		'	   <Quote>' +
		'		   <Id>12345</Id>' +
		'		   <Name>Test Quote</Name>' +
		'		   <Amount>3000.00</Amount>' +
		'		   <CurrencyIsoCode>USD</CurrencyIsoCode>' +
		'		   <StartDate>2010-11-29</StartDate>' +
		'		   <EndDate>2011-11-28</EndDate>' +
		'		   <Number>12345</Number>' +
		'		   <OpportunityId>006P0000002tsqr</OpportunityId>' +
		'		   <PayNow>Yes</PayNow>' +
		'		   <CloseDate>2010-10-10</CloseDate>' +
		'		   <FulfillmentChannel>Direct - End Customer</FulfillmentChannel>' +
		'		   <StageName>Unqualified</StageName>' +
		'		   <PricebookId>01s60000000EUnsAAG</PricebookId>' +
		'		   <Term>365</Term>' +
		'		   <Type>Standard</Type>' +
		'		   <Year1PaymentAmount>3000.00</Year1PaymentAmount>' +
		'		   <Year2PaymentAmount></Year2PaymentAmount>' +
		'		   <Year3PaymentAmount></Year3PaymentAmount>' +
		'		   <Year4PaymentAmount></Year4PaymentAmount>' +
		'		   <Year5PaymentAmount></Year5PaymentAmount>' +
		'		   <Year6PaymentAmount></Year6PaymentAmount>' +
		'		   <LastCalculatedDate></LastCalculatedDate>' +
		'		   <QuoteLineItem>' +
		'			   <Id>12345</Id>' +
		'			   <Name>Test Line Item</Name>' +
		'			   <NewOrRenewal>New</NewOrRenewal>' +
		'			   <ConfiguredSKU>RH012345</ConfiguredSKU>' +
		'			   <ContractNumbers>12345</ContractNumbers>' +
		'			   <StartDate>2011-01-20</StartDate>' +
		'			   <EndDate>2012-01-19</EndDate>' +
		'			   <Term>365</Term>' +
		'			   <PricebookEntryId>01s60000000EUnsAAG</PricebookEntryId>' +
		'			   <PricingAttributes>a=1, b=2, c=3</PricingAttributes>' +
		'			   <ProductDescription>Happy Fun Ball</ProductDescription>' +
		'			   <ProductFamily>GLS</ProductFamily>' +
		'			   <YearlySalesPrice>3000.00</YearlySalesPrice>' +
		'			   <Quantity>1</Quantity>' +
		'			   <UnitPrice>3000.00</UnitPrice>' +
		'			   <TotalPrice>3000.00</TotalPrice>' +
		'			   <QuoteLineItemSchedule>' +
		'				   <PricePerDay></PricePerDay>' +
		'				   <ProrateTotalPrice></ProrateTotalPrice>' +
		'				   <ProrateUnitPrice></ProrateUnitPrice>' +
		'				   <ProrateYearTotalPrice></ProrateYearTotalPrice>' +
		'				   <ProrateYearUnitPrice></ProrateYearUnitPrice>' +
		'				   <StartDate></StartDate>' +
		'				   <EndDate></EndDate>' +
		'				   <Year></Year>' +
		'				</QuoteLineItemSchedule>' +
		'			</QuoteLineItem>' +
		'		</Quote>' +
		'	</Payload>' +
		'</SalesForceMessage>';

		//
		// calculate the quoting line item schedules
		//

		String response = QUOTING.calculate( requestXML );
		system.debug( 'XML Response: ' + response );

		//
		// parse the response
		//

		DOM.Document doc = new DOM.Document();
		doc.load( response );

		DOM.XMLNode salesForceMsg = doc.getRootElement();
		DOM.XMLNode payload = salesForceMsg.getChildElement('Payload', SALESFORCE_MSG_NAMESPACE);
		DOM.XMLNode q = payload.getChildElement('Quote', SALESFORCE_MSG_NAMESPACE);
		DOM.XmlNode quoteLineItem = q.getChildElement('QuoteLineItem', SALESFORCE_MSG_NAMESPACE);
		DOM.XmlNode quoteLineItemSchedule = quoteLineItem.getChildElement('QuoteLineItemSchedule', SALESFORCE_MSG_NAMESPACE);
	
		String pricePerDay = quoteLineItemSchedule.getChildElement('PricePerDay', SALESFORCE_MSG_NAMESPACE).getText();
		String prorateTotalPrice = quoteLineItemSchedule.getChildElement('ProrateTotalPrice', SALESFORCE_MSG_NAMESPACE).getText();
		String prorateUnitPrice = quoteLineItemSchedule.getChildElement('ProrateUnitPrice', SALESFORCE_MSG_NAMESPACE).getText();
		String prorateYearTotalPrice = quoteLineItemSchedule.getChildElement('ProrateYearTotalPrice', SALESFORCE_MSG_NAMESPACE).getText();
		String prorateYearUnitPrice = quoteLineItemSchedule.getChildElement('ProrateYearUnitPrice', SALESFORCE_MSG_NAMESPACE).getText();
		String startDate = quoteLineItemSchedule.getChildElement('StartDate', SALESFORCE_MSG_NAMESPACE).getText();
		String endDate = quoteLineItemSchedule.getChildElement('EndDate', SALESFORCE_MSG_NAMESPACE).getText();
		String year = quoteLineItemSchedule.getChildElement('Year', SALESFORCE_MSG_NAMESPACE).getText();

		system.assertEquals('8.2191780822', pricePerDay);
		system.assertEquals('3000.00', prorateTotalPrice);
		system.assertEquals('3000.00', prorateUnitPrice);
		system.assertEquals('3000.00', prorateYearTotalPrice);
		system.assertEquals('3000.00', prorateYearUnitPrice);
		system.assertEquals('2011-01-20', startDate);
		system.assertEquals('2012-01-19', endDate);
		system.assertEquals('1', year);
	}
	*/

	/**
	 * method for creating quotes
	 *
	 * @param String quoteType
	 * @param Date startDate
	 * @param Date endDate
	 * @param Integer term
	 * @return Quote__c
	 **/
	
	private static Quote__c createQuote(Id opportunityId, String quoteType, Date startDt, Date endDt, Integer term )
	{
		return createQuote(opportunityId, quoteType, startDt, endDt, term , 3000.00, 'No');
	}

	/**
	 * method for creating quotes
	 *
	 * @param String quoteType
	 * @param Date startDate
	 * @param Date endDate
	 * @param Integer term
	 * @param Double amount
	 * @param String payNow
	 * @return Quote__c
	 **/
	
	private static Quote__c createQuote(Id opportunityId, String quoteType, Date startDt, Date endDt, Integer term, Decimal amount, String payNow )
	{
		Quote__c quote = new Quote__c();
		quote.Amount__c = amount;
		quote.CurrencyIsoCode = 'USD';
		quote.EndDate__c = endDt;
		quote.OpportunityId__c = opportunityId;
		quote.PayNow__c = payNow;
		quote.PricebookId__c = PRICEBOOK.Id;
		quote.StartDate__c = startDt;
		quote.Term__c = term;
		quote.Type__c = quoteType;
		insert quote;

		return quote;
	}

	/**
	 * method for create quote line items
	
	 * @param   Id quoteId
	 * @param   Date startDt
	 * @param   Date endDt
	 * @param   Integer quantity
	 * @param   Integer term
	 * @param   Decimal totalPrice
	 * @param   Decimal unitPrice
	 * @param   Decimal salesPrice
	 * @return  QuoteLineItem__c
	 **/
	
	private static QuoteLineItem__c createQuoteLineItem( Id quoteId, Date startDt, Date endDt, Integer quantity, Integer term, Decimal totalPrice, Decimal unitPrice, Decimal salesPrice, String productFamily )
	{
		QuoteLineItem__c quoteLineItem = new QuoteLineItem__c();
		quoteLineItem.Configured_SKU__c = 'RH012345';
		quoteLineItem.ContractNumbers__c = '12345';
		quoteLineItem.EndDate__c = endDt;
		quoteLineItem.Name = 'Shared Storage';
		quoteLineItem.NewOrRenewal__c = 'New';
		quoteLineItem.opportunityId__c = OPPORTUNITY.Id;
		quoteLineItem.PricebookEntryId__c = priceBookEntry.Id;
		quoteLineItem.Pricing_Attributes__c = 'a=1; b=2; c=3';
		quoteLineItem.ProductDescription__c = 'Happy Fun Ball';
		quoteLineItem.ProductFamily__c = productFamily;
		quoteLineItem.Quantity__c = quantity;
		quoteLineItem.QuoteId__c = quoteId;
		quoteLineItem.StartDate__c = startDt;
		quoteLineItem.Term__c = term;
		quoteLineItem.TotalPrice__c = totalPrice;
		quoteLineItem.UnitPrice__c = unitPrice;
		quoteLineItem.YearlySalesPrice__c = salesPrice;
		insert quoteLineItem;

		return quoteLineItem;
	}


	/**
	 * retrieves a quote and the line item schedules
	 *
	 * @param Id quoteId
	 * @return quote
	 **/
	private static Quote__c getQuote( Id quoteId )
	{
		Quote__c quote = [SELECT Id
				, Amount__c
				, Year1PaymentAmount__c
				, Year2PaymentAmount__c
				, Year3PaymentAmount__c
				, Year4PaymentAmount__c
				, Year5PaymentAmount__c
				, Year6PaymentAmount__c
				, (SELECT Id
					, CurrencyIsoCode
					, EndDate__c
					, Name
					, PricePerDay__c
					, ProrateTotalPrice__c
					, ProrateUnitPrice__c
					, ProrateYearTotalPrice__c
					, ProrateYearUnitPrice__c
					, QuoteLineItemId__c
					, StartDate__c
					, Type__c
					, Year__c
				 FROM QuoteLineItemSchedule__r)
			FROM Quote__c
			WHERE Id =: quoteId
		];

		return quote;
	}
}