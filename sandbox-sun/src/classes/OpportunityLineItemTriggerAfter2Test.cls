/**
 * This is the test class for OpportunityLineItemTriggerAfter2.
 * 
 * @versio 2015-10-28
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-10-28 - created
 */
@isTest
private class OpportunityLineItemTriggerAfter2Test {
	static Opportunity opportunity { get {
		if(opportunity == null) {
			// create the source renewal opportunity
			opportunity = OpportunityLineItemTriggerBefore2Test.createOpportunity('Renewal Source Opportunity',null,null);
			opportunity.QuoteNumber__c = '3';
			insert opportunity;
		}
		return opportunity;
	}}

	static OpportunityLineItem lineItem { get {
		if(lineItem == null) {
			// create an opportunity line item for the source opportunity
			lineItem = OpportunityLineItemTriggerBefore2Test.createLineItem(opportunity.Id);
		}
		return lineItem;
	}}

	static BigMachines__Quote__c quote { get {
		if(quote == null) {
			quote = new BigMachines__Quote__c(
				BigMachines__Opportunity__c = opportunity.Id,
				BigMachines__Is_Primary__c = false,
				BigMachines__Account__c = opportunity.AccountId,
				BigMachines__Pricebook_Id__c = Renewal_Coterm.globalPriceBookId,
				BigMachines__Is_Forced_Sync__c = false,
				Contract_End_Date__c = Date.newInstance(Date.Today().year()+2, 11, 10),
				Contract_Start_Date__c = Date.newInstance(Date.Today().year()+1, 11, 10),
				Term_of_Contract__c = '365');
			insert quote;
		}
		return quote;
	}}

	static BigMachines__Quote_Product__c quoteProduct { get {
		if(quoteProduct == null) {
			quoteProduct = new BigMachines__Quote_Product__c(
				BigMachines__Quote__c = quote.Id,
				Scheduled_Locked__c = true,
				BigMachines__Product__c = OpportunityLineItemTriggerBefore2Test.product.Id,
				BigMachines__Quantity__c = 2,
				BigMachines_Contract_Number__c = 'abc123',
				BigMachines__Sales_Price__c = OpportunityLineItemTriggerBefore2Test.priceBookEntry.UnitPrice);
			insert quoteProduct;
		}
		return quoteProduct;
	}}

	@isTest (SeeAllData=true)
	static void deactivateQuotesTest() {
		OpportunityLineItem lineItem2 = lineItem.clone();
		Id quoteId = quoteProduct.BigMachines__Quote__c;
		quote.BigMachines__Is_Primary__c = true;
		update quote;

		System.assertEquals(1,[SELECT count() FROM BigMachines__Quote__c WHERE Id = :quoteId and BigMachines__Is_Primary__c = true],'Expected primary quote');

		OpportunityLineItemTriggerAfter2 afterTrigger = new OpportunityLineItemTriggerAfter2(
			new Map<Id,OpportunityLineItem>{lineItem.Id=>lineItem},
			new Map<Id,OpportunityLineItem>{lineItem2.Id=>lineItem2},
			false );

		OpportunityLineItemTriggerAfter2.deactivateQuotesOnChangeMap.put('UnitPrice','*UnitPrice*');
		Test.startTest();
		afterTrigger.deactivateQuotes();

		System.assertEquals(1,[SELECT count() FROM BigMachines__Quote__c WHERE Id = :quoteId and BigMachines__Is_Primary__c = true],'Expected primary quote');

		lineItem2.UnitPrice += lineItem.UnitPrice;

		afterTrigger.deactivateQuotes();
		Test.stopTest();

		System.assertEquals(1,[SELECT count() FROM BigMachines__Quote__c WHERE Id = :quoteId and BigMachines__Is_Primary__c = false],'Expected non-primary quote');

		// just to cover the exception code
		OpportunityLineItemTriggerAfter2.deactivateQuotesOnChangeMap.remove('UnitPrice');
		OpportunityLineItemTriggerAfter2.deactivateQuotesOnChangeMap.put('CatDog','CatDog');
		afterTrigger.deactivateQuotes();
	}

	@isTest (SeeAllData=true) // needed to access pricebooks
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('LineItem_After.',false);
		AbstractTrigger.insertMissing = 100;
		OpportunityLineItem lineItem0 = lineItem;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityLineItemTriggerAfter2.processTrigger(null,new Map<Id,OpportunityLineItem>{null=>lineItem0},false);
		// insert the lineItem, again with the triggers off
		insert lineItem;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('LineItem_After.',true);
		OpportunityLineItem lineItem1 = lineItem0.clone(true);
		OpportunityLineItem lineItem2 = lineItem0.clone(true);
		lineItem2.UnitPrice += lineItem.UnitPrice;
		Test.startTest();
		// insert test
		OpportunityLineItemTriggerAfter2.processTrigger(null,new Map<Id,OpportunityLineItem>{lineItem2.Id=>lineItem2},false);
		// update test
		OpportunityLineItemTriggerAfter2.processTrigger(new Map<Id,OpportunityLineItem>{lineItem1.Id=>lineItem0},new Map<Id,OpportunityLineItem>{lineItem2.Id=>lineItem2},false);
		// delete test
		OpportunityLineItemTriggerAfter2.processTrigger(new Map<Id,OpportunityLineItem>{lineItem1.Id=>lineItem1},null,false);
		// undelete test
		OpportunityLineItemTriggerAfter2.processTrigger(null,new Map<Id,OpportunityLineItem>{lineItem2.Id=>lineItem2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('LineItem_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		AbstractTriggerTest.deployTest('LineItem_After.',new List<OpportunityLineItem>{lineItem});
	}
}