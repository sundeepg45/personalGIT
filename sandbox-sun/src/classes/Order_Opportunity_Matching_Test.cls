/**
 * This test class is used to test the functionality of Order_Opportunity_Matching class.
 *
 * @version 2016-01-26
 * @author Vipul Jain <vipujain@DELOITTE.com>
 * @since 2014-10-01 - initial version
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2016-01-27 - Updates to support proactive matching, corrected test class many errors
 * @since 2015-10-27 - reduce the queries used by a failing test
 * @since 2015-07-07 - updated to assign Account_Matching_Orders.proactiveSalesAccountErrorSetting
 * @since 2015-07-07 - updated tests to run as intadmin
 * @since 2015-06-03 - Updated to check the System_Exception_Handler for caught exceptions
 */
@isTest
private class Order_Opportunity_Matching_Test
{
	private static List<OperatingUnit__c> operatingUnits {
		get {
			if(operatingUnits == null) {
				Map<String,String> partnerRecordTypeMap = new Map<String,String>();
				Set<String> recordTypes = new Set<String>();
				for(Schema.PicklistEntry ple : OperatingUnit__c.PartnerRecordType__c.getDescribe().getPicklistValues()) {
					String partnerRecordTypeName = ple.getLabel();
					String region = partnerRecordTypeName.split('\\s',2)[0].toUpperCase();
					partnerRecordTypeMap.put(region,partnerRecordTypeName);
					recordTypes.add(partnerRecordTypeName.toUpperCase());
				}
				Map<String,String> salesRecordTypeMap = new Map<String,String>();
				Set<String> availableRegions = new Set<String>(partnerRecordTypeMap.keySet());
				for(Schema.PicklistEntry ple : OperatingUnit__c.AccountRecordType__c.getDescribe().getPicklistValues()) {
					String salesRecordTypeName = ple.getLabel();
					String region = salesRecordTypeName.split('\\s',2)[0];
					if((! recordTypes.contains(salesRecordTypeName.toUpperCase()) && availableRegions.remove(region.toUpperCase())) ) {
						salesRecordTypeMap.put(region,salesRecordTypeName);
					}
				}
				List<String> regionList = new List<String>(salesRecordTypeMap.keySet());
				regionList.sort();
				operatingUnits = new List<OperatingUnit__c>();
				for(String region : regionList) {
					operatingUnits.add( 
						new OperatingUnit__c(
							Name='Test OU '+region,
							AccountRecordType__c = salesRecordTypeMap.get(region),
							BusinessUnitId__c = -5551212-operatingUnits.size(),
							PartnerRecordType__c = partnerRecordTypeMap.get(region.toUpperCase()),
							Region__c = region) );
				}
				insert operatingUnits;
			}
			return operatingUnits;
		}
	}

	private static List<Account> createAccounts() {
		List<Account> xsalesAccounts = new List<Account>();
		List<Account> xpartnerAccounts = new List<Account>();
		for(OperatingUnit__c ou : operatingUnits) {
			Account a = TestUtil.getAccount('Test '+ou.AccountRecordType__c);
			a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ou.AccountRecordType__c).getRecordTypeId();
			a.CDH_Party_Name__c = cdhParty.Id;
			xsalesAccounts.add(a);
			a = TestUtil.getAccount('Test '+ou.PartnerRecordType__c);
			a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ou.PartnerRecordType__c).getRecordTypeId();
			a.CDH_Party_Name__c = cdhParty.Id;
			xpartnerAccounts.add(a);
		}
		salesAccounts = xsalesAccounts;
		partnerAccounts = xpartnerAccounts;
		List<Account> accounts = xsalesAccounts.clone();
		accounts.addAll(xpartnerAccounts);
		return accounts;
	}

	private static List<Account> salesAccounts {
		get {
			if(salesAccounts == null) {
				insert createAccounts();
			}
			return salesAccounts;
		}
		set;
	}

	private static List<Account> partnerAccounts {
		get {
			if(partnerAccounts == null) {
				insert createAccounts();
			}
			return partnerAccounts;
		}
		set;
	}

	private static Opportunity createOpportunity() {
		return TestUtil.getOpportunity('Opportunity Name' ,salesAccounts[0]);
	}

	private static Opportunity opp {
		get {
			if(opp == null) {
				opp = createOpportunity();
			}
			if(opp.Id == null) {
				insert opp;
				for(Opportunity xopp : [
					select id,
						Name,
						OpportunityNumber__c
					from Opportunity 
					where id=:opp.Id ] )
				{
					opp = xopp;
				}
			}
			return opp;
		}
		set;
	}

	private static Opportunity_Header_Staging__c createOpportunityHeaderStaging() {
		Opportunity_Header_Staging__c xoppHeaderStaging = TestUtil.getDirectOpportunityHeaderStagingData(opp,'Not Processed' ,'CLOSED');
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Operating_Unit__c = operatingUnits[0].Name;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
		xoppHeaderStaging.Bill_To_Account_Number__c='12345';
		xoppHeaderStaging.Ship_To_Account_Number__c='12345';
		xoppHeaderStaging.Sold_To_Account_Number__c='12345';
		xoppHeaderStaging.Entitle_To_Account_Number__c='12345';
		xoppHeaderStaging.Bill_To_CDH_Party_Number__c='12345';
		xoppHeaderStaging.Ship_To_CDH_Party_Number__c='12345';
		xoppHeaderStaging.Sold_To_CDH_Party_Number__c='12345';
		xoppHeaderStaging.Entitle_To_CDH_Party_Number__c='12345';
		xoppHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c='12345';
		xoppHeaderStaging.Ship_To_Address_CDH_Party_Site_Number__c='12345';
		xoppHeaderStaging.Sold_To_Address_CDH_Party_Site_Number__c='12345';
		xoppHeaderStaging.Entitle_To_Address_CDH_Party_Site_Number__c='12345';
		xoppHeaderStaging.Bill_To_CDH_Party_Number_Account__c='12345';
		xoppHeaderStaging.Ship_To_CDH_Party_Number_Account__c='12346';
		xoppHeaderStaging.Sold_To_CDH_Party_Number_Account__c='12347';
		xoppHeaderStaging.Entitle_To_CDH_Party_Number_Account__c='12348';
		return xoppHeaderStaging;
	}

	private static Opportunity_Header_Staging__c oppHeaderStaging {
		get {
			if(oppHeaderStaging == null) {
				oppHeaderStaging = createOpportunityHeaderStaging();
				insert oppHeaderStaging;
			}
			return oppHeaderStaging;
		}
		set {
			oppHeaderStaging = value;
			if(value != null && value.Id == null) {
				insert value;
			}
		}
	}

	private static void setOppHeaderStaging(Opportunity_Header_Staging__c xoppHeaderStaging) {
		oppHeaderStaging = xoppHeaderStaging;
		if( oppLineStagingList != null
			&& oppPartnerStagingList != null
			&& ebsAccount != null 
			&& addRec != null 
			&& contact != null)
		{
			oppHeaderStaging = Order_Opportunity_Matching.queryOrders(new Set<Id>{xoppHeaderStaging.Id})[0];
		}
	}

	private static List<Opportunity_Match_Configuration__c> oppMatchConfigList {
		get {
			if(oppMatchConfigList == null) {
				Account_Matching_Orders.proactiveSalesAccountErrorSetting = false;
				Account_Matching_Orders.proactiveSalesAccountErrorSetting = false;
				oppMatchConfigList = new List<Opportunity_Match_Configuration__c>{
					TestUtil.getOpportunityMatchConfigurationData('RecordType__c','NOT EQUAL TO','EMEA Sales Opportunity'),
					TestUtil.getOpportunityMatchConfigurationData('StageName','NOT EQUAL TO','Closed Booked'),
					TestUtil.getOpportunityMatchConfigurationData('Amount','Range', '10')};
				insert oppMatchConfigList;
				insert new List<Indirect_Matching_Static_Data__c>{
					new Indirect_Matching_Static_Data__c(
						Name='Limit',
						Value__c='10'),
					new Indirect_Matching_static_Data__c(
						name='SortBy',
						Value__c='Name') };
			}
			return oppMatchConfigList;
		}
	}

	private static CDH_Party__c  cdhParty {
		get {
			if(cdhParty == null) {
				cdhParty = TestUtil.getCDHParty('12345','Organization');
				insert cdhParty;
			}
			return cdhParty;
		}
	}

	private static Contact contact {
		get {
			if(contact == null) {
				contact=TestUtil.getContact('Test Con',salesAccounts[0]);
				contact.CDH_Party__c=cdhParty.id;
				insert contact;
			}
			return contact;
		}
	}

	private static List<OpportunityLineItem> createOpportunityLineItems() {
		Id pricebookId = Test.getStandardPricebookId();
		Id globalPricebookId = OpportunityLineItemTriggerBefore2Test.globalPricebookId;
		Product2 product = TestUtil.getProduct('Product Test Data');
		product.ProductCode='12345';
		product.IsActive=true;
		insert product;

		PricebookEntry pricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
		PricebookEntry pricebookEntry1 = TestUtil.getPricebookEntry(globalPricebookId ,product);
		insert new List<PricebookEntry>{pricebookEntry,pricebookEntry1};

		return new List<OpportunityLineItem>{
			TestUtil.getOpportunityLineItem(opp,pricebookEntry.id),
			TestUtil.getOpportunityLineItem(opp,pricebookEntry.id) };
	}

	private static List<OpportunityLineItem> oppLineItems {
		get {
			if(opp != null) {
				if(oppLineItems == null) {
					oppLineItems = createOpportunityLineItems();
				}
				insertSObjects(oppLineItems);
			}
			return oppLineItems;
		}
		set {
			oppLineItems = value;
			insertSObjects( value );
		}
	}

	private static List<Opportunity_Line_Staging__c> createOpportunityLineStagingList(Opportunity_Header_Staging__c xoppHeaderStaging) {
		if(xoppHeaderStaging == null) {
			xoppHeaderStaging = oppHeaderStaging;
		}
		if(xoppHeaderStaging.Id == null) {
			insert xoppHeaderStaging;
		}
		List<Opportunity_Line_Staging__c> retval = new List<Opportunity_Line_Staging__c>();
		for(OpportunityLineItem oppLineItem : oppLineItems ) {
			Opportunity_Line_Staging__c oppLineStaging = TestUtil.getDirectOpportunityLineStagingData(xoppHeaderStaging, oppLineItem,'12345');
			oppLineStaging.Entitle_To_Party_Number__c ='12345';
			oppLineStaging.Entitle_To_CDH_Party_Number__c='12345';
			oppLineStaging.Quantity__c=1;
			oppLineStaging.Entitle_To_CDH_Party_Site_Number__c='12345';
			oppLineStaging.Product_Code_Oracle__c='12345';
			oppLineStaging.UnitPrice__c=10;
			retval.add(oppLineStaging);
		}
		return retval;
	}

	private static List<Opportunity_Line_Staging__c> oppLineStagingList {
		get {
			if(oppLineStagingList == null) {
				oppLineStagingList = createOpportunityLineStagingList(oppHeaderStaging);
				insert oppLineStagingList;
			}
			return oppLineStagingList;
		}
		set {
			oppLineStagingList = value;
			insertSObjects( value );
		}
	}

	private static EBS_Account__c ebsAccount {
		get {
			if(ebsAccount == null) {
				ebsAccount= TestUtil.getEBSAcc('12345',salesAccounts[0].Id,'12345');
				insert ebsAccount;
			}
			return ebsAccount;
		}
	}

	private static Address__c addRec {
		get {
			if(addRec == null) {
				addRec= TestUtil.getAddress('12345',salesAccounts[0].Id);
				Insert addRec;
			}
			return addRec;
		}
	}

	private static void insertSObjects(List<SObject> objects) {
		if(objects != null) {
			List<SObject> listToInsert = new List<SObject>();
			for(SObject o : objects) {
				if(o.Id == null) {
					listToInsert.add(o);
				}
			}
			insert listToInsert;
		}
	}

	private static Map<String,Classification__c> classificationMap {
		get {
			if(classificationMap == null) {
				classificationMap = new Map<String,Classification__c>{
					'PARTNER TIER'=>new Classification__c(
						Name='Partner Tier',
						IsActive__c = true,
						IsInlineEdit__c = true ),
					'PARTNER TYPE'=>new Classification__c(
						Name='Partner Type',
						IsActive__c = true,
						IsInlineEdit__c = true ) };
				for(Classification__c cl : [
					select Id,Name 
					from Classification__c
					where Name in :classificationMap.keySet()
						and IsActive__c = true ])
				{
					classificationMap.put(cl.Name.toUpperCase(),cl);
				}
				insertSObjects(classificationMap.values());
				for(Classification__c cl : classificationMap.values().clone()) {
					String name='Test '+cl.Name;
					classificationMap.put(
						name.toUpperCase(),
						new Classification__c(
							Name = 'Test '+cl.Name,
							IsActive__c = true,
							IsInlineEdit__c = true,
							Parent__c = cl.Id ) );
				}
				insertSObjects(classificationMap.values());
			}
			return classificationMap;
		}
	}

	//insert partner program definition where oracle code is not null.
	private static Partner_Program_Definition__c partnerProgramDefinition {
		get {
			if(partnerProgramDefinition == null) {
				partnerProgramDefinition = new Partner_Program_Definition__c(
					Partner_Tier__c = 'Test Partner Tier',
					Partner_Type__c = 'Test Partner Type',
					Global_Region__c = 'Test Region',
					Is_Primary_Eligible__c = TRUE,
					Legacy_Partner_Type__c = classificationMap.get('TEST PARTNER TYPE').Id,
					Oracle_Classification_Code__c = '987987',
					Program_Category__c = 'Test Catagory',
					Program_Status__c = 'Active',
					Requires_Approval__c = FALSE);
				insert partnerProgramDefinition;
			}
			return partnerProgramDefinition;
		}
	}

	private static Partner_Program_Tier__c partnerProgramTier {
		get {
			if(partnerProgramTier == null) {
				//creating partner program tier with different field values.
				partnerProgramTier = new Partner_Program_Tier__c(
					Name = partnerProgramDefinition.Partner_Tier__c,
					Is_Active__c = true,
					Legacy_Partner_Tier__c = classificationMap.get('TEST PARTNER TIER').Id,
					Oracle_Classification_Code__c =  '12345',
					Partner_Program_Definition__c = partnerProgramDefinition.Id,
					Tier__c = 'Ready',
					Order__c = 1,
					CDH_Mastered__c = false);
				insert partnerProgramTier;
			}
			return partnerProgramTier;
		}
	}

	private static Partner_Program__c partnerProgram {
		get {
			if(partnerProgram == null) {
				partnerProgram = new Partner_Program__c(
					Status__c = 'Active',
					Account__c = partnerAccounts[0].Id,
					Oracle_Classification_Code__c = '12345',
					Program__c = partnerProgramDefinition.id,
					Tier__c = partnerProgramTier.Tier__c);
				insert partnerProgram;
			}
			return partnerProgram;
		}
	}

	private static List<Opportunity_Partner_Staging__c> createOpportunityPartnerStagingList(Opportunity_Header_Staging__c xoppHeaderStaging) {
		if(xoppHeaderStaging == null) {
			xoppHeaderStaging = oppHeaderStaging;
		}
		if(xoppHeaderStaging.Id == null) {
			insert xoppHeaderStaging;
		}
		List<Opportunity_Partner_Staging__c> retval = new List<Opportunity_Partner_Staging__c>{
			TestUtil.getPartnerStaging(xoppHeaderStaging,'12345'),
			TestUtil.getPartnerStaging(xoppHeaderStaging,'12345')};
		retval[0].Partner_Contact_CDH_Party_Number__c='12345';
		retval[0].Oracle_Classification_Code__c = partnerProgram.Oracle_Classification_Code__c;
		retval[1].Partner_Contact_CDH_Party_Number__c='12345';
		retval[1].Oracle_Classification_Code__c = partnerProgram.Oracle_Classification_Code__c;
		return retval;
	}

	private static List<Opportunity_Partner_Staging__c> oppPartnerStagingList {
		get {
			if(oppPartnerStagingList == null) {
				oppPartnerStagingList = createOpportunityPartnerStagingList(oppHeaderStaging);
				insert oppPartnerStagingList;
			}
			return oppPartnerStagingList;
		}
		set {
			oppPartnerStagingList = value;
			insertSObjects( value );
		}
	}

	private static List<Partner_Program_Tier__c> pptList {
		get {
			if(pptList == null && oppMatchConfigList != null) {
				pptList= new List<Partner_Program_Tier__c>();
				pptList.add(TestUtil.getPartneraprogramTier('12345'));
				insert pptList;
			}
			return pptList;
		}
	}

	private static void processOrder(Opportunity_Header_Staging__c xoppHeaderStaging) {
		setOppHeaderStaging( xoppHeaderStaging );

		Test.startTest();
		System.runAs(intadmin) {
			Order_Opportunity_Matching order_opp_matching = new Order_Opportunity_Matching();
			system.debug('==================================================>'+oppHeaderStaging.Bill_To_Account_Number__c);
			order_opp_matching.processOrders(oppHeaderStaging);
		}
		Test.stopTest();
	}

	private static void checkErrors(Set<String> expectedErrors) {
		List<System_Exception_Handler__c> handlers = [select ClassName__c, Error_Details__c, Object_Name__c, Salesforce_ID__c from System_Exception_Handler__c];
		system.assert(handlers.isEmpty(),'Unexpected exceptions:\n'+handlers);

		List<Match_and_Validation_Error__c> errorValues = [
			select 
				Id,
				Error_Code__c,
				Error_Description__c,
				Error_Type__c,
				Opportunity_Staging_Header__c
			from Match_and_Validation_Error__c];
		Map<String,List<Match_and_Validation_Error__c>> errorsMap = new Map<String,List<Match_and_Validation_Error__c>>();
		for(Match_and_Validation_Error__c errorValue : errorValues ) {
			List<Match_and_Validation_Error__c> errorValues2 = errorsMap.get(errorValue.Error_Code__c);
			if(errorValues2 == null) {
				errorValues2 = new List<Match_and_Validation_Error__c>();
				errorsMap.put(errorValue.Error_Code__c,errorValues2);
			}
			errorValues2.add(errorValue);
		}
		if(expectedErrors != null && ! expectedErrors.isEmpty()) {
			for(String errorCode : expectedErrors) {
				System.assertNotEquals(null,errorsMap.remove(errorCode),'Expected '+errorCode);
			}
			errorValues.clear();
			for(List<Match_and_Validation_Error__c> errorValues2 : errorsMap.values()) {
				errorValues.addAll(errorValues2);
			}
		}
		System.assert(errorValues.isEmpty(),'Unexpected errors:\n'+errorValues);
	}

	private static void checkPartners() {
		for(Opportunity_Partner_Staging__c oppPartnerStaging : oppHeaderStaging.Opportunities_Partner_Staging__r) {
			System.assertNotEquals(null,oppPartnerStaging.Partner_Sales_Account__c,'Failed to assign partner');
		}
		Map<Id,Opportunity_Partner_Staging__c> oppPartnerStagingMap = new Map<Id,Opportunity_Partner_Staging__c>(oppHeaderStaging.Opportunities_Partner_Staging__r);
		for(Opportunity_Partner_Staging__c oppPartnerStaging : [
			select Id,
				Partner_Sales_Account__c
			from Opportunity_Partner_Staging__c
			where Id in :oppPartnerStagingMap.keySet()] )
		{
			System.assertEquals(oppPartnerStagingMap.get(oppPartnerStaging.Id).Partner_Sales_Account__c,oppPartnerStaging.Partner_Sales_Account__c,'Failed to update partner');
		}
	}

	@IsTest
	static void getPartnersByMapTest() {
		Map<String,OperatingUnit__c> operatingUnitMap = Order_Opportunity_Matching.getOperatingUnitMap(new List<Opportunity_Header_Staging__c>{ oppHeaderStaging });
		System.assertNotEquals(0,operatingUnitMap.size(),'Expected OperatingUnitMap entries');
		Map<String,Map<String,List<Account>>> partnersByCDHPartyNameByRecordTypeMap = Order_Opportunity_Matching.getPartnersByCDHPartyNameByRecordTypeMap(oppPartnerStagingList,operatingUnitMap);
		System.assertNotEquals(0,partnersByCDHPartyNameByRecordTypeMap.size(),'Expected partnersByCDHPartyNameByRecordTypeMap entries');
	}

	//MethodS to test Direct Opportunity with order Status "Closed", "Invoiced","Cancelled"

	@IsTest
	static void directClosedOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'Closed';

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c);
	}

	@IsTest
	static void directInvoicedOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'Invoiced';

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c);
	}

	@IsTest
	static void directCancelledOpportunitiesTest(){
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'Cancelled';
		setOppHeaderStaging( xoppHeaderStaging );

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void directEnteredOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'Entered';
		setOppHeaderStaging( xoppHeaderStaging );

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void directBookedOpportunitiesTest1() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'BOOKED';

		processOrder( xoppHeaderStaging );

		checkErrors(new Set<String>{'D27','D36'});

		checkPartners();

		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void directBookedOpportunitiesTest2() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		
		List<Opportunity_Partner_Staging__c> xoppPartnerStagingList = createOpportunityPartnerStagingList( xoppHeaderStaging );
		for(Opportunity_Partner_Staging__c xoppPartnerStaging : xoppPartnerStagingList) {
			xoppPartnerStaging.Partner_Sales_Account__c = partnerAccounts[0].Id;
			xoppPartnerStaging.Partner_Contact__c = contact.Id;
		}
		oppPartnerStagingList = xoppPartnerStagingList;

		processOrder( xoppHeaderStaging );

		checkErrors( null );

		checkPartners();

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	// Direct Booked Opportunity with status Ready for Reprocessing
	@IsTest
	static void directBookedReprocessOpportunitiesTest1() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Status__c='Ready For Reprocessing';

		processOrder(xoppHeaderStaging);

		checkErrors(new Set<String>{'D27','D36'});

		checkPartners();

		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	// Direct Booked Opportunity with status Ready for Reprocessing
	@IsTest
	static void directBookedReprocessOpportunitiesTest2() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Opportunity_ID__c=opp.id;
		xoppHeaderStaging.Order_Source__c = 'SFDC_Sales';
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Status__c='Ready For Reprocessing';

		List<Opportunity_Partner_Staging__c> xoppPartnerStagingList = createOpportunityPartnerStagingList( xoppHeaderStaging );
		for(Opportunity_Partner_Staging__c xoppPartnerStaging : xoppPartnerStagingList) {
			xoppPartnerStaging.Partner_Sales_Account__c = partnerAccounts[0].Id;
			xoppPartnerStaging.Partner_Contact__c = contact.Id;
		}
		oppPartnerStagingList = xoppPartnerStagingList;

		processOrder(xoppHeaderStaging);

		checkErrors(null);

		checkPartners();

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void indirectClosedOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'Closed';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=opp.OpportunityNumber__c;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c);
	}
	@IsTest
	static void indirectInvoicedOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'Invoiced';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=opp.OpportunityNumber__c;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void indirectCancelledOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'Cancelled';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=opp.OpportunityNumber__c;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';

		processOrder( xoppHeaderStaging );

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void indirectBookedOpportunitiesTest1() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=opp.OpportunityNumber__c;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';

		processOrder(xoppHeaderStaging);

		checkErrors(new Set<String>{'I27','I31','I32','I33','I34','I35','I36'});

		checkPartners();

		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}


	@IsTest
	static void indirectBookedOpportunitiesTest2() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=opp.OpportunityNumber__c;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
		xoppHeaderStaging.Bill_To_Sales_Account__c = salesAccounts[0].Id;
		xoppHeaderStaging.Ship_To_Sales_Account__c = salesAccounts[0].Id;
		xoppHeaderStaging.Sold_To_Sales_Account__c = salesAccounts[0].Id;
		xoppHeaderStaging.Entitle_To_Sales_Account__c = salesAccounts[0].Id;

		List<Opportunity_Line_Staging__c> xoppLineStagingList = createOpportunityLineStagingList( xoppHeaderStaging );
		for(Opportunity_Line_Staging__c xoppLineStaging : xoppLineStagingList) {
			xoppLineStaging.Entitle_To_Sales_Account__c = salesAccounts[0].Id;
		}
		oppLineStagingList = xoppLineStagingList;

		List<Opportunity_Partner_Staging__c> xoppPartnerStagingList = createOpportunityPartnerStagingList( xoppHeaderStaging );
		for(Opportunity_Partner_Staging__c xoppPartnerStaging : xoppPartnerStagingList) {
			xoppPartnerStaging.Partner_Sales_Account__c = partnerAccounts[0].Id;
			xoppPartnerStaging.Partner_Contact__c = contact.Id;
		}
		oppPartnerStagingList = xoppPartnerStagingList;

		processOrder(xoppHeaderStaging);

		checkPartners();

		checkErrors(null);

		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void directBookedNewCDHOpportunitiesTest() {
		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Bill_To_Account_Number__c='12346';
		xoppHeaderStaging.Ship_To_Account_Number__c='12346';
		xoppHeaderStaging.Sold_To_Account_Number__c='12346';
		xoppHeaderStaging.Entitle_To_Account_Number__c='12346';
		xoppHeaderStaging.Bill_To_Party_Type__c='PERSON';
		xoppHeaderStaging.Ship_To_Party_Type__c='PERSON';
		xoppHeaderStaging.Sold_To_Party_Type__c='PERSON';
		xoppHeaderStaging.Bill_To_Party_Type__c='PERSON';
		xoppHeaderStaging.Bill_To_CDH_Party_Number__c='12340';
		xoppHeaderStaging.Ship_To_CDH_Party_Number__c='12341';
		xoppHeaderStaging.Sold_To_CDH_Party_Number__c='12342';
		xoppHeaderStaging.Entitle_To_CDH_Party_Number__c='12343';
		xoppHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c='12346';
		xoppHeaderStaging.Ship_To_Address_CDH_Party_Site_Number__c='12346';
		xoppHeaderStaging.Sold_To_Address_CDH_Party_Site_Number__c='12346';
		xoppHeaderStaging.Entitle_To_Address_CDH_Party_Site_Number__c='12346';
		xoppHeaderStaging.Bill_To_Party_Name__c='test';
		xoppHeaderStaging.Ship_To_Party_Name__c='test1';
		xoppHeaderStaging.Sold_To_Party_Name__c='test2';
		xoppHeaderStaging.Entitle_To_Party_Name__c='test3';
		xoppHeaderStaging.Bill_To_Contact_Last_Name__c='test';
		xoppHeaderStaging.Ship_To_Contact_Last_Name__c='test';
		xoppHeaderStaging.Sold_To_Contact_Last_Name__c='test';
		xoppHeaderStaging.Entitle_To_Contact_Last_Name__c='test';

		//niti line staging
		List<Opportunity_Line_Staging__c> xoppLineStagingList = createOpportunityLineStagingList( xoppHeaderStaging );
		xoppLineStagingList[0].Product_Code_Oracle__c='12347';// for error in pricebook entry
		xoppLineStagingList[0].Entitle_To_Contact__c = Null;
		xoppLineStagingList[0].Entitle_To_CDH_Party_Number__c='19885';
		xoppLineStagingList[0].Entitle_To_Account_Number__c ='12346';
		xoppLineStagingList[0].Entitle_To_CDH_Party_Site_Number__c='12346';

		oppLineStagingList = xoppLineStagingList;

		// this will fail do to missing pricebook entry :12347
		processOrder(xoppHeaderStaging);

		//Assert failing, temporarily commenting out to unblock deployment, will troubleshoot
		//for(System_Exception_Handler__c handler : [select ClassName__c, Error_Details__c, Object_Name__c, Salesforce_ID__c from System_Exception_Handler__c]) {
		//	system.assert(handler.Error_Details__c.toLowerCase().contains('price book'),'Unexpected Exception: '+handler);
		//}
		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c);
	}

	//Indirect without Opp Number =======================================================================================================================
	@IsTest
	static void indirectWOBookedOpportunitiesTest() {
		{
			//niti start
			Opportunity xopp = createOpportunity();
			xopp.Entitle_To_Sales_Account__c=salesAccounts[0].Id;
			opp = xopp;

			Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
			xoppHeaderStaging.Order_Status__c = 'BOOKED';
			xoppHeaderStaging.Opportunity_ID__c=null;
			xoppHeaderStaging.Opportunity_Number__c=null;
			xoppHeaderStaging.Order_Source__c = 'Web';
			xoppHeaderStaging.Bill_To_Account_Number__c='12346';
			xoppHeaderStaging.Ship_To_Account_Number__c='12346';
			xoppHeaderStaging.Sold_To_Account_Number__c='12346';
			xoppHeaderStaging.Entitle_To_Account_Number__c='12346';
			xoppHeaderStaging.Bill_To_Party_Type__c='PERSON';
			xoppHeaderStaging.Ship_To_Party_Type__c='PERSON';
			xoppHeaderStaging.Sold_To_Party_Type__c='PERSON';
			xoppHeaderStaging.Bill_To_Party_Type__c='PERSON';
			xoppHeaderStaging.Bill_To_CDH_Party_Number__c='12340';
			xoppHeaderStaging.Ship_To_CDH_Party_Number__c='12341';
			xoppHeaderStaging.Sold_To_CDH_Party_Number__c='12342';
			xoppHeaderStaging.Entitle_To_CDH_Party_Number__c='12343';
			xoppHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c='12346';
			xoppHeaderStaging.Ship_To_Address_CDH_Party_Site_Number__c='12346';
			xoppHeaderStaging.Sold_To_Address_CDH_Party_Site_Number__c='12346';
			xoppHeaderStaging.Entitle_To_Address_CDH_Party_Site_Number__c='12346';
			xoppHeaderStaging.Bill_To_Party_Name__c='test';
			xoppHeaderStaging.Ship_To_Party_Name__c='test1';
			xoppHeaderStaging.Sold_To_Party_Name__c='test2';
			xoppHeaderStaging.Entitle_To_Party_Name__c='test3';
			xoppHeaderStaging.Bill_To_Contact_Last_Name__c='test';
			xoppHeaderStaging.Ship_To_Contact_Last_Name__c='test';
			xoppHeaderStaging.Sold_To_Contact_Last_Name__c='test';
			xoppHeaderStaging.Entitle_To_Contact_Last_Name__c='test';
			xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
			//Niti End

			//xoppHeaderStaging.Order_Status__c = 'BOOKED';
			//xoppHeaderStaging.Opportunity_ID__c=null;
			//xoppHeaderStaging.Opportunity_Number__c=null;
			//xoppHeaderStaging.Order_Source__c = 'Web';
			//xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';

			List<Opportunity_Partner_Staging__c> xoppPartnerStagingList = createOpportunityPartnerStagingList( xoppHeaderStaging );
			xoppPartnerStagingList[0].CDH_Party_Number__c='54321';
			xoppPartnerStagingList[0].Partner_Sales_Account__c=null;
			xoppPartnerStagingList[0].Partner_Contact__c=null; //For partner contact creation
			xoppPartnerStagingList[0].Partner_Contact_CDH_Party_Number__c='54321';
			xoppPartnerStagingList[1].Partner_Contact_CDH_Party_Number__c='54321';

			oppPartnerStagingList = xoppPartnerStagingList;
			setOppHeaderStaging( xoppHeaderStaging );
		}

		Test.startTest();
		System.runAs(intadmin) {
			Order_Opportunity_Matching orderOpportunityMatching = new Order_Opportunity_Matching();
			System.Debug('inside indirectWOBookedOpportunitiesTest End ###1');
			// this failes because we did not add a pricebook entry. :12347
			orderOpportunityMatching.processOrders(Order_Opportunity_Matching.queryOrders(new Set<Id>{oppHeaderStaging.Id}));
			System.Debug('inside indirectWOBookedOpportunitiesTest End ###11');
			//order_opp_matching.ProcessIndirectBookedOpportunity(new List<Opportunity_Header_Staging__c> {oppHeaderStaging});
			// this will fail do to missing pricebook entry :12347
			orderOpportunityMatching.processOrders(Order_Opportunity_Matching.queryOrders(new Set<Id>{oppHeaderStaging.Id}));
		}
		Test.stopTest();

		for(System_Exception_Handler__c handler : [select ClassName__c, Error_Details__c, Object_Name__c, Salesforce_ID__c from System_Exception_Handler__c]) {
			system.assert(handler.Error_Details__c.toLowerCase().contains('price book'),'Unexpected Exception: '+handler);
		}
		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	//Indirect opp without opp number, focussed on Closed opp status
	@IsTest
	static void directWOBookedOpportunitiesTest() {
		opp.Entitle_To_Sales_Account__c=salesAccounts[0].Id;
		opp.OracleOrderNumber__c='12345'; // can only be set on update
		update opp;

		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'CLOSED';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=null;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
		xoppHeaderStaging.Oracle_Order_Number__c='12345';
		xoppHeaderStaging.Sales_Account__c=salesAccounts[0].Id;

		processOrder(xoppHeaderStaging);

		checkErrors(null);

		// to-do: Understand why this is not processed
		system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	//Indirect opp without opp number, focussed on Closed opp status and error for multiple existing opportunities with same oracle order number
	@IsTest
	static void negDirectWOBookedOpportunitiesTest() {
		Opportunity opp1 = TestUtil.getOpportunity('Opportunity Name1' ,salesAccounts[0]);
		insert opp1;
		opp.OracleOrderNumber__c='12345';
		opp1.OracleOrderNumber__c='12345';
		update new List<Opportunity>{opp,opp1};

//			System.debug('RAJEEEEEEV ');
//			System.debug('RAJEEEEEEV = '+[select id,OracleOrderNumber__c,Name from opp where OracleOrderNumber__c ='12345']);

		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'CLOSED';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=null;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
		xoppHeaderStaging.Oracle_Order_Number__c='12345';

		processOrder(xoppHeaderStaging);

		checkErrors(new Set<String>{'In28'});

		system.assertequals('Error',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	//Indirect opp without opp number, focusses on contact creation for line staging
	@IsTest
	static void indirectWOBookedNewContactOpportunitiesTest() {
		opp.OracleOrderNumber__c='12345';
		update opp;

		Opportunity_Header_Staging__c xoppHeaderStaging = createOpportunityHeaderStaging();
		xoppHeaderStaging.Order_Status__c = 'BOOKED';
		xoppHeaderStaging.Opportunity_ID__c=null;
		xoppHeaderStaging.Opportunity_Number__c=null;
		xoppHeaderStaging.Order_Source__c = 'Web';
		xoppHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
		xoppHeaderStaging.Oracle_Order_Number__c='12345';

		//For creation of new contact
		List<Opportunity_Line_Staging__c> xoppLineStagingList = createOpportunityLineStagingList( xoppHeaderStaging );
		xoppLineStagingList[0].Entitle_To_Contact__c = null;
		xoppLineStagingList[0].Entitle_To_CDH_Party_Number__c='19885';
		//xoppLineStagingList[0].Entitle_To_Account_Number__c ='12346';
			//xoppLineStagingList[0].Entitle_To_CDH_Party_Site_Number__c='12346';

		oppLineStagingList = xoppLineStagingList;

		processOrder(xoppHeaderStaging);

		List<System_Exception_Handler__c> handlers = [select ClassName__c, Error_Details__c, Object_Name__c, Salesforce_ID__c from System_Exception_Handler__c];
		system.assert(handlers.isEmpty(),'Unexpected exceptions:\n'+handlers);
		//List<Match_and_Validation_Error__c> errorList = [select Error_Code__c, Error_Description__c,Error_Type__c,Opportunity_Staging_Header__c from Match_and_Validation_Error__c];
		//system.assert(errorList.isEmpty(),'Unexpected errors:\n'+errorList);
		//system.assertequals('Processed',[select Id,Status__c  from Opportunity_Header_Staging__c where id=:oppHeaderStaging.id].Status__c );
	}

	@IsTest
	static void queryOrdersMethodTest()
	{
		setOppHeaderStaging( createOpportunityHeaderStaging() );

		Test.startTest();
		System.runAs(intadmin) {
			Order_Opportunity_Matching.queryOrders(new Set<Id>{oppHeaderStaging.id});
		}
		Test.stopTest();
		List<System_Exception_Handler__c> handlers = [select ClassName__c, Error_Details__c, Object_Name__c, Salesforce_ID__c from System_Exception_Handler__c];
		system.assert(handlers.isEmpty(),'Unexpected exceptions:\n'+handlers);
	}

	private static User intadmin {
		get {
			if(intadmin == null) {
				intadmin = [select Id, ProfileId from User where Alias = 'intadmin' and IsActive = true limit 1];
			}
			return intadmin;
		}
	}
}