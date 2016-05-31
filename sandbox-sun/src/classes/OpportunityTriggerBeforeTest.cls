/**
 * Test class for OpportunityTriggerBeforeTest.cls
 *
 * @version 2015-01-27
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciate
 * 2013-07-18 - Removed setPOCApprovalFlags test method
 * 2013-07-05 - Added test for updatePOCStatus
 * 2013-04-30 - Added test method for assignServicesRiskReview
 * 2013-04-19 - Propigate CurrencyIsoCode across the objects
 * 2013-02-15 - Added test for updateRushOrder
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2013-07-24 - Added test for updating POC close comments
 * 2013-07-23 - Added test for POC parent opp owner role
 * 2013-06-27 - No longer setting POC status to "Defined"
 * 2012-12-17 - Updated POC approval flags test
 * 2012-11-29 - Added test for POC approval flags trigger
 * 2012-05-29 - Added test for owner assignment trigger
 */
@isTest
public class OpportunityTriggerBeforeTest {
//depreciated	public static final String GLOBAL_PRICE_BOOK_NAME = 'Global Price Book';

//depreciated	public static final Integer STANDARD_PRICE_BOOK_INDEX = 0;
//depreciated	public static final Integer GLOBAL_PRICE_BOOK_INDEX = 1;

//depreciated	public static final String SUPER_REGION = 'EMEA';
//depreciated	public static final String SUPER_REGION2 = 'NA';

//depreciated	public static RecordType preferredRecordType {
//depreciated		get {
//depreciated			if(preferredRecordType == null) {
//depreciated				preferredRecordType = [
//depreciated					select Id,name
//depreciated					from RecordType
//depreciated					where name like :(SUPER_REGION+' %')
//depreciated						and SObjectType = 'Opportunity'
//depreciated						and IsActive = true
//depreciated					limit 1 ];
//depreciated			}
//depreciated			return preferredRecordType;
//depreciated		}
//depreciated	}

//depreciated	public static Account account {
//depreciated		get {
//depreciated			if(account == null) {
//depreciated				RecordType recordType = [
//depreciated					select Id,name
//depreciated					from RecordType
//depreciated					where name = 'Strategic'
//depreciated						and SObjectType = 'Account'
//depreciated						and IsActive = true
//depreciated					limit 1 ];
//depreciated				account = new Account(
//depreciated					CurrencyIsoCode='USD',
//depreciated					name='Test Account',
//depreciated					RecordTypeId=recordType.Id,
//depreciated					AccountClassification__c=recordType.name );
//depreciated				insert account;
//depreciated				account.RecordType = recordType;
//depreciated			}
//depreciated			return account;
//depreciated		}
//depreciated	}

//depreciated	public static Opportunity opportunity {
//depreciated		get {
//depreciated			if(opportunity == null) {
//depreciated				opportunity = new Opportunity(
//depreciated					Name='Opportunity Test',
//depreciated					CurrencyIsoCode=account.CurrencyIsoCode,
//depreciated					CloseDate=System.today(),
//depreciated					ContractStartDate__c = System.today().addDays(1),
//depreciated					StageName='Unqualified',
//depreciated					OwnerId=UserInfo.getUserId(),
//depreciated					AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
//depreciated					RecordTypeId = preferredRecordType.Id,
//depreciated					PrimaryBusinessUnit__c=null,
//depreciated					POC_Status__c=null);
//depreciated			}
//depreciated			return opportunity;
//depreciated		}
//depreciated	}

//depreciated	public static Id opportunityId {
//depreciated		get {
//depreciated			if(opportunity.Id == null) {
//depreciated				insert opportunity;
//depreciated			}
//depreciated			return opportunity.Id;
//depreciated		}
//depreciated	}

//depreciated	public static List<Pricebook2> priceBooks {
//depreciated		get {
//depreciated			if(priceBooks == null) {
//depreciated				Map<Boolean,Pricebook2> priceBookMap = new Map<Boolean,Pricebook2>{
//depreciated					false => new Pricebook2(Description='Global',IsActive=true,Name = GLOBAL_PRICE_BOOK_NAME),
//depreciated					true => new Pricebook2(Description='Standard',IsActive=true,Name = 'Standard Price Book') };
//depreciated				Pricebook2 standardPriceBook = null;
//depreciated				for(Pricebook2 pb : [select IsActive,IsStandard,Name from Pricebook2 where IsStandard = true or Name = :GLOBAL_PRICE_BOOK_NAME]) {
//depreciated					pb.IsActive = true;
//depreciated					pricebookMap.put((pb.Name != GLOBAL_PRICE_BOOK_NAME),pb);
//depreciated				}
//depreciated				priceBooks = new List<Pricebook2>{pricebookMap.get(true),pricebookMap.get(false)};
//depreciated				upsert priceBooks;
//depreciated			}
//depreciated			return priceBooks;
//depreciated		}
//depreciated	}

//depreciated	public static Product2 product {
//depreciated		get {
//depreciated			if (product == null) {
//depreciated				product = new Product2(
//depreciated					CurrencyIsoCode=opportunity.CurrencyIsoCode,
//depreciated					Name = 'Test Product',
//depreciated					Family = 'GLS',
//depreciated					IsActive = true,
//depreciated					ProductCode = '__TESTING');
//depreciated				insert product;
//depreciated			}
//depreciated			return product;
//depreciated		}
//depreciated	}

//depreciated	public static List<PricebookEntry> priceBookEntries {
//depreciated		get {
//depreciated			if (priceBookEntries == null) {
//depreciated				priceBookEntries = new List<PricebookEntry>();
//depreciated				for(Pricebook2 pb : priceBooks) {
//depreciated					priceBookEntries.add(new PricebookEntry(
//depreciated						CurrencyIsoCode=product.CurrencyIsoCode,
//depreciated						UseStandardPrice = false,
//depreciated						Pricebook2Id = pb.Id,
//depreciated						UnitPrice = 75.00,
//depreciated						Product2Id = product.Id,
//depreciated						IsActive=true));
//depreciated				}
//depreciated				insert priceBookEntries;
//depreciated				for(PricebookEntry pe : pricebookEntries) {
//depreciated					pe.Product2 = product;
//depreciated				}
//depreciated			}
//depreciated			return priceBookEntries;
//depreciated		}
//depreciated	}

//depreciated	public static OpportunityLineItem opportunityLineItem {
//depreciated		get {
//depreciated			if(opportunityLineItem == null) {
//depreciated				opportunityLineItem = new OpportunityLineItem(
//depreciated					OpportunityId = opportunityId,
//depreciated					PricebookEntryId = priceBookEntries[STANDARD_PRICE_BOOK_INDEX].Id);
//depreciated				insert opportunityLineItem;
//depreciated				opportunityLineItem.PricebookEntry=priceBookEntries[STANDARD_PRICE_BOOK_INDEX];
//depreciated			}
//depreciated			return opportunityLineItem;
//depreciated		}
//depreciated	}

//depreciated	public static OpportunityLineItem opportunityLineItemGlobal {
//depreciated		get {
//depreciated			if(opportunityLineItemGlobal == null) {
//depreciated				opportunityLineItemGlobal = new OpportunityLineItem(
//depreciated					OpportunityId = opportunityId,
//depreciated					PricebookEntryId = priceBookEntries[GLOBAL_PRICE_BOOK_INDEX].Id);
//depreciated				insert opportunityLineItemGlobal;
//depreciated				opportunityLineItemGlobal.PricebookEntry=priceBookEntries[GLOBAL_PRICE_BOOK_INDEX];
//depreciated			}
//depreciated			return opportunityLineItemGlobal;
//depreciated		}
//depreciated	}	

//depreciated	@isTest(SeeAllData=true) // need all data to access custom settings
//depreciated	static void customSettingTest() {
//depreciated		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Opportunity.DefaultRecordTypeId');
//depreciated		System.assertNotEquals(null,defaultRecordTypeId,'Custom String setting Opportunity.DefaultRecordTypeId has not been defined');
//depreciated		Boolean found = false;
//depreciated		for(RecordType rt : [
//depreciated			select Id,name
//depreciated			from RecordType
//depreciated			where Id = :defaultRecordTypeId.Value__c
//depreciated				and SObjectType = 'Opportunity'
//depreciated			limit 1 ] )
//depreciated		{
//depreciated			found = true;
//depreciated		}
//depreciated		System.assert(found,'No record type was found with an Id value of Opportunity.DefaultRecordTypeId = '+defaultRecordTypeId.Value__c);
//depreciated	}

//depreciated	@isTest // we create the custom settings needed
//depreciated	static void assignRecordTypeTest() {
//depreciated		DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
//depreciated		dfrt.GlobalAs__c=SUPER_REGION;
//depreciated		dfrt.PreferredAccountRecordType__c='Like it matters.';
//depreciated		dfrt.PreferredOpportunityRecordType__c='oatuehaseouthaseuth';
//depreciated		dfrt.SecondaryAccountRecordType__c='Who cares?';
//depreciated		dfrt.SecondaryOpportunityRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
//depreciated		upsert dfrt;
//depreciated		Id recordTypeId = '012000000000000AAA';
//depreciated		StringSetting__c defaultRecordTypeId = new StringSetting__c(
//depreciated			Name='Opportunity.DefaultRecordTypeId',
//depreciated			Value__c=recordTypeId);
//depreciated		insert new StringSetting__c(
//depreciated			Name='Opportunity.DefaultRecordTypeId',
//depreciated			Value__c=recordTypeId);
//depreciated		opportunity.RecordTypeId = recordTypeId;
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(null,new List<Opportunity>{opportunity});
//depreciated		triggerBefore.currentUser.Region__c = 'GLOBAL';
//depreciated		RecordTypeAssignment__c rta = new RecordTypeAssignment__c(
//depreciated			ManagedProfiles__c = triggerBefore.currentUser.Profile.Name,
//depreciated			Object_Label__c = 'Opportunity',
//depreciated			RecordType__c = preferredRecordType.Name,
//depreciated			Super_Region__c = 'GLOBAL');
//depreciated		insert rta;
//depreciated		// testing assignment from the secondary value
//depreciated		triggerBefore.assignRecordType();
//depreciated		System.assertEquals(preferredRecordType.Id,opportunity.recordTypeId);
//depreciated		opportunity.RecordTypeId = recordTypeId;
//depreciated		dfrt.SecondaryOpportunityRecordType__c='aoetuhaseouthshs';
//depreciated		update dfrt;
//depreciated		triggerBefore = new OpportunityTriggerBefore(null,new List<Opportunity>{opportunity});
//depreciated		triggerBefore.currentUser.Region__c = 'GLOBAL';
//depreciated		// testing failure case
//depreciated		triggerBefore.assignRecordType();
//depreciated		System.assertEquals(recordTypeId,opportunity.recordTypeId);
//depreciated		dfrt.PreferredOpportunityRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
//depreciated		update dfrt;
//depreciated		triggerBefore = new OpportunityTriggerBefore(null,new List<Opportunity>{opportunity});
//depreciated		triggerBefore.currentUser.Region__c = 'GLOBAL';
//depreciated		// testing assignment from preferred value
//depreciated		triggerBefore.assignRecordType();
//depreciated		System.assertEquals(preferredRecordType.Id,opportunity.recordTypeId);
//depreciated	}

//depreciated	@isTest
//depreciated	static void updatePOCStatusTest() {
//depreciated		Opportunity opp = new Opportunity(
//depreciated					Name = 'Opportunity Test',
//depreciated					EngagementStartDate__c = System.today(),
//depreciated					POC_Status__c = OpportunityTriggerBefore.POC_STATUS_ACCEPTED);
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
//depreciated		triggerBefore.updatePOCStatus();
//depreciated		System.assertEquals(OpportunityTriggerBefore.POC_STATUS_ENGAGED,opp.POC_Status__c);
//depreciated	}

//depreciated	@isTest
//depreciated	static void updatePOCCloseCommentsTest() {
//depreciated		Opportunity opp = new Opportunity(
//depreciated					Name = 'Opportunity Test',
//depreciated					POC_Status__c = 'Test');
//depreciated		Opportunity opp2 = opp.clone();
//depreciated		opp2.POC_Status__c = OpportunityTriggerBefore.POC_STATUS_CLOSED;
//depreciated		opp2.POC_Close_Reason__c = 'Rejected';
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
//depreciated		triggerBefore.updatePOCCloseComments();
//depreciated	}

//depreciated	@isTest
//depreciated	static void updatePOCParentOppOwnerRoleTest() {
//depreciated		insert new RecordTypeLookup__c(Name='Proof of Concept',IdForOpportunity__c='012000000000000AAA');
//depreciated		Opportunity opp = new Opportunity(
//depreciated					Name = 'Opportunity Test',
//depreciated					Cloned_From_Opportunity__c = opportunityId,
//depreciated					RecordTypeId = OpportunityTriggerBefore.pocRecordTypeId);
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
//depreciated		triggerBefore.updatePOCParentOppOwnerRole();
//depreciated		System.assert(!String.isBlank(opp.POC_Parent_Opportunity_Owner_Role__c));		
//depreciated	}

//depreciated	@isTest(SeeAllData=true)
//depreciated	static void updateRushOrderTest() {
//depreciated		// setup for testing
//depreciated		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
//depreciated		AbstractTrigger.setBooleanSettings('Opp_After.',false);
//depreciated		String sku = product.ProductCode;
//depreciated		RushOrderSKU__c ros = RushOrderSKU__c.getInstance(sku);
//depreciated		if(ros == null) {
//depreciated			ros = new RushOrderSKU__c(Name=sku);
//depreciated			insert ros;
//depreciated		}
//depreciated		OpportunityLineItem lineItem = opportunityLineItem;
//depreciated		Opportunity opp = [
//depreciated			select
//depreciated				BigMachines__Line_Items__c,
//depreciated				ContractStartDate__c,
//depreciated				Rush_Order__c,
//depreciated				Rush_Order_Reason__c,
//depreciated				Rush_Order_Set_By_System__c
//depreciated			from Opportunity where Id = :opportunityId ];
//depreciated		opp.Rush_Order__c = true;
//depreciated		opp.Rush_Order_Reason__c = OpportunityTriggerBefore.RUSH_PRODUCT_EXCEPTION;
//depreciated		opp.Rush_Order_Set_By_System__c = true;
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
//depreciated		triggerBefore.updateRushOrder();
//depreciated		// we meet all the criteria, tho opportunity should not have been changed
//depreciated		System.assert(opp.Rush_Order__c,'Rush Order should not have been cleared');
//depreciated		System.assertEquals(OpportunityTriggerBefore.RUSH_PRODUCT_EXCEPTION,opp.Rush_Order_Reason__c);
//depreciated		System.assert(opp.Rush_Order_Set_By_System__c,'Rush Order Set By System should not have been cleared');

//depreciated		// now try deleting a line item
//depreciated		delete lineItem;
//depreciated		Opportunity opp2 = [
//depreciated			select
//depreciated				BigMachines__Line_Items__c,
//depreciated				ContractStartDate__c,
//depreciated				Rush_Order__c,
//depreciated				Rush_Order_Reason__c,
//depreciated				Rush_Order_Set_By_System__c
//depreciated			from Opportunity where Id = :opportunityId ];
//depreciated		opp2.Rush_Order__c = true;
//depreciated		opp2.Rush_Order_Reason__c = OpportunityTriggerBefore.RUSH_PRODUCT_EXCEPTION;
//depreciated		opp2.Rush_Order_Set_By_System__c = true;
//depreciated		triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
//depreciated		triggerBefore.updateRushOrder();
//depreciated		// the rush order fields should have been cleared
//depreciated		System.assert(! opp2.Rush_Order__c,'Rush Order should have been cleared');
//depreciated		System.assertEquals(null,opp2.Rush_Order_Reason__c);
//depreciated		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');

//depreciated		opp = opp2;
//depreciated		opp.Rush_Order__c = true;
//depreciated		opp.Rush_Order_Reason__c = OpportunityTriggerBefore.RUSH_SLA_TIME_PERIOD;
//depreciated		opp.Rush_Order_Set_By_System__c = true;
//depreciated		opp2 = opp.clone(true,false,true,true);
//depreciated		triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
//depreciated		triggerBefore.updateRushOrder();
//depreciated		// we still pass the criteria, so nothing should change
//depreciated		System.assert(opp2.Rush_Order__c,'Rush Order should not have been cleared');
//depreciated		System.assertEquals(OpportunityTriggerBefore.RUSH_SLA_TIME_PERIOD,opp2.Rush_Order_Reason__c);
//depreciated		System.assert(opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should not have been cleared');

//depreciated		// now try moving the contract start date
//depreciated		opp2.ContractStartDate__c = System.today().addDays(30);
//depreciated		triggerBefore.updateRushOrder();
//depreciated		// we no longer meet the criteria so the rush order should be cleared
//depreciated		System.assert(! opp2.Rush_Order__c,'Rush Order should have been cleared');
//depreciated		System.assertEquals(null,opp2.Rush_Order_Reason__c);
//depreciated		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');

//depreciated		// new lets try changing to a non-system value
//depreciated		opp.Rush_Order__c = true;
//depreciated		opp.Rush_Order_Reason__c = OpportunityTriggerBefore.RUSH_SLA_TIME_PERIOD;
//depreciated		opp.Rush_Order_Set_By_System__c = true;
//depreciated		opp2 = opp.clone(true,false,true,true);
//depreciated		opp2.Rush_Order_Reason__c = 'Anything';
//depreciated		triggerBefore = new OpportunityTriggerBefore(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
//depreciated		triggerBefore.updateRushOrder();
//depreciated		System.assert(opp2.Rush_Order__c,'Rush Order should not have been cleared');
//depreciated		System.assertEquals('Anything',opp2.Rush_Order_Reason__c);
//depreciated		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');
//depreciated	}

//depreciated	@isTest
//depreciated	static void assignServicesRiskReviewTest() {
//depreciated		opportunity.Services_Risk_Review__c = false;
//depreciated		Opportunity opp2 = opportunity.clone(true);
//depreciated		opportunity.Services_Contract_Type__c = 'Fixed Price';
//depreciated		opp2.Services_Contract_Type__c = 'Anything Else';
//depreciated		OpportunityTriggerBefore triggerBefore = new OpportunityTriggerBefore(
//depreciated			new Map<Id,Opportunity>{opp2.Id=>opp2},new List<Opportunity>{opportunity});
//depreciated		triggerBefore.assignServicesRiskReview();
//depreciated		system.assertEquals(true,opportunity.Services_Risk_Review__c);
//depreciated		opp2.Services_Risk_Review__c = true;
//depreciated		opp2.Services_Contract_Type__c = 'Fixed Price';
//depreciated		opportunity.Services_Contract_Type__c = 'Anything Else';
//depreciated		triggerBefore.assignServicesRiskReview();
//depreciated		system.assertEquals(false,opportunity.Services_Risk_Review__c);
//depreciated	}

//depreciated	@isTest // (SeeAllData=true) is not needed anymore because we insert missing settings
//depreciated	static void processTriggerTest() {
//depreciated		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
//depreciated		// insert missing boolean settings
//depreciated		AbstractTrigger.insertMissing = 0;
//depreciated		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
//depreciated		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{ opportunity.Id => opportunity };
//depreciated		List<Opportunity> newList = opportunities.deepClone(true);
//depreciated		// Turn on all the triggers, and make sure everything is tested.
//depreciated		AbstractTrigger.setBooleanSettings('Opp_Before.',true);
//depreciated		// insert
//depreciated		AbstractTrigger.insertMissing = 0;
//depreciated		OpportunityTriggerBefore.processTrigger(null,newList);
//depreciated		// update
//depreciated		newList = opportunities.deepClone(true);
//depreciated		OpportunityTriggerBefore.processTrigger(oldMap,newList);
//depreciated		// delete
//depreciated		OpportunityTriggerBefore.processTrigger(oldMap,null);
//depreciated		// If there were any missing values, our test is invalid
//depreciated		AbstractTriggerTest.validateSettings('Opp_Before.');
//depreciated	}

//depreciated	@isTest
//depreciated	static void deployTest() {
//depreciated		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
//depreciated		AbstractTriggerTest.deployTest('Opp_Before.',opportunities);
//depreciated	}
}