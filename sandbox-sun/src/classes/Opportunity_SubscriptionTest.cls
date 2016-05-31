/**
 * Test class for Opportunity_Subscription
 *
 * @version 2015-04-28
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-04-28 - Added tests for conversion of operating unit for WEB STANDARD - US.
 * 2015-03-27 - HACK ALERT - By pass some of the triggers in the createRenewalOpportunity tests to avoid SQL queries limit
 * 2015-03-24 - Updated to support operating unit and finincial partner errors, removed deferredErrors
 * 2015-03-17 - expose getOpportunityId
 * 2015-03-03 - Removed getStageNameTest, as values are now assigned from maps.
 * 2015-01-29 - refactored
 * 2015-01-27 - Test financial partner
 * 2015-01-22 - Updated to support refactored code
 * 2015-01-15 - New fulfillment channel test
 * 2015-01-14 - Updated to support Opportunity_Subscription refactoring
 * 2014-12-11 - Added c360 accounts
 * 2014-11-24 - Added back in campaign tests
 * 2013-10-06 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2014-01-08 - Update to use previously mapped subscription contacts on opportunity
 * 2014-01-13 - Update to use previously mapped source opportunity when creating renewal opp
 */
@isTest
public class Opportunity_SubscriptionTest {
	//
	// create the opportunity object hierarchy
	//

	static Campaign campaign { get {
		if(campaign == null) {
			// create a campaign
			campaign = new Campaign(Name = 'Test Campaign');
		}
		return campaign;
	}}

	static Id getCampaignId() {
		if(campaign.Id == null) {
			insert campaign;
		}
		return campaign.Id;
	}

	static Product2 happyBall { get {
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

	static PricebookEntry globalPricebookEntry { get {
		if(globalPricebookEntry == null) {
			// create a pricebook entry for the global pricebook
			globalPricebookEntry = new PricebookEntry(
				CurrencyIsoCode = 'USD',
				IsActive = true,
				Product2Id = happyBall.Id,
				UnitPrice = 2000.00);
			globalPricebookEntry.Pricebook2Id = Account_MatchingTest.customPB.Id;
//			for(PriceBook2 pb : [SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book' and IsActive = true limit 1]) {
//				globalPricebookEntry.Pricebook2Id = pb.Id;
//			}
		}
		return globalPricebookEntry;
	}}

	static Id getGlobalPricebookEntryId() {
		if(globalPricebookEntry.Id == null && globalPricebookEntry.Pricebook2Id != null) {
			// create a pricebook entry for the standard pricebook
			PricebookEntry pricebookEntry1 = globalPricebookEntry.clone();
			// get the id of the standard price book
//			for(Pricebook2 pb : [SELECT Id FROM PriceBook2 WHERE isStandard = true and IsActive = true limit 1] ) {
//				pricebookEntry1.Pricebook2Id = pb.Id;
//			}
			pricebookEntry1.Pricebook2Id = Account_MatchingTest.pricebookId;
			insert new List<PricebookEntry>{priceBookEntry1,globalPricebookEntry};
			System.debug(happyBall);
			System.debug(pricebookEntry1);
			System.debug(globalPricebookEntry);
		}
		return globalPricebookEntry.Id;
	}

	static Account account {
		get {
			if(account == null) {
				account = new Account(
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					CurrencyIsoCode = globalPricebookEntry.CurrencyIsoCode,
					Name = 'Red Hat',
					OracleAccountNumber__c = '12345',
					Owner = new User(Id=UserInfo.getUserId(),IsActive=true),
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

	static Id getAccountId() {
		if(account.Id == null) {
			insert account;
		}
		return account.Id;
	}

	static BillToAccount__c billToAccount {
		get {
			if(billToAccount == null) {
				billToAccount = new BillToAccount__c(
					Bill_To_Account_Number__c=account.OracleAccountNumber__c,
					Channel_Code__c='Direct - End Customer',
					Region__c='EMEA');
			}
			return billToAccount;
		}
	}

	static Id getBillToAccountId() {
		if(billToAccount.Id == null) {
			AdminByPass__c adminByPass = AdminByPass__c.getInstance();
			adminByPass.IsBillToAdmin__c = true;
			upsert adminByPass;
			insert billToAccount;
		}
		return billToAccount.Id;
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					AccountId = account.Id,
					CloseDate = Date.today(),
					Country_Of_Order__c = 'Japan',
					CurrencyIsoCode = globalPricebookEntry.CurrencyIsoCode,
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

	public static Id getOpportunityId() {
		if(opportunity.Id == null) {
			String orderNumber = opportunity.OracleOrderNumber__c;
			opportunity.AccountId = getAccountId();
			insert opportunity;
			Opportunity opp = [
				select
					AccountId,
					BillingAccountNumber__c,
					CampaignId,
					CloseDate,
					Country_of_Order__c,
					CurrencyIsoCode,
					FulfillmentChannel__c,
					Name,
					OpportunityType__c,
					OpportunityNumber__c,
					OracleOrderNumber__c,
					Owner.IsActive,
					PaymentType__c,
					PONumber__c,
					Pricebook2Id,
					Primary_Partner__c,
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

	static Contact contact { get {
		if(contact == null) {
			contact = new Contact(
				AccountId = account.Id,
				OwnerId = UserInfo.getUserId(),
				FirstName = 'first name',
				LastName = 'last name',
				Email = 'test@nowhere.com',
				Phone = '1-800-555-1212');
		}
		return contact;
	} }

	static Id getContactId() {
		if(contact.Id == null) {
			contact.AccountId = getAccountId();
			insert contact;
		}
		return contact.Id;
	}

	static List<OpportunityContactRole> contactRoles { get {
		if(contactRoles == null) {
			contactRoles = new List<OpportunityContactRole>{
				new OpportunityContactRole(
					OpportunityId = getOpportunityId(),
					ContactId = getContactId(),
					Role = Opportunity_Subscription.SHIPPING_CONTACT_ROLE),
				new OpportunityContactRole(
					OpportunityId = getOpportunityId(),
					ContactId = getContactId(),
					Role = 'Payables Contact')
			};
		}
		return contactRoles;
	} }

	static List<EBS_Account__c> ebsAccounts {
		get { return Account_MatchingTest.ebsAccounts; }
	}

	static List<EBS_Account__c> partnerEBSAccounts {
		get { return Account_MatchingTest.partnerEBSAccounts; }
	}

	static Map<Id,EBS_Account__c> ebsAccountMap {
		get { return Account_MatchingTest.ebsAccountMap; }
	}

	static List<Address__c> addresses {
		get { return Account_MatchingTest.addresses; }
	}

	static Map<Id,Address__c> addressMap {
		get { return Account_MatchingTest.addressMap; }
	}

	static List<Contact> contacts {
		get { return Account_MatchingTest.contacts; }
	}

	static Map<Id,Contact> contactMap {
		get { return Account_MatchingTest.contactMap; }
	}

	public static Subscription__c subscription1 { get {
		if(subscription1 == null) {
			System.assert(! ebsAccountMap.isEmpty());
			System.assert(! addressMap.isEmpty());
			System.assert(! contactMap.isEmpty());
			subscription1 = new Subscription__c(
				Account__r = account,
				Account__c = getAccountId(),
				AssignTo__c = null,
				AssignToId__c = null,
				BillToAccountNumber__c = ebsAccounts[0].Name,// account.OracleAccountNumber__c,
				BillToAddress1__c = account.BillingStreet,
				BillToAddress2__c = null,
				BillToCity__c = account.BillingCity,
				BillToCountry__c = account.BillingCountry,
				BillToPartyName__c = reseller.Name,
				BillToPostalCode__c = account.BillingPostalCode,
				BillToState__c = account.BillingState,
//				BillToAccountNumber__c = ebsAccounts[0].Name,
				BillToCDHPartyNumber__c = ebsAccounts[0].CDH_Party_Number__c,
				BillToCDHPartySiteNumber__c = addresses[0].CDH_Party_Site_Number__c,
				BillToContCDHPartyNumber__c = contacts[0].CDH_Party__r.CDH_Party_Number_Ext__c,
				BillToContactEmail__c = contacts[0].Email,
				// BillToCountry__c = addresses[0].Country__c,
				BillToAddress__c = addresses[0].Id,
				BillToContact__c = contacts[0].Id,
				BillToEBSAccount__c = ebsAccounts[0].Id,
				BillToSfAddressId__c = addresses[0].Id,
				BillToSfContactId__c = contacts[0].Id,
				BillToSfEBSAccountId__c = ebsAccounts[0].Id,
				BusinessUnitName__c = Opportunity_Subscription.operatingUnitValues.iterator().next().toUpperCase(),
				Campaign__c = getCampaignId(),
				CampaignId__c = getCampaignId(),
				ContractAmount__c = globalPricebookEntry.UnitPrice,
				ContractEndDate__c = Date.today().addYears(1),
				ContractId__c = Decimal.valueOf('-312215540494148380.'),
//				ContractNumber__c,
				ContractStartDate__c = Date.today(),
				CountryOfOrder__c = opportunity.Country_of_Order__c,
				CurrencyIsoCode = globalPricebookEntry.CurrencyIsoCode,
				EntitleToAccountNumber__c = ebsAccounts[1].Name,
				EntitleToCDHPartyNumber__c = ebsAccounts[1].CDH_Party_Number__c,
				EntitleToCDHPartySiteNumber__c = addresses[1].CDH_Party_Site_Number__c,
				EntitleToContCDHPartyNumber__c = contacts[1].CDH_Party__r.CDH_Party_Number_Ext__c,
				EntitleToContactEmail__c = contacts[1].Email,
				EntitleToCountry__c = addresses[1].Country__c,
				EntitleToAddress__c = addresses[1].Id,
				EntitleToContact__c = contacts[1].Id,
				EntitleToEBSAccount__c = ebsAccounts[1].Id,
				EntitleToSfAddressId__c = addresses[1].Id,
				EntitleToSfContactId__c = contacts[1].Id,
				EntitleToSfEBSAccountId__c = ebsAccounts[1].Id,
//				ErrorMessage__c,
//				Opportunity__c,
				OrderId__c = Decimal.valueOf('-312215540494148381.'),
				OrderNumber__c = opportunity.OracleOrderNumber__c,
//				OrderSourceName__c,
				OrderTypeName__c = Opportunity_Subscription.WEB_STANDARD_US_ORDER_TYPE,
//				OriginalOpportunity__c,
				PurchaseOrderNumber__c = opportunity.PONumber__c,
				Region__c = opportunity.Region__c,
				SalesChannelCode__c = 'Direct End Customer',
//				ShippingContact__c,
				ShippingContact__c = contact.Id,
				ShipToAddress1__c = account.ShippingStreet,
				ShipToAddress2__c = null,
				ShipToCity__c = account.ShippingCity,
				ShipToContactEmail__c = contact.Email,
				ShipToContactFirstName__c = contact.FirstName,
				ShipToContactLastName__c = contact.LastName,
				ShipToContactName__c = contact.FirstName+' '+contact.LastName,
				ShipToContactPhone__c = contact.Phone,
				ShipToCountry__c = account.ShippingCountry,
				ShipToPostalCode__c = account.ShippingPostalCode,
				ShipToState__c = account.ShippingState,
				ShipToAccountNumber__c = ebsAccounts[2].Name,
				ShipToCDHPartyNumber__c = ebsAccounts[2].CDH_Party_Number__c,
				ShipToCDHPartySiteNumber__c = addresses[2].CDH_Party_Site_Number__c,
				ShipToContCDHPartyNumber__c = contacts[2].CDH_Party__r.CDH_Party_Number_Ext__c,
				// ShipToContactEmail__c = contacts[2].Email,
				// ShipToCountry__c = addresses[2].Country__c,
				ShipToAddress__c = addresses[2].Id,
				ShipToContact__c = contacts[2].Id,
				ShipToEBSAccount__c = ebsAccounts[2].Id,
				ShipToSfAddressId__c = addresses[2].Id,
				ShipToSfContactId__c = contacts[2].Id,
				ShipToSfEBSAccountId__c = ebsAccounts[2].Id,
				SoldToAccountNumber__c = account.OracleAccountNumber__c,
				SellingContact__c = contact.Id,
				SoldToContactEmail__c = contact.Email,
				SoldToContactFirstName__c = contact.FirstName,
				SoldToContactLastName__c = contact.LastName,
				SoldToContactName__c = contact.FirstName+' '+contact.LastName,
				SoldToContactPhone__c = contact.Phone,
				SoldToPartyName__c = account.Name,
				//SoldToAccountNumber__c = ebsAccounts[3].Name,
				SoldToCDHPartyNumber__c = ebsAccounts[3].CDH_Party_Number__c,
				SoldToCDHPartySiteNumber__c = addresses[3].CDH_Party_Site_Number__c,
				SoldToContCDHPartyNumber__c = contacts[3].CDH_Party__r.CDH_Party_Number_Ext__c,
				// SoldToContactEmail__c = contacts[3].Email,
				SoldToCountry__c = addresses[3].Country__c,
				SoldToAddress__c = addresses[3].Id,
				SoldToContact__c = contacts[3].Id,
				SoldToEBSAccount__c = ebsAccounts[3].Id,
				SoldToSfAddressId__c = addresses[3].Id,
				SoldToSfContactId__c = contacts[3].Id,
				SoldToSfEBSAccountId__c = ebsAccounts[3].Id,
				Status__c = SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS,
				SuperRegion__c = 'EMEA');
		}
		return subscription1;
	} }

	static Subscription__c subscription2 {
		get {
			if(subscription2 == null) {
				subscription2 = subscription1.clone();
				subscription2.OrderId__c = Decimal.valueOf('-312215540494148382.');
				subscription2.Status__c = 'MERGED';
			}
			return subscription2;
		}
	}
	public static Id getSubscriptionId() {
		if(subscription1.Id == null) {
			String status = subscription1.Status__c;
			subscription1.OpportunityNumber__c = opportunity.OpportunityNumber__c;
			insert new List<Subscription__c>{subscription1,subscription2};
			subscription1.Status__c = status;
		}
		return subscription1.Id;
	}

	static List<SubscriptionLine__c> subscriptionLines { get {
		if(subscriptionLines == null) {
			SubscriptionLine__c subLine1 = new SubscriptionLine__c(
					ConfiguredItem__c = happyBall.ProductCode,
					ContractId__c = subscription1.ContractId__c,
					ContractLineId__c = '-TEST1',
					ErrorMessage__c = null,
					ExpiringProduct__c = null,
					FulfilledItemDescription__c = happyBall.Description,
					OpportunityLineItemId__c = null,
					OrderId__c = subscription1.OrderId__c,
					OrderedItem__c = happyBall.ProductCode,
					OrderedQuantity__c = 1.0,
					OrderLineId__c = null,
					RenewalItem__c = happyBall.ProductCode,
					ServiceEndDate__c = Date.today().addYears(1),
					ServiceStartDate__c = Date.today(),
					Status__c = 'Ready',
					SubstituteItem__c = happyBall.ProductCode,
					NetTotalPrice__c = globalPricebookEntry.UnitPrice,
					NetUnitSellingPrice__c = globalPricebookEntry.UnitPrice,
					TotalPrice__c = globalPricebookEntry.UnitPrice * 0.5,
					UnitSellingPrice__c = globalPricebookEntry.UnitPrice * 0.5);
					SubscriptionLine__c subLine2 = subLine1.clone();
					subLine2.ContractLineId__c = '-TEST2';
					subLine2.OrderId__c = subscription2.OrderId__c;
					subLine2.SubscriptionCompositeKey__c = subscription1.ContractId__c.longValue()+':'+subscription1.OrderId__c.longValue();
					subscriptionLines = new List<SubscriptionLine__c> {
						subLine1,
						subLine2 };
		}
		return subscriptionLines;
	} }

	public static Map<Id,SubscriptionLine__c> subscriptionLineMap { get {
		if(subscriptionLineMap == null) {
			for(SubscriptionLine__c lineItem : subscriptionLines) {
				lineItem.Subscription__c = getSubscriptionId();
			}
			upsert subscriptionLines;
			subscriptionLineMap = new Map<Id,SubscriptionLine__c>(subscriptionLines);
			update subscription1;
		}
		return subscriptionLineMap;
	}}

	static Account reseller { get {
		if ( reseller == null ) {
			reseller = partnerEBSAccounts[0].Sales_Account__r;
//			reseller.OracleAccountNumber__c = '123456';
//			reseller.RecordTypeId = RecordTypeLookup.getRecordTypeId('APAC Partner','Account');
//			reseller.OraclePartyNumber__c = '-424223';
		}
		return reseller;
	} }

	static Id getResellerId() {
		if(reseller.Id == null) {
			System.assert(! ebsAccountMap.isEmpty());
		}
		return reseller.Id;
	}

	static PartnerStatus__c partnerStatus {
		get {
			if(partnerStatus == null) {
				Classification__c pType = new Classification__c(Name='Partner Type');
				Classification__c pTier = new Classification__c(Name='Partner Tier');
				for(Classification__c c : [
					select Name 
					from Classification__c 
					where Name in ('Partner Type','Partner Tier') 
						and Parent__c = null])
				{
					if(c.Name == 'Partner Type') {
						pType = c;
					}
					else if(c.Name == 'Partner Tier')
					{
						pTier = c;
					}
				}

				if(pType.Id == null || pTier.Id == null) {
					upsert new List<Classification__c>{pType,pTier};
				}
				Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
				Classification__c cType = new Classification__c(Name=Opportunity_Subscription.RESELLER_TYPE,Parent__c=pType.Id);
				for(Classification__c ct : [
					select Name, Parent__c
					from Classification__c
					where Parent__c = :pType.Id
						and Name = :Opportunity_Subscription.RESELLER_TYPE
					limit 1 ] )
				{
					cType = ct;
				}
				upsert new List<Classification__c>{cTier,cType};
				// this is a sad story...
				List<RedHatObjectReferences__c> rhors = new List<RedHatObjectReferences__c>{
					new RedHatObjectReferences__c(
						Name='PARTNER_TYPE.ISV',
						ObjectId__c=cType.Id),
					new RedHatObjectReferences__c(
						Name='PARTNER_TIER.ADVANCED',
						ObjectId__c=cTier.Id) };
				Database.upsert(rhors,RedHatObjectReferences__c.SObjectType.fields.Name, false);
				partnerStatus = new PartnerStatus__c(
					ActivationDate__c = Date.today().addDays(-1),
					ApprovalStatus__c = 'Approved',
					ExpirationDate__c = Date.today().addDays(7),
					Partner__r = reseller,
					Partner__c = getResellerId(),
					PartnerTier__r = cTier,
					PartnerTier__c = cTier.Id,
					PartnerType__r = cType,
					PartnerType__c = cType.Id);
				insert partnerStatus;
			}
			return partnerStatus;
		}
	}

	static SubscriptionPartner__c subscriptionPartner1 { get {
		if(subscriptionPartner1 == null) {
			subscriptionPartner1 = new SubscriptionPartner__c(
				Account__c = getResellerId(),
				// AccountNumber__c,
				ApId__c = Decimal.valueOf('-312215540494148382.'),
				ContactEmail__c = contact.Email,
				ContactName__c = contact.FirstName+' '+contact.LastName,
				ContactPhone__c = contact.Phone,
				OrderId__c = subscription1.OrderId__c,
				PartnerStatus__c = partnerStatus.Id,
				PartyName__c = reseller.Name,
//				PurchaseOrderNumber__c = reseller.PONumber__c,
				PartyNumber__c = reseller.OraclePartyNumber__c
				);
		}
		return subscriptionPartner1;
	} }

	static Id getSubscriptionPartnerId() {
		if(subscriptionPartner1.Id == null) {
			insert subscriptionPartner1;
		}
		return subscriptionPartner1.Id;
	}

	static SubscriptionPartnerRelationship__c subscriptionPartnerRelationship1 { 
		get {
			if(subscriptionPartnerRelationship1 == null) {
				subscriptionPartnerRelationship1 = new SubscriptionPartnerRelationship__c(
					SubscriptionPartner__r=subscriptionPartner1 );
			}
			return subscriptionPartnerRelationship1;
		}
		set;
	}

	static Boolean firstAttempt = true;

	static Id getSubscriptionPartnerRelationshipId() {
		if(subscriptionPartnerRelationship1.Id == null && firstAttempt) {
			firstAttempt = false;
			subscriptionPartnerRelationship1.Subscription__c = getSubscriptionId();
			subscriptionPartnerRelationship1.SubscriptionPartner__c = getSubscriptionPartnerId();
			Database.insert(subscriptionPartnerRelationship1,false);
			if(subscriptionPartnerRelationship1.Id == null) {
				for(SubscriptionPartnerRelationship__c spr : [
					select Id
					from SubscriptionPartnerRelationship__c
					where Subscription__c = :getSubscriptionId()
						and SubscriptionPartner__c = :getSubscriptionPartnerId() ])
				{
					subscriptionPartnerRelationship1 = spr.clone(true);
					subscriptionPartnerRelationship1.SubscriptionPartner__r = subscriptionPartner1;
				}
			}
		}
		return subscriptionPartnerRelationship1.Id;
	}

	static void createRenewalOpportunityTestRegion(String superRegion,String region) {
		if(getGlobalPricebookEntryId() != null) {
			// HACK ALERT - by passing triggers to avoid sql query limit
			AbstractTrigger.setBooleanSettings('Opp_Before.',false);
			AbstractTrigger.setBooleanSettings('Opp_After.',false);
			AbstractTrigger.setBooleanSettings('LineItem_Before.',false);
			AbstractTrigger.setBooleanSettings('LineItem_After.',false);
			subscription1.Opportunity__c = getOpportunityId();			
			subscription1.SuperRegion__c = superRegion;
			subscription1.Region__c = region;
			getSubscriptionPartnerRelationshipId();
			PartnerStatus__c ps = partnerStatus;
			Map<Id,SubscriptionLine__c> lineMap = subscriptionLineMap;
			Test.startTest();
			Map<Id,List<Database.Error>> retval = Opportunity_Subscription.createRenewalOpportunities(new Set<Id>{ getSubscriptionId() }, true);
			Test.stopTest();
			for(Id subId : retval.keySet()) {
				for(Database.Error de : retval.get(subId)) {
					System.assert(false,'Database('+subId+')='+de);
				}
			}
			Subscription__c sub = [
				select
					Status__c,
					ErrorMessage__c,
					Opportunity__c,
					OrderTypeName__c
				from Subscription__c
				where Id = :subscription1.Id ];
			System.assertEquals(null,sub.ErrorMessage__c);
			System.assertEquals(Opportunity_Subscription.SUCCESS_STATUS,sub.Status__c);
			System.assertNotEquals(null,sub.Opportunity__c);
			Opportunity opp = [
				select
					Operating_Unit__c,
					Order_Type__c
				from Opportunity
				where Id = : sub.Opportunity__c ];
			System.assertEquals( sub.OrderTypeName__c, opp.Order_Type__c);
			if(sub.OrderTypeName__c == Opportunity_Subscription.WEB_STANDARD_US_ORDER_TYPE) {
				System.assertEquals( Opportunity_Subscription.RH_US_OPERATING_UNIT_NAME, opp.Operating_Unit__c );
			}
		}
	}

	@isTest //(SeeAllData=true)
	static void createRenewalOpportunityTestAPAC() {
		createRenewalOpportunityTestRegion('APAC',null);
	}

	@isTest //(SeeAllData=true)
	static void createRenewalOpportunityTestJAPAN() {
		createRenewalOpportunityTestRegion('JAPAN','JAPAN');
	}

	@isTest //(SeeAllData=true)
	static void createRenewalOpportunityTestEMEA() {
		createRenewalOpportunityTestRegion('EMEA',null);
	}

	@isTest //(SeeAllData=true)
	static void createRenewalOpportunityTestLATAM() {
		createRenewalOpportunityTestRegion('LATAM',null);
	}

	@isTest //(SeeAllData=true)
	static void createRenewalOpportunityTestNA() {
		createRenewalOpportunityTestRegion('NA',null);
	}

	@isTest
	static void createRenewalOpportunityTestNoLines() {
		insert subscription1;
		Test.startTest();
		Opportunity_Subscription.createRenewalOpportunities(new Set<Id>{subscription1.Id},true);
		Test.stopTest();
		// to do: test results
	}

	@isTest
	static void prepareErrorsTest() {
		getSubscriptionPartnerRelationshipId();
		PartnerStatus__c ps = partnerStatus;
		Test.startTest();
		Opportunity_Subscription oppSub = new Opportunity_Subscription( new Set<Id>() );
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			subscriptionLineMap.values(),
			new List<SubscriptionPartnerRelationship__c>{ subscriptionPartnerRelationship1 } );
		oppCreator.addError('anything','anything',true);
		System.assert(oppCreator.prepareErrors(),'Expected Errors');
		Test.stopTest();
		System.assertNotEquals(null,oppCreator.subscription.ContractEndDate__c);
	}

//legacy	@isTest
//legacy	static void getBillToAccountTest() {
//legacy		Id billToAccountId = getBillToAccountId();
//legacy		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
//legacy		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
//legacy			oppSub,
//legacy			new Subscription__c(BillToAccountNumber__c=billToAccount.Bill_To_Account_Number__c),
//legacy			new List<SubscriptionLine__c>(),
//legacy			new List<SubscriptionPartnerRelationship__c>() );
//legacy		BillToAccount__c bta = oppSub.billToAccountMap.get(billToAccount.Bill_To_Account_Number__c);
//legacy		System.assertEquals(billToAccountId,bta.Id);
//legacy	}

	@isTest
	static void insertOpportunityContactRolesTest() {
		opportunity.CampaignId = getCampaignId();
		Id opportunityId = getOpportunityId();
		insert contactRoles;
		Opportunity renewalOpp = opportunity.clone(false, false, false, false);
		insert renewalOpp;
		Opportunity_Subscription oppSub = new Opportunity_Subscription( new Set<Id>() );
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			new List<SubscriptionLine__c>(),
			new List<SubscriptionPartnerRelationship__c>() );
		oppCreator.setOpportunity(renewalOpp);
		subscription1.OriginalOpportunity__c = opportunityId;
		subscription1.OriginalOpportunity__r = opportunity;
		subscription1.SuperRegion__c = 'EMEA';
		Map<String,OpportunityContactRole> opportunityContactRoleMap = new Map<String,OpportunityContactRole>();
		Map<String,CampaignMember> campaignMemberMap = new Map<String,CampaignMember>();
		Test.startTest();
		oppCreator.copyOpportunityContactRoles(opportunityContactRoleMap,campaignMemberMap);
		System.assertEquals(contactRoles.size(),opportunityContactRoleMap.size());
		System.assertNotEquals(0,campaignMemberMap.size());
		campaignMemberMap.clear();
		opportunityContactRoleMap.clear();
		subscription1.SuperRegion__c = 'NA';
		oppCreator.addShippingContact(opportunityContactRoleMap,campaignMemberMap);
		System.assertEquals(1,opportunityContactRoleMap.size());
		System.assertEquals(1,campaignMemberMap.size());
		campaignMemberMap.clear();
		opportunityContactRoleMap.clear();
		oppCreator.addSellingContact(opportunityContactRoleMap,campaignMemberMap);
		System.assertEquals(1,opportunityContactRoleMap.size());
		System.assertEquals(1,campaignMemberMap.size());
		campaignMemberMap.clear();
		List<CampaignMember> campaignMembers = oppSub.insertOpportunityContactRoles(new List<Opportunity_Subscription.OppCreator>{oppCreator});
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		OpportunityContactRole contactRole1 = [
			select
				OpportunityId,
				ContactId,
				Role
			from OpportunityContactRole
			where ContactId = :getContactId()
				and OpportunityId = :renewalOpp.Id
			limit 1 ];
		System.assertNotEquals(0,campaignMembers.size());
		oppSub.insertCampaignMembers(campaignMembers);
		Test.stopTest();
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		CampaignMember cm = [
			select
				ContactId,
				CampaignId,
				Status
			from CampaignMember
			where ContactId = :getContactId()
				and CampaignId = : getCampaignId()
			limit 1 ];
	}

//depreciated	@isTest
//depreciated	static void createOrLinkContactTest() {
//depreciated		final String role = Opportunity_Subscription.SHIPPING_CONTACT_ROLE;
//depreciated		getAccountId();
//depreciated		User owner = [select IsActive from User where Id = :UserInfo.getUserId() ];
//depreciated		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
//depreciated		Id contactId = oppSub.createOrLinkContact(
//depreciated			false,
//depreciated			contact.AccountId,
//depreciated			getOpportunityId(),
//depreciated			owner,
//depreciated			getCampaignId(),
//depreciated			role,
//depreciated			contact.FirstName,
//depreciated			contact.LastName,
//depreciated			contact.Name,
//depreciated			contact.Email,
//depreciated			contact.Phone,
//depreciated			true,
//depreciated			null,
//depreciated			new Map<String,Contact>());
//depreciated		System.assertNotEquals(null,contactId);
//depreciated		Contact xcontact = [
//depreciated			select
//depreciated				AccountId,
//depreciated				OwnerId,
//depreciated				FirstName,
//depreciated				LastName,
//depreciated				Name,
//depreciated				Email,
//depreciated				Phone
//depreciated			from Contact
//depreciated			where Id = :contactId ];
//depreciated		System.assertEquals(getAccountId(),xcontact.AccountId);
//depreciated		OpportunityContactRole ocr = [
//depreciated			select
//depreciated				OpportunityId,
//depreciated				ContactId,
//depreciated				Role,
//depreciated				IsPrimary
//depreciated			from OpportunityContactRole
//depreciated			where ContactId = :contactId
//depreciated				and OpportunityId = :getOpportunityId()
//depreciated				and Role = :role
//depreciated			limit 1 ];
//depreciated		System.assertNotEquals(null,ocr);
//depreciated		System.assertEquals(contactId,ocr.ContactId);

//depreciated		delete ocr;
//depreciated		Test.startTest();
//depreciated		oppSub.createOrLinkContact(
//depreciated			false,
//depreciated			contact.AccountId,
//depreciated			getOpportunityId(),
//depreciated			owner,
//depreciated			getCampaignId(),
//depreciated			role,
//depreciated			contact.FirstName,
//depreciated			contact.LastName,
//depreciated			contact.Name,
//depreciated			contact.Email,
//depreciated			contact.Phone,
//depreciated			true,
//depreciated			contactId,
//depreciated			new Map<String,Contact>());
//depreciated		Test.stopTest();
//depreciated		ocr = [
//depreciated			select
//depreciated				OpportunityId,
//depreciated				ContactId,
//depreciated				Role,
//depreciated				IsPrimary
//depreciated			from OpportunityContactRole
//depreciated			where ContactId = :contactId
//depreciated				and OpportunityId = :getOpportunityId()
//depreciated				and Role = :Opportunity_Subscription.SHIPPING_CONTACT_ROLE
//depreciated			limit 1 ];
//depreciated		System.assertNotEquals(null,ocr);
//depreciated		System.assertEquals(contactId,ocr.ContactId);
//depreciated	}	

//legacy	public void getOrCreateAccount1() {
//legacy		getOrCreateAccount();
//legacy	}

//legacy	@isTest
//legacy	static void getAccountTest() {
//legacy		new Opportunity_SubscriptionTest(
//legacy			subscription1,
//legacy			new List<SubscriptionLine__c>(),
//legacy			new List<SubscriptionPartnerRelationship__c>() ).getOrCreateAccount1();
//legacy		System.assertNotEquals(null,subscription1.Account__r.Id);
//legacy		getAccountId();
//legacy		subscription1.Account__r = account;
//legacy		new Opportunity_SubscriptionTest(
//legacy			subscription1,
//legacy			new List<SubscriptionLine__c>(),
//legacy			new List<SubscriptionPartnerRelationship__c>() ).getOrCreateAccount1();
//legacy		System.assertEquals(account.Id,subscription1.Account__r.Id);
//legacy	}

//depreciated	//isTest(SeeAllData=true) // needed to access the global pricebook
//depreciated	static void getPricebookEntryMapTest() {
//depreciated		Id globalPricebookEntryId = getGlobalPricebookEntryId();
//depreciated		Opportunity_Subscription oppSub = new Opportunity_Subscription( new Set<Id>{ subscription1.Id } );
//depreciated		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
//depreciated			oppSub,
//depreciated			subscription1,
//depreciated			subscriptionLineMap.values(),
//depreciated			new List<SubscriptionPartnerRelationship__c>{ subscriptionPartnerRelationship1 } );
//depreciated		PricebookEntry pe = oppCreator.pricebookEntryMap.get(happyBall.ProductCode);
//depreciated		System.assertEquals(globalPricebookEntryId,pe.Id);
//depreciated	}

	//@isTest
	//static void getSourceOpportunityTest() {
	//	getOpportunityId();
	//	List<Opportunity> opps = new List<Opportunity>{ opportunity };
	//	System.assertNotEquals(null,Opportunity_Subscription.getSourceOpportunity(opps,opportunity.OpportunityNumber__c,null,null));
	//	System.assertNotEquals(null,Opportunity_Subscription.getSourceOpportunity(opps,null,opportunity.OracleOrderNumber__c,null));
	//	System.assertNotEquals(null,Opportunity_Subscription.getSourceOpportunity(opps,null,null,opportunity.PONumber__c));
	//}

	//@isTest
	//static void getSourceOpportunitiesTest() {
	//	Id oppId = getOpportunityId();
	//	System.assertNotEquals(null,opportunity.OpportunityNumber__c);
	//	Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(
	//		Opportunity_Subscription.getSourceOpportunities(
	//			new Set<String>{opportunity.OpportunityNumber__c},
	//			new Set<String>{opportunity.OracleOrderNumber__c},
	//			new Set<String>{opportunity.PONumber__c}) );
	//	System.assertNotEquals(0,oppMap.size());
	//	System.assert(oppMap.containsKey(oppId),'Failed to find source opportunity');
	//	System.assertNotEquals(null,Opportunity_Subscription.getSourceOpportunity(oppMap.values(),opportunity.OpportunityNumber__c,null,null));
	//	Opportunity_Subscription.getSourceOpportunity(oppMap.values(),null,opportunity.OracleOrderNumber__c,null);
	//	System.assertNotEquals(null,Opportunity_Subscription.getSourceOpportunity(oppMap.values(),null,null,opportunity.PONumber__c));
	//}

	@isTest
	static void truncateTest() {
		String part = '1234';
		String full = part+'567890';
		System.assertEquals(full,Opportunity_Subscription.truncate(full,full.length()+100));
		System.assertEquals(full,Opportunity_Subscription.truncate(full,full.length()));
		System.assertEquals(part,Opportunity_Subscription.truncate(full,part.length()));
	}

	@isTest
	static void convertToAccountTest() {
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			new List<SubscriptionLine__c>(),
			new List<SubscriptionPartnerRelationship__c>() );
		Test.startTest();
		Account acc = oppCreator.convertToAccount();
		Test.stopTest();
		System.assertEquals(oppCreator.subscription.SoldToAccountNumber__c,acc.OracleAccountNumber__c);
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
	}

	@isTest // (SeeAllData=true) // needed to access the global pricebook
	static void convertToOpportunityTest() {
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			subscriptionLines,
			new List<SubscriptionPartnerRelationship__c>() );
		Map<String,Opportunity> regionOppMap = new Map<String,Opportunity>();
		getAccountId();
		getOpportunityId();
		oppCreator.subscription.AssignTo__r = opportunity.Owner;
		Test.startTest();
		for( String superRegion : new Set<String>{'APAC','EMEA','LATAM','NA'} ) {
			oppCreator.subscription.SuperRegion__c = superRegion;
			Opportunity opp = oppCreator.convertToOpportunity(account, opportunity);
			System.assertNotEquals(null,opp);
			regionOppMap.put(superRegion,opp);
		}
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		insert regionOppMap.values();
		// now a failure case
		oppCreator.subscription.AssignTo__r = null;
		try {
			oppCreator.convertToOpportunity(account, opportunity);
		}
		catch(Exception ex) {}
		Test.stopTest();
	}

//depreciated	@isTest
//depreciated	static void createCampaignMembersTest() {
//depreciated		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
//depreciated			new Opportunity_Subscription(new Set<Id>()),
//depreciated			new Subscription__c(
//depreciated				ShippingContact__c = getContactId() ),
//depreciated			new List<SubscriptionLine__c>(),
//depreciated			new List<SubscriptionPartnerRelationship__c>{
//depreciated				new SubscriptionPartnerRelationship__c(
//depreciated					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
//		this.salesforceCampaignId = getCampaignId();
//depreciated		Id campaignId = getCampaignId();
//depreciated		Id contactId = getContactId();
//depreciated		oppCreator.subscription.Campaign__c = campaignId;
//depreciated		Test.startTest();
//depreciated		oppCreator.createCampaignMembers();
//depreciated		CampaignMember cm = [
//depreciated			select Id
//depreciated			from CampaignMember
//depreciated			where CampaignId = :campaignId
//depreciated				and ContactId = :contactId ];
//depreciated		// one more just for coverage
//		this.salesforceCampaignId = null;
//depreciated		oppCreator.subscription.Campaign__c = null;
//depreciated		oppCreator.createCampaignMembers();
//depreciated		Test.stopTest();
//depreciated		System.assertEquals(null,oppCreator.deferredError);
//depreciated	}

//legacy	void createContactTestImpl() {
//legacy		Map<String,Id> contactIdMap = new Map<String,Id>();
//legacy		Test.startTest();
//legacy		createContact(getAccountId(),account.Owner.Id,contactIdMap);
//legacy		Test.stopTest();
//legacy		System.assertEquals(1,contactIdMap.size());
//legacy	}

//legacy	@isTest
//legacy	static void createContactTest() {
//legacy		new Opportunity_SubscriptionTest(
//legacy			subscription1,
//legacy			new List<SubscriptionLine__c>(),
//legacy			new List<SubscriptionPartnerRelationship__c>{
//legacy				new SubscriptionPartnerRelationship__c(
//legacy					SubscriptionPartner__r = new SubscriptionPartner__c()) } ).createContactTestImpl();
//legacy	}

	@isTest
	static void upsertExpiringProductsTest() {
		Id globalPricebookEntryId = getGlobalPricebookEntryId();
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			subscriptionLines,
			new List<SubscriptionPartnerRelationship__c>{
				new SubscriptionPartnerRelationship__c(
					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
		getOpportunityId();
		oppCreator.setOpportunity(opportunity);
		List<Opportunity_Subscription.OppCreator> oppCreators = new List<Opportunity_Subscription.OppCreator>{oppCreator};
		Test.startTest();
		System.assert(! oppCreator.expiringProducts.isEmpty(),'No expiringProducts!');
		oppSub.upsertExpiringProducts(oppCreators);
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		// to do : test results
		Integer i=0;
		for(Opportunity_Subscription.SubscriptionLine sl : oppCreator.lineList) {
			System.assertEquals(null,sl.subLine.ErrorMessage__c);
			System.assertNotEquals(null,sl.subLine.ExpiringProduct__c);
			System.assertEquals(Opportunity_Subscription.SUCCESS_STATUS,sl.subLine.Status__c);
		}
		// strictly for coverage
		try {
			oppCreator.expiringProducts = null;
			System.assert(! oppCreator.expiringProducts.isEmpty(),'No expiringProducts!');
			for(Expiring_Product__c ep : oppCreator.expiringProducts) {
				ep.Opportunity__c = null;
			}
			oppSub.upsertExpiringProducts(oppCreators);
		}
		catch(Exception ex) {}
		Test.stopTest();
	}

	@isTest
	static void calculateAmountTest() {
		getGlobalPricebookEntryId();
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			subscriptionLines,
			new List<SubscriptionPartnerRelationship__c>());
		getOpportunityId();
		oppCreator.setOpportunity(opportunity);
		Test.startTest();
		System.assertNotEquals(null,oppCreator.calculateAmount());
		Test.stopTest();
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
	}

//legacy	@isTest
//legacy	static void createOpportunityContactRolesTest() {
//legacy		// to do
//legacy	}

	@isTest // (SeeAllData=true) // need the global price book
	static void insertOpportunityLineItemsTest() {
		Id globalPricebookEntryId = getGlobalPricebookEntryId();
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			subscriptionLines,
			new List<SubscriptionPartnerRelationship__c>{
				new SubscriptionPartnerRelationship__c(
					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
		getOpportunityId();
		oppCreator.setOpportunity(opportunity);
		List<Opportunity_Subscription.OppCreator> oppCreators = new List<Opportunity_Subscription.OppCreator>{oppCreator};
		Test.startTest();
		if(globalPricebookEntryId != null) {
			System.assert(! oppCreator.opportunityLineItems.isEmpty(),'No line items!');
			for(Integer i=oppCreator.opportunityLineItems.size();i-- > 0;) {
				OpportunityLineItem lineItem = oppCreator.opportunityLineItems[i];
				SubscriptionLine__c subLine = oppCreator.lineList[i].subLine;
				System.assertEquals(subLine.NetUnitSellingPrice__c,lineItem.UnitPrice);
			}
			oppSub.insertOpportunityLineItems(oppCreators);
			System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
			// to do : test results
			for(Opportunity_Subscription.SubscriptionLine sl : oppCreator.lineList) {
				System.assertEquals(null,sl.subLine.ErrorMessage__c);
				System.assertNotEquals(null,sl.subLine.OpportunityLineItemId__c);
				System.assertEquals(Opportunity_Subscription.SUCCESS_STATUS,sl.subLine.Status__c);
			}
		}
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		// strictly for coverage
		try {
			oppCreator.opportunityLineItems = null;
			System.assert(! oppCreator.opportunityLineItems.isEmpty(),'No line items!');
			for(OpportunityLineItem lineItem : oppCreator.opportunityLineItems) {
				lineItem.OpportunityId = null;
			}
			oppSub.insertOpportunityLineItems( oppCreators );
		}
		catch(Exception ex) {}
		Test.stopTest();
		System.assert(! oppCreator.errorList.isEmpty(),'Expected errors');
	}

	@isTest
	static void insertOpportunityPartnersTest() {
		subscription1.SalesChannelCode__c = 'Direct Reseller';
		Id partnerStatusId = partnerStatus.Id;
		Id subscriptionId = getSubscriptionId();
		Id subscriptionPartnerRelId = getSubscriptionPartnerRelationshipId();
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>{ subscriptionId });
		Opportunity_Subscription.OppCreator oppCreator = oppSub.oppCreatorMap.get(subscriptionId);
		opportunity.FulfillmentChannel__c = 'Direct Reseller';
		opportunity.BillingAccountNumber__c = subscription1.BillToAccountNumber__c;
		opportunity.Primary_Partner__c = 'Anything';
		getOpportunityId();
		oppCreator.setOpportunity(opportunity);
		List<Opportunity_Subscription.OppCreator> oppCreators = new List<Opportunity_Subscription.OppCreator>{oppCreator};
		Test.startTest();
		oppSub.insertOpportunityPartners( oppCreators );
		Test.stopTest();
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
		List<OpportunityPartner__c> oppPartners = [
			select Id, RelationshipType__c
			from OpportunityPartner__c
			where Opportunity__c = :getOpportunityId()];
		System.assertNotEquals(null,oppPartners);
		Set<String> transactionRoles = new Set<String>();
		for(OpportunityPartner__c oppPartner : oppPartners) {
			System.assert(! transactionRoles.contains(oppPartner.RelationshipType__c),'Duplicate Transaction Role='+oppPartner.RelationshipType__c);
			transactionRoles.add(oppPartner.RelationshipType__c);
		}
		System.assert(transactionRoles.contains(Opportunity_ManagePartners.FINANCIAL),'Missing financial partner');
		System.assert(transactionRoles.contains('Reseller 2'),'Missing Reseller 2');
		update oppCreator.updatePartnerRelationships;
		
		SubscriptionPartnerRelationship__c subPartnerRel = [
			select OpportunityPartner__c
			from SubscriptionPartnerRelationship__c
			where Id = :getSubscriptionPartnerRelationshipId()];
		System.assertNotEquals(null,subPartnerRel.OpportunityPartner__c);
	}

//depreciated	@isTest
//depreciated	static void addShippingContactTest() {
//depreciated		subscription1.Account__c = getAccountId();
//depreciated		subscription1.ShippingContact__c = getContactId();
//depreciated		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
//depreciated		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
//depreciated			oppSub,
//depreciated			subscription1,
//depreciated			new List<SubscriptionLine__c>(),
//depreciated			new List<SubscriptionPartnerRelationship__c>{
//depreciated				new SubscriptionPartnerRelationship__c(
//depreciated					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
//depreciated		getOpportunityId();
//depreciated		oppCreator.opportunity = opportunity;
//depreciated		Id oppId = oppCreator.getOpportunityId();
//depreciated		System.assertEquals(null,oppCreator.deferredError);
//depreciated		System.assertNotEquals(null,oppId);
//depreciated		Test.startTest();
//depreciated		oppCreator.addShippingContact();
//depreciated		Test.stopTest();
//depreciated		System.assertEquals(null,oppCreator.deferredError);
//depreciated		OpportunityContactRole ocr = [
//depreciated			select Id, ContactId
//depreciated			from OpportunityContactRole
//depreciated			where OpportunityId = :getOpportunityId()
//depreciated				and ContactId = :getContactId()
//depreciated				and Role = :Opportunity_Subscription.SHIPPING_CONTACT_ROLE
//depreciated			limit 1];
//depreciated		System.assertNotEquals(null,ocr);
//depreciated		System.assertEquals(getContactId(),ocr.ContactId);
//depreciated	}

//depreciated	@isTest
//depreciated	static void addSellingContactTest() {
//depreciated		subscription1.Account__c = getAccountId();
//depreciated		subscription1.SellingContact__c = getContactId();
//depreciated		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
//depreciated		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
//depreciated			oppSub,
//depreciated			subscription1,
//depreciated			new List<SubscriptionLine__c>(),
//depreciated			new List<SubscriptionPartnerRelationship__c>{
//depreciated				new SubscriptionPartnerRelationship__c(
//depreciated					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
//depreciated		getOpportunityId();
//depreciated		oppCreator.opportunity = opportunity;
//depreciated		Id oppId = oppCreator.getOpportunityId();
//depreciated		System.assertEquals(null,oppCreator.deferredError);
//depreciated		System.assertNotEquals(null,oppId);
//depreciated		Test.startTest();
//depreciated		oppCreator.addSellingContact();
//depreciated		Test.stopTest();
//depreciated		System.assertEquals(null,oppCreator.deferredError);
//depreciated		OpportunityContactRole ocr = [
//depreciated			select Id, ContactId
//depreciated			from OpportunityContactRole
//depreciated			where OpportunityId = :getOpportunityId()
//depreciated				and ContactId = :getContactId()
//depreciated				and Role = :Opportunity_Subscription.SOLD_TO_CONTACT_ROLE];
//depreciated		System.assertNotEquals(null,ocr);
//depreciated		System.assertEquals(getContactId(),ocr.ContactId);				
//depreciated	}

	//void getContactIdMapTestImpl() {
	//	Id contactId = getContactId();
	//	Map<String,Id> contactIdMap = getContactIdMap(getAccountId(),new Set<String>{contact.Email});
	//	System.assertEquals(contactId,contactIdMap.get(contact.Email.toLowerCase()));
	//}

	//@isTest
	//static void getContactIdMapTest() {
	//	new Opportunity_SubscriptionTest(
	//		new Subscription__c(),
	//		new List<SubscriptionLine__c>(),
	//		new List<SubscriptionPartnerRelationship__c>{
	//			new SubscriptionPartnerRelationship__c(
	//				SubscriptionPartner__r = new SubscriptionPartner__c()) } ).getContactIdMapTestImpl();
	//}

	@isTest
	static void getDescriptionTest() {
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			subscription1,
			new List<SubscriptionLine__c>(),
			new List<SubscriptionPartnerRelationship__c>{
				new SubscriptionPartnerRelationship__c(
					SubscriptionPartner__r = new SubscriptionPartner__c()) } );
		oppCreator.subscription.OrderNumber__c = '123';
		oppCreator.subscription.ContractNumber__c = '456';
		oppCreator.subscription.SuperRegion__c = 'EMEA';
		oppCreator.subscription.PurchaseOrderNumber__c = '789';
		oppCreator.subscription.OrderNumber__c = '987654321';
		oppCreator.subscription.OpportunityNumber__c = '3';
		System.assertEquals(
			'order number: 987654321\n'
				+'contract number: 456\n'
				+'po number: 789\n'
				+'opportunity number: 3',
			oppCreator.getDescription().toLowerCase().trim());
		oppCreator.primaryReseller = oppCreator.partnerList[0].SubscriptionPartner__r;
		oppCreator.primaryReseller.ContactName__c = 'contact name';
		oppCreator.primaryReseller.ContactEmail__c = 'test@redhat.com';
		oppCreator.primaryReseller.ContactPhone__c = '1-800-555-1212';
		Test.startTest();
		System.assertEquals(
			'partner contact: contact name\n'
				+'partner email: test@redhat.com\n'
				+'partner phone: 1-800-555-1212\n'
				+'\n'
				+'order number: 987654321\n'
				+'contract number: 456\n'
				+'po number: 789\n'
				+'opportunity number: 3',
			oppCreator.getDescription().toLowerCase().trim());
		Test.stopTest();
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
	}

	@isTest
	static void getFulfillmentChannelTest() {
		Opportunity_Subscription oppSub = new Opportunity_Subscription(new Set<Id>());
		Opportunity_Subscription.OppCreator oppCreator = new Opportunity_Subscription.OppCreator(
			oppSub,
			new Subscription__c(),
			new List<SubscriptionLine__c>(),
			new List<SubscriptionPartnerRelationship__c>() );
		oppCreator.subscription.SalesChannelCode__c = 'DIRECT END CUSTOMER';
		Test.startTest();
		System.assertEquals(Opportunity_Subscription.DIRECT_END_CUSTOMER_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'DISTRIBUTOR';
		System.assertEquals(Opportunity_Subscription.DISTRIBUTOR_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'DIRECT CARASOFT-NA ONLY';
		System.assertEquals(Opportunity_Subscription.DISTRIBUTOR_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'RESELLER';
		System.assertEquals(Opportunity_Subscription.DIRECT_RESELLER_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'DIRECT DLT-NA ONLY';
		System.assertEquals(Opportunity_Subscription.DIRECT_RESELLER_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'WEBSTORE';
		System.assertEquals(Opportunity_Subscription.WEBSTORE_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'OEM PO';
		System.assertEquals(Opportunity_Subscription.OEM_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'OEM ROYALTIES';
		System.assertEquals(Opportunity_Subscription.DIRECT_END_CUSTOMER_FC,oppCreator.getFulfillmentChannel());
		getBillToAccountId();
		oppCreator.subscription.BillToAccountNumber__c=billToAccount.Bill_To_Account_Number__c;
		System.assertEquals(Opportunity_Subscription.OEM_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'DIRECT';
		System.assertEquals(Opportunity_Subscription.DIRECT_END_CUSTOMER_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'CLOUD PROVIDER';
		System.assertEquals(Opportunity_Subscription.CLOUD_PROVIDER_FC,oppCreator.getFulfillmentChannel());
		oppCreator.subscription.SalesChannelCode__c = 'SOME RANDOM TEXT!';
		System.assertEquals(Opportunity_Subscription.DEFAULT_FC,oppCreator.getFulfillmentChannel());
		Test.stopTest();
		System.assert(oppCreator.errorList.isEmpty(),'Unexpected errors='+oppCreator.errorList);
	}
}