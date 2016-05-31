/**
 * Test class for OpportunityTriggerBefore2Test.cls
 *
 * @version 2015-10-23
 *
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-10-23 - Added clearCreditCardInformationTest
 * 2015-05-12 - Add test for clearing order status and related fields
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-03-24 - Back out updateAssignedApprovers
 * 2014-03-18 - Added tests for updateAssignedApprovers and updateRejectComments
 * 2014-03-05 - Added checkRequiredTest
 * 2014-03-03 - Added assignShippingContactTest
 * 2014-01-17 - Added assignRegionsTest
 * 2013-08-08 - Renamed to avoid release conflicts
 * 2013-08-08 - Added test for closeDateMoved method
 * 2013-07-18 - Removed setPOCApprovalFlags test method
 * 2013-07-05 - Added test for updatePOCStatus
 * 2013-04-30 - Added test method for assignServicesRiskReview
 * 2013-04-19 - Propigate CurrencyIsoCode across the objects
 * 2013-02-15 - Added test for updateRushOrder
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2014-02-10 - implemented test for convertELQAmount() 
 * 2013-10-16 - implemented test for updateReparentedPOC()
 * 2013-08-09 - implemented test for protectEmbedded()
 * 2013-07-24 - Added test for updating POC close comments
 * 2013-07-23 - Added test for POC parent opp owner role
 * 2013-06-27 - No longer setting POC status to "Defined"
 * 2012-12-17 - Updated POC approval flags test
 * 2012-11-29 - Added test for POC approval flags trigger
 * 2012-05-29 - Added test for owner assignment trigger
 */
@isTest
public class OpportunityTriggerBefore2Test {
	public static final String GLOBAL_PRICE_BOOK_NAME = 'Global Price Book';

	public static final Integer STANDARD_PRICE_BOOK_INDEX = 0;
	public static final Integer GLOBAL_PRICE_BOOK_INDEX = 1;

	public static final String SUPER_REGION = 'EMEA';
	public static final String SUPER_REGION2 = 'NA';

	public static RecordType preferredRecordType {
		get {
			if(preferredRecordType == null) {
				preferredRecordType = [
					select Id,name
					from RecordType
					where name like :(SUPER_REGION+' %')
						and SObjectType = 'Opportunity'
						and IsActive = true
					limit 1 ];
			}
			return preferredRecordType;
		}
	}

	public static Account account {
		get {
			if(account == null) {
				RecordType recordType = [
					select Id,name
					from RecordType
					where name = 'Strategic'
						and SObjectType = 'Account'
						and IsActive = true
					limit 1 ];
				account = new Account(
					CurrencyIsoCode='USD',
					name='Test Account',
					RecordTypeId=recordType.Id,
					AccountClassification__c=recordType.name );
				insert account;
				account.RecordType = recordType;
			}
			return account;
		}
	}

	public static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CurrencyIsoCode=account.CurrencyIsoCode,
					CloseDate=System.today(),
					ContractStartDate__c = System.today().addDays(1),
					Embedded__c = false,
					EmbeddedOverridden__c = 0,
					StageName='Prepare',
					OwnerId=UserInfo.getUserId(),
					AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
					RecordTypeId = preferredRecordType.Id,
					PrimaryBusinessUnit__c=null,
					POC_Status__c=null);
			}
			return opportunity;
		}
	}

	public static Contact contact {
		get {
			if(contact == null) {
				contact = new Contact(
					AccountId=account.Id,
					Email='test@redhat.com',
					FirstName='John',
					LastName='Smith',
					Phone='9055551212',
					Title='Dr',
					LoginName__c='test@redhat.com');
			}
			return contact;
		}
	}

	public static Id opportunityId {
		get {
			if(opportunity.Id == null) {
				AbstractTrigger.setBooleanSettings('Opp_Before.',false);
				AbstractTrigger.setBooleanSettings('Opp_After.',false);
				insert opportunity;
				AbstractTrigger.setBooleanSettings('Opp_Before.',true);
				AbstractTrigger.setBooleanSettings('Opp_After.',true);
			}
			return opportunity.Id;
		}
	}

	static DateTime getOpportunityLastModifiedDate() {
		if(opportunity.LastModifiedDate == null) {
			for(Opportunity opp : [
				select
					Name,
					CurrencyIsoCode,
					CloseDate,
					ContractStartDate__c,
					Embedded__c,
					EmbeddedOverridden__c,
					StageName,
					OwnerId,
					AccountId,
					ApprovalStatus__c,
					Country_of_Order__c,
					FulfillmentChannel__c,
					HasOpportunityLineItem,
					LastModifiedDate,
					ProductsWithoutContractNumberCount__c,
					RecordTypeId,
					PrimaryBusinessUnit__c,
					POC_Status__c
				from Opportunity
				where Id = :opportunityId])
			{
				opportunity = opp.clone(true,true,true,true);
			}
		}
		return opportunity.LastModifiedDate;
	}

	public static List<Pricebook2> priceBooks {
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

	public static Product2 product {
		get {
			if (product == null) {
				product = new Product2(
					CurrencyIsoCode=opportunity.CurrencyIsoCode,
					Name = 'Test Product',
					Family = 'GLS',
					IsActive = true,
					ProductCode = '__TESTING');
				insert product;
			}
			return product;
		}
	}

	public static List<PricebookEntry> priceBookEntries {
		get {
			if (priceBookEntries == null) {
				priceBookEntries = new List<PricebookEntry>();
				for(Pricebook2 pb : priceBooks) {
					priceBookEntries.add(new PricebookEntry(
						CurrencyIsoCode=product.CurrencyIsoCode,
						UseStandardPrice = false,
						Pricebook2Id = pb.Id,
						UnitPrice = 75.00,
						Product2Id = product.Id,
						IsActive=true));
				}
				insert priceBookEntries;
				for(PricebookEntry pe : pricebookEntries) {
					pe.Product2 = product;
				}
			}
			return priceBookEntries;
		}
	}

	public static OpportunityLineItem opportunityLineItem {
		get {
			if(opportunityLineItem == null) {
				opportunityLineItem = new OpportunityLineItem(
					OpportunityId = opportunityId,
					PricebookEntryId = priceBookEntries[STANDARD_PRICE_BOOK_INDEX].Id);
				insert opportunityLineItem;
				opportunityLineItem.PricebookEntry=priceBookEntries[STANDARD_PRICE_BOOK_INDEX];
			}
			return opportunityLineItem;
		}
	}

	public static OpportunityLineItem opportunityLineItemGlobal {
		get {
			if(opportunityLineItemGlobal == null) {
				opportunityLineItemGlobal = new OpportunityLineItem(
					OpportunityId = opportunityId,
					PricebookEntryId = priceBookEntries[GLOBAL_PRICE_BOOK_INDEX].Id);
				insert opportunityLineItemGlobal;
				opportunityLineItemGlobal.PricebookEntry=priceBookEntries[GLOBAL_PRICE_BOOK_INDEX];
			}
			return opportunityLineItemGlobal;
		}
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void customSettingTest() {
		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Opportunity.DefaultRecordTypeId');
		System.assertNotEquals(null,defaultRecordTypeId,'Custom String setting Opportunity.DefaultRecordTypeId has not been defined');
		Boolean found = false;
		for(RecordType rt : [
			select Id,name
			from RecordType
			where Id = :defaultRecordTypeId.Value__c
				and SObjectType = 'Opportunity'
			limit 1 ] )
		{
			found = true;
		}
		System.assert(found,'No record type was found with an Id value of Opportunity.DefaultRecordTypeId = '+defaultRecordTypeId.Value__c);
	}

	@isTest
	static void assignShippingContactTest() {
		opportunity.RecordTypeId = OpportunityTriggerBefore2.zeroValueOpportunityRecordTypeId;
		if(opportunity.RecordTypeId != null) {
			insert contact;
			OpportunityContactRole ocr = new OpportunityContactRole(
				ContactId = contact.Id,
				OpportunityId = opportunityId,
				Role = 'Shipping Contact');
			insert ocr;
			OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunityId=>opportunity},new List<Opportunity>{opportunity});
			triggerBefore.assignShippingContact();
			System.assertEquals(contact.Id,opportunity.ShippingContact__c);
		}
	}

	@isTest
	static void checkRequiredTest() {
		opportunity.RecordTypeId = OpportunityTriggerBefore2.zeroValueOpportunityRecordTypeId;
		opportunity.OpportunityType__c = 'Bridge';
		if(opportunity.RecordTypeId != null) {
			getOpportunityLastModifiedDate();
			Opportunity opp2 = opportunity.clone(true,true,true,true);
			opp2.ApprovalStatus__c = OpportunityTriggerBefore2.PENDING_PLV;
			OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunityId=>opportunity},new List<Opportunity>{opp2});
			triggerBefore.checkRequired();
			System.assert(triggerBefore.hasErrors,'Expected errors from missing fields');
		}
	}

	@isTest // we create the custom settings needed
	static void assignRecordTypeTest() {
		DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
		dfrt.GlobalAs__c=SUPER_REGION;
		dfrt.PreferredAccountRecordType__c='Like it matters.';
		dfrt.PreferredOpportunityRecordType__c='oatuehaseouthaseuth';
		dfrt.SecondaryAccountRecordType__c='Who cares?';
		dfrt.SecondaryOpportunityRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
		upsert dfrt;
		Id recordTypeId = '012000000000000AAA';
		StringSetting__c defaultRecordTypeId = new StringSetting__c(
			Name='Opportunity.DefaultRecordTypeId',
			Value__c=recordTypeId);
		insert new StringSetting__c(
			Name='Opportunity.DefaultRecordTypeId',
			Value__c=recordTypeId);
		opportunity.RecordTypeId = recordTypeId;
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{opportunity});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		RecordTypeAssignment__c rta = new RecordTypeAssignment__c(
			ManagedProfiles__c = triggerBefore.currentUser.Profile.Name,
			Object_Label__c = 'Opportunity',
			RecordType__c = preferredRecordType.Name,
			Super_Region__c = 'GLOBAL');
		insert rta;
		// testing assignment from the secondary value
		triggerBefore.assignRecordType();
		System.assertEquals(preferredRecordType.Id,opportunity.recordTypeId);
		opportunity.RecordTypeId = recordTypeId;
		dfrt.SecondaryOpportunityRecordType__c='aoetuhaseouthshs';
		update dfrt;
		triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{opportunity});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		// testing failure case
		triggerBefore.assignRecordType();
		System.assertEquals(recordTypeId,opportunity.recordTypeId);
		dfrt.PreferredOpportunityRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
		update dfrt;
		triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{opportunity});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		// testing assignment from preferred value
		triggerBefore.assignRecordType();
		System.assertEquals(preferredRecordType.Id,opportunity.recordTypeId);
	}

	@isTest
	static void closeDateMovedTest() {
		Opportunity opp = new Opportunity(
					Name = 'Opportunity Test',
					CloseDate = System.today(),
					Close_Date_Moved_Reason__c='anything',
					Close_Date_Moved_Details__c='anything');
		// first test try moving into the past
		OpportunityTriggerBefore2.adminByPass.IsSalesUser__c = false;
		Opportunity oppNew = opp.clone();
		oppNew.CloseDate = opp.CloseDate.addYears(-1);
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{oppNew});
		triggerBefore.closeDateMoved();
		System.assert(! triggerBefore.hasErrors,'Non-Sales users should be able to move the close date into the past.');
		System.assertEquals(false,oppNew.Close_Date_Moved__c);
		System.assertEquals(null,oppNew.Close_Date_Moved_Reason__c);
		System.assertEquals(null,oppNew.Close_Date_Moved_Details__c);
		OpportunityTriggerBefore2.adminByPass.IsSalesUser__c = true;
		oppNew = opp.clone();
		oppNew.CloseDate = opp.CloseDate.addYears(-1);
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{oppNew});
		triggerBefore.closeDateMoved();
		System.assert(triggerBefore.hasErrors,'Sales users should not be able to move the close date into the past.');
		// now test moving into the future
		oppNew = opp.clone();
		oppNew.CloseDate = opp.CloseDate.addYears(1);
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{oppNew});
		triggerBefore.closeDateMoved();
		System.assertEquals(true,oppNew.Close_Date_Moved__c);
		System.assertNotEquals(null,oppNew.Close_Date_Moved_Reason__c);
		System.assertNotEquals(null,oppNew.Close_Date_Moved_Details__c);
		System.assert(! triggerBefore.hasErrors,'No error expected, as a reason was supplied');
		oppNew = opp.clone();
		oppNew.CloseDate = opp.CloseDate.addYears(1);
		oppNew.Close_Date_Moved_Reason__c = null;
		oppNew.Close_Date_Moved_Details__c = null;
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{oppNew});
		triggerBefore.closeDateMoved();
		System.assert(triggerBefore.hasErrors,'error expected, as no reason was supplied');
	}

	@isTest
	static void updatePOCStatusTest() {
		Opportunity opp = new Opportunity(
					Name = 'Opportunity Test',
					EngagementStartDate__c = System.today(),
					POC_Status__c = OpportunityTriggerBefore2.POC_STATUS_ACCEPTED);
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
		triggerBefore.updatePOCStatus();
		System.assertEquals(OpportunityTriggerBefore2.POC_STATUS_ENGAGED,opp.POC_Status__c);
	}

	@isTest
	static void updateRejectCommentsTest1() {
		opportunity.POC_Status__c = 'Test';
		opportunity.RecordTypeId = OpportunityTriggerBefore2.POCRecordTypeId;
		Id oppId = opportunityId;
		Opportunity opp2 = opportunity.clone(true);
		opp2.POC_Status__c = OpportunityTriggerBefore2.POC_STATUS_CLOSED;
		opp2.POC_Close_Reason__c = 'Rejected';
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new List<Opportunity>{opp2});
		triggerBefore.updateRejectComments();
		System.assert(triggerBefore.rejectPOCIds.contains(oppId));
		System.assert(triggerBefore.rejectOppIds.contains(oppId));
		System.assertEquals(null,opp2.POC_Close_Comments__c);
	}

	@isTest
	static void updateRejectCommentsTest2() {
		opportunity.RecordTypeId = OpportunityTriggerBefore2.zeroValueOpportunityRecordTypeId;
		if(opportunity.RecordTypeId != null) {
			opportunity.ApprovalStatus__c = OpportunityTriggerBefore2.PENDING_PLV;
			Id oppId = opportunityId;
			Opportunity opp2 = opportunity.clone(true);
			opp2.ApprovalStatus__c = OpportunityTriggerBefore2.REJECTED_PLV;
			OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new List<Opportunity>{opp2});
			triggerBefore.updateRejectComments();
			System.assert(triggerBefore.rejectZeroValueOpportunityIds.contains(oppId));
			System.assert(triggerBefore.rejectOppIds.contains(oppId));
			System.assertEquals(null,opp2.POC_Close_Comments__c);
			System.assert(triggerBefore.hasErrors,'Expected a failure due the lack of a comment record');
		}
	}

	@isTest(SeeAllData=true)
	static void updateRejectCommentsTest3() {
		for(ProcessInstanceStep pis : [
			select
				Comments,
				ProcessInstance.TargetObjectId
			from ProcessInstanceStep
			where Comments != null
			limit 1])
		{
			Opportunity opp = new Opportunity(
				recordTypeId = OpportunityTriggerBefore2.POCRecordTypeId,
				POC_Status__c = 'Test');
			Opportunity opp2 = opp.clone(true);
			opp2.POC_Status__c = OpportunityTriggerBefore2.POC_STATUS_CLOSED;
			opp2.POC_Close_Reason__c = 'Rejected';
			OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{null=>opp},new List<Opportunity>{opp2});
			triggerBefore.oppMapClone = new Map<Id,Opportunity>{pis.ProcessInstance.TargetObjectId => opp2};
			triggerBefore.rejectPOCIds = new Set<Id>{ pis.ProcessInstance.TargetObjectId };
			triggerBefore.processInstances =  [
				select
					TargetObjectId,
					(	select
							Comments
						from StepsAndWorkitems
						where Comments != null
						limit 1)
				from ProcessInstance
				where Id = :pis.ProcessInstanceId ];
			triggerBefore.updateRejectComments();
			System.assertEquals(triggerBefore.processInstances[0].StepsAndWorkitems[0].Comments,opp2.POC_Close_Comments__c);
		}
	}

	@isTest
	static void updatePOCParentFieldsTest() {
		insert new RecordTypeLookup__c(Name='Proof of Concept',IdForOpportunity__c='012000000000000AAA');
		Opportunity opp = new Opportunity(
					Name = 'Opportunity Test',
					Cloned_From_Opportunity__c = opportunityId,
					RecordTypeId = OpportunityTriggerBefore2.pocRecordTypeId);
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
		triggerBefore.updatePOCParentFields();
		System.assert(!String.isBlank(opp.POC_Parent_Opportunity_Owner_Role__c));
		System.assert(!String.isBlank(opp.POC_Parent_Stage__c));
	}

	@isTest
	static void updateReparentedPOCTest() {
		insert new RecordTypeLookup__c(Name='Proof of Concept',IdForOpportunity__c='012000000000000AAA');
		Opportunity parentOpp1 = opportunity;
		insert parentOpp1;
		Opportunity parentOpp2 = parentOpp1.clone(false);
		parentOpp2.Country_of_Order__c='United States';
		insert parentOpp2;
		Opportunity poc = new Opportunity(
					Name = 'Opportunity Test',
					Cloned_From_Opportunity__c = parentOpp1.Id,
					RecordTypeId = OpportunityTriggerBefore2.pocRecordTypeId);
		Opportunity poc2 = poc.clone();
		poc2.Cloned_From_Opportunity__c = parentOpp2.Id;
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{poc.Id=>poc},new List<Opportunity>{poc2});
		triggerBefore.updateReparentedPOC();
		System.assertEquals('United States', poc2.Country_of_Order__c);
	}

	@isTest(SeeAllData=true)
	static void updateRushOrderTest() {
		// setup for testing
		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		String sku = product.ProductCode;
		RushOrderSKU__c ros = RushOrderSKU__c.getInstance(sku);
		if(ros == null) {
			ros = new RushOrderSKU__c(Name=sku);
			insert ros;
		}
		OpportunityLineItem lineItem = opportunityLineItem;
		Opportunity opp = [
			select
				BigMachines__Line_Items__c,
				ContractStartDate__c,
				Rush_Order__c,
				Rush_Order_Reason__c,
				Rush_Order_Set_By_System__c
			from Opportunity where Id = :opportunityId ];
		opp.Rush_Order__c = true;
		opp.Rush_Order_Reason__c = OpportunityTriggerBefore2.RUSH_PRODUCT_EXCEPTION;
		opp.Rush_Order_Set_By_System__c = true;
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp});
		triggerBefore.updateRushOrder();
		// we meet all the criteria, tho opportunity should not have been changed
		System.assert(opp.Rush_Order__c,'Rush Order should not have been cleared');
		System.assertEquals(OpportunityTriggerBefore2.RUSH_PRODUCT_EXCEPTION,opp.Rush_Order_Reason__c);
		System.assert(opp.Rush_Order_Set_By_System__c,'Rush Order Set By System should not have been cleared');

		// now try deleting a line item
		delete lineItem;
		Opportunity opp2 = [
			select
				BigMachines__Line_Items__c,
				ContractStartDate__c,
				Rush_Order__c,
				Rush_Order_Reason__c,
				Rush_Order_Set_By_System__c
			from Opportunity where Id = :opportunityId ];
		opp2.Rush_Order__c = true;
		opp2.Rush_Order_Reason__c = OpportunityTriggerBefore2.RUSH_PRODUCT_EXCEPTION;
		opp2.Rush_Order_Set_By_System__c = true;
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
		triggerBefore.updateRushOrder();
		// the rush order fields should have been cleared
		System.assert(! opp2.Rush_Order__c,'Rush Order should have been cleared');
		System.assertEquals(null,opp2.Rush_Order_Reason__c);
		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');

		opp = opp2;
		opp.Rush_Order__c = true;
		opp.Rush_Order_Reason__c = OpportunityTriggerBefore2.RUSH_SLA_TIME_PERIOD;
		opp.Rush_Order_Set_By_System__c = true;
		opp2 = opp.clone(true,false,true,true);
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
		triggerBefore.updateRushOrder();
		// we still pass the criteria, so nothing should change
		System.assert(opp2.Rush_Order__c,'Rush Order should not have been cleared');
		System.assertEquals(OpportunityTriggerBefore2.RUSH_SLA_TIME_PERIOD,opp2.Rush_Order_Reason__c);
		System.assert(opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should not have been cleared');

		// now try moving the contract start date
		opp2.ContractStartDate__c = System.today().addDays(30);
		triggerBefore.updateRushOrder();
		// we no longer meet the criteria so the rush order should be cleared
		System.assert(! opp2.Rush_Order__c,'Rush Order should have been cleared');
		System.assertEquals(null,opp2.Rush_Order_Reason__c);
		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');

		// new lets try changing to a non-system value
		opp.Rush_Order__c = true;
		opp.Rush_Order_Reason__c = OpportunityTriggerBefore2.RUSH_SLA_TIME_PERIOD;
		opp.Rush_Order_Set_By_System__c = true;
		opp2 = opp.clone(true,false,true,true);
		opp2.Rush_Order_Reason__c = 'Anything';
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opp.Id=>opp},new List<Opportunity>{opp2});
		triggerBefore.updateRushOrder();
		System.assert(opp2.Rush_Order__c,'Rush Order should not have been cleared');
		System.assertEquals('Anything',opp2.Rush_Order_Reason__c);
		System.assert(! opp2.Rush_Order_Set_By_System__c,'Rush Order Set By System should have been cleared');
	}

	@isTest
	static void assignServicesRiskReviewTest() {
		opportunity.Services_Risk_Review__c = false;
		Opportunity opp2 = opportunity.clone(true);
		opportunity.Services_Contract_Type__c = 'Fixed Price';
		opp2.Services_Contract_Type__c = 'Anything Else';
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(
			new Map<Id,Opportunity>{opp2.Id=>opp2},new List<Opportunity>{opportunity});
		triggerBefore.assignServicesRiskReview();
		system.assertEquals(true,opportunity.Services_Risk_Review__c);
		opp2.Services_Risk_Review__c = true;
		opp2.Services_Contract_Type__c = 'Fixed Price';
		opportunity.Services_Contract_Type__c = 'Anything Else';
		triggerBefore.assignServicesRiskReview();
		system.assertEquals(false,opportunity.Services_Risk_Review__c);
	}

	@isTest
	static void protectEmbeddedTest() {
		//test with override priviledge granted
		EmbeddedOverride__c overrideSetting = new EmbeddedOverride__c(SetupOwnerId = UserInfo.getUserId(), OverrideAllowed__c = true);
		insert overrideSetting;
		insert opportunity;
		Opportunity opp2 = opportunity.clone(true);
		opp2.Embedded__c = true;
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new List<Opportunity>{opp2});
		triggerBefore.protectEmbedded();
		system.assertEquals(opportunity.Id,opp2.Id);
		system.assert(opp2.Embedded__c);
		system.assertEquals(1,opp2.EmbeddedOverridden__c);

		//test with override priviledge revoked
		delete overrideSetting;
		OpportunityTriggerBefore2.embedded = null;
		opp2 = opportunity.clone(true);
		opp2.Embedded__c = true;
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new List<Opportunity>{opp2});
		triggerBefore.protectEmbedded();
		system.assert(!opp2.Embedded__c);
		system.assertEquals(0,opp2.EmbeddedOverridden__c);

		//test bypass for lineitem trigger
		opp2.Embedded__c = true;
		opp2.EmbeddedOverridden__c = OpportunityLineItemTriggerBefore2.EMBEDDED_TRIGGER_KEY;
		triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new List<Opportunity>{opp2});
		triggerBefore.protectEmbedded();
		system.assert(opp2.Embedded__c);
		system.assertEquals(0,opp2.EmbeddedOverridden__c);
	}

	static List<Region__c> regList {
		get {
			if(regList == null) {
				regList = new List<Region__c>{
					new Region__c(
						Country__c = 'India',
						CurrencyIsoCode = 'INR',
						Name = 'Test Region',
						Region__c = 'India/Pakistan',
						Super_Region__c = 'APAC',
						Sub_Region__c = null),
					new Region__c(
						Country__c = 'United States',
						CurrencyIsoCode = 'USD',
						Name = 'Test Region',
						Region__c = 'US',
						Super_Region__c = 'NA',
						Sub_Region__c = null),
					new Region__c(
						Country__c = 'United Kingdom',
						CurrencyIsoCode = 'GBP',
						Name = 'Test Region',
						Region__c = 'NEE',
						Super_Region__c = 'EMEA',
						Sub_Region__c = 'UK' ),
					new Region__c(
						Country__c = 'Argentina',
						CurrencyIsoCode = 'USD',
						Name = 'Test Region',
						Region__c = 'SOLA',
						Super_Region__c = 'LATAM',
						Sub_Region__c = null) };
				insert regList;
			}
			return regList;
		}
	}

	static List<Opportunity> oppList {
		get {
			if(oppList == null) {
				Opportunity opp = new Opportunity(
					Name='Test Opp',
					FulfillmentChannel__c='Indirect – VAR/VAD',
					CloseDate=System.today(),
					StageName='Unqualified',
					AccountId=account.Id,
					Country_of_Order__c='Bogus Country',
					CurrencyIsoCode = 'USD',
					Amount = 1000.00);
				oppList = new List<Opportunity>{ opp };
				for(Region__c reg : regList) {
					Opportunity o = opp.clone();
					o.Country_of_Order__c = reg.Country__c;
					o.CurrencyIsoCode = reg.CurrencyIsoCode;
					o.Amount = 1000.00;
					oppList.add(o);
				}
			}
			return oppList;
		}
	}

	@isTest
	static void assignRegionsTest() 
	{
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(null,oppList);
		triggerBefore.assignRegions();
		List<Region__c> regList2 = regList.clone();
		for(Opportunity opp : oppList) {
			if (opp.Country_of_Order__c == 'Bogus Country') {
				System.assertEquals(null, opp.Region2__c);
				//In prod, this field has a default value. Commenting out this assert for now.
				//System.assertEquals(null, opp.Region__c);
				System.assertEquals(null, opp.SubRegion__c);
			}
			else {
				Region__c reg = regList2.remove(0);
				if(reg.Super_Region__c == 'APAC') {
					System.assertEquals('1',opp.Region2__c);
				}
				else if(reg.Super_Region__c == 'EMEA') {
					System.assertEquals('4',opp.Region2__c);
				}
				else if(reg.Super_Region__c == 'LATAM') {
					System.assertEquals('8',opp.Region2__c);
				}
				else if(reg.Super_Region__c == 'NA') {
					System.assertEquals('3',opp.Region2__c);
				}
				System.assertEquals(reg.Region__c,opp.Region__c);
				System.assertEquals(reg.Sub_Region__c,opp.SubRegion__c);
			}
		}
	}

	static void initELQ() {
		OpportunityTriggerBefore2.currencyIsoCodes = new Set<String>();
		OpportunityTriggerBefore2.closeDates = new Set<Date>();
		OpportunityTriggerBefore2.conversionMap = null;
	}

	@isTest
	static void convertELQAmountTest() {
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(null,oppList);
		initELQ();
		triggerBefore.convertELQAmount();
		for(Opportunity opp : oppList) {
			system.assert(opp.Amount > 0.0);
			system.assert(opp.ELQ_USD_AMT__c > 0.0, opp.ELQ_USD_AMT__c + ' should be greater than 0 for '+opp.CurrencyIsoCode+' on '+opp.CloseDate);
		}

		Opportunity pastOpp = oppList[0].clone();
		pastOpp.CurrencyIsoCode = 'GBP';
		pastOpp.Amount = 1000.00;
		pastOpp.CloseDate = System.today().addYears(-5);
		triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{pastOpp});
		initELQ();
		triggerBefore.convertELQAmount();
		system.assert(pastOpp.ELQ_USD_AMT__c > 0.0, pastOpp.ELQ_USD_AMT__c + ' should be greater than 0');

		Opportunity futureOpp = oppList[0].clone();
		futureOpp.CurrencyIsoCode = 'GBP';
		futureOpp.Amount = 1000.00;
		futureOpp.CloseDate = System.today().addYears(5);
		triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{futureOpp});
		initELQ();
		triggerBefore.convertELQAmount();
		system.assert(futureOpp.ELQ_USD_AMT__c > 0.0, futureOpp.ELQ_USD_AMT__c + ' should be greater than 0');

		Opportunity testOpp = oppList[0].clone();
		testOpp.CurrencyIsoCode = 'GBP';
		testOpp.Amount = 1000.00;
		triggerBefore = new OpportunityTriggerBefore2(null,new List<Opportunity>{testOpp});
		initELQ();
		//clear the conversion map to enter exception handler
		OpportunityTriggerBefore2.conversionMap = New Map<String, Map<Date, Double>>();
		triggerBefore.convertELQAmount();
		system.assertEquals(0.0, testOpp.ELQ_USD_AMT__c);
	}

	@IsTest
	static void assignOpportunityPartnersTest() {
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{opportunityId=>opportunity},new List<Opportunity>{opportunity});
		triggerBefore.assignOpportunityPartners();
		System.assertNotEquals(null,opportunity.Opportunity_Partners__c);
	}

	@IsTest
	static void clearOrderStatusTest() {
		oppList[0].Order_Status__c = 'Anything';
		oppList[0].OM_review_complete__c = true;
		oppList[0].Pending_OM_Review__c = true;
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(null,oppList);
		triggerBefore.clearOrderStatus();
		System.assertEquals(null,oppList[0].Order_Status__c);
		System.assertEquals(false,oppList[0].OM_review_complete__c);
		System.assertEquals(false,oppList[0].Pending_OM_Review__c);
	}

	@IsTest
	static void clearCreditCardInformationTest() {
		Opportunity oppBefore = oppList[0];
		oppBefore.CreditCardType__c = 'VISA';
		oppBefore.Credit_Card_Number__c = '1';
		oppBefore.Credit_Card_Token__c = null;
		oppBefore.Operating_Unit__c = 'RH China Operating Unit';
		// the default will be that token number is required
		Opportunity oppAfter = oppBefore.clone(true);
		oppAfter.Operating_Unit__c = 'RH US Operating Unit';
		OpportunityTriggerBefore2 triggerBefore = new OpportunityTriggerBefore2(new Map<Id,Opportunity>{oppBefore.Id=>oppBefore},new List<Opportunity>{oppAfter});
		triggerBefore.clearCreditCardInformation();
		System.assertEquals(null,oppAfter.Credit_Card_Number__c);
		System.assertEquals(null,oppAfter.CreditCardType__c);
	}


	@isTest // (SeeAllData=true) is not needed anymore because we insert missing settings
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{ opportunity.Id => opportunity };
		List<Opportunity> newList = opportunities.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Opp_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		OpportunityTriggerBefore2.processTrigger(null,newList);
		// update
		newList = opportunities.deepClone(true);
		OpportunityTriggerBefore2.processTrigger(oldMap,newList);
		// delete
		OpportunityTriggerBefore2.processTrigger(oldMap,null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Opp_Before.');
	}

	@isTest
	static void deployTest() {
		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
		AbstractTriggerTest.deployTest('Opp_Before.',opportunities);
	}
}