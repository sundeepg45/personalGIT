/**
 * Test the SubscriptionPartnerTriggerBefore class.
 *
 * @version 2015-01-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - commenting out assigned batch tests
 * 2014-12-12 - added assign composite key test
 * 2013-09-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2014-01-10 - added test for mapResellerPartner()
 */
@isTest
private class SubscriptionPartnerTriggerBeforeTest {

	static Account account {
		get {
			if(account == null) {
				account = new Account(
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					CurrencyIsoCode = 'USD',
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

	static Id getAccountId() {
		if(account.Id == null) {
			insert account;
		}
		return account.Id;
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

	public static Subscription__c subscription1 { get {
		if(subscription1 == null) {
			subscription1 = new Subscription__c(
				Account__c = null,
				AssignTo__c = null,
				BillToAccountNumber__c = account.OracleAccountNumber__c,
				BillToAddress1__c = account.BillingStreet,
				BillToAddress2__c = null,
				BillToCity__c = account.BillingCity,
				BillToCountry__c = account.BillingCountry,
				BillToPartyName__c = null,
				BillToPostalCode__c = account.BillingPostalCode,
				BillToState__c = account.BillingState,
				ContractAmount__c = 10000,
				ContractEndDate__c = Date.today().addYears(1),
				ContractId__c = Decimal.valueOf('-312215540494148380.'),
				ContractStartDate__c = Date.today(),
				CountryOfOrder__c = 'Japan',
				CurrencyIsoCode = 'USD',
				OrderId__c = Decimal.valueOf('-312215540494148381.'),
				OrderNumber__c = null,
				PurchaseOrderNumber__c = null,
				Region__c = null,
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
				SoldToAccountNumber__c = account.OracleAccountNumber__c,
				SoldToContactEmail__c = contact.Email,
				SoldToContactFirstName__c = contact.FirstName,
				SoldToContactLastName__c = contact.LastName,
				SoldToContactName__c = contact.FirstName+' '+contact.LastName,
				SoldToContactPhone__c = contact.Phone,
				SoldToPartyName__c = account.Name,
				Status__c = 'Ready',
				SuperRegion__c = 'APAC');
		}
		return subscription1;
	} }

	public static Id getSubscriptionId() {
		if(subscription1.Id == null) {
			insert subscription1;
		}
		return subscription1.Id;
	}

	static Account reseller { get {
		if ( reseller == null ) {
			reseller = account.clone();
			reseller.OracleAccountNumber__c = '123456';
			reseller.RecordTypeId = RecordTypeLookup.getRecordTypeId('APAC Partner','Account');
			reseller.OraclePartyNumber__c = '-424223';
		}
		return reseller;
	} }

	static Id getResellerId() {
		if(reseller.Id == null) {
			insert reseller;
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
					Partner__c = getResellerId(),
					PartnerTier__c = cTier.Id,
					PartnerType__c = cType.Id );
				insert partnerStatus;
				partnerStatus.Partner__r = reseller;
				partnerStatus.PartnerTier__r = cTier;
				partnerStatus.PartnerType__r = cType;
			}
			return partnerStatus;
		}
	}

	static SubscriptionPartner__c subscriptionPartner1 { get {
		if(subscriptionPartner1 == null) {
			subscriptionPartner1 = new SubscriptionPartner__c(
				Account__c = getResellerId(),
				ApId__c = Decimal.valueOf('-312215540494148382.'),
				ContactEmail__c = contact.Email,
				ContactName__c = contact.FirstName+' '+contact.LastName,
				ContactPhone__c = contact.Phone,
				OrderId__c = subscription1.OrderId__c,
				PartnerStatus__c = null,
				PartyName__c = reseller.Name,
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

//depreciated	@isTest
//depreciated	static void assignBatchTest1() {
//depreciated		List<SubscriptionPartner__c> subscriptionPartners = SubscriptionBatchTriggerAfterTest.subscriptionPartners;
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		SubscriptionPartnerTriggerBefore triggerBefore = new SubscriptionPartnerTriggerBefore(null,subscriptionPartners);
//depreciated		triggerBefore.assignBatch();
//depreciated		for(SubscriptionPartner__c subPartner : subscriptionPartners) {
//depreciated			System.assertEquals(batchId,subPartner.Batch__c);
//depreciated		}
//depreciated	}

//depreciated	@isTest
//depreciated	static void assignBatchTest2() {
//depreciated		List<SubscriptionPartner__c> subscriptionPartners = SubscriptionBatchTriggerAfterTest.subscriptionPartners;
//depreciated		SubscriptionPartnerTriggerBefore triggerBefore = new SubscriptionPartnerTriggerBefore(null,subscriptionPartners);
//depreciated		triggerBefore.assignBatch();
//depreciated		Id batchId = SubscriptionBatchTriggerAfterTest.getSubscriptionBatchId();
//depreciated		for(SubscriptionPartner__c subPartner : subscriptionPartners) {
//depreciated			System.assertEquals(batchId,subPartner.Batch__c);
//depreciated		}
//depreciated	}

	@isTest
	static void assignCompositeKeyTest() {
		List<SubscriptionPartner__c> subscriptionPartners = SubscriptionBatchTriggerAfterTest.subscriptionPartners;
		SubscriptionPartnerTriggerBefore triggerBefore = new SubscriptionPartnerTriggerBefore(null,subscriptionPartners);
		triggerBefore.assignCompositeKey();
		System.assertEquals(SubscriptionBatchTriggerAfterTest.PARTNER_COMPOSITE_KEY00,subscriptionPartners[0].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.PARTNER_COMPOSITE_KEY01,subscriptionPartners[1].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.PARTNER_COMPOSITE_KEY10,subscriptionPartners[2].CompositeKey__c);
		System.assertEquals(SubscriptionBatchTriggerAfterTest.PARTNER_COMPOSITE_KEY11,subscriptionPartners[3].CompositeKey__c);
	}

	@isTest
	static void mapResellerPartnerTest() {
		PartnerStatus__c status = partnerStatus;
		SubscriptionPartner__c partner = subscriptionPartner1;
		Id relationshipId = getSubscriptionPartnerRelationshipId();
		SubscriptionPartnerTriggerBefore triggerBefore = new SubscriptionPartnerTriggerBefore(null,new List<SubscriptionPartner__c>{partner});
		System.assertEquals(null,partner.PartnerStatus__c);
		triggerBefore.mapResellerPartner();
		System.assertEquals(status.Id,partner.PartnerStatus__c);
		partner.Account__c = null;
		partner.PartyNumber__c = '999999';
		triggerBefore.mapResellerPartner();
		System.assertEquals(null,partner.PartnerStatus__c);
	}

	@isTest
	static void processTriggerTest() {
		SubscriptionPartner__c subscriptionPartner = SubscriptionBatchTriggerAfterTest.subscriptionPartners[0];
		AbstractTrigger.setBooleanSettings('SubPart_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<SubscriptionPartner__c> subscriptionPartners = new List<SubscriptionPartner__c>{subscriptionPartner};
		Map<Id,SubscriptionPartner__c> oldMap = new Map<Id,SubscriptionPartner__c>{ subscriptionPartner.Id => subscriptionPartner };
		List<SubscriptionPartner__c> newList = subscriptionPartners.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('SubPart_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		SubscriptionPartnerTriggerBefore.processTrigger(null,newList);
		// update
		newList = subscriptionPartners.deepClone(true);
		SubscriptionPartnerTriggerBefore.processTrigger(oldMap,newList);
		// delete
		SubscriptionPartnerTriggerBefore.processTrigger(oldMap,null);
	}

	@isTest
	static void deployTest() {
		SubscriptionPartner__c subscriptionPartner = SubscriptionBatchTriggerAfterTest.subscriptionPartners[0];
		AbstractTriggerTest.deployTest('SubPart_Before.',new List<SubscriptionPartner__c>{subscriptionPartner});
	}
}