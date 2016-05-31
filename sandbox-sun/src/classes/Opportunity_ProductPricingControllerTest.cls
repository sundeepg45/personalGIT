/**
 * This class contains unit tests for validating the Opportunity_ProductPricingControllerTest class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2015-11-17
 * @author Bryan Bosely <bbosely@redhat.com>
 * Bill Riemers <briemers@redhat.com>
 * 2015-11-17 - Added rounding tests
 * 2015-10-29 - Testing of new will deactivate quotes methods
 * 2015-10-05 - Updated for refactoring and forecasting
 * 2012-07-12 - Updated to add support for override reason
 * 2012-03-15 - Refactoring
 * Abhijeet Anand
 * 2011-09-15 - Enhancement of code coverage
 * Bryan Bosely <bbosely@redhat.com> 
 * 2010-09-08 - Commented out a test method.  - ToDo Fix the pricing service class to work when testing
 * Scott Coleman <scoleman@redhat.com>
 * 2013-07-15 - Implemented Opp Lock
 */
@isTest
private class Opportunity_ProductPricingControllerTest {
	static Account account { get {
		if(account == null) {
			// create an account
			account = new Account(
				BillingCity = 'Raleigh',
				BillingCountry = 'IN',
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

	static Pricebook2 priceBook { get {
		if(priceBook == null) {
			// get the id of the standard price book
			priceBook= new Pricebook2(Id = Test.getStandardPricebookId());//[SELECT Id FROM PriceBook2 WHERE isStandard = true];
		}
		return priceBook;
	}}

	static Pricebook2 globalPriceBook { get {
		if(globalPriceBook == null) {
			// get the id of the global price book
			globalPriceBook= new Pricebook2(Name = 'Global Price Book', isActive = TRUE);
			insert globalPriceBook;//[SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book'];
		}
		return globalPriceBook;
	}}

	static Product2 product { get {
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

	static PricebookEntry priceBookEntry { get {
		if(priceBookEntry == null) {
			// create a pricebook entry for the standard pricebook
			priceBookEntry = new PricebookEntry(
				CurrencyIsoCode = 'USD',
				isActive = true,
				Pricebook2Id = priceBook.Id,
				Product2Id = product.Id,
				UnitPrice = 2000.00);
			insert priceBookEntry;
		}
		return priceBookEntry;
	}}

	static PricebookEntry priceBookEntry2 { get {
		if(priceBookEntry2 == null) {
			// create a pricebook entry for the global pricebook
			priceBookEntry2 = new PricebookEntry(
				CurrencyIsoCode = priceBookEntry.CurrencyIsoCode,
				IsActive = priceBookEntry.IsActive,
				Pricebook2Id = globalPriceBook.Id,
				Product2Id = priceBookEntry.Product2Id,
				UnitPrice = priceBookEntry.UnitPrice);
			insert priceBookEntry2;
		}
		return priceBookEntry2;
	}}

	static Opportunity opportunity { get {
		if(opportunity == null) {
			opportunity = new Opportunity(
				AccountId = account.Id,
				CloseDate = Date.newInstance(2009, 11, 10),
				Country_Of_Order__c = 'US',
				CurrencyIsoCode = 'USD',
				Name = 'Opportunity',
				OpportunityType__c = 'Standard',
				PaymentType__c = 'NA Purchase Order',
				Pricebook2Id = globalPriceBook.Id,
				StageName = 'Test Stage',
				QuoteNumber__c = '3');
			insert opportunity;
		}
		return opportunity;
	}}

	static List<OpportunityLineItem> lineItems { get {
		if(lineItems == null) {
			// create an opportunity line item
			OpportunityLineItem i = new OpportunityLineItem(
				ActualStartDate__c = Date.newInstance(2009, 11, 11),
				ActualEndDate__c = Date.newInstance(2010, 11, 10),
				ActualTerm__c = 365,
				OpportunityId = opportunity.Id,
				PricebookEntryId = priceBookEntry2.Id,
				Quantity = 2,
				UnitPrice = 2000.00765,
				PriceOverrideReason__c = null,
				ScheduleLocked__c = true,
				Description=product.Description);
			lineItems = new List<OpportunityLineItem>{
				i,i.clone(),i.clone()
			};
		}
		return lineItems;
	}}

	static OpportunityLineItem lineItem { get {
		if(lineItem == null) {
			lineItem = lineItems[0];
			upsert lineItem;
		}
		return lineItem;
	}}

	static Quote__c quote {
		get {
			if(quote == null) {
				quote = new Quote__c(
					Amount__c = lineItem.UnitPrice,
					CurrencyIsoCode = opportunity.CurrencyIsoCode,
					IsActive__c = true,
					OpportunityId__c = lineItem.OpportunityId,
					PayNow__c = 'Yes',
					QuoteOwnerId__c = UserInfo.getUserId());
				insert quote;
			}
			return quote;
		}
	}

	static Opportunity_ProductPricingController createController(Id oppId) {
		// add the opportunity id
		ManageProductsPageSetting__c setting = new  ManageProductsPageSetting__c();
		setting.Name = 'RowsPerPage';
		setting.RowsPerPage__c = 50;
		Insert setting;
		ApexPages.currentPage().getParameters().put('id',oppId);
		return new Opportunity_ProductPricingController();
	}

	@isTest (SeeAllData=false)
	static void testQueryStringParams() {
		Opportunity_ProductPricingController controller = createController(opportunity.Id);
		System.assertEquals(opportunity.Id, controller.opportunityId);
		controller.getIsPartnerUser();
	}

	@isTest (SeeAllData=false)
	static void testOptions() {
		Opportunity_ProductPricingController controller = createController(opportunity.Id);
		System.assertNotEquals(0,controller.getNewOrRenewalOptions().size(),'Renewal options not created');
		System.assertNotEquals(0,controller.getPriceOverrideReasonOptions().size(),'Price Override Reason options not created');
	}

	static void testOpportunity(Id oppId) {
		Opportunity_ProductPricingController controller = createController(oppId);
		// ensure we can retrieve the opportunity
		System.assertEquals('Opportunity',controller.opportunity.Name);
		System.assertEquals(globalPriceBook.Id,controller.opportunity.pricebook2Id);
		System.assertEquals(1,controller.opportunity.OpportunityLineItems.size());
		System.assertEquals(1,controller.opportunity.Quotes__r.size());
	}

	static void testAddProduct(Id oppId) {
		Savepoint sp = Database.setSavepoint();
		Opportunity_ProductPricingController controller = createController(lineItem.opportunityId);
		//System.assertEquals(1,controller.lineItems.size());

		// test failure due to no pricebook entry
		OpportunityLineItem xlineItem = controller.lineItem;
		xlineItem.Quantity = 3;
		xlineItem.UnitPrice = 1200.00;
		xlineItem.NewOrRenewal__c = 'New';

		controller.addProduct();
		//System.assertEquals(0,controller.lineItems.size());
		Quote__c q = [select IsActive__c from Quote__c where Id = :quote.Id];
		System.assert(q.IsActive__c,'Quote is not active');

		// test success
		xlineItem = controller.lineItem;
		xlineItem.PricebookEntryId = priceBookEntry2.Id;
		xlineItem.Quantity = 3;
		xlineItem.UnitPrice = 1200.00;
		xlineItem.NewOrRenewal__c = 'New';

		controller.addProduct();
		//System.assertEquals(0,controller.lineItems.size(),'Insert of lineItem failed');
		q = [select IsActive__c from Quote__c where Id = :quote.Id];
		System.assert(! q.IsActive__c,'Quote is still active');
		Database.rollback(sp);
	}

	@isTest (SeeAllData=false)
	static void testAddConfiguredProduct() {
		Opportunity_ProductPricingController controller = createController(lineItem.opportunityId);
		OpportunityLineItem xlineItem = controller.lineItem;
		xlineItem.Configured_SKU__c = 'RH1493836';
		xlineItem.Quantity = 3;
		xlineItem.UnitPrice = 1200.00;
		xlineItem.NewOrRenewal__c = 'New';

		Test.startTest();
		controller.addConfiguredProduct();
		Test.stopTest();

//		System.assertEquals(2,controller.lineItems.size());
	}

	static void testAddConfiguredProductNoSKU(Id oppId) {
		Savepoint sp = Database.setSavepoint();
		Opportunity_ProductPricingController controller = createController(oppId);
		System.assertEquals(1,controller.getLineItems().size());

		OpportunityLineItem xlineItem = controller.lineItem;
		xlineItem.Quantity = 3;
		xlineItem.UnitPrice = 1200.00;
		xlineItem.NewOrRenewal__c = 'New';

		controller.addConfiguredProduct();
		//System.assertEquals(1,controller.lineItems.size());
		Quote__c q = [select IsActive__c from Quote__c where Id = :quote.Id];
		System.assert(q.IsActive__c,'Quote is not active');
		Database.rollback(sp);
	}

	static void testRemoveProduct(Id oppId) {
		Savepoint sp = Database.setSavepoint();
		Opportunity_ProductPricingController controller = createController(oppId);
		//System.assertNotEquals(0,controller.lineItems.size());
		for( Opportunity_ProductPricingController.PricingLineItem xlineItem : controller.getLineItems()) {
			xlineItem.isBeingRemoved = true;
		}
		controller.remove();
		//System.assertEquals(0,controller.lineItems.size());
		Quote__c q = [select IsActive__c from Quote__c where Id = :quote.Id];
		//System.assert(! q.IsActive__c,'Quote is still active');
		Database.rollback(sp);
	}

	static void testSaveProducts(Id oppId) {
		Savepoint sp = Database.setSavepoint();
		Opportunity_ProductPricingController controller = createController(oppId);
		Map<Id,Decimal> oppLinePrices = null;
		// update the quantity on all line items to 10
		for (Opportunity_ProductPricingController.PricingLineItem xlineItem : controller.getLineItems()) {
			xlineItem.OpportunityLineItem.Quantity = 10;
			Decimal unitPrice = xlineItem.unitPrice; 
			if(oppLinePrices == null) {
				oppLinePrices = new Map<Id,Decimal>();
				unitPrice = xlineItem.OpportunityLineItem.UnitPrice += 100;
			}
			oppLinePrices.put(xlineItem.OpportunityLineItem.Id,unitPrice);
		}

		// verify that we are returned to the opportunity page on success
		PageReference PAGE_REF = controller.save();
		//System.assertEquals('/' + oppId, PAGE_REF.getUrl());

		// ensure that our change was saved
		for (OpportunityLineItem xlineItem : [SELECT Quantity,UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :lineItem.Opportunity.Id]) {
			System.assertEquals(10,xlineItem.Quantity,'line item not updated');
			Decimal unitPrice = oppLInePrices.get(xlineItem.Id);
			System.assertEquals(unitPrice,xlineItem.UnitPrice,'invalid price');
		}
		Quote__c q = [select IsActive__c from Quote__c where Id = :quote.Id];
		//System.assert(! q.IsActive__c,'Quote is still active');
		Database.rollback(sp);
	}

	@isTest (SeeAllData=false)
	static void testActions() {
		testOpportunity(quote.OpportunityId__c);
		testAddProduct(quote.OpportunityId__c);
		test.startTest();
		testAddConfiguredProductNoSKU(quote.OpportunityId__c);
		testRemoveProduct(quote.OpportunityId__c);
		testSaveProducts(quote.OpportunityId__c);
		test.stopTest();
	}

	@isTest (SeeAllData=false)
	static void testPricing() {
		Opportunity_ProductPricingController controller = createController(quote.OpportunityId__c);
		// this is strictly coverage testing

		Test.startTest();
		controller.Pricing();
		Test.stopTest();
	}

	@isTest (SeeAllData=false)
	static void testPricingOverrideReason() {
		upsert lineItems;
		Opportunity_ProductPricingController controller = createController(quote.OpportunityId__c);
		// test that if no base price is set the price override reason is null
		Opportunity_ProductPricingController.updateOverrideReasons(controller.opportunity,controller.getLineItems());
		System.assertEquals(null,controller.opportunity.PriceOverrideReason__c);
		for(Opportunity_ProductPricingController.PricingLineItem line : controller.getLineItems()) {
			System.assertEquals(null,line.opportunityLineItem.PriceOverrideReason__c);
			System.assertEquals('',line.priceOverrideReason);
		}
		// test that if base price is equal to the unit price the override reason is NO_OVERRIDE_REASON
		controller.getLineItems()[0].opportunityLineItem.Base_Price__c = lineItems[0].UnitPrice;
		controller.getLineItems()[1].opportunityLineItem.Base_Price__c = lineItems[1].UnitPrice;
		Opportunity_ProductPricingController.updateOverrideReasons(controller.opportunity,controller.getLineItems());
		System.assertEquals(Opportunity_ProductPricingController.NO_OVERRIDE_REASON,controller.opportunity.PriceOverrideReason__c);
		for(Opportunity_ProductPricingController.PricingLineItem line : controller.getLineItems()) {
			if(line.opportunityLineItem.Base_Price__c == null) {
				System.assertEquals(null,line.opportunityLineItem.PriceOverrideReason__c);
			}
			else {
				System.assertEquals(line.opportunityLineItem.UnitPrice,line.opportunityLineItem.Base_Price__c);
				System.assertEquals(Opportunity_ProductPricingController.NO_OVERRIDE_REASON,line.opportunityLineItem.PriceOverrideReason__c);
			}
			System.assertEquals('',line.priceOverrideReason);
		}
		// test that if base price is greater than the unit price the override reason is kept
		controller.opportunity.PriceOverrideReason__c = null;
		controller.getLineItems()[0].opportunityLineItem.Base_Price__c = lineItems[0].UnitPrice*2.0;
		controller.getLineItems()[0].priceOverrideReason = 'Cookie';
		controller.getLineItems()[1].opportunityLineItem.Base_Price__c = lineItems[1].UnitPrice;
		controller.getLineItems()[1].priceOverrideReason = 'Cookie 2';
		controller.getLineItems()[2].priceOverrideReason = 'Cookie 3';
		Opportunity_ProductPricingController.updateOverrideReasons(controller.opportunity,controller.getLineItems());
		System.assertEquals('Cookie',controller.opportunity.PriceOverrideReason__c);
		for(Opportunity_ProductPricingController.PricingLineItem line : controller.getLineItems()) {
			if(line.opportunityLineItem.Base_Price__c == null) {
				System.assertEquals(null,line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('',line.priceOverrideReason);
			}
			else if(line.opportunityLineItem.Base_Price__c == line.opportunityLineItem.UnitPrice) {
				System.assertEquals(Opportunity_ProductPricingController.NO_OVERRIDE_REASON,line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('',line.priceOverrideReason);
			}
			else {
				System.assertEquals('Cookie',line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('Cookie',line.priceOverrideReason);
			}
		}
		// test that if that the override reason is copied where needed
		controller.opportunity.PriceOverrideReason__c = null;
		controller.getLineItems()[0].opportunityLineItem.Base_Price__c = lineItems[0].UnitPrice*2.0;
		controller.getLineItems()[0].priceOverrideReason = '';
		controller.getLineItems()[1].opportunityLineItem.Base_Price__c = lineItems[1].UnitPrice*2.0;
		controller.getLineItems()[1].priceOverrideReason = 'Cookie';
		controller.getLineItems()[2].priceOverrideReason = '';
		Opportunity_ProductPricingController.updateOverrideReasons(controller.opportunity,controller.getLineItems());
		System.assertEquals('Cookie',controller.opportunity.PriceOverrideReason__c);
		for(Opportunity_ProductPricingController.PricingLineItem line : controller.getLineItems()) {
			if(line.opportunityLineItem.Base_Price__c == null) {
				System.assertEquals(null,line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('',line.priceOverrideReason);
			}
			else if(line.opportunityLineItem.Base_Price__c == line.opportunityLineItem.UnitPrice) {
				System.assertEquals(Opportunity_ProductPricingController.NO_OVERRIDE_REASON,line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('',line.priceOverrideReason);
			}
			else {
				System.assertEquals('Cookie',line.opportunityLineItem.PriceOverrideReason__c);
				System.assertEquals('Cookie',line.priceOverrideReason);
			}
		}
		// Now we will actually try a test where the results are saved
		controller.opportunity.PriceOverrideReason__c = null;
		controller.getLineItems()[0].opportunityLineItem.Base_Price__c = lineItems[0].UnitPrice;
		controller.getLineItems()[0].priceOverrideReason = '';
		controller.getLineItems()[1].opportunityLineItem.Base_Price__c = lineItems[1].UnitPrice*2.0;
		controller.getLineItems()[1].priceOverrideReason = 'Cookie';
		controller.getLineItems()[2].priceOverrideReason = '';
		controller.save();
		System.assertEquals(null,controller.opportunity.PriceOverrideReason__c);
		test.startTest();
		// Remove the line item with NO_OVERRIDE_REASON, and see the opportunity updates
		controller.remove();
		controller.getRegion();
		controller.Next();
		controller.Previous();
		controller.First();
		controller.Last();
		System.assertEquals(null,controller.opportunity.PriceOverrideReason__c);
		for(Opportunity_ProductPricingController.PricingLineItem line : controller.getLineItems()) {
			//System.assertEquals(null,line.opportunityLineItem.Base_Price__c);
			//System.assertEquals(null,line.opportunityLineItem.PriceOverrideReason__c);
			//System.assertEquals('',line.priceOverrideReason);
		}
		test.stopTest();
	}

	@isTest (SeeAllData=false)
	static void testCancel() {
		Opportunity_ProductPricingController c = createController(opportunity.Id);
		PageReference PAGE_REF = c.cancel();
		c.Next();
		c.Previous();
		c.First();
		c.Last();
		System.assertEquals('/' + opportunity.Id, PAGE_REF.getUrl());
	}

	@isTest (SeeAllData=false)
	static void coverageTest() {
		Opportunity_ProductPricingController c = createController(opportunity.Id);
		c.clearEntitleToInfo();
		c.copyEntitleToInfo();
		c.Next();
		c.Previous();
		c.First();
		c.Last();
		System.assertNotEquals(null,c.getDecimal());
		System.assertNotEquals(null,c.getThousandsSep());
		System.assertNotEquals(null,Opportunity_ProductPricingController.currentUser);
		System.assertNotEquals(null,c.useConfiguredSKUs);
		Boolean b = c.unitPriceWillDeactivateQuotes;
		b = c.getPricingWillDeactivateQuotes();
		b = c.newOrRenewalWillDeactivateQuotes;
		b = c.contractNumbersWillDeactivateQuotes;
		b = c.entitleToAccountWillDeactivateQuotes;
		b = c.entitleToSalesAccountWillDeactivateQuotes;
		b = c.entitleToAddressWillDeactivateQuotes;
		b = c.entitleToContactWillDeactivateQuotes;
		b = c.getCopyEntitleToWillDeactivateQuotes();
		b = c.getClearEntitleToWillDeactivateQuotes();
	}
	
	@isTest
	static void entitleManagement(){
		 // Variable to store Recordtype id
		string recordtypeid;
		//Create Sales Account
		Account salesAccountOne = new Account();
		Account salesAccountTwo = new Account();
		List<Account> salesAccountList = new List<Account>();
		//Fetch account record type
		recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		salesAccountOne.Name = 'Test Sales Account1';
		salesAccountOne.CurrencyIsoCode = 'USD';
		salesAccountOne.RecordTypeId = recordTypeId;
		salesAccountList.add(salesAccountOne);
		
		//Fetch account record type
		recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		salesAccountTwo.Name = 'Test Sales Account2';
		salesAccountTwo.CurrencyIsoCode = 'USD';
		salesAccountTwo.RecordTypeId = recordTypeId;
		salesAccountList.add(salesAccountTwo);
		
		// insert Sales Accounts
		insert salesAccountList;
		
		//Create Contact
		Contact contactAccount = new Contact(LastName = 'title',AccountId = salesAccountList[0].Id,Email = 'xyz@123.com');
		insert contactAccount;
		system.assertNotEquals(null,[select AccountId from Contact where Id =:contactAccount.Id].AccountId);
		
		//Generate sample EBS Account 
		EBS_Account__c ebsAccount = new EBS_Account__c(Name='1234',Sales_Account__c = salesAccountList[0].Id,CDH_Party_Number__c='77777777',Credit_Hold__c=false,EBS_Account_Description__c='test account',EBS_Party_Name__c='test ebs party',EBS_Party_Number__c='1233',Last_Credit_Review_Date__c=System.Today(),Next_Credit_Review_Date__c=System.Today(),Primary_EBS_Account__c=false,Status__c='Active');		
		
		//Inserting EBS Account
		Insert ebsAccount;
		system.assertNotEquals(null,[select CDH_Party_Number__c from EBS_Account__c where Id =:ebsAccount.Id].CDH_Party_Number__c);
		
		//Create Address
		Address__c addressRecord = new Address__c(Sales_Account__c = salesAccountList[0].Id,Address_Line1__c = '150, 14th main',Bill_To_Address__c = true,Entitle_To_Address__c = false,Sold_To_Address__c =false,Ship_To_Address__c =false ,Province__c = '' ,Zip_Postal_Code__c ='560050', Country__c = 'IN', State__c ='Karnataka', City__c = 'Bangalore',CDH_Party_Site_Number__c = '1234',status__c = 'Active');
		Insert addressRecord;
		
		system.assertNotEquals(null,[select Id from Address__c where Id =:addressRecord.Id].Id);
		
		
		Test.startTest();
			Opportunity_ProductPricingController.salesAccountSearch('Test Sales Account');
			Opportunity_ProductPricingController.EBSAccountSearch(string.valueOf(salesAccountList[0].Id));
			Opportunity_ProductPricingController.AddressSearch(string.valueOf(salesAccountList[0].Id));
			Opportunity_ProductPricingController.ContactSearch(string.valueOf(salesAccountList[0].Id));
		Test.stopTest();
	}

	@isTest
	static void willDeactivateTest() {
		upsert lineItems;
		Opportunity_ProductPricingController c = createController(quote.OpportunityId__c);
		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.clear();

		System.assert(!c.unitPriceWillDeactivateQuotes);
		System.assert(!c.getPricingWillDeactivateQuotes());
		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('unitprice');
		System.assert(c.unitPriceWillDeactivateQuotes);
		System.assert(c.getPricingWillDeactivateQuotes());

		System.assert(!c.newOrRenewalWillDeactivateQuotes);
		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('neworrenewal__c');
		System.assert(c.newOrRenewalWillDeactivateQuotes);

		System.assert(!c.contractNumbersWillDeactivateQuotes);
		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('contract_numbers__c');
		System.assert(c.contractNumbersWillDeactivateQuotes);

		System.assert(!c.entitleToAccountWillDeactivateQuotes);
		System.assert(!c.entitleToSalesAccountWillDeactivateQuotes);
		System.assert(!c.entitleToAddressWillDeactivateQuotes);
		System.assert(!c.entitleToContactWillDeactivateQuotes);
		System.assert(!c.getCopyEntitleToWillDeactivateQuotes());
		System.assert(!c.getClearEntitleToWillDeactivateQuotes());
		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('entitle_to_account__c');
		System.assert(c.entitleToAccountWillDeactivateQuotes);
		System.assert(!c.entitleToSalesAccountWillDeactivateQuotes);
		System.assert(!c.entitleToAddressWillDeactivateQuotes);
		System.assert(!c.entitleToContactWillDeactivateQuotes);
		c.getCopyEntitleToWillDeactivateQuotes();
		c.getClearEntitleToWillDeactivateQuotes();

		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('entitle_to_sales_account__c');
		System.assert(c.entitleToAccountWillDeactivateQuotes);
		System.assert(c.entitleToSalesAccountWillDeactivateQuotes);
		System.assert(!c.entitleToAddressWillDeactivateQuotes);
		System.assert(!c.entitleToContactWillDeactivateQuotes);
		c.getCopyEntitleToWillDeactivateQuotes();
		c.getClearEntitleToWillDeactivateQuotes();

		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('entitle_to_address__c');
		System.assert(c.entitleToAccountWillDeactivateQuotes);
		System.assert(c.entitleToSalesAccountWillDeactivateQuotes);
		System.assert(c.entitleToAddressWillDeactivateQuotes);
		System.assert(!c.entitleToContactWillDeactivateQuotes);
		c.getCopyEntitleToWillDeactivateQuotes();
		c.getClearEntitleToWillDeactivateQuotes();

		Opportunity_ProductPricingController.deactivateQuotesOnChangeFieldPaths.add('entitle_to_contact__c');
		System.assert(c.entitleToAccountWillDeactivateQuotes);
		System.assert(c.entitleToSalesAccountWillDeactivateQuotes);
		System.assert(c.entitleToAddressWillDeactivateQuotes);
		System.assert(c.entitleToContactWillDeactivateQuotes);
		c.getCopyEntitleToWillDeactivateQuotes();
		c.getClearEntitleToWillDeactivateQuotes();
	}
}