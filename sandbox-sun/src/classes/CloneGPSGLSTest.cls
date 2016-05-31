/**
 * Test class for CloneGPSGLS.
 *
 * @author unknown
 * @version 2012-07-10
 * Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - SMR update
 * Nitesh Dokania
 * 2011-09-20 - Enhancement of code coverage.
 */
@IsTest
private class CloneGPSGLSTest {
	
	public static Opportunity OPPORTUNITY;
	public static OpportunityLineItem LINE_ITEM;

	@isTest(SeeAllData=true)
	public static void testCloneGPSGLS() {
		
		test.startTest();
		
		User u = new User(alias = 'st8912', email='standarduser8912@testorg.com',
		emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
		localesidkey='en_US', profileid = UserInfo.getProfileId(),
		timezonesidkey='America/Los_Angeles', username='standarduser8912@testorg.com');
		insert u;
		System.runAs(u)
		{
		
			Account account = new Account(Name='Test Account');
			insert account;
			
			// get the id of the standard price book
			Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
			String priceBookId = priceBook.Id;
			
			// create a product
			Product2 product = new Product2();
			product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
			product.IsActive = true;
			product.Name = 'Happy Fun Ball';
			product.ProductCode = 'HFB007';
			product.Family = 'GPS';
			insert product;
			
			// create a pricebook entry for the standard pricebook
			PricebookEntry priceBookEntry = new PricebookEntry();
			priceBookEntry.CurrencyIsoCode = 'USD';
			priceBookEntry.isActive = true;
			priceBookEntry.Pricebook2Id = priceBookId;
			priceBookEntry.Product2Id = product.Id;
			priceBookEntry.UnitPrice = 2000.00;
			insert priceBookEntry;
			String priceBookEntryId = priceBookEntry.Id;
			
			// create an opportunity
			OPPORTUNITY = new Opportunity();
			OPPORTUNITY.AccountId = account.Id;
			OPPORTUNITY.CloseDate = Date.newInstance(2009, 11, 10);
			OPPORTUNITY.Country_Of_Order__c = 'United Kingdom';
			OPPORTUNITY.CurrencyIsoCode = 'USD';
			OPPORTUNITY.Name = 'Opportunity';
			OPPORTUNITY.OpportunityType__c = 'Standard';
			OPPORTUNITY.PaymentType__c = 'NA Purchase Order';
			OPPORTUNITY.StageName = 'Test Stage';
			//OPPORTUNITY.Super_Region__c = 'EMEA';
			insert OPPORTUNITY;
			
			// create an opportunity line item
			LINE_ITEM = new OpportunityLineItem();
			LINE_ITEM.OpportunityId = OPPORTUNITY.Id;
			LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
			LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
			LINE_ITEM.ActualTerm__c = 365;
			LINE_ITEM.PricebookEntryId = priceBookEntryId;
			LINE_ITEM.Quantity = 2;
			LINE_ITEM.UnitPrice = 2000.00;
			LINE_ITEM.ScheduleLocked__c = true;
			insert LINE_ITEM;
			//LINE_ITEM_ID = LINE_ITEM.Id;
			System.debug('oppSuperRgion**'+OPPORTUNITY.Super_Region__c);
			//System.debug('lineitems****'+LINE_ITEM.PricebookEntryId.);

			List<Opportunity> oppList = new List<Opportunity>();
			oppList.add(OPPORTUNITY);
			new CloneGPSGLS().cloneOpportunity(oppList);
			
			test.stopTest();
		}
	}
}