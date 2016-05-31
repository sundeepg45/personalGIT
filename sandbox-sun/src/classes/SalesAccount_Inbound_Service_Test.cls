/**
 * This is test class for SalesAccount_Inbound_Service.
 * 
 * @version 2016-02-22
 * @author Vipul Jain
 * @since 2014-08-14 - Added one more test method to cover the record type assignment scenario 
 * 		based on Region of country.
 * 		- Momentum Ticket Number : RH-00343537
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-02-22 - support multiple ids
 * @since 2015-12-02 - update tests since we no longer throw an error for missing identify addresses
 * @since 2015-09-10 - fix test failure
 * @since 2015-06-24 - Change the default owner to someone other than intadmin and current user
 * @since 2015-05-29 - Adding testing for owner assignment, cleaning up obvious tech debt problems
 * 
 * @todo Many of the tests are negative tests.  However, they do not appear to be intended as
 * negative tests, and there is no assertions to discover if the failures are due to the expected
 * reason.  Meaning they set-up some very complicated data structures with no verification those
 * data structures are correct other than the intended problem to be tested.
 */
@isTest
public class SalesAccount_Inbound_Service_Test{

	private static Partner_Program_Definition__c def;
	private static Partner_Program_Tier__c tier;

	/**
	 * Test when CDH Party record does not exist.
	 */
	@IsTest
	static void positiveScenario1() {
		Id defaultOwnerId = defaultOwner.Id;
		IntegrationObjects.SalesAccount ioAccount = getioAccount('12489' , 'Account Testing Scenario 1' , '12345' , '12346' ,'12347');
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		ioAccount.addresses = addresses;
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs( intadmin ) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		Account a = [
			select Id,RecordTypeId,OwnerId 
			from Account 
			where RecordTypeId in :rtfMap.keySet()
			order by CreatedDate desc
			limit 1 ];
		System.assertNotEquals(null,a.RecordTypeId);
		System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
		System.assertEquals(defaultOwnerId,a.OwnerId);
	}

	/**
	 * Test when CDH Party record does not exist.
	 */
	@IsTest
	static void negativeScenario10(){
		IntegrationObjects.SalesAccount ioAccount = getioAccount( null , 'Account Testing Scenario 1' , '12345' , '12346' ,'12347');
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		ioAccount.addresses = addresses;
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when CDH Party record exist , but no sales account exist under this CDH Party .
	 */
	@IsTest
	static void scenario2(){
		Id defaultOwnerId = defaultOwner.Id;
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251020', 'Account Testing Scenario 1', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// prepare the sales account integration object and address record under it.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251020' , 'Account Testing Scenario 1' , '251021' , '251022' ,'251023');
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		ioAccount.addresses = addresses;
		List<IntegrationObjects.Classification> clsList = new List<IntegrationObjects.Classification>();
		clsList.add(fetchPartnerClassificationList('0230', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = clsList;

		// invoke the service class
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs( intadmin ) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		Account a = [
			select Id,RecordTypeId,OwnerId 
			from Account 
			where RecordTypeId in :rtfMap.keySet()
			order by CreatedDate desc
			limit 1 ];
		System.assertNotEquals(null,a.RecordTypeId);
		System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
		System.assertEquals(defaultOwnerId,a.OwnerId);
	}

	/** 
	 * Test when CDH Party record exist , and sales account record also exist under this CDH Party.
	 */
	@IsTest
	static void scenario3(){
		Id defaultOwnerId = defaultOwner.Id;
		List<IntegrationObjects.Classification> clsList = new List<IntegrationObjects.Classification>();
		// insert CDH Party record
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251020', 'Account Testing Scenario 1', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// prepare integration object for account.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251020' , 'Account Testing Scenario 1' , '251021' , '251022' ,'251023');
		clsList.add(fetchPartnerClassificationList('0230', 'Active', '2014-12-05 20:03:20', ''));

		// prepare the list of address under account.
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));

		//Set the address list.
		ioAccount.addresses = addresses;
		ioAccount.PartnerClassifications = clsList;
		// invoke the sales account service.
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs( intadmin ) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		Account a = [
			select Id,RecordTypeId,OwnerId 
			from Account 
			where RecordTypeId in :rtfMap.keySet()
			order by CreatedDate desc
			limit 1 ];
		System.assertNotEquals(null,a.RecordTypeId);
		System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
		System.assertEquals(defaultOwnerId,a.OwnerId);
	}

	/**
	 * Test when CDH Party record exist , and sales account record also exist under this CDH Party, deleted account .
	 * @param deleteFirstAccount
	 */
	private static void scenario4(Boolean deleteFirstAccount){
		Id defaultOwnerId = defaultOwner.Id;
		List<IntegrationObjects.Classification> clsList = new List<IntegrationObjects.Classification>();
		// insert CDH Party record
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251020', 'Account Testing Scenario 1', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// insert account record.
		List<Account> accounts = new List<Account>{IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Account Testing Scenario 1')};
		if(deleteFirstAccount) {
			accounts.add(accounts[0].clone());
		}
		insert accounts;
		System.assertNotEquals(accounts[0].Id, null);

		// prepare integration object for account.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251020' , 'Account Testing Scenario 1' , '251021' , '251022' ,'251023');
		for(Account a : accounts) {
			ioAccount.IDList.add(a.Id);
		}
		if(deleteFirstAccount) {
			delete accounts[0];
		}
		clsList.add(fetchPartnerClassificationList('0230', 'Active', '2014-12-05 20:03:20', ''));

		// prepare the list of address under account.
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));

		//Set the address list.
		ioAccount.addresses = addresses;
		ioAccount.PartnerClassifications = clsList;

		// invoke the sales account service.
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs(intadmin) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		Account a = [
			select Id,RecordTypeId,OwnerId 
			from Account 
			where RecordTypeId in :rtfMap.keySet()
			order by CreatedDate desc
			limit 1 ];
		System.assertNotEquals(null,a.RecordTypeId);
		System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
		System.assertEquals(defaultOwnerId,a.OwnerId);
	}

	/**
	 * Test when CDH Party record exist , and sales account record also exist under this CDH Party, deleted account .
	 */
	@IsTest
	static void scenario4A() {
		scenario4(false);
	}

	/**
	 * Test when CDH Party record exist , and sales account record also exist under this CDH Party, deleted account .
	 */
	@IsTest
	static void scenario4B() {
		scenario4(true);
	}

	/**
	 * Test when CDH Party , Account and Address record alread exists. and message contains the OSR Number of sales account and address
	 * @param useMultiple
	 */
	private static void scenario6(Boolean useMultiple){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251024', 'Testing of Account', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// insert two account records
		List<Account> accounts = new List<Account>{
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'),
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Second Account') };
		accounts[0].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		accounts[1].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('EMEA Account').getRecordTypeId();
		insert accounts;

		// insert address record under first account
		Address__c address = IntegrationObjectsTestUtil.getSFAddress(accounts[0], 'Street', 'City' , 'State');
		address.CDH_Party_Site_Number__c = '25134900';
		insert address;
		system.debug('address record created-->'+[select id , Identifying_Address__c,CDH_Party_Site_Number__c from Address__c]);

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251024' , 'Account Testing Scenario 4' , '251025' , '251026' ,'251027');
		ioAccount.IDList = new List<Id>{accounts[0].Id};
		if(useMultiple) {
			ioAccount.IDList.add(accounts[1].Id);
		}
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		IntegrationObjects.Address ioAddress = (getioAddress('25134900','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		ioAddress.Ids = address.Id;
		ioAddress.IDList = new List<Id>{address.Id};
		addresses.add(ioAddress);
		ioAccount.addresses = addresses;

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs(intadmin) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		system.debug('ioAccount is--->'+ioAccount);
		// to do: We need some sort of validation test here
	}

	/**
	 * Test when CDH Party , Account and Address record alread exists. and message contains the OSR Number of sales account and address
	 */
	@IsTest
	static void scenario6A() {
		scenario6(false);
	}

	/**
	 * Test when CDH Party , Account and Address record alread exists. and message contains the OSR Number of sales account and address
	 */
	@IsTest
	static void scenario6B(){
		scenario6(true);
	}

	/**
	 * Test record type assignment based on the region of country.
	 */
	@IsTest
	static void scenario7(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251024', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2332536';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251024' , 'Account Testing Scenario 4' , '251025' , '251026' ,'251027');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = classifications;

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		// Fails due to multiple tier definition 2332536...
		// To Do: Test this to be a positive test, not a negative test
		System.assertNotEquals(null,serviceExceptionMessage);
	}

	/**
	 * Test partner classification creation/updation and record type assignment.
	 */
	@IsTest
	static void scenario8() {
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2332536';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		//insert classification record:

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 9' , '25125' , '25126' ,'25127');
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		//IntegrationObjects.Address ioAddress = (getioAddress('25134900','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		//addresses.add(ioAddress);
		system.debug('test here test ******id'+ioAccount.IDList);
		ioAccount.addresses = addresses;

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = classifications;

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assertNotEquals(null,serviceExceptionMessage);
		// Fails due to multiple tier definition 2332536...
		// To Do: Test this to be a positive test, not a negative test
		system.debug('account detail'+ioAccount.IDList);
	}

	/**
	 * Test record type assignment based on the region of country.
	 */
	@IsTest
	static void scenario9(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251024', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251024' , 'Account Testing Scenario 4' , '251025' , '251026' ,'251027');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = classifications;

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		// We should fail here because we never assigned an address to this account
		// consiquently the record type id cannot be assigned
		System.assertNotEquals(null,serviceExceptionMessage);
	}

	/** 
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario10(){
		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251024' , 'Account Testing Scenario 10' , '251025' , '251026' ,'251027');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		fetchPartnerClassificationList('2332540', 'Active', '2014-12-05 20:03:20', '');

		IntegrationObjects.Classification objClassification = new IntegrationObjects.Classification();
		objClassification.Code = '2332541';
		objClassification.Status = 'Active';
		objClassification.StartDate = IntegrationObjectsUtils.formatDatetime(System.today());

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(objClassification );
		ioAccount.PartnerClassifications = classifications;

		System.debug('*****Scenario 10************');

// An exception is no longer thrown for this scenario...
//		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
//			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
//			}catch(Interface_ServiceException e) {
//				serviceExceptionMessage = e.getMessage();
//			}
			Test.stopTest();
		}
//		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario11(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord1 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord1.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord1;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '251024';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		Partner_Program_Tier__c tierRecord2 = new Partner_Program_Tier__c();
		tierRecord2.CDH_Mastered__c = true;
		tierRecord2.Oracle_Classification_Code__c = '251024';
		tierRecord2.Tier__c = 'Ready';
		tierRecord2.Partner_Program_Definition__c = partnerProgramDefinitionRecord1.id;
		tierRecord2.Order__c = 1;
		insert tierRecord2;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251024' , 'Account Testing Scenario 10' , '251025' , '251026' ,'251027');

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('251024', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = classifications;

		System.debug('*****Scenario 11************');

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 * @param useMuliple
	 */
	private static void scenario12(Boolean useMultiple){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord1 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord1.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord1;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord2 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord2.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord2;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord3 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord3.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord3;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord4 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord4.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord4;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord5 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord5.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord5;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2510241';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		Partner_Program_Tier__c tierRecord2 = new Partner_Program_Tier__c();
		tierRecord2.CDH_Mastered__c = true;
		tierRecord2.Oracle_Classification_Code__c = '2510242';
		tierRecord2.Tier__c = 'Ready';
		tierRecord2.Partner_Program_Definition__c = partnerProgramDefinitionRecord2.id;
		tierRecord2.Order__c = 2;
		insert tierRecord2;

		Partner_Program_Tier__c tierRecord3 = new Partner_Program_Tier__c();
		tierRecord3.CDH_Mastered__c = true;
		tierRecord3.Oracle_Classification_Code__c = '2510243';
		tierRecord3.Tier__c = 'Ready';
		tierRecord3.Partner_Program_Definition__c = partnerProgramDefinitionRecord3.id;
		tierRecord3.Order__c = 3;
		insert tierRecord3;

		Partner_Program_Tier__c tierRecord4 = new Partner_Program_Tier__c();
		tierRecord4.CDH_Mastered__c = true;
		tierRecord4.Oracle_Classification_Code__c = '2510244';
		tierRecord4.Tier__c = 'Ready';
		tierRecord4.Partner_Program_Definition__c = partnerProgramDefinitionRecord4.id;
		tierRecord4.Order__c = 4;
		insert tierRecord4;

		Partner_Program_Tier__c tierRecord5 = new Partner_Program_Tier__c();
		tierRecord5.CDH_Mastered__c = true;
		tierRecord5.Oracle_Classification_Code__c = '2510245';
		tierRecord5.Tier__c = 'Ready';
		tierRecord5.Partner_Program_Definition__c = partnerProgramDefinitionRecord4.id;
		tierRecord5.Order__c = 5;
		insert tierRecord5;

		Partner_Program_Tier__c tierRecord6 = new Partner_Program_Tier__c();
		tierRecord6.CDH_Mastered__c = true;
		tierRecord6.Oracle_Classification_Code__c = '2510246';
		tierRecord6.Tier__c = 'Ready';
		tierRecord6.Partner_Program_Definition__c = partnerProgramDefinitionRecord5.id;
		tierRecord6.Order__c = 6;
		insert tierRecord6;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// insert five account records
		List<Account> accounts = new List<Account>{
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'),
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Second Account'),
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Third Account') };
		accounts[0].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		accounts[1].recordtypeid = accounts[2].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Partner').getRecordTypeId();

		insert accounts;

		Partner_Program__c program = new Partner_Program__c();
		program.Name = 'Test 1';
		program.Account__c = accounts[1].Id;
		program.oracle_classification_code__c = '2510244';
		program.Program__c = partnerProgramDefinitionRecord4.Id;
		program.Status__c = 'Inactive';
		program.Tier__c = 'Affiliated';
		insert program;

		program = new Partner_Program__c();
		program.Name = 'Test 2';
		program.Account__c = accounts[2].Id;
		program.oracle_classification_code__c = '2510243';
		program.Program__c = partnerProgramDefinitionRecord3.Id;
		program.Status__c = 'Active';
		program.Tier__c = 'Affiliated';
		insert program;

		// prepare the sales account domain object.

		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 10' , '251025' , '251026' ,'251027');
		ioAccount.IDList = new List<Id>{accounts[0].Id};
		if(useMultiple) {
			ioAccount.IDList.add(accounts[1].Id);	
			ioAccount.IDList.add(accounts[2].Id);	
		}
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		// insert address record under first account
		Address__c address = IntegrationObjectsTestUtil.getSFAddress(accounts[0], 'Street', 'City' , 'State');
		address.CDH_Party_Site_Number__c = '25134900';
		insert address;

		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		IntegrationObjects.Address ioAddress = getioAddress('25134900','Address Line 1' ,'Meerut' , 'U.P' , 'IN');
		ioAddress.Ids = address.Id;
		ioAddress.IDList = new List<Id>{address.Id};
		addresses.add(ioAddress);
		ioAccount.addresses = addresses;

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2510241', 'Active', '2014-12-09 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2510241', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510241', 'Inactive', '2014-12-07 20:03:20', '2014-12-08 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510242', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510243', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510244', 'Active', '2014-12-05 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2510245', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510246', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510246', 'Inactive', '2014-12-07 20:03:20', '2014-12-08 20:03:20'));

		ioAccount.PartnerClassifications = classifications;


		System.debug('*****Scenario 11************');

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assertNotEquals(null,serviceExceptionMessage);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario12A(){
		scenario12(false);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario12B(){
		scenario12(true);
	}

	/**
	 * Test partner classification creation/updation and record type assignment.
	 */
	@IsTest
	static void scenario13(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2332536';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		//insert classification record:

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 9' , '25125' , '25126' ,'25127');
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		//IntegrationObjects.Address ioAddress = (getioAddress('25134900','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		//addresses.add(ioAddress);
		system.debug('test here test ******id'+ioAccount.IDList);
		ioAccount.addresses = addresses;

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		ioAccount.PartnerClassifications = classifications;

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);

		system.debug('account detail'+ioAccount.IDList);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 * @param useMultiple
	 */
	private static void scenario14(Boolean useMultiple){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord1 = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord1.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord1;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2510241';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		Partner_Program_Tier__c tierRecord2 = new Partner_Program_Tier__c();
		tierRecord2.CDH_Mastered__c = true;
		tierRecord2.Oracle_Classification_Code__c = '2510242';
		tierRecord2.Tier__c = 'Ready';
		tierRecord2.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord2.Order__c = 2;
		insert tierRecord2;

		Partner_Program_Tier__c tierRecord3 = new Partner_Program_Tier__c();
		tierRecord3.CDH_Mastered__c = true;
		tierRecord3.Oracle_Classification_Code__c = '2510243';
		tierRecord3.Tier__c = 'Ready';
		tierRecord3.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord3.Order__c = 3;
		insert tierRecord3;

		Partner_Program_Tier__c tierRecord4 = new Partner_Program_Tier__c();
		tierRecord4.CDH_Mastered__c = true;
		tierRecord4.Oracle_Classification_Code__c = '2510244';
		tierRecord4.Tier__c = 'Ready';
		tierRecord4.Partner_Program_Definition__c = partnerProgramDefinitionRecord1.id;
		tierRecord4.Order__c = 4;
		insert tierRecord4;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// insert five account records
		List<Account> accounts = new List<Account>{
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'),
			IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Second Account') };
		accounts[0].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		accounts[1].recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Partner').getRecordTypeId();
		insert accounts;

		Partner_Program__c program = new Partner_Program__c();
		program.Name = 'Test 1';
		program.Account__c = accounts[1].Id;
		program.oracle_classification_code__c = '2510244';
		program.Program__c = partnerProgramDefinitionRecord1.Id;
		program.Status__c = 'Inactive';
		program.Tier__c = 'Affiliated';
		insert program;

			// prepare the sales account domain object.

		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 10' , '251025' , '251026' ,'251027');
		ioAccount.IDList = new List<Id>{accounts[0].Id};
		if(useMultiple) {
			ioAccount.IDList.add(accounts[1].Id);
		}
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		// insert address record under first account
		Address__c address = IntegrationObjectsTestUtil.getSFAddress(accounts[0], 'Street', 'City' , 'State');
		address.CDH_Party_Site_Number__c = '25134900';
		insert address;

		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		IntegrationObjects.Address ioAddress = getioAddress('25134900','Address Line 1' ,'Meerut' , 'U.P' , 'IN');
		ioAddress.Ids = address.Id;
		ioAddress.IDList = new List<Id>{address.Id};
		addresses.add(ioAddress);
		ioAccount.addresses = addresses;

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2510241', 'Active', '2014-12-09 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2510241', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510241', 'Inactive', '2014-12-07 20:03:20', '2014-12-08 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510242', 'Inactive', '2014-11-01 20:03:20', '2014-11-02 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510242', 'Inactive', '2014-11-03 20:03:20', '2014-11-04 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510243', 'Inactive', '2014-12-09 20:03:20', '2014-12-10 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510243', 'Inactive', '2014-12-11 20:03:20', '2014-12-12 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510244', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		classifications.add(fetchPartnerClassificationList('2510244', 'Inactive', '2014-12-07 20:03:20', '2014-12-08 20:03:20'));

		ioAccount.PartnerClassifications = classifications;

		System.debug('*****Scenario 11************');

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assertNotEquals(null,serviceExceptionMessage);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario14A(){
		scenario14(false);
	}

	/**
	 * Test when there is no matching tier record corresponding to the oracle classification code in Classification IO object
	 */
	@IsTest
	static void scenario14B(){
		scenario14(true);
	}

	/**
	 * Test partner classification creation/updation and record type assignment.
	 */
	@IsTest
	static void scenario15(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2332536';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 9' , '25125' , '25126' ,'25127');

		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
		account.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		insert account;

		ioAccount.IDList = new List<Id>{account.Id};

		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		IntegrationObjects.Address ioAddress = getioAddress('','Address Line 1' ,'Meerut' , 'U.P' , 'IN');
		addresses.add(ioAddress);
		system.debug('test here test ******id'+ioAccount.IDList);
		ioAccount.addresses = addresses;

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2332536', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		ioAccount.PartnerClassifications = classifications;

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assertNotEquals(null,serviceExceptionMessage);

		system.debug('account detail'+ioAccount.IDList);
	}

	/**
	 * Test partner classification creation/update and record type assignment.
	 */
	@IsTest
	static void scenario16(){
		// insert CDH Party record.
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251524', 'Account Testing Scenario 4', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		//creating record for partner program definitoin:
		Partner_Program_Definition__c partnerProgramDefinitionRecord = new Partner_Program_Definition__c();
		partnerProgramDefinitionRecord.Partner_Tier__c = 'Ready';
		insert partnerProgramDefinitionRecord;

		//creating record for partner program definitoin tier:
		Partner_Program_Tier__c tierRecord1 = new Partner_Program_Tier__c();
		tierRecord1.CDH_Mastered__c = true;
		tierRecord1.Oracle_Classification_Code__c = '2332536';
		tierRecord1.Tier__c = 'Ready';
		tierRecord1.Partner_Program_Definition__c = partnerProgramDefinitionRecord.id;
		tierRecord1.Order__c = 1;
		insert tierRecord1;

		// Insert country record.
		List<Country__c> countryList = new List<Country__c>{ getCountry('INDIA','IN','APAC') };

		// prepare the sales account domain object.
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251524' , 'Account Testing Scenario 9' , '25125' , '25126' ,'25127');

		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
		account.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
		insert account;

		ioAccount.IDList = new List<Id>{account.Id};

		List<IntegrationObjects.Classification> classifications = new List<IntegrationObjects.Classification>();
		classifications.add(fetchPartnerClassificationList('2332536', 'Active', '2014-12-05 20:03:20', ''));
		classifications.add(fetchPartnerClassificationList('2332536', 'Inactive', '2014-12-05 20:03:20', '2014-12-06 20:03:20'));
		ioAccount.PartnerClassifications = classifications;

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);

		system.debug('account detail'+ioAccount.IDList);
	}

	/**
	 * Test existing account comming in with new classifcation
	 */
	@IsTest
	static void scenario17(){
		Id defaultOwnerId = defaultOwner.Id;
		Country__c c = getCountry('United States','US','NA');

		List<IntegrationObjects.Classification> clsList = new List<IntegrationObjects.Classification>();
		// insert CDH Party record
		String partyNumber = '251020';
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty(partyNumber, 'Account Testing Scenario 1', 'ORGANIZATION');
		insert cdhParty;

		system.debug('==============================================>'+cdhParty.CDH_Party_Number_Ext__c);
		System.assertNotEquals(cdhParty.Id, null);

		// insert account record.
		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Account Testing Scenario 1');
		insert account;
		Address__c address = IntegrationObjectsTestUtil.getSFAddress(account, '1801 Varisty Drive', 'Raleigh', 'NC');
		address.Identifying_Address__c = True;
		address.Zip_Postal_Code__c = '27606';
		insert address;

		System.assertNotEquals(account.Id, null);
		Set<Id> existingAccountIds = new Set<Id>{account.Id};

		List<Account> accts = [Select Id, Name, RecordType.Name, (Select Id, Program_Name__c, Tier__c  from Partner_Programs__r) from Account where CDH_Party_Name__r.Name = : partyNumber];
		System.assertEquals(1, accts.size());
		for (Account a : accts){
			existingAccountIds.add(a.Id);
			System.debug(a.Id + ' ' + a.RecordType.Name + ' ' + a.Partner_Programs__r.size());
		}

		// prepare integration object for account.
		IntegrationObjects.SalesAccount ioAccount = getioAccount(partyNumber , 'Account Testing Scenario 1' , '12345' , '12346' ,'12347');
		ioAccount.IDList = new List<Id>{account.Id};
		clsList.add(fetchPartnerClassificationList('Ready','Reseller','0230', 'Active', '2014-12-05 20:03:20', ''));
		clsList.add(fetchPartnerClassificationList('Ready','ISV','0130', 'Active', '2014-12-05 20:03:20', ''));
		clsList.add(fetchPartnerClassificationList('Ready','ISV','0220', 'Active', '2014-12-01 20:03:20', ''));
		clsList.add(fetchPartnerClassificationList('Ready','ISV','0240', 'Inactive', '2014-12-01 20:03:20', ''));

		ioAccount.PartnerClassifications = clsList;
		// invoke the sales account service.
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		system.debug('================================================================>'+ioAccount);
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs( intadmin ) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		accts = [Select Id, OwnerId, Name, RecordTypeId, RecordType.Name, PartnerStatuses__c, (Select Id, Program_Name__c, Tier__c  from Partner_Programs__r) from Account where CDH_Party_Name__r.Name = : partyNumber];
		System.assertEquals(4, accts.size());
		for (Account a : accts){
			System.debug(a.Id + ' ' + a.RecordType.Name + ' ' + a.PartnerStatuses__c);  
			if(! existingAccountIds.contains(a.Id)) {
				System.assertNotEquals(null,a.RecordTypeId);
				if(rtfMap.containsKey(a.RecordTypeId)) {
					System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
					System.assertEquals(defaultOwnerId,a.OwnerId);
				}
			}
		}
	}


	/**
	 * Test existing account comming in with new classifcation
	 */
	@IsTest
	static void scenario18(){
		Id defaultOwnerId = defaultOwner.Id;
		Country__c c = getCountry('United States','US','NA');

		State__c s = new State__c();
		s.Name = 'North Carolina';
		s.Country__c = c.Id;
		s.Region__c = 'NA';
		s.Abbreviation__c = 'NC';
		s.FIPSNumeric__c = 37;
		s.FIPSAlpha__c = 'NC';
		s.Subregion__c = 'Southeast';
		insert s;

		List<IntegrationObjects.Classification> clsList = new List<IntegrationObjects.Classification>();
		// insert CDH Party record
		String partyNumber = '251020';
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty(partyNumber, 'Account Testing Scenario 1', 'ORGANIZATION');
		insert cdhParty;
		System.assertNotEquals(cdhParty.Id, null);

		// insert account record.
		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Account Testing Scenario 1');
		insert account;
		Address__c address = IntegrationObjectsTestUtil.getSFAddress(account, '1801 Varisty Drive', 'Raleigh', 'NC');
		address.Identifying_Address__c = True;
		address.Zip_Postal_Code__c = '27606';
		insert address;

		System.assertNotEquals(account.Id, null);
		Set<Id> existingAccountIds = new Set<Id>{account.Id};

		List<Account> accts = [Select Id, Name, RecordType.Name, (Select Id, Program_Name__c, Tier__c  from Partner_Programs__r) from Account where CDH_Party_Name__r.Name = : partyNumber];
		System.assertEquals(1, accts.size());
		for (Account a : accts){
			System.debug(a.Id + ' ' + a.RecordType.Name + ' ' + a.Partner_Programs__r.size());
			existingAccountIds.add(a.Id);
		}

		// prepare integration object for account.
		IntegrationObjects.SalesAccount ioAccount = getioAccount(partyNumber , 'Account Testing Scenario 1' , null , null ,null);
		ioAccount.IDList = new List<Id>{account.Id};
		clsList.add(fetchPartnerClassificationList('Ready','Reseller','0230', 'Active', '2014-12-05 20:03:20', ''));
		clsList.add(fetchPartnerClassificationList('Ready','ISV','0130', 'Active', '2014-12-05 20:03:20', ''));

		ioAccount.PartnerClassifications = clsList;
		// invoke the sales account service.
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		Map<Id,RecordTypeFields__c> rtfMap = null;
		System.runAs( intadmin ) {
			rtfMap = createRecordTypeFieldsMap();
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		accts = [Select Id, OwnerId, Name, RecordTypeId, RecordType.Name, PartnerStatuses__c, Global_Region__c, Subregion__c, (Select Id, Program_Name__c, Tier__c  from Partner_Programs__r) from Account where CDH_Party_Name__r.Name = : partyNumber];
		System.assertEquals(3, accts.size());
		for (Account a : accts){
			System.debug(a.Id + ' ' + a.RecordType.Name + ' ' + a.PartnerStatuses__c + ' in ' + a.Global_Region__c + ', ' + a.Subregion__c);
			if (a.Global_Region__c != null){
				System.assertEquals('NA', a.Global_Region__c);
				System.assertEquals('Southeast', a.Subregion__c);
			}
			if(! existingAccountIds.contains(a.Id)) {
				System.assertNotEquals(null,a.RecordTypeId);
				if(rtfMap.containsKey(a.RecordTypeId)) {
					System.assertEquals(defaultOwnerId,(Id)rtfMap.get(a.RecordTypeId).DefaultOwnerId__c);
					System.assertEquals(defaultOwnerId,a.OwnerId);
				}
			}
		}
	}

	/**
	 * Test when a new contact comes in the message.
	 */
	@IsTest
	static void ContactScenario1(){
		List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251004', 'Account Testing Scenario 4', 'ORGANIZATION');
		cdhPartyList.add(cdhParty);

		CDH_Party__c cdhPartySecond = IntegrationObjectsTestUtil.getCDHParty('251050', 'Account Testing Scenario 4', 'Contact Party');
		cdhPartyList.add(cdhPartySecond);

		insert cdhPartyList;

		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
		insert account;

		Contact contact = IntegrationObjectsTestUtil.getSFContact(cdhPartySecond , 'Paul', 'Edison');
		contact.AccountId = account.Id;
		insert contact;
		IntegrationObjects.Contact ioContact = getioContact('251004' , '251050', 'First Name' , 'Last Name');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		salesAccountInboundService.Contact_Service(ioContact);

//	  String serviceExceptionMessage = null;
//	  try {
			Test.startTest();
			salesAccountInboundService.Contact_Service(ioContact);
			Test.stopTest();
//	  }catch(Interface_ServiceException e) {
//		  serviceExceptionMessage = e.getMessage();
//	  }
//	  System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when contact message comes with OSR Number.
	 */
	@IsTest
	static void ContactScenario2(){

		List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251004', 'Account Testing Scenario 4', 'ORGANIZATION');
		cdhPartyList.add(cdhParty);

		CDH_Party__c cdhPartySecond = IntegrationObjectsTestUtil.getCDHParty('251050', 'Account Testing Scenario 4', 'Contact Party');
		cdhPartyList.add(cdhPartySecond);

		insert cdhPartyList;
		system.debug('cdhPartyList is-->'+cdhPartyList);

		Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
		insert account;

		Contact contact = IntegrationObjectsTestUtil.getSFContact(cdhPartySecond , 'Paul', 'Edison');
		contact.AccountId = account.Id;
		insert contact;

		IntegrationObjects.Contact ioContact = getioContact('251004' , '251050', 'First Name' , 'Last Name');
		ioContact.Ids = contact.Id;
		ioContact.IDList = new List<Id>{contact.Id};

		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		salesAccountInboundService.Contact_Service(ioContact);
	}

	/**
	 * Test when there is no idebtifying address under sales account.
	 */
	@IsTest
	static void negativeScenario1(){
		DateTime startTime = DateTime.now();
		Map<Id,RecordTypeFields__c> rtfMap = createRecordTypeFieldsMap();

		IntegrationObjects.SalesAccount ioAccount = getioAccount('251009' , 'Account Testing Negative Scenario 1','123121' , '123126' ,'123129');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		String serviceExceptionMessage = null;
		Integer accountCount = [select count() from Account where CreatedDate >= :startTime];
		System.runAs(intadmin) {
			Test.startTest();
			salesAccountInboundService.SalesAccount_Service(ioAccount);
			Test.stopTest();
		}
		// no new accounts should have been created
		System.assertEquals(accountCount,[select count() from Account where CreatedDate >= :startTime]);
	}

	/**
	 * Test when CDH Party# is missing from the message.
	 */
	@IsTest
	static void negativeScenario2(){
		IntegrationObjects.SalesAccount ioAccount = getioAccount('251006' , 'Account Testing Negative Scenario 2','12345' , '12346' ,'12347');
		ioAccount.CDH_Party_Number = '';
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
			try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
			}catch(Interface_ServiceException e) {
				serviceExceptionMessage = e.getMessage();
			}
			Test.stopTest();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test no hierarchy relationship (Domestic/Global/Headquarters).
	 */
	@IsTest
	static void negativeScenario3(){
		Map<Id,RecordTypeFields__c> rtfMap = createRecordTypeFieldsMap();
		IntegrationObjects.SalesAccount ioAccount = getioAccount('120001' , 'Account Testing Scenario 3',null ,null,null);
		List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
		addresses.add(getioAddress('251316','Address Line 1' ,'Meerut' , 'U.P' , 'IN'));
		ioAccount.addresses = addresses;
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
//	  String serviceExceptionMessage = null;
		System.runAs(intadmin) {
			Test.startTest();
//		  try {
				salesAccountInboundService.SalesAccount_Service(ioAccount);
//		  }catch(Interface_ServiceException e) {
//			  serviceExceptionMessage = e.getMessage();
//		  }
			Test.stopTest();
		}
//	  System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
		// one sales account record under CDH party record should have been created wihout Domestic ultimate relationship.
		//system.assertequals (null, ([Select id,Domestic_Ultimate__c from Account where CDH_Party_Name__r.Name = '120001'][0]).Domestic_Ultimate__c);
	}

	/**
	 * Test when no contact exist with the CDH Party# and CDH Person Party# coming in the message.
	 */
	@IsTest
	static void ContactNegativeScenario1(){
		Map<Id,RecordTypeFields__c> rtfMap = createRecordTypeFieldsMap();
		List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251001', 'Account Testing Scenario 4', 'ORGANIZATION');
		cdhPartyList.add(cdhParty);

		CDH_Party__c cdhPartySecond = IntegrationObjectsTestUtil.getCDHParty('251002', 'Account Testing Scenario 4', 'Contact Party');
		cdhPartyList.add(cdhPartySecond);

		insert cdhPartyList;

		IntegrationObjects.Contact ioContact = getioContact('251001' , '251002', 'First Name' , 'Last Name');
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
		String serviceExceptionMessage = null;
		try {
			Test.startTest();
			salesAccountInboundService.Contact_Service(ioContact);
			Test.stopTest();
		}catch(Interface_ServiceException e) {
			serviceExceptionMessage = e.getMessage();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when single contact message does not contain CDH Person Party#.
	 */
	@IsTest
	static void ContactNegativeScenario2(){
		List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251001', 'Account Testing Scenario 4', 'ORGANIZATION');
		cdhPartyList.add(cdhParty);

		CDH_Party__c cdhPartySecond = IntegrationObjectsTestUtil.getCDHParty('251002', 'Account Testing Scenario 4', 'Contact Party');
		cdhPartyList.add(cdhPartySecond);

		IntegrationObjects.Contact ioContact = new IntegrationObjects.Contact();
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		String serviceExceptionMessage = null;
		try {
			Test.startTest();
			salesAccountInboundService.Contact_Service(ioContact);
			Test.stopTest();
		}catch(Interface_ServiceException e) {
			serviceExceptionMessage = e.getMessage();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}

	/**
	 * Test when a contact from the List of contact message does not contain CDH Person Party#
	 */
	@IsTest
	static void ContactNegativeScenario3(){
		List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();
		CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251001', 'Account Testing Scenario 4', 'ORGANIZATION');
		cdhPartyList.add(cdhParty);

		CDH_Party__c cdhPartySecond = IntegrationObjectsTestUtil.getCDHParty('251002', 'Account Testing Scenario 4', 'Contact Party');
		cdhPartyList.add(cdhPartySecond);

		IntegrationObjects.Contact ioContact = new IntegrationObjects.Contact();
		List<IntegrationObjects.Contact> ioContactList = new List<IntegrationObjects.Contact>();
		ioContactList.add(ioContact);
		SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();

		String serviceExceptionMessage = null;
		try {
			Test.startTest();
			salesAccountInboundService.Contact_Service(ioContact);
			Test.stopTest();
		}catch(Interface_ServiceException e) {
			serviceExceptionMessage = e.getMessage();
		}
		System.assert(serviceExceptionMessage.toLowerCase().startsWith('unable to persist'),'Unexpected message: '+serviceExceptionMessage);
	}


	/**
	 * Method to create Integration contact object.
	 * @param cdhPartyNumber
	 * @param CDH_Person_Party_Number
	 * @param FirstName
	 * @param LastName
	 * @return newly created ingration object contact
	 */
	public static IntegrationObjects.Contact getioContact(String cdhPartyNumber , String CDH_Person_Party_Number, String FirstName , String LastName) {
		IntegrationObjects.Contact ioContact = new IntegrationObjects.Contact();
		ioContact.SalesAccount_CDH_Party_Number  = cdhPartyNumber;
		ioContact.CDH_Party_Number = CDH_Person_Party_Number;
		ioContact.LoginName = 'Login Name';
		ioContact.FirstName = FirstName;
		ioContact.LastName = LastName;
		//ioContact.Name = FirstName+LastName;
		ioContact.Salutation = 'Mr.';
		ioContact.Status = 'Pending';
		ioContact.Email = 'test@test.com';
		ioContact.Phone = '9891066666';
		ioContact.MobilePhone = '9891066666';
		ioContact.Fax = '012066666';
		return ioContact;
	}

	/**
	 * Method to create Integration account object.
	 * @param cdhPartyNumber CDH Party Number
	 * @param accountName Sales Account Name
	 * @param HQ Head Quarters
	 * @param DU Domestic Ultimate
	 * @param GL Global Ultimate
	 * @return newly created integration object sales account
	 */
	private static IntegrationObjects.SalesAccount getioAccount(String cdhPartyNumber , String accountName , String HQ, String DU, String GL) {

		IntegrationObjects.SalesAccount ioAccount = new IntegrationObjects.SalesAccount();
		ioAccount.CDH_Party_Number = cdhPartyNumber;
		ioAccount.Name = accountName;
		ioAccount.VATNumber  = '123456';
		ioAccount.D_U_N_S = '98910';
		ioAccount.Status = 'Status';
		ioAccount.Head_Quarters = HQ;
		ioAccount.Domestic_Ultimate = DU;
		ioAccount.Global_Ultimate = GL;
		return ioAccount;
	}

	private static Map<String,Country__c> countryMap = new Map<String,Country__c>();

	private static Country__c getCountry(String name,String countryCode,String region) {
		if(countryCode == null) {
			countryCode = name.toUpperCase().substring(0,2);
		}
		if(region == null) {
			region = 'APAC';
		}
		Country__c retval = countryMap.get(countryCode);
		if(retval == null) {
			retval = new Country__c(
				Name = name,
				Iso3166Alpha2__c = countryCode,
				Global_Region__c = region);
			countryMap.put(countryCode,retval);
		}
		if(retval.Id == null) {
			upsert retval;
		}
		return retval;
	}

	// Method to create Integration address object.
	private static IntegrationObjects.Address getioAddress(String cdhPartySiteNumber , String AddressLine1 , String City, String State , String country ) {
		getCountry(country,null,null);
		IntegrationObjects.Address ioAddress = new IntegrationObjects.Address();
		ioAddress.CDH_Party_Site_Number = cdhPartySiteNumber;
		ioAddress.Address_Line1 = AddressLine1;
		ioAddress.Address_Line2 = 'Line 2';
		ioAddress.Address_Line3 = 'Line 3';
		ioAddress.Address_Line4 = 'Line 4';
		ioAddress.City = City;
		ioAddress.State = State;
		ioAddress.Province = 'Province';
		ioAddress.Zip_Postal_Code = '251001';
		ioAddress.County = 'County';
		ioAddress.Country = country;
		ioAddress.Bill_To_Address = False;
		ioAddress.Sold_To_Address = False;
		ioAddress.Ship_To_Address = False;
		ioAddress.Entitle_To_Address = False;
		ioAddress.Identifying_Address = True;
		ioAddress.Status = 'Status';

		return ioAddress;
	}


	// Method to create Integration account object.
	private static IntegrationObjects.Classification fetchPartnerClassificationList(String codeNo, String status, String startDate, String endDate) {
		return fetchPartnerClassificationList('Ready', 'Reseller', codeNo, status, startDate, endDate);
	}

	private static List<Classification__c> ctfnP {
		get {
			if(ctfnP == null) {
				ctfnP = new List<Classification__c>{
					new Classification__c(
						IsActive__c = True,
						Name = 'Partner Type'),
					new Classification__c(
						IsActive__c = True,
						Name = 'Partner Tier') };
				insert ctfnP;
			}
			return ctfnP;
		}
	}

	// Method to create Integration account object.
	private static IntegrationObjects.Classification fetchPartnerClassificationList(String pTier, String pType, String codeNo, String status, String startDate, String endDate) {
		Classification__c clfnPType = ctfnP[0];
		Classification__c clfnPTier = ctfnP[1];
		Classification__c clfnType = new Classification__c();
		clfnType.IsActive__c = True;
		clfnType.Name = pType;
		clfnType.Parent__c = clfnPType.Id;
		Classification__c clfnTier = new Classification__c();
		clfnTier.IsActive__c = True;
		clfnTier.Name = pTier;
		clfnTier.Parent__c = clfnPTier.Id;
		insert new List<Classification__c>{clfnType,clfnTier};

		def = new Partner_Program_Definition__c();
		def.Partner_Tier__c = pTier;
		def.Partner_Type__c = pType;
		def.Program_Category__c = pType;
		def.Legacy_Partner_Type__c = clfnType.id;
		def.Global_Region__c = 'APAC;EMEA;NA;LATAM';
		def.Is_Primary_Eligible__c = false;
		def.Oracle_Classification_Code__c = codeNo;
		insert def;

		tier = new Partner_Program_Tier__c();
		tier.CDH_Mastered__c = true;
		tier.Is_Active__c = true;
		tier.Legacy_Partner_Tier__c = clfnTier.id;
		tier.Partner_Program_Definition__c = def.Id;
		tier.Tier__c = pTier;
		tier.Order__c = 1;
		tier.Oracle_Classification_Code__c = codeNo;
		insert tier;

		IntegrationObjects.Classification objClassification = new IntegrationObjects.Classification();
		objClassification.Code = codeNo;
		objClassification.Status = status;
		//'2014-12-05 20:03:20'
		if(startDate != '')
			objClassification.StartDate = IntegrationObjectsUtils.formatDatetime(datetime.valueOf(startDate));
		//stringDate = '2014-12-06 20:03:20';
		if(endDate != '')
			objClassification.EndDate = IntegrationObjectsUtils.formatDatetime(datetime.valueOf(endDate));

		return objClassification;
	}

	private static User defaultOwner {
		get {
			if(defaultOwner == null) {
				defaultOwner = [select Id from User where Id != :intadmin.Id and ProfileId = :intadmin.ProfileId and Id != :UserInfo.getUserId() and IsActive = true limit 1];
			}
			return defaultOwner;
		}
	}

	private static User intadmin {
		get {
			if(intadmin == null) {
				intadmin = [select Id, ProfileId from User where Alias = 'intadmin' and IsActive = true limit 1];
			}
			return intadmin;
		}
	}

	private static Map<Id,RecordTypeFields__c> createRecordTypeFieldsMap() {
		Id defaultOwnerId = defaultOwner.Id;
		Map<Id,RecordTypeFields__c> recordTypeFieldsMap = new Map<Id,RecordTypeFields__c>{
			'012300000000QglAAE'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='APAC Account',Name='012300000000QglAAE',ObjectType__c='Account'),
			'012600000004yfVAAQ'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='EMEA Partner',Name='012600000004yfVAAQ',ObjectType__c='Account'),
			'012600000004yfaAAA'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='NA Partner',Name='012600000004yfaAAA',ObjectType__c='Account'),
			'0126000000053LWAAY'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='LATAM Partner',Name='0126000000053LWAAY',ObjectType__c='Account'),
			'0126000000053LRAAY'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='LATAM Account',Name='0126000000053LRAAY',ObjectType__c='Account'),
			'012600000004yfQAAQ'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='APAC Partner',Name='012600000004yfQAAQ',ObjectType__c='Account'),
			'012300000000NBLAA2'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='EMEA Account',Name='012300000000NBLAA2',ObjectType__c='Account'),
			'012300000000NBGAA2'=>new RecordTypeFields__c(DefaultOwnerId__c=defaultOwnerId,Label__c='NA Account',Name='012300000000NBGAA2',ObjectType__c='Account') };
		insert recordTypeFieldsMap.values();
		return recordTypeFieldsMap;
	}
}