/**
 * This is the controller used for testing LinkChannelOppController.
 *
 * @version 2015-05-08
 * @author unknown
 * Bill C Riemers <briemers@redhat.com>
 * 2015-05-08 - Revised to reduce queries and DML operations
 * 2013-02-19 - Update to allow deactivations of pricebooks
 * 2012-07-31 - Updated admin bypass to include partner related records.
 * Scott Coleman <scoleman@redhat.com>
 * 2014-04-25 - Now leaving Deal Registration flag alone if it's checked on target. (US45939)
 * 2013-05-28 - Now checking expected attributes of target opp quotes
 * 2012-09-13 - Removing Channel Load restriction on Touched flag logic
 * Nitesh Dokania:
 * 2011-09-11 - Code coverage enhanced and assert statements added
 */
@isTest
private class LinkChannelOppControllerTest {
	static final String GLOBAL_PRICE_BOOK_NAME = 'Global Price Book';

	static final Integer STANDARD_PRICE_BOOK_INDEX = 0;
	static final Integer GLOBAL_PRICE_BOOK_INDEX = 1;

	static LinkChannelOppController instance {
		set;
		get;
	}
	
	static void doInitializeInstance() {
		instance = new LinkChannelOppController();
	}

	static List<Pricebook2> priceBooks {
		get {
			if(priceBooks == null) {
				Map<Boolean,Pricebook2> priceBookMap = new Map<Boolean,Pricebook2>{
					false => new Pricebook2(Description='Global',IsActive=true,Name = GLOBAL_PRICE_BOOK_NAME),
					true => new Pricebook2(Description='Standard',IsActive=true,Name = 'Standard Price Book') };
				Pricebook2 standardPriceBook = null;
				for(Pricebook2 pb : [select IsActive,IsStandard,Name from Pricebook2 where IsStandard = true or Name = :GLOBAL_PRICE_BOOK_NAME]) {
					pb.IsActive = true;
					pricebookMap.put((pb.Name != GLOBAL_PRICE_BOOK_NAME),pb);
				}
				priceBooks = new List<Pricebook2>{pricebookMap.get(true),pricebookMap.get(false)};
				upsert priceBooks;
			}
			return priceBooks;
		}
	}

	static Product2 product {
		get {
			if (product == null) {
				product = new Product2(CurrencyIsoCode='USD',Name = 'Test Product',Family = 'GLS', IsActive = true);
				insert product;
			}
			return product;
		}
	}

	static List<PricebookEntry> priceBookEntries {
		get {
			if (priceBookEntries == null) {
				priceBookEntries = new List<PricebookEntry>();
				for(Pricebook2 pb : priceBooks) {
					priceBookEntries.add(new PricebookEntry(CurrencyIsoCode='USD',UseStandardPrice = false,Pricebook2Id = pb.Id,UnitPrice = 75.00,Product2Id = product.Id, IsActive=true));
				}
				insert priceBookEntries;
			}
			return priceBookEntries;
		}
	}

	static Account account {
		get {
			if(account == null) {
				account = new Account(Name = 'Test Account');
				insert account;
			}
			return account;
		}
	}

	static Opportunity doInsertOpportunity(String postfix) {
		return doInsertOpportunities(new List<String>{postfix})[0];
	}

	static List<Opportunity> doInsertOpportunities(List<String> suffixes) {
		
		List<Opportunity> opportunities = new List<Opportunity>();
		for(String suffix : suffixes) {
			opportunities.add(new Opportunity(
				Name = 'Test Opportunity #' + suffix,
				CurrencyIsoCode = 'USD',
				CloseDate = Date.today(),
				StageName = 'Test Stage'));
		}
		insert opportunities;
		
		List<Quote__c> activeQuotes = new List<Quote__c>();
		List<BigMachines__Quote__c> primaryQuotes = new List<BigMachines__Quote__c>();
		List<OpportunityLineItem> opptyLineItems = new List<OpportunityLineItem>();
		for(Opportunity opportunity : opportunities) {
			activeQuotes.add(new Quote__c(CurrencyIsoCode='USD',Amount__c=0,LastCalculatedDate__c=Datetime.newInstance(2009,1,1),IsActive__c=true,OpportunityId__c=opportunity.Id));
			primaryQuotes.add(new BigMachines__Quote__c(CurrencyIsoCode='USD',BigMachines__Total__c=0,BigMachines__Is_Primary__c=true,BigMachines__Opportunity__c=opportunity.Id));
			opptyLineItems.add(new OpportunityLineItem(OpportunityId = opportunity.Id,PricebookEntryId = priceBookEntries[STANDARD_PRICE_BOOK_INDEX].Id));
		}
		insert activeQuotes;
		insert primaryQuotes;
		insert opptyLineItems;
		
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>( [
			select OpportunityNumber__c 
			from Opportunity 
			where Id in :new Map<Id,Opportunity>(opportunities).keySet()]);
		List<Opportunity> retval = new List<Opportunity>();
		for(Opportunity opportunity : opportunities) {
			retval.add(oppMap.get(opportunity.Id));
		}
		return retval;
	}

	@isTest(SeeAllData=true)
	static void testTargetOpportunityId() {
		
		doInitializeInstance();
		Opportunity opportunity = doInsertOpportunity('1');
		
		System.assert(null == instance.targetOpportunityId);
		instance.targetOpportunityId = opportunity.Id;
		System.assertEquals(opportunity.Id, instance.targetOpportunityId);
	}

	@isTest(SeeAllData=true)
	static void testQuickSet() {
		
		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];
		instance.sourceOpportunityNumber = opportunity1.OpportunityNumber__c;
		instance.targetOpportunityId = opportunity2.Id;
		
		System.debug(instance.sourceOpportunity);
		System.debug(instance.targetOpportunity);
		instance.getReturnUrl();
		instance.cancel();
		
		System.assert(null != instance.targetOpportunity.OpportunityNumber__c);
		System.assert(null != instance.sourceOpportunity.Id);
		
		doInitializeInstance();
		System.debug(instance.targetOpportunity);
		System.assert(null == instance.targetOpportunity.OpportunityNumber__c);

		doInitializeInstance();
		System.debug(instance.sourceOpportunity);
		System.assert(null == instance.sourceOpportunity.Id);
	}
	
	@isTest(SeeAllData=true)
	static void testSearch() {

		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];
		instance.sourceOpportunityNumber = opportunity2.OpportunityNumber__c;
		instance.search();
		
		System.assertNotEquals(null, instance.sourceOpportunity, 'sourceOpportunity is null');
		System.assertNotEquals(null, instance.targetOpportunity, 'targetOpportunity is null');
	}

	@isTest(SeeAllData=true)
	static void testSaveChanges() {
		
		//create source and target opps
		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];

		//set any additional test values on the source and target opp and save
		opportunity1.Deal_Registration__c = false;
		opportunity2.Deal_Registration__c = true;
		update opportunities;
		
		Test.startTest();

		//exercise the class
		instance.sourceOpportunityNumber = opportunity1.OpportunityNumber__c;
		instance.targetOpportunityId = opportunity2.Id;
		instance.search();
		System.assertNotEquals(null, instance.sourceOpportunity, 'sourceOpportunity is null');
		System.assertNotEquals(null, instance.targetOpportunity, 'targetOpportunity is null');
		Decimal targetProbability = instance.targetOpportunity.Probability;
		String targetStageName = instance.targetOpportunity.StageName;
		instance.sourceOpportunity.StageName = 'Closed Booked';
		instance.sourceOpportunity.FulfillmentChannel__c = 'Direct - VAR/VAD';
		instance.targetOpportunity.FulfillmentChannel__c = 'Indirect - VAR/VAD';
		instance.saveChanges();

		Test.stopTest();
		
		// fetch saved target opp and check values
		instance.targetOpportunity = null;
		Opportunity fetchedTargetOpp = instance.targetOpportunity;
		Opportunity sourceOpp = instance.sourceOpportunity;
		System.assert(fetchedTargetOpp.Touched__c, 'target opp field Touched__c is not true');
		System.assert(sourceOpp.Touched__c, 'source opp field Touched__c is not true');
		System.assertEquals(sourceOpp.OpportunityNumber__c, fetchedTargetOpp.Channel_Load_Opp__c, 'target opp field Channel_Load_Opp__c does not match sourc opp field OpportunityNumber__c');
		System.assertEquals(sourceOpp.CloseDate, fetchedTargetOpp.CloseDate, 'target opp field CloseDate does not match source opp');
		System.assertEquals(sourceOpp.ContractEndDate__c, fetchedTargetOpp.ContractEndDate__c, 'target opp field ContractEndDate__c does not match source opp');
		System.assertEquals(sourceOpp.ContractStartDate__c, fetchedTargetOpp.ContractStartDate__c, 'target opp field ContractStartDate__c does not match source opp');
		System.assertEquals(sourceOpp.CurrencyIsoCode, fetchedTargetOpp.CurrencyIsoCode, 'target opp field CurrencyIsoCode does not match source opp');
		System.assertNotEquals(sourceOpp.Deal_Registration__c, fetchedTargetOpp.Deal_Registration__c, 'target opp field Deal_Registration__c should not be overwritten if true');
		System.assertEquals(sourceOpp.Pay_Now__c, fetchedTargetOpp.Pay_Now__c, 'target opp field Pay_Now__c does not match source opp');
		System.assertEquals(sourceOpp.PONumber__c, fetchedTargetOpp.PONumber__c, 'target opp field PONumber__c does not match source opp');
		System.assertEquals(sourceOpp.FinancialPartner__c, fetchedTargetOpp.FinancialPartner__c, 'target opp field FinancialPartner__c does not match source opp');
		System.assertEquals(sourceOpp.Amount, fetchedTargetOpp.Year1PaymentAmount__c, 'target opp field Year1PaymentAmount__c does not match source opp field Amount');
		System.assertEquals(0, fetchedTargetOpp.Year2PaymentAmount__c, 'target opp field Year2PaymentAmount__c does not match source opp');
		System.assertEquals(0, fetchedTargetOpp.Year3PaymentAmount__c, 'target opp field Year3PaymentAmount__c does not match source opp');
		System.assertEquals(0, fetchedTargetOpp.Year4PaymentAmount__c, 'target opp field Year4PaymentAmount__c does not match source opp');
		System.assertEquals(0, fetchedTargetOpp.Year5PaymentAmount__c, 'target opp field Year5PaymentAmount__c does not match source opp');
		System.assertEquals(0, fetchedTargetOpp.Year6PaymentAmount__c, 'target opp field Year6PaymentAmount__c does not match source opp');
		System.assertEquals(instance.globalPricebookId, fetchedTargetOpp.Pricebook2Id, 'target opp field Pricebook2Id does not match globalPricebookId');
		System.assertEquals(1,sourceOpp.OpportunityLineItems.size(), 'more than 1 OpportunityLineItem on source opp');
		System.assertEquals(1,fetchedTargetOpp.OpportunityLineItems.size(), 'more than 1 OpportunityLineItem on target opp');
		System.assertEquals(fetchedTargetOpp.OpportunityLineItems[0].PricebookEntry.productCode, sourceOpp.OpportunityLineItems[0].PricebookEntry.productCode, 'target opp productCode on OpportunityLineItem.PricebookEntry does not match source opp');
		System.assertEquals(targetProbability, fetchedTargetOpp.Probability, 'target opp field Probability did not retain its value');
		System.assertEquals(targetStageName, fetchedTargetOpp.StageName, 'target opp field StageName did not retain its value');
		System.assert(!fetchedTargetOpp.Quotes__r[0].IsActive__c, 'target opp quote active flag not cleared');
		System.assert(!fetchedTargetOpp.BigMachines__BigMachines_Quotes__r[0].BigMachines__Is_Primary__c, 'target opp BigMachines quote primary flag not cleared');
	}

	@isTest(SeeAllData=true)
	static void testSaveChanges_ProbabilityGreaterThanZero() {

		//create source and target opps
		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];
		Decimal targetProbability = 10;
		String targetStageName = 'Test Stage';
		opportunity2.Probability = targetProbability;
		opportunity2.StageName = targetStageName;
		update opportunity2;

		Test.startTest();
		
		// excercise the class
		instance.sourceOpportunityNumber = opportunity1.OpportunityNumber__c;
		instance.targetOpportunityId = opportunity2.Id;
		instance.search();
		System.assertNotEquals(null, instance.sourceOpportunity, 'sourceOpportunity is null');
		instance.saveChanges();

		Test.stopTest();
		
		// fetch saved target opp and check values
		instance.targetOpportunity = null;
		Opportunity fetchedTargetOpp = instance.targetOpportunity;
		Opportunity sourceOpp = instance.sourceOpportunity;
		System.assertEquals(targetProbability, fetchedTargetOpp.Probability,  'target opp field Probability did not retain its value');
		System.assertEquals(targetStageName, fetchedTargetOpp.StageName, 'target opp field StageName did not retain its value');
	}
	 
	@isTest(SeeAllData=true)
	static void testSaveChanges_WithYear1PaymentAmount() {

		//create source and target opps
		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];

		Test.startTest();

		// excercise the class
		instance.sourceOpportunityNumber = opportunity1.OpportunityNumber__c;
		instance.targetOpportunityId = opportunity2.Id;
		instance.search();
		instance.sourceOpportunity.Year1PaymentAmount__c = 100;
		System.assertNotEquals(null, instance.targetOpportunity, 'targetOpportunity is null');
		instance.saveChanges();

		Test.stopTest();
		
		// fetch saved target opp and check values
		instance.targetOpportunity = null;
		Opportunity fetchedTargetOpp = instance.targetOpportunity;
		Opportunity sourceOpp = instance.sourceOpportunity;
		System.assertEquals(sourceOpp.Year1PaymentAmount__c, fetchedTargetOpp.Year1PaymentAmount__c, 'target opp field Year1PaymentAmount__c does not match source opp');
		System.assertEquals(sourceOpp.Year2PaymentAmount__c, fetchedTargetOpp.Year2PaymentAmount__c, 'target opp field Year2PaymentAmount__c does not match source opp');
		System.assertEquals(sourceOpp.Year3PaymentAmount__c, fetchedTargetOpp.Year3PaymentAmount__c, 'target opp field Year3PaymentAmount__c does not match source opp');
		System.assertEquals(sourceOpp.Year4PaymentAmount__c, fetchedTargetOpp.Year4PaymentAmount__c, 'target opp field Year4PaymentAmount__c does not match source opp');
		System.assertEquals(sourceOpp.Year5PaymentAmount__c, fetchedTargetOpp.Year5PaymentAmount__c, 'target opp field Year5PaymentAmount__c does not match source opp');
		System.assertEquals(sourceOpp.Year6PaymentAmount__c, fetchedTargetOpp.Year6PaymentAmount__c, 'target opp field Year6PaymentAmount__c does not match source opp');
	}

	@isTest(SeeAllData=true)
	static void testReverseOrder() {
		
		doInitializeInstance();
		List<Opportunity> opportunities = doInsertOpportunities(new List<String>{'1','2'});
		Opportunity opportunity1 = opportunities[0];
		Opportunity opportunity2 = opportunities[1];
		instance.sourceOpportunityNumber = opportunity1.OpportunityNumber__c;
		instance.targetOpportunityId = opportunity2.Id;
		System.assertNotEquals(null,instance.sourceOpportunity);
		System.assertNotEquals(null,instance.targetOpportunity);
		instance.reverseOrder();
	}
	
	@isTest(SeeAllData=false)
	static void testNullSaveChanges() {
				
		LinkChannelOppController instances = new LinkChannelOppController();
		
		instances.saveChanges();
	}
}