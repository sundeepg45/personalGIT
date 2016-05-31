/**
 * Test the SubscriptionTriggerBefore class.
 *
 * @version 2015-03-30
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2015-03-30 - create CDH Party for account
 * @since 2015-02-21 - New test for syncAccountFields
 * @since 2015-02-04 - extended createContactsTest to cover all subscription contacts
 * @since 2015-01-27 - commenting out assigned batch tests
 * @since 2014-12-22 - Added test for createContacts
 * @since 2014-12-22 - Updated test for mapContacts
 * @since 2014-11-25 - Added test for syncCampaignFields
 * @since 2013-09-19 - created
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2014-01-07 - added test for mapContacts()
 * @since 2014-01-12 - added test for mapSourceOpp()
 * @since 2014-01-13 - added test for mapResellerPartner()
 */
@isTest
public class SubscriptionTriggerBeforeTest {

	private static Campaign campaign { get {
		if(campaign == null) {
			// create a campaign
			campaign = new Campaign(Name = 'Test Campaign');
		}
		return campaign;
	}}

	private static Id getCampaignId() {
		if(campaign.Id == null) {
			insert campaign;
		}
		return campaign.Id;
	}

	private static Product2 happyBall { get {
		if(happyBall == null) {
			// create a product
			happyBall = new Product2(
				Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.',
				IsActive = true,
				Name = 'Happy Fun Ball',
				ProductCode = 'HFB7');
			insert happyBall;
		}
		return happyBall;
	}}

	private static PricebookEntry globalPricebookEntry { get {
		if(globalPricebookEntry == null) {
			// create a pricebook entry for the global pricebook
			globalPricebookEntry = new PricebookEntry(
				CurrencyIsoCode = 'USD',
				IsActive = true,
				Product2Id = happyBall.Id,
				UnitPrice = 2000.00);
			for(PriceBook2 pb : [SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book' and IsActive = true limit 1]) {
				globalPricebookEntry.Pricebook2Id = pb.Id;
			}
		}
		return globalPricebookEntry;
	}}

	private static Id getGlobalPricebookEntryId() {
		if(globalPricebookEntry.Id == null && globalPricebookEntry.Pricebook2Id != null) {
			// create a pricebook entry for the standard pricebook
			PricebookEntry pricebookEntry1 = globalPricebookEntry.clone();
			// get the id of the standard price book
			for(Pricebook2 pb : [SELECT Id FROM PriceBook2 WHERE isStandard = true and IsActive = true limit 1] ) {
				pricebookEntry1.Pricebook2Id = pb.Id;
			}
			insert new List<PricebookEntry>{priceBookEntry1,globalPricebookEntry};
			System.debug(happyBall);
			System.debug(pricebookEntry1);
			System.debug(globalPricebookEntry);
		}
		return globalPricebookEntry.Id;
	}

	private static CDH_Party__c cdhPartyAccount {
		get {
			if(cdhPartyAccount == null) {
				cdhPartyAccount = new CDH_Party__c(
					Name = 'testParty1',
					CDH_Party_Name__c = 'testParty1',
					CDH_Party_Number_Ext__c = 'testParty1',
					CDH_Party_Type__c = 'ORGANIZATION');
				insert cdhPartyAccount;
			}
			return cdhPartyAccount;
		}
		set;
	}

	private static Account account {
		get {
			if(account == null) {
				account = new Account(
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					CurrencyIsoCode = 'USD',
					CDH_Party_Name__c = cdhPartyAccount.Id,
					Name = 'Red Hat',
					OracleAccountNumber__c = '12345',
					Owner = new User(Id=UserInfo.getUserId()),
					RecordTypeId = RecordTypeLookup.getRecordTypeId('APAC Account','Account'),
					ShippingCity = 'Raleigh',
					ShippingCountry = 'US',
					ShippingPostalCode = '27606',
					ShippingState = 'North Carolina',
					ShippingStreet = '1801 Varsity Drive',
					VATNumber__c = '67890');
			}
			return account;
		}
	}

	public static Id getAccountId() {
		if(account.Id == null) {
			insert account;
		}
		return account.Id;
	}

	private static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					AccountId = account.Id,
					CloseDate = Date.newInstance(2009, 11, 10),
					Country_Of_Order__c = 'Japan',
					CurrencyIsoCode = 'USD',
					Name = 'Japan Opportunity',
					OpportunityType__c = 'Standard',
					OracleOrderNumber__c = '-31221554049414838',
					PaymentType__c = 'APAC Purchase Order',
					PONumber__c = '-312215540494148386',
					Pricebook2Id = globalPricebookEntry.Pricebook2Id,
					RecordTypeId = '012300000000TVCAA2',
					StageName = 'Prepare',
					Touched__c = true);
			}
			return opportunity;
		}
		set;
	}

	private static Id getOpportunityId() {
		if(opportunity.Id == null) {
			String orderNumber = opportunity.OracleOrderNumber__c;
			opportunity.AccountId = getAccountId();
			insert opportunity;
			Opportunity opp = [
				select
					AccountId,
					CampaignId,
					CloseDate,
					Country_of_Order__c,
					CurrencyIsoCode,
					Name,
					OpportunityType__c,
					OpportunityNumber__c,
					OracleOrderNumber__c,
					Owner.IsActive,
					PaymentType__c,
					PONumber__c,
					Pricebook2Id,
					RecordTypeId,
					Region__c,
					StageName,
					Super_Region__c,
					Touched__c
				from Opportunity
				where Id = :opportunity.Id ];
			opportunity = opp.clone(true,false,true,true);
			opportunity.OracleOrderNumber__c = orderNumber;
		}
		return opportunity.Id;
	}

	private static Contact contact { 
		get {
			if(contact == null) {
				contact = new Contact(
					AccountId = account.Id,
					OwnerId = UserInfo.getUserId(),
					FirstName = 'first name',
					LastName = 'last name',
					Email = 'test@nowhere.com',
					Phone = '1-800-555-1212',
					LoginName__c = 'test12345@nowhere.com');
			}
			return contact;
		} 
	}

	private static Id getContactId() {
		if(contact.Id == null) {
			contact.AccountId = getAccountId();
			insert contact;
		}
		return contact.Id;
	}	

//depreciated	@isTest
//depreciated	static void assignBatchTest1() {
//depreciated		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
//depreciated		triggerBefore.assignBatch();
//depreciated		for(Subscription__c sub : subscriptions) {
//depreciated			System.assertEquals(batchId,sub.Batch__c);
//depreciated		}
//depreciated	}

//depreciated	@isTest
//depreciated	static void assignBatchTest2() {
//depreciated		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
//depreciated		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
//depreciated		triggerBefore.assignBatch();
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		for(Subscription__c sub : subscriptions) {
//depreciated			System.assertEquals(batchId,sub.Batch__c);
//depreciated		}
//depreciated	}

	@isTest
	static void assignCompositeKeyTest() {
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		triggerBefore.assignCompositeKey();
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00,subscriptions[0].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01,subscriptions[1].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10,subscriptions[2].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11,subscriptions[3].CompositeKey__c);
	}

	@isTest
	static void assignRegionTest() {
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		triggerBefore.assignRegion();
		for(Subscription__c sub : subscriptions) {
			System.assertEquals(SubscriptionBatchTriggerAfterTest.region.Super_Region__c,sub.SuperRegion__c);
			System.assertEquals(SubscriptionBatchTriggerAfterTest.region.Region__c,sub.Region__c);
		}
	}

	@isTest
	static void aggregateSubscriptionLinesTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		subscriptions[0].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptions[1].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY01;
		subscriptions[2].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY10;
		subscriptions[3].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY11;
		for(Subscription__c sub : subscriptions) {
			sub.ExpiringProductsAmount__c = 1234.00;
		}
		subscriptionLine.SubscriptionCompositeKey__c = subscriptions[0].CompositeKey__c;
		subscriptionLine.RenewalTotalPrice__c = 100.00;
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		triggerBefore.aggregateSubscriptionLines();
		System.assertEquals(subscriptionLine.RenewalTotalPrice__c,subscriptions[0].ExpiringProductsAmount__c);
		subscriptions.remove(0);
		for(Subscription__c sub : subscriptions) {
			System.assertEquals(0.00,sub.ExpiringProductsAmount__c);
		}
	}

	@isTest
	static void updateFromSubscriptionLinesTest() {
		SubscriptionLine__c subscriptionLine = SubscriptionBatchTriggerAfterTest.subscriptionLines[0];
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		subscriptionLine.OriginalCompositeKey__c = subscriptions[0].CompositeKey__c = SubscriptionBatchTriggerAfterTest.COMPOSITE_KEY00;
		subscriptions[0].EntitleToAccountNumber__c = subscriptionLine.EntitleToAccountNumber__c = '-1';
		subscriptions[0].EntitleToCDHPartyNumber__c = subscriptionLine.EntitleToCDHPartyNumber__c = '-1';
		subscriptions[0].EntitleToCDHPartySiteNumber__c = subscriptionLine.EntitleToCDHPartySiteNumber__c = '-2';
		subscriptions[0].EntitleToContCDHPartyNumber__c = subscriptionLine.EntitleToContCDHPartyNumber__c = '-3';
		subscriptions[0].EntitleToAddress1__c = null;
		subscriptions[0].EntitleToAddress2__c = null;
		subscriptions[0].EntitleToCity__c = null;
		subscriptions[0].EntitleToContactEmail__c = null;
		subscriptions[0].EntitleToContactFirstName__c = null;
		subscriptions[0].EntitleToContactLastName__c = null;
		subscriptions[0].EntitleToContactName__c = null;
		subscriptions[0].EntitleToContactPhone__c = null;
		subscriptions[0].EntitleToCountry__c = null;
		subscriptions[0].EntitleToPostalCode__c = null;
		subscriptions[0].EntitleToState__c = null;
		subscriptionLine.EntitleToAddress1__c = 'address 1';
		subscriptionLine.EntitleToAddress2__c = 'address 2';
		subscriptionLine.EntitleToCity__c = 'city';
		subscriptionLine.EntitleToContactEmail__c = 'test@nowhere.com';
		subscriptionLine.EntitleToContactFirstName__c = 'firstname';
		subscriptionLine.EntitleToContactLastName__c = 'lastname';
		subscriptionLine.EntitleToContactName__c = 'firsname lastname';
		subscriptionLine.EntitleToContactPhone__c = '1-800-555-1212';
		subscriptionLine.EntitleToCountry__c = 'US';
		subscriptionLine.EntitleToPostalCode__c = '49001';
		subscriptionLine.EntitleToState__c = 'MI';
		AbstractTrigger.setBooleanSettings('SubLine_Before.',false);
		AbstractTrigger.setBooleanSettings('SubLine_After.',false);
		insert subscriptionLine;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Test.startTest();
		triggerBefore.updateFromSubscriptionLines();
		Test.stopTest();
		System.assertEquals(subscriptionLine.EntitleToAddress1__c,subscriptions[0].EntitleToAddress1__c);
		System.assertEquals(subscriptionLine.EntitleToAddress2__c,subscriptions[0].EntitleToAddress2__c);
		System.assertEquals(subscriptionLine.EntitleToCity__c,subscriptions[0].EntitleToCity__c);
		System.assertEquals(subscriptionLine.EntitleToState__c,subscriptions[0].EntitleToState__c);
		System.assertEquals(subscriptionLine.EntitleToPostalCode__c,subscriptions[0].EntitleToPostalCode__c);
		System.assertEquals(subscriptionLine.EntitleToContactEmail__c,subscriptions[0].EntitleToContactEmail__c);
		System.assertEquals(subscriptionLine.EntitleToContactFirstName__c,subscriptions[0].EntitleToContactFirstName__c);
		System.assertEquals(subscriptionLine.EntitleToContactLastName__c,subscriptions[0].EntitleToContactLastName__c);
		System.assertEquals(subscriptionLine.EntitleToContactName__c,subscriptions[0].EntitleToContactName__c);
		System.assertEquals(subscriptionLine.EntitleToContactPhone__c,subscriptions[0].EntitleToContactPhone__c);
	}

	@isTest
	static void matchAccountsTest() {
		System.assertEquals(null,SubscriptionTriggerBefore.errorList);
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		subscription.Status__c = SubscriptionTriggerBefore.READY_STATUS;
		// insert the subscription
		System.assert(! SubscriptionBatchTriggerAfterTest.subscriptionMap.isEmpty());
		// we don't need subscription lines, because we'll get generate a no lines error
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,new List<Subscription__c>{subscription});
		// activate the after trigger
		AbstractTrigger.setBooleanSettings(SubscriptionTriggerAfter.MATCH_ACCOUNTS_SETTING,true);
		Test.startTest();
		triggerBefore.matchAccounts();
		Test.stopTest();
		System.assertNotEquals(null,SubscriptionTriggerBefore.errorList);
		System.assertNotEquals(0,SubscriptionTriggerBefore.errorList.size());
	}

	@isTest
	static void updateStatusesTest() {
		List<Subscription__c> subs = new List<Subscription__c>{ 
			new Subscription__c(
				Status__c = null,
				SuperRegion__c = 'APAC'),
			new Subscription__c(
				Status__c = SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS,
				SuperRegion__c = 'APAC'),
			new Subscription__c(
				Status__c = SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS,
				SuperRegion__c = 'APAC') };
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subs);
		triggerBefore.updateStatuses();
		for(Subscription__c sub : subs) {
			System.assertEquals(SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS,sub.Status__c);
		}
	}

	@isTest
	static void ssiOptInTest() {
		SubscriptionBatchTriggerAfterTest.subscriptions[0].ContractAmount__c = 1000000000000000.00;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,SubscriptionBatchTriggerAfterTest.subscriptions);
		Test.startTest();
		triggerBefore.ssiOptIn();
		Test.stopTest();
		System.assertEquals(false,SubscriptionBatchTriggerAfterTest.subscriptions[0].SSI_OptIn__c);
		System.assertEquals(true,SubscriptionBatchTriggerAfterTest.subscriptions[1].SSI_OptIn__c);
	}

	@isTest
	static void mapContactsTest() {
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Id accountId = getAccountId();
		Id contactId = getContactId();
		//sub 0: account id populated, ship to and sold to contact email populated
		subscriptions[0].Account__c = accountId;
		subscriptions[0].ShipToContactEmail__c = contact.Email;
		subscriptions[0].SoldToContactEmail__c = contact.Email;
		subscriptions[0].EntitleToContactEmail__c = null;
		//sub 1: none of the relevant fields populated
		subscriptions[1].Account__c = null;
		subscriptions[1].ShipToContactEmail__c = null;
		subscriptions[1].SoldToContactEmail__c = null;
		subscriptions[1].EntitleToContactEmail__c = null;
		//sub 2: account id populated, entitle to contact email populated
		subscriptions[2].Account__c = accountId;
		subscriptions[2].ShipToContactEmail__c = null;
		subscriptions[2].EntitleToContactEmail__c = contact.Email;
		//sub 3: only account id populated
		subscriptions[3].Account__c = accountId;
		subscriptions[3].ShipToContactEmail__c = null;
		subscriptions[3].SoldToContactEmail__c = null;
		subscriptions[3].EntitleToContactEmail__c = null;
		triggerBefore.mapContacts();
		System.assertEquals(contactId,subscriptions[0].ShippingContact__c);
		System.assertEquals(contactId,subscriptions[0].SellingContact__c);
		System.assertEquals(null,subscriptions[1].ShippingContact__c);
		System.assertEquals(null,subscriptions[1].SellingContact__c);
		System.assertEquals(null,subscriptions[2].ShippingContact__c);
		System.assertEquals(contactId,subscriptions[2].SellingContact__c);
		System.assertEquals(null,subscriptions[3].ShippingContact__c);
		System.assertEquals(null,subscriptions[3].SellingContact__c);
	}

	@isTest
	static void createContactsTest() {
		Account_Matching.CONTACT_EMAIL_SUFFIX = '.test';
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		triggerBefore.contactInsertSizeLimit = 10000;
		Id accountId = getAccountId();
		//sub 0: account id populated, ship to and sold to contact email populated
		subscriptions[0].Account__c = accountId;
		subscriptions[0].Status__c = SubscriptionTriggerBefore.READY_STATUS;
		subscriptions[0].SuperRegion__c = 'NA';
		subscriptions[0].BillToSalesAccount__c = null;
		subscriptions[0].BillToContactFirstName__c = 'x'+contact.FirstName;
		subscriptions[0].BillToContactLastName__c = 'x'+contact.LastName;
		subscriptions[0].BillToContactEmail__c = 'x'+contact.Email;
		subscriptions[0].ShipToSalesAccount__c = null;
		subscriptions[0].ShipToContactFirstName__c = contact.FirstName;
		subscriptions[0].ShipToContactLastName__c = contact.LastName;
		subscriptions[0].ShipToContactEmail__c = contact.Email;
		subscriptions[0].SoldToSalesAccount__c = null;
		subscriptions[0].SoldToContactFirstName__c = contact.FirstName;
		subscriptions[0].SoldToContactLastName__c = contact.LastName;
		subscriptions[0].SoldToContactEmail__c = contact.Email;
		subscriptions[0].EntitleToSalesAccount__c = null;
		subscriptions[0].EntitleToContactFirstName__c = null;
		subscriptions[0].EntitleToContactLastName__c = null;
		subscriptions[0].EntitleToContactEmail__c = null;
		//sub 1: none of the relevant fields populated
		subscriptions[1].Account__c = null;
		subscriptions[1].SuperRegion__c = 'NA';
		subscriptions[1].Status__c = SubscriptionTriggerBefore.READY_STATUS;
		subscriptions[1].BillToSalesAccount__c = null;
		subscriptions[1].BillToContactFirstName__c = null;
		subscriptions[1].BillToContactLastName__c = null;
		subscriptions[1].BillToContactEmail__c = null;
		subscriptions[1].ShipToSalesAccount__c = null;
		subscriptions[1].ShipToContactFirstName__c = null;
		subscriptions[1].ShipToContactLastName__c = null;
		subscriptions[1].ShipToContactEmail__c = null;
		subscriptions[1].SoldToSalesAccount__c = null;
		subscriptions[1].SoldToContactFirstName__c = null;
		subscriptions[1].SoldToContactLastName__c = null;
		subscriptions[1].SoldToContactEmail__c = null;
		subscriptions[1].EntitleToSalesAccount__c = null;
		subscriptions[1].EntitleToContactFirstName__c = null;
		subscriptions[1].EntitleToContactLastName__c = null;
		subscriptions[1].EntitleToContactEmail__c = null;
		//sub 2: account id populated, entitle to contact email populated
		subscriptions[2].Account__c = accountId;
		subscriptions[2].SuperRegion__c = 'NA';
		subscriptions[2].Status__c = SubscriptionTriggerBefore.READY_STATUS;
		subscriptions[2].BillToSalesAccount__c = null;
		subscriptions[2].BillToContactFirstName__c = null;
		subscriptions[2].BillToContactLastName__c = null;
		subscriptions[2].BillToContactEmail__c = null;
		subscriptions[2].ShipToSalesAccount__c = null;
		subscriptions[2].ShipToContactFirstName__c = null;
		subscriptions[2].ShipToContactLastName__c = null;
		subscriptions[2].ShipToContactEmail__c = null;
		subscriptions[2].SoldToSalesAccount__c = null;
		subscriptions[2].SoldToContactFirstName__c = null;
		subscriptions[2].SoldToContactLastName__c = null;
		subscriptions[2].SoldToContactEmail__c = null;
		subscriptions[2].EntitleToSalesAccount__c = null;
		subscriptions[2].EntitleToContactFirstName__c = contact.FirstName;
		subscriptions[2].EntitleToContactLastName__c = contact.LastName;
		subscriptions[2].EntitleToContactEmail__c = contact.Email;
		//sub 3: everything populated except account id
		subscriptions[3].Account__c = null;
		subscriptions[3].ShipToContactFirstName__c = null;
		subscriptions[3].SuperRegion__c = 'NA';
		subscriptions[3].Status__c = SubscriptionTriggerBefore.READY_STATUS;
		subscriptions[3].BillToSalesAccount__c = accountId;
		subscriptions[3].BillToContactFirstName__c = 'x'+contact.FirstName;
		subscriptions[3].BillToContactLastName__c = 'x'+contact.LastName;
		subscriptions[3].BillToContactEmail__c = 'x'+contact.Email;
		subscriptions[3].ShipToSalesAccount__c = accountId;
		subscriptions[3].ShipToContactFirstName__c = contact.FirstName;
		subscriptions[3].ShipToContactLastName__c = contact.LastName;
		subscriptions[3].ShipToContactEmail__c = contact.Email;
		subscriptions[3].SoldToSalesAccount__c = accountId;
		subscriptions[3].SoldToContactFirstName__c = contact.FirstName;
		subscriptions[3].SoldToContactLastName__c = contact.LastName;
		subscriptions[3].SoldToContactEmail__c = contact.Email;
		subscriptions[3].EntitleToSalesAccount__c = accountId;
		subscriptions[3].EntitleToContactFirstName__c = contact.FirstName;
		subscriptions[3].EntitleToContactLastName__c = contact.LastName;
		subscriptions[3].EntitleToContactEmail__c = contact.Email;
		Test.startTest();
		triggerBefore.createContacts( null );
		Test.stopTest();
		System.assertNotEquals(null,subscriptions[0].ShippingContact__c,'0. Expected shipping contact');
		System.assertNotEquals(null,subscriptions[0].SellingContact__c,'0. Expected selling contact');
		System.assertEquals(null,subscriptions[0].BillToContact__c,'0. Did not expect bill to contact');
		System.assertEquals(null,subscriptions[0].ShipToContact__c,'0. Did not expect ship to contact');
		System.assertEquals(null,subscriptions[0].SoldToContact__c,'0. Did not expect sold to contact');
		System.assertEquals(null,subscriptions[0].EntitleToContact__c,'0. Did not expect entile to contact');
		System.assertEquals(null,subscriptions[1].ShippingContact__c,'1. Did not expect shipping contact');
		System.assertEquals(null,subscriptions[1].SellingContact__c,'1. Did not expect selling contact');
		System.assertEquals(null,subscriptions[1].BillToContact__c,'1. Did not expect bill to contact');
		System.assertEquals(null,subscriptions[1].ShipToContact__c,'1. Did not expect ship to contact');
		System.assertEquals(null,subscriptions[1].SoldToContact__c,'1. Did not expect sold to contact');
		System.assertEquals(null,subscriptions[1].EntitleToContact__c,'1. Did not expect entile to contact');
		System.assertEquals(null,subscriptions[2].ShippingContact__c,'2. Did not expected shipping contact');
		System.assertNotEquals(null,subscriptions[2].SellingContact__c,'2. Expected selling contact');
		System.assertEquals(null,subscriptions[2].BillToContact__c,'2. Did not expect bill to contact');
		System.assertEquals(null,subscriptions[2].ShipToContact__c,'2. Did not expect ship to contact');
		System.assertEquals(null,subscriptions[2].SoldToContact__c,'2. Did not expect sold to contact');
		System.assertEquals(null,subscriptions[2].EntitleToContact__c,'2. Did not expect entile to contact');
		System.assertNotEquals(null,subscriptions[3].BillToContact__c,'3. Expected bill to contact');
		System.assertNotEquals(null,subscriptions[3].ShipToContact__c,'3. Expected ship to contact');
		System.assertNotEquals(null,subscriptions[3].SoldToContact__c,'3. Expected sold to contact');
		System.assertNotEquals(null,subscriptions[3].EntitleToContact__c,'3. Expected entitle to contact');
		System.assertNotEquals(null,subscriptions[3].ShippingContact__c,'3. Expected shipping contact');
		System.assertNotEquals(null,subscriptions[3].SellingContact__c,'3. Expected selling contact');
	}

	@isTest
	static void mapResellerPartner() {
		//this is a coverage test - asserts are in SubscriptionPartnerTriggerBeforeTest
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		triggerBefore.mapResellerPartner();
	}

	@isTest
	static void syncAssignToFieldsTest() {
		Id userId = UserInfo.getUserId();
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		// assign only AssignTo__c
		subscriptions[0].AssignTo__c = userId;
		subscriptions[0].AssignToId__c = null;
		// assign only AssignToId__c
		subscriptions[1].AssignTo__c = null;
		subscriptions[1].AssignToId__c = userId;
		// assign only AssignToId__c an invalid campaign Id
		Id dummyUserId = (''+userId).substring(0,4)+'00000000000';
		subscriptions[2].AssignTo__c = null;
		subscriptions[2].AssignToId__c = dummyUserId;
		// assign a completely bogus value to AssignToId__c
		subscriptions[3].AssignTo__c = null;
		subscriptions[3].AssignToId__c = 'DOG FOOD';
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Test.startTest();
		triggerBefore.syncAssignToFields();

		System.assertEquals(userId,subscriptions[0].AssignTo__c,'AssignTo__c assignment from AssignToId__c failed.');

		System.assertEquals(''+userId,subscriptions[0].AssignToId__c,'AssignToId__c changed on AssignTo__c assignment from AssignToId__c.');

		System.assertEquals(userId,subscriptions[1].AssignTo__c,'AssignTo__c changed on AssignToId__c assignment from AssignTo__c.');

		System.assertEquals(''+userId,subscriptions[1].AssignToId__c,'AssignToId__c assignment from AssignTo__c failed.');

		System.assertEquals(null,subscriptions[2].AssignTo__c,'Did not expect AssignTo__c assignment from '+dummyUserId);

		System.assertEquals(null,subscriptions[2].AssignToId__c,'Did not expect AssignToId__c to change');

		System.assertEquals(null,subscriptions[3].AssignTo__c,'Did not expect AssignTo__c assignment from DOG FOOD');

		System.assertEquals('DOG FOOD',subscriptions[3].AssignToId__c,'Did not expect AssignToId__c to change');

		subscriptions[1].AssignTo__c = dummyUserId;
		subscriptions[1].AssignToId__c = userId;

		triggerBefore = new SubscriptionTriggerBefore(new Map<Id,Subscription__c>{subscriptions[1].Id=>subscriptions[0]},new List<Subscription__c>{subscriptions[1]});
		triggerBefore.syncAssignToFields();

		System.assertEquals(dummyUserId,subscriptions[1].AssignTo__c,'AssignTo__c changed on AssignToId__c assignment from AssignTo__c.');

		System.assertEquals(''+dummyUserId,subscriptions[1].AssignToId__c,'AssignToId__c assignment from AssignTo__c failed.');

		subscriptions[1].AssignTo__c = userId;

		triggerBefore.syncAssignToFields();

		System.assertEquals(null,subscriptions[1].AssignTo__c,'Expect AssignTo__c to change');

		System.assertEquals(null,subscriptions[1].AssignToId__c,'Expect AssignToId__c to change');

		subscriptions[0].AssignTo__c = dummyUserId;
		subscriptions[0].AssignToId__c = dummyUserId;
		subscriptions[1].AssignTo__c = dummyUserId;
		subscriptions[1].AssignToId__c = userId;

		triggerBefore.syncAssignToFields();

		System.assertEquals(userId,subscriptions[1].AssignTo__c,'Expect AssignTo__c to change');

		System.assertEquals(userId,subscriptions[1].AssignToId__c,'Did not expect AssignToId__c to change');

		subscriptions[1].AssignTo__c = dummyUserId;
		subscriptions[1].AssignToId__c = null;

		triggerBefore.syncAssignToFields();

		System.assertEquals(null,subscriptions[1].AssignTo__c,'Expect AssignTo__c to change');

		System.assertEquals(null,subscriptions[1].AssignToId__c,'Did not expect AssignToId__c to change');

		subscriptions[1].AssignToId__c = dummyUserId;

		triggerBefore.syncAssignToFields();

		System.assertEquals(null,subscriptions[1].AssignTo__c,'Did not expect AssignTo__c to change');

		System.assertEquals(null,subscriptions[1].AssignToId__c,'Expect AssignToId__c to change');

		Test.stopTest();
	}

	@isTest
	static void syncAccountFieldsTest() {
		Id accountId = getAccountId();
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		// assign only Account__c
		subscriptions[0].Account__c = accountId;
		subscriptions[0].AccountId__c = null;
		subscriptions[0].BillToSalesAccount__c = accountId;
		subscriptions[0].BillToSfAccountId__c = null;
		subscriptions[0].SoldToSalesAccount__c = accountId;
		subscriptions[0].SoldToSfAccountId__c = null;
		subscriptions[0].ShipToSalesAccount__c = accountId;
		subscriptions[0].ShipToSfAccountId__c = null;
		subscriptions[0].EntitleToSalesAccount__c = accountId;
		subscriptions[0].EntitleToSfAccountId__c = null;
		// assign only AccountId__c
		subscriptions[1].Account__c = null;
		subscriptions[1].AccountId__c = accountId;
		subscriptions[1].BillToSalesAccount__c = null;
		subscriptions[1].BillToSfAccountId__c = accountId;
		subscriptions[1].ShipToSalesAccount__c = null;
		subscriptions[1].ShipToSfAccountId__c = accountId;
		subscriptions[1].SoldToSalesAccount__c = null;
		subscriptions[1].SoldToSfAccountId__c = accountId;
		subscriptions[1].EntitleToSalesAccount__c = null;
		subscriptions[1].EntitleToSfAccountId__c = accountId;
		// assign only AccountId__c an invalid campaign Id
		Id dummyAccountId = (''+accountId).substring(0,4)+'00000000000';
		subscriptions[2].Account__c = null;
		subscriptions[2].AccountId__c = dummyAccountId;
		subscriptions[2].BillToSalesAccount__c = null;
		subscriptions[2].BillToSfAccountId__c = dummyAccountId;
		subscriptions[2].ShipToSalesAccount__c = null;
		subscriptions[2].ShipToSfAccountId__c = dummyAccountId;
		subscriptions[2].SoldToSalesAccount__c = null;
		subscriptions[2].SoldToSfAccountId__c = dummyAccountId;
		subscriptions[2].EntitleToSalesAccount__c = null;
		subscriptions[2].EntitleToSfAccountId__c = dummyAccountId;
		// assign a completely bogus value to AccountId__c
		subscriptions[3].Account__c = null;
		subscriptions[3].AccountId__c = 'DOG FOOD';
		subscriptions[3].BillToSalesAccount__c = null;
		subscriptions[3].BillToSfAccountId__c = 'DOG FOOD';
		subscriptions[3].ShipToSalesAccount__c = null;
		subscriptions[3].ShipToSfAccountId__c = 'DOG FOOD';
		subscriptions[3].SoldToSalesAccount__c = null;
		subscriptions[3].SoldToSfAccountId__c = 'DOG FOOD';
		subscriptions[3].EntitleToSalesAccount__c = null;
		subscriptions[3].EntitleToSfAccountId__c = 'DOG FOOD';
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Test.startTest();
		triggerBefore.syncAccountFields();

		System.assertEquals(accountId,subscriptions[0].Account__c,'Account__c assignment from AccountId__c failed.');
		System.assertEquals(accountId,subscriptions[0].BillToSalesAccount__c,'BillToSalesAccount__c assignment from BillToSalesAccountId__c failed.');
		System.assertEquals(accountId,subscriptions[0].ShipToSalesAccount__c,'ShipToSalesAccount__c assignment from ShipToSalesAccountId__c failed.');
		System.assertEquals(accountId,subscriptions[0].SoldToSalesAccount__c,'SoldToSalesAccount__c assignment from SoldToSalesAccountId__c failed.');
		System.assertEquals(accountId,subscriptions[0].EntitleToSalesAccount__c,'EntitleToSalesAccount__c assignment from EntitleToSalesAccountId__c failed.');

		System.assertEquals(''+accountId,subscriptions[0].AccountId__c,'AccountId__c changed on Account__c assignment from AccountId__c.');
		System.assertEquals(''+accountId,subscriptions[0].BillToSfAccountId__c,'BillToSfAccountId__c changed on BillToSfAccount__c assignment from BillToSfAccountId__c.');
		System.assertEquals(''+accountId,subscriptions[0].ShipToSfAccountId__c,'ShipToSfAccountId__c changed on ShipToSfAccount__c assignment from ShipToSfAccountId__c.');
		System.assertEquals(''+accountId,subscriptions[0].SoldToSfAccountId__c,'SoldToSfAccountId__c changed on SoldToSfAccount__c assignment from SoldToSfAccountId__c.');
		System.assertEquals(''+accountId,subscriptions[0].EntitleToSfAccountId__c,'EntitleToSfAccountId__c changed on EntitleToSfAccount__c assignment from EntitleToSfAccountId__c.');

		System.assertEquals(accountId,subscriptions[1].Account__c,'Account__c changed on AccountId__c assignment from Account__c.');
		System.assertEquals(accountId,subscriptions[1].BillToSalesAccount__c,'BillToSalesAccount__c changed on BillToSfAccountId__c assignment from BillToSalesAccount__c.');
		System.assertEquals(accountId,subscriptions[1].ShipToSalesAccount__c,'ShipToSalesAccount__c changed on ShipToSfAccountId__c assignment from ShipToSalesAccount__c.');
		System.assertEquals(accountId,subscriptions[1].SoldToSalesAccount__c,'SoldToSalesAccount__c changed on SoldToSfAccountId__c assignment from SoldToSalesAccount__c.');
		System.assertEquals(accountId,subscriptions[1].EntitleToSalesAccount__c,'EntitleToSalesAccount__c changed on EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c.');

		System.assertEquals(''+accountId,subscriptions[1].AccountId__c,'AccountId__c assignment from Account__c failed.');
		System.assertEquals(''+accountId,subscriptions[1].BillToSfAccountId__c,'BillToSfAccountId__c assignment from BillToSalesAccount__c failed.');
		System.assertEquals(''+accountId,subscriptions[1].ShipToSfAccountId__c,'ShipToSfAccountId__c assignment from ShipToSalesAccount__c failed.');
		System.assertEquals(''+accountId,subscriptions[1].SoldToSfAccountId__c,'SoldToSfAccountId__c assignment from SoldToSalesAccount__c failed.');
		System.assertEquals(''+accountId,subscriptions[1].EntitleToSfAccountId__c,'EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c failed.');

		System.assertEquals(null,subscriptions[2].Account__c,'Did not expect Account__c assignment from '+dummyAccountId);
		System.assertEquals(null,subscriptions[2].BillToSalesAccount__c,'Did not expect BillToSalesAccount__c assignment from '+dummyAccountId);
		System.assertEquals(null,subscriptions[2].ShipToSalesAccount__c,'Did not expect ShipToSalesAccount__c assignment from '+dummyAccountId);
		System.assertEquals(null,subscriptions[2].SoldToSalesAccount__c,'Did not expect SoldToSalesAccount__c assignment from '+dummyAccountId);
		System.assertEquals(null,subscriptions[2].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c assignment from '+dummyAccountId);

		System.assertEquals(null,subscriptions[2].AccountId__c,'Did not expect AccountId__c to change');
		System.assertEquals(null,subscriptions[2].BillToSfAccountId__c,'Did not expect BillToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[2].ShipToSfAccountId__c,'Did not expect ShipToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[2].SoldToSfAccountId__c,'Did not expect SoldToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[2].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		System.assertEquals(null,subscriptions[3].Account__c,'Did not expect Account__c assignment from DOG FOOD');
		System.assertEquals(null,subscriptions[3].BillToSalesAccount__c,'Did not expect BillToSalesAccount__c assignment from DOG FOOD');
		System.assertEquals(null,subscriptions[3].ShipToSalesAccount__c,'Did not expect ShipToSalesAccount__c assignment from DOG FOOD');
		System.assertEquals(null,subscriptions[3].SoldToSalesAccount__c,'Did not expect SoldToSalesAccount__c assignment from DOG FOOD');
		System.assertEquals(null,subscriptions[3].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c assignment from DOG FOOD');

		System.assertEquals('DOG FOOD',subscriptions[3].AccountId__c,'Did not expect AccountId__c to change');
		System.assertEquals('DOG FOOD',subscriptions[3].BillToSfAccountId__c,'Did not expect BillToSfAccountId__c to change');
		System.assertEquals('DOG FOOD',subscriptions[3].ShipToSfAccountId__c,'Did not expect ShipToSfAccountId__c to change');
		System.assertEquals('DOG FOOD',subscriptions[3].SoldToSfAccountId__c,'Did not expect SoldToSfAccountId__c to change');
		System.assertEquals('DOG FOOD',subscriptions[3].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptions[1].Account__c = dummyAccountId;
		subscriptions[1].AccountId__c = accountId;
		subscriptions[1].BillToSalesAccount__c = dummyAccountId;
		subscriptions[1].BillToSfAccountId__c = accountId;
		subscriptions[1].ShipToSalesAccount__c = dummyAccountId;
		subscriptions[1].ShipToSfAccountId__c = accountId;
		subscriptions[1].SoldToSalesAccount__c = dummyAccountId;
		subscriptions[1].SoldToSfAccountId__c = accountId;
		subscriptions[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptions[1].EntitleToSfAccountId__c = accountId;

		triggerBefore = new SubscriptionTriggerBefore(new Map<Id,Subscription__c>{subscriptions[1].Id=>subscriptions[0]},new List<Subscription__c>{subscriptions[1]});
		triggerBefore.syncAccountFields();

		System.assertEquals(dummyAccountId,subscriptions[1].Account__c,'Account__c changed on AccountId__c assignment from Account__c.');
		System.assertEquals(dummyAccountId,subscriptions[1].BillToSalesAccount__c,'BillToSalesAccount__c changed on BillToSfAccountId__c assignment from BillToSalesAccount__c.');
		System.assertEquals(dummyAccountId,subscriptions[1].ShipToSalesAccount__c,'ShipToSalesAccount__c changed on ShipToSfAccountId__c assignment from ShipToSalesAccount__c.');
		System.assertEquals(dummyAccountId,subscriptions[1].SoldToSalesAccount__c,'SoldToSalesAccount__c changed on SoldToSfAccountId__c assignment from SoldToSalesAccount__c.');
		System.assertEquals(dummyAccountId,subscriptions[1].EntitleToSalesAccount__c,'EntitleToSalesAccount__c changed on EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c.');

		System.assertEquals(''+dummyAccountId,subscriptions[1].AccountId__c,'AccountId__c assignment from Account__c failed.');
		System.assertEquals(''+dummyAccountId,subscriptions[1].BillToSfAccountId__c,'BillToSfAccountId__c assignment from BillToSalesAccount__c failed.');
		System.assertEquals(''+dummyAccountId,subscriptions[1].ShipToSfAccountId__c,'ShipToSfAccountId__c assignment from ShipToSalesAccount__c failed.');
		System.assertEquals(''+dummyAccountId,subscriptions[1].SoldToSfAccountId__c,'SoldToSfAccountId__c assignment from SoldToSalesAccount__c failed.');
		System.assertEquals(''+dummyAccountId,subscriptions[1].EntitleToSfAccountId__c,'EntitleToSfAccountId__c assignment from EntitleToSalesAccount__c failed.');

		subscriptions[1].Account__c = accountId;
		subscriptions[1].BillToSalesAccount__c = accountId;
		subscriptions[1].ShipToSalesAccount__c = accountId;
		subscriptions[1].SoldToSalesAccount__c = accountId;
		subscriptions[1].EntitleToSalesAccount__c = accountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptions[1].Account__c,'Expect Account__c to change');
		System.assertEquals(null,subscriptions[1].BillToSalesAccount__c,'Expect BillToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].ShipToSalesAccount__c,'Expect ShipToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].SoldToSalesAccount__c,'Expect SoldToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptions[1].AccountId__c,'Expect AccountId__c to change');
		System.assertEquals(null,subscriptions[1].BillToSfAccountId__c,'Expect BillToSfAccountId__c to change from '+dummyAccountId);
		System.assertEquals(null,subscriptions[1].ShipToSfAccountId__c,'Expect ShipToSfAccountId__c to change from '+dummyAccountId);
		System.assertEquals(null,subscriptions[1].SoldToSfAccountId__c,'Expect SoldToSfAccountId__c to change from '+dummyAccountId);
		System.assertEquals(null,subscriptions[1].EntitleToSfAccountId__c,'Expect EntitleToSfAccountId__c to change from '+dummyAccountId);

		subscriptions[0].Account__c = dummyAccountId;
		subscriptions[0].AccountId__c = dummyAccountId;
		subscriptions[0].BillToSalesAccount__c = dummyAccountId;
		subscriptions[0].BillToSfAccountId__c = dummyAccountId;
		subscriptions[0].ShipToSalesAccount__c = dummyAccountId;
		subscriptions[0].ShipToSfAccountId__c = dummyAccountId;
		subscriptions[0].SoldToSalesAccount__c = dummyAccountId;
		subscriptions[0].SoldToSfAccountId__c = dummyAccountId;
		subscriptions[0].EntitleToSalesAccount__c = dummyAccountId;
		subscriptions[0].EntitleToSfAccountId__c = dummyAccountId;
		subscriptions[1].Account__c = dummyAccountId;
		subscriptions[1].AccountId__c = accountId;
		subscriptions[1].BillToSalesAccount__c = dummyAccountId;
		subscriptions[1].BillToSfAccountId__c = accountId;
		subscriptions[1].ShipToSalesAccount__c = dummyAccountId;
		subscriptions[1].ShipToSfAccountId__c = accountId;
		subscriptions[1].SoldToSalesAccount__c = dummyAccountId;
		subscriptions[1].SoldToSfAccountId__c = accountId;
		subscriptions[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptions[1].EntitleToSfAccountId__c = accountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(accountId,subscriptions[1].Account__c,'Expect Account__c to change');
		System.assertEquals(accountId,subscriptions[1].BillToSalesAccount__c,'Expect BillToSalesAccount__c to change');
		System.assertEquals(accountId,subscriptions[1].ShipToSalesAccount__c,'Expect ShipToSalesAccount__c to change');
		System.assertEquals(accountId,subscriptions[1].SoldToSalesAccount__c,'Expect SoldToSalesAccount__c to change');
		System.assertEquals(accountId,subscriptions[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(accountId,subscriptions[1].AccountId__c,'Did not expect AccountId__c to change');
		System.assertEquals(accountId,subscriptions[1].BillToSfAccountId__c,'Did not expect BillToSfAccountId__c to change');
		System.assertEquals(accountId,subscriptions[1].ShipToSfAccountId__c,'Did not expect ShipToSfAccountId__c to change');
		System.assertEquals(accountId,subscriptions[1].SoldToSfAccountId__c,'Did not expect SoldToSfAccountId__c to change');
		System.assertEquals(accountId,subscriptions[1].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptions[1].Account__c = dummyAccountId;
		subscriptions[1].AccountId__c = null;
		subscriptions[1].BillToSalesAccount__c = dummyAccountId;
		subscriptions[1].BillToSfAccountId__c = null;
		subscriptions[1].ShipToSalesAccount__c = dummyAccountId;
		subscriptions[1].ShipToSfAccountId__c = null;
		subscriptions[1].SoldToSalesAccount__c = dummyAccountId;
		subscriptions[1].SoldToSfAccountId__c = null;
		subscriptions[1].EntitleToSalesAccount__c = dummyAccountId;
		subscriptions[1].EntitleToSfAccountId__c = null;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptions[1].Account__c,'Expect Account__c to change');
		System.assertEquals(null,subscriptions[1].BillToSalesAccount__c,'Expect BillToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].ShipToSalesAccount__c,'Expect ShipToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].SoldToSalesAccount__c,'Expect SoldToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].EntitleToSalesAccount__c,'Expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptions[1].AccountId__c,'Did not expect AccountId__c to change');
		System.assertEquals(null,subscriptions[1].BillToSfAccountId__c,'Did not expect BillToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].ShipToSfAccountId__c,'Did not expect ShipToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].SoldToSfAccountId__c,'Did not expect SoldToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].EntitleToSfAccountId__c,'Did not expect EntitleToSfAccountId__c to change');

		subscriptions[1].AccountId__c = dummyAccountId;
		subscriptions[1].BillToSfAccountId__c = dummyAccountId;
		subscriptions[1].ShipToSfAccountId__c = dummyAccountId;
		subscriptions[1].SoldToSfAccountId__c = dummyAccountId;
		subscriptions[1].EntitleToSfAccountId__c = dummyAccountId;

		triggerBefore.syncAccountFields();

		System.assertEquals(null,subscriptions[1].Account__c,'Did not expect Account__c to change');
		System.assertEquals(null,subscriptions[1].BillToSalesAccount__c,'Did not expect BillToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].ShipToSalesAccount__c,'Did not expect ShipToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].SoldToSalesAccount__c,'Did not expect SoldToSalesAccount__c to change');
		System.assertEquals(null,subscriptions[1].EntitleToSalesAccount__c,'Did not expect EntitleToSalesAccount__c to change');

		System.assertEquals(null,subscriptions[1].AccountId__c,'Expect AccountId__c to change');
		System.assertEquals(null,subscriptions[1].BillToSfAccountId__c,'Expect BillToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].ShipToSfAccountId__c,'Expect ShipToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].SoldToSfAccountId__c,'Expect SoldToSfAccountId__c to change');
		System.assertEquals(null,subscriptions[1].EntitleToSfAccountId__c,'Expect EntitleToSfAccountId__c to change');

		Test.stopTest();
	}

	@isTest
	static void syncCampaignFieldsTest() {
		Id campaignId = getCampaignId();
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		// assign only Campaign__c
		subscriptions[0].Campaign__c = campaignId;
		subscriptions[0].CampaignId__c = null;
		// assign only CampaignId__c
		subscriptions[1].Campaign__c = null;
		subscriptions[1].CampaignId__c = campaignId;
		// assign only CampaignId__c an invalid campaign Id
		Id dummyCampaignId = (''+campaignId).substring(0,4)+'00000000000';
		subscriptions[2].Campaign__c = null;
		subscriptions[2].CampaignId__c = dummyCampaignId;
		// assign a completely bogus value to CampaignId__c
		subscriptions[3].Campaign__c = null;
		subscriptions[3].CampaignId__c = 'DOG FOOD';
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Test.startTest();
		triggerBefore.syncCampaignFields();

		System.assertEquals(campaignId,subscriptions[0].Campaign__c,'Campaign__c assignment from CampaignId__c failed.');

		System.assertEquals(''+campaignId,subscriptions[0].CampaignId__c,'CampaignId__c changed on Campaign__c assignment from CampaignId__c.');

		System.assertEquals(campaignId,subscriptions[1].Campaign__c,'Campaign__c changed on CampaignId__c assignment from Campaign__c.');

		System.assertEquals(''+campaignId,subscriptions[1].CampaignId__c,'CampaignId__c assignment from Campaign__c failed.');

		System.assertEquals(null,subscriptions[2].Campaign__c,'Did not expect Campaign__c assignment from '+dummyCampaignId);

		System.assertEquals(null,subscriptions[2].CampaignId__c,'Did not expect CampaignId__c to change');

		System.assertEquals(null,subscriptions[3].Campaign__c,'Did not expect Campaign__c assignment from DOG FOOD');

		System.assertEquals('DOG FOOD',subscriptions[3].CampaignId__c,'Did not expect CampaignId__c to change');

		subscriptions[1].Campaign__c = dummyCampaignId;
		subscriptions[1].CampaignId__c = campaignId;

		triggerBefore = new SubscriptionTriggerBefore(new Map<Id,Subscription__c>{subscriptions[1].Id=>subscriptions[0]},new List<Subscription__c>{subscriptions[1]});
		triggerBefore.syncCampaignFields();

		System.assertEquals(dummyCampaignId,subscriptions[1].Campaign__c,'Campaign__c changed on CampaignId__c assignment from Campaign__c.');

		System.assertEquals(''+dummyCampaignId,subscriptions[1].CampaignId__c,'CampaignId__c assignment from Campaign__c failed.');

		subscriptions[1].Campaign__c = campaignId;

		triggerBefore.syncCampaignFields();

		System.assertEquals(null,subscriptions[1].Campaign__c,'Expect Campaign__c to change');

		System.assertEquals(null,subscriptions[1].CampaignId__c,'Expect CampaignId__c to change');

		subscriptions[0].Campaign__c = dummyCampaignId;
		subscriptions[0].CampaignId__c = dummyCampaignId;
		subscriptions[1].Campaign__c = dummyCampaignId;
		subscriptions[1].CampaignId__c = campaignId;

		triggerBefore.syncCampaignFields();

		System.assertEquals(campaignId,subscriptions[1].Campaign__c,'Expect Campaign__c to change');

		System.assertEquals(campaignId,subscriptions[1].CampaignId__c,'Did not expect CampaignId__c to change');

		subscriptions[1].Campaign__c = dummyCampaignId;
		subscriptions[1].CampaignId__c = null;

		triggerBefore.syncCampaignFields();

		System.assertEquals(null,subscriptions[1].Campaign__c,'Expect Campaign__c to change');

		System.assertEquals(null,subscriptions[1].CampaignId__c,'Did not expect CampaignId__c to change');

		subscriptions[1].CampaignId__c = dummyCampaignId;

		triggerBefore.syncCampaignFields();

		System.assertEquals(null,subscriptions[1].Campaign__c,'Did not expect Campaign__c to change');

		System.assertEquals(null,subscriptions[1].CampaignId__c,'Expect CampaignId__c to change');

		Test.stopTest();
	}

	@isTest
	static void syncOriginalOpportunityFieldsTest() {
		Id oppId = getOpportunityId();
		List<Subscription__c> subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
		// assign only OriginalOpportunity__c
		subscriptions[0].OriginalOpportunity__c = oppId;
		subscriptions[0].OriginalOpportunityId__c = null;
		// assign only OriginalOpportunityId__c
		subscriptions[1].OriginalOpportunity__c = null;
		subscriptions[1].OriginalOpportunityId__c = oppId;
		// assign only OriginalOpportunityId__c an invalid campaign Id
		Id dummyOpportunityId = (''+oppId).substring(0,4)+'00000000000';
		subscriptions[2].OriginalOpportunity__c = null;
		subscriptions[2].OriginalOpportunityId__c = dummyOpportunityId;
		// assign a completely bogus value to OriginalOpportunityId__c
		subscriptions[3].OriginalOpportunity__c = null;
		subscriptions[3].OriginalOpportunityId__c = 'DOG FOOD';
		SubscriptionTriggerBefore triggerBefore = new SubscriptionTriggerBefore(null,subscriptions);
		Test.startTest();
		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(oppId,subscriptions[0].OriginalOpportunity__c,'OriginalOpportunity__c assignment from OriginalOpportunityId__c failed.');

		System.assertEquals(''+oppId,subscriptions[0].OriginalOpportunityId__c,'OriginalOpportunityId__c changed on OriginalOpportunity__c assignment from OriginalOpportunityId__c.');

		System.assertEquals(oppId,subscriptions[1].OriginalOpportunity__c,'OriginalOpportunity__c changed on OriginalOpportunityId__c assignment from OriginalOpportunity__c.');

		System.assertEquals(''+oppId,subscriptions[1].OriginalOpportunityId__c,'OriginalOpportunityId__c assignment from OriginalOpportunity__c failed.');

		System.assertEquals(null,subscriptions[2].OriginalOpportunity__c,'Did not expect OriginalOpportunity__c assignment from '+dummyOpportunityId);

		System.assertEquals(null,subscriptions[2].OriginalOpportunityId__c,'Did not expect OriginalOpportunityId__c to change');

		System.assertEquals(null,subscriptions[3].OriginalOpportunity__c,'Did not expect OriginalOpportunity__c assignment from DOG FOOD');

		System.assertEquals('DOG FOOD',subscriptions[3].OriginalOpportunityId__c,'Did not expect OriginalOpportunityId__c to change');

		subscriptions[1].OriginalOpportunity__c = dummyOpportunityId;
		subscriptions[1].OriginalOpportunityId__c = oppId;

		triggerBefore = new SubscriptionTriggerBefore(new Map<Id,Subscription__c>{subscriptions[1].Id=>subscriptions[0]},new List<Subscription__c>{subscriptions[1]});
		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(dummyOpportunityId,subscriptions[1].OriginalOpportunity__c,'OriginalOpportunity__c changed on OriginalOpportunityId__c assignment from OriginalOpportunity__c.');

		System.assertEquals(''+dummyOpportunityId,subscriptions[1].OriginalOpportunityId__c,'OriginalOpportunityId__c assignment from OriginalOpportunity__c failed.');

		subscriptions[1].OriginalOpportunity__c = oppId;

		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(null,subscriptions[1].OriginalOpportunity__c,'Expect OriginalOpportunity__c to change');

		System.assertEquals(null,subscriptions[1].OriginalOpportunityId__c,'Expect OriginalOpportunityId__c to change');

		subscriptions[0].OriginalOpportunity__c = dummyOpportunityId;
		subscriptions[0].OriginalOpportunityId__c = dummyOpportunityId;
		subscriptions[1].OriginalOpportunity__c = dummyOpportunityId;
		subscriptions[1].OriginalOpportunityId__c = oppId;

		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(oppId,subscriptions[1].OriginalOpportunity__c,'Expect OriginalOpportunity__c to change');

		System.assertEquals(oppId,subscriptions[1].OriginalOpportunityId__c,'Did not expect OriginalOpportunityId__c to change');

		subscriptions[1].OriginalOpportunity__c = dummyOpportunityId;
		subscriptions[1].OriginalOpportunityId__c = null;

		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(null,subscriptions[1].OriginalOpportunity__c,'Expect OriginalOpportunity__c to change');

		System.assertEquals(null,subscriptions[1].OriginalOpportunityId__c,'Did not expect OriginalOpportunityId__c to change');

		subscriptions[1].OriginalOpportunityId__c = dummyOpportunityId;

		triggerBefore.syncOriginalOpportunityFields();

		System.assertEquals(null,subscriptions[1].OriginalOpportunity__c,'Did not expect OriginalOpportunity__c to change');

		System.assertEquals(null,subscriptions[1].OriginalOpportunityId__c,'Expect OriginalOpportunityId__c to change');

		Test.stopTest();
	}

	@isTest
	static void processTriggerTest() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		AbstractTrigger.setBooleanSettings('Sub_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<Subscription__c> subscriptions = new List<Subscription__c>{subscription};
		Map<Id,Subscription__c> oldMap = new Map<Id,Subscription__c>{ subscription.Id => subscription };
		List<Subscription__c> newList = subscriptions.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Sub_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		SubscriptionTriggerBefore.processTrigger(null,newList);
		// update
		newList = subscriptions.deepClone(true);
		SubscriptionTriggerBefore.processTrigger(oldMap,newList);
		// delete
		SubscriptionTriggerBefore.processTrigger(oldMap,null);
	}

	@isTest
	static void deployTest() {
		Subscription__c subscription = SubscriptionBatchTriggerAfterTest.subscriptions[0];
		AbstractTriggerTest.deployTest('Sub_Before.',new List<Subscription__c>{subscription});
	}
}