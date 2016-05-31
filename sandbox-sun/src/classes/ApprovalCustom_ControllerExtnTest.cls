/**
 * Test class for ApprovalCustom_ControllerExtension.
 *
 * @version 2013-01-29
 * @author Bill Riemers <briemers@redhat.com>
 * 2012-08-01 - Set flag on user record to pass validation rule
 * Scott Coleman <scoleman@redhat.com>
 * 2013-01-29 - Added test for Credit__c.Opportunity_Amount__c
 * 2012-10-02 - Added proxy approver property
 */
@isTest
private class ApprovalCustom_ControllerExtnTest {

	static RecordType paymentTermsRT {
		get {
			if(paymentTermsRT == null) {
				paymentTermsRT = [
					select Name
					from RecordType
					where Name='Payment Terms'
						and SObjectType = 'ApprovalCustom__c' ];
			}
			return paymentTermsRT;
		}
	}

	static RecordType naSalesOpportunityRT {
		get {
			if(naSalesOpportunityRT == null) {
				naSalesOpportunityRT = [
					select Id
					from RecordType
					where Name='NA Sales Opportunity'
						and SObjectType = 'Opportunity' ];
			}
			return naSalesOpportunityRT;
		}
	}

	static Account acc {
		get {
			if(acc == null) {
				acc = new Account(Name='Testing');
				insert acc;
			}
			return acc;
		}
	}

	static Opportunity opp {
		get {
			if(opp == null) {
				opp = new Opportunity(
					Name='Testing',
					AccountId=acc.Id,
					FulfillmentChannel__c = 'Direct - VAR/VAD',
					Country_of_Order__c = 'United States',
					CurrencyIsoCode = 'USD',
					Pay_Now__c = 'Yes',
					CloseDate=System.today(),
					OpportunityType__c='Standard',
					StageName='Prepare',
					RecordTypeId = naSalesOpportunityRT.Id,
					Amount = 3000.00 );
				insert opp;
			}
			return opp;
		}
	}

	static Quote__c quote {
		get {
			if(quote == null) {
				quote = new Quote__c(
					OpportunityId__c = opp.Id,
					PayNow__c = 'Yes',
					CurrencyIsoCode = 'USD',
					Amount__c = 3000.00,
					QuoteOwnerId__c = UserInfo.getUserId());
				insert quote;
			}
			return quote;
		}
	}

	static QuoteLineItem__c quoteLineItem {
		get {
			if(quoteLineItem == null) {
				quoteLineItem = new QuoteLineItem__c(
					CurrencyIsoCode = 'USD',
					ProductCode__c = 'RH01',
					Configured_SKU__c = 'X001',
					ProductDescription__c = 'Happy Quote',
					Quantity__c = 1.0,
					UnitPrice__c = 0,
					TotalPrice__c = 0,
					QuoteId__c = quote.Id);
				insert quoteLineItem;
			}
			return quoteLineItem;
		}
	}

	static ApprovalCustom__c app {
		get {
			if(app == null) {
				app = new ApprovalCustom__c(
					Opportunity__c = opp.Id,
					RecordType = paymentTermsRT,
					RecordTypeId=paymentTermsRT.Id,
					ApprovedBy__c = null,
					ApprovalStatus__c = 'New',
					AssignApprovalTo__c = null,
					Quote__c = quote.Id);
				insert app;
			}
			return app;
		}
	}

	static testMethod void quoteTest() {
		User u = new User(Id=UserInfo.getUserId(),AprvrPaymentTerms__c=true);
		System.runAs(u) {
			update u;
		}
		System.assertNotEquals(null,quoteLineItem.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(app);
		ApprovalCustom_ControllerExtension controller = new ApprovalCustom_ControllerExtension(sc);
		System.assertNotEquals(null,controller.getApprovalCustom());
		System.assertEquals(quote.Id,controller.getQuote().Id);
		System.assert(! controller.getIsBmQuote());
		System.assertEquals(acc.Id,controller.getQuoteAccount().Id);
		System.assertEquals(null,controller.getQuoteDescription());
		System.assert(! controller.assignApprovalToOptions.isEmpty());
		System.assert(! controller.getIsProxyApprover());
		System.assertNotEquals(null,controller.save());
		controller.getApprovalCustom().ApprovalStatus__c = 'Approved';
		System.assertEquals(quoteLineItem.Id,controller.getQuoteLineItems()[0].Id);
		System.assertNotEquals(null,controller.save());
		System.assertEquals(0,[select Count() from Credit__c where Opportunity__c = :opp.Id]);
	}

	static testMethod void bmQuoteTest() {
		ApexPages.StandardController sc = null;
		try {
			for(ApprovalCustom__c o : Database.query(
				'select Id from ApprovalCustom__c '+
				'where Status__c != \'Approved\' and BigMachines_Quote__c in ('+
					'select BigMachines__Quote__c '+
					'from BigMachines__Quote_Product__c) '+
				'order by ApprovalCustom__c desc limit 1'))
			{
				sc = new ApexPages.StandardController(o);
			}
		}
		catch(Exception e) {}
		if(sc != null) {
			ApprovalCustom_ControllerExtension controller = new ApprovalCustom_ControllerExtension(sc);
			System.assert(controller.getIsBmQuote());
			System.assertEquals(null,controller.getQuote().Id);
			System.assertNotEquals(null,controller.quoteId);
			controller.getApprovalCustom().ApprovalStatus__c = 'Approved';
			System.assertNotEquals(null,controller.save());
			System.assertEquals(1,[select Count() from Credit__c where Opportunity__c = :opp.Id]);
			Credit__c credit = [select Opportunity_Amount__c from Credit__c where Opportunity__c = :opp.Id LIMIT 1];
			System.assertEquals(quote.Amount__c,credit.Opportunity_Amount__c);
		}
	}

	// This fakes out the BM quote part of the save to create a credit check record
	// so we can test that code even if there are no BM quotes available.
	static testMethod void fakeBmQuoteTest() {
		User u = new User(Id=UserInfo.getUserId(),AprvrPaymentTerms__c=true);
		System.runAs(u) {
			update u;
		}
//		OrderManagementControllerExtension.EXCLUDED_CREDIT_CHECK_COUNTRIES
		System.assertNotEquals(null,quoteLineItem.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(app);
		ApprovalCustom_ControllerExtension controller = new ApprovalCustom_ControllerExtension(sc);
		System.assertNotEquals(null,controller.getApprovalCustom());
		System.assertEquals(quote.Id,controller.getQuote().Id);
		controller.quote=controller.getQuote().clone(false,false,true,true);
		System.assertEquals(null,controller.getQuote().Id);
		System.assertNotEquals(null,controller.quoteId);
		controller.getApprovalCustom().ApprovalStatus__c = 'Approved';
		controller.quoteId = null;
		System.assertNotEquals(null,controller.save());
		System.assertEquals(1,[select Count() from Credit__c where Opportunity__c = :opp.Id]);
	}

	// Excluded country test
	static testMethod void excludeCountryTest() {
		User u = new User(Id=UserInfo.getUserId(),AprvrPaymentTerms__c=true);
		System.runAs(u) {
			update u;
		}
		for(String countryOfOrder : OrderManagementControllerExtension.EXCLUDED_CREDIT_CHECK_COUNTRIES) {
			opp.Country_of_Order__c = countryOfOrder;
			update opp;
			System.assertNotEquals(null,quoteLineItem.Id);
			ApexPages.StandardController sc = new ApexPages.StandardController(app);
			ApprovalCustom_ControllerExtension controller = new ApprovalCustom_ControllerExtension(sc);
			System.assertNotEquals(null,controller.getApprovalCustom());
			System.assertEquals(quote.Id,controller.getQuote().Id);
			controller.quote=controller.getQuote().clone(false,false,true,true);
			System.assertEquals(null,controller.getQuote().Id);
			System.assertNotEquals(null,controller.quoteId);
			controller.getApprovalCustom().ApprovalStatus__c = 'Approved';
			controller.quoteId = null;
			System.assertNotEquals(null,controller.save());
			System.assertEquals(0,[select Count() from Credit__c where Opportunity__c = :opp.Id]);
			break;
		}
	}
}