/**
 * This is a test class for Order_Opportunity_ControllerExtension.
 *
 * @version 2015-07-06
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-07-06 - update to test autocreate 
 * 2014-10-02 - created
 */
@isTest
public class Order_Opportunity_ControllerExtnTest {
	static final List<String> accountCDHPartyNumbers = new List<String>{'-1001','-1002','-1003','-1004','-1005'};

	public static Opportunity_Header_Staging__c oppHeaderStaging {
		get {
			if(oppHeaderStaging == null) { 
				oppHeaderStaging = Order_Opportunity_BatchableTest.oppHeaderStaging;
				oppHeaderStaging.Bill_To_CDH_Party_Number_Account__c = accountCDHPartyNumbers[0];
				oppHeaderStaging.Entitle_To_CDH_Party_Number_Account__c = accountCDHPartyNumbers[1];
				oppHeaderStaging.Ship_To_CDH_Party_Number_Account__c = accountCDHPartyNumbers[2];
				oppHeaderStaging.Sold_To_CDH_Party_Number_Account__c = accountCDHPartyNumbers[3];
				oppHeaderStaging.Order_Status__c = 'BOOKED';
				oppHeaderStaging.Status__c = 'ERROR';
			}
			return oppHeaderStaging;
		}
		set;
	}

	static Id getOppHeaderStagingId() {
		return Order_Opportunity_BatchableTest.getOppHeaderStagingId();
	}

	public static List<CDH_Party__c> cdhPartyList {
		get {
			if(cdhPartyList == null) {
				cdhPartyList = new List<CDH_Party__c>();
				for(String cdhPartyNumber : accountCDHPartyNumbers) {
					cdhPartyList.add(TestUtil.getCDHParty(cdhPartyNumber,'Organization'));
				}
				insert cdhPartyList;
			}
			return cdhPartyList;
		}
		set;
	}

	public static List<Account> salesAccounts {
		get {
			if(salesAccounts == null) {
				salesAccounts = new List<Account>();
				for(CDH_Party__c cdhParty : cdhPartyList) {
					Account a = TestUtil.getAccount('Test Account '+cdhParty.Name);
					a.CDH_Party_Name__c = cdhParty.Id;
					salesAccounts.add(a);
				}
				insert salesAccounts;
			}
			return salesAccounts;
		}
		set;
	}

	public static List<Opportunity_Line_Staging__c> oppLineStagingList {
		get {
			if(oppLineStagingList == null) {
				oppLineStagingList = new List<Opportunity_Line_Staging__c>{
					new Opportunity_Line_Staging__c(
						Opportunity_Stage_Header_ID__c = getOppHeaderStagingId(), 
						Entitle_To_Account_Number__c = '-103',
						Entitle_To_Address_Line_1__c = 'eline 1',
						Entitle_To_Address_Line_2__c = 'eline 2',
						Entitle_To_Address_Line_3__c = 'eline 3',
						Entitle_To_Address_Line_4__c = 'eline 4',
						Entitle_To_CDH_Party_Number__c = '-101',
						Entitle_To_CDH_Party_Number_Account__c = accountCDHPartyNumbers[4],
						Entitle_To_CDH_Party_Site_Number__c='-102',
						Entitle_To_City__c = 'Toronto',
						Entitle_To_Contact_Email__c = 'email@nowhere.com',
						Entitle_To_Contact_First_Name__c = 'efirst',
						Entitle_To_Contact_Last_Name__c = 'elast',
						Entitle_To_Contact_Phone__c = '411',
						Entitle_To_Country__c = 'Canada',
						Entitle_To_County__c = null,
						Entitle_To_Party_Name__c = 'epname',
						Entitle_To_Party_Number__c ='-100',
						Entitle_To_Party_Type__c = 'None',
						Entitle_To_Province__c = 'Ontario',
						Entitle_To_State__c = null,
						Entitle_To_Zip_Postal_Code__c = 'L8J 3S8',
						Quantity__c=1,
						Product_Code_Oracle__c='-12345',
						UnitPrice__c=0 ) };
			}
			return oppLineStagingList;
		}
		set;
	}

	public static Map<Id,Opportunity_Line_Staging__c> oppLineStagingMap {
		get {
			if(oppLineStagingMap == null) {
				upsert oppLineStagingList;
				oppLineStagingMap = new Map<Id,Opportunity_Line_Staging__c>(oppLineStagingList);
			}
			return oppLineStagingMap;
		}
		set;
	}

	public static void assignSalesAccounts() {
		oppHeaderStaging.Bill_To_Sales_Account__c = salesAccounts[0].Id;
		oppHeaderStaging.Entitle_To_Sales_Account__c = salesAccounts[1].Id;
		oppHeaderStaging.Ship_To_Sales_Account__c = salesAccounts[2].Id;
		oppHeaderStaging.Sold_To_Sales_Account__c = salesAccounts[3].Id;
		if(oppHeaderStaging.Id == null) {
			getOppHeaderStagingId();
		}
		else {
			upsert oppHeaderStaging;
		}
		for(Integer i=0; i < oppLineStagingList.size();i++) {
			oppLineStagingList[i].Entitle_To_Sales_Account__c = salesAccounts[i+4].Id;
		}
		oppLineStagingMap = null;
		oppLineStagingMap.size();
	}

	// Since the class method we are testing is currently used for automation
	// testing, coverage test is probably sufficient.  Should we begin
	// using the class method for other purposes, we should write test methods
	// that actually assert the correct functionality.
	@isTest
	static void matchingStatusTest() {
		String currentStatus = 'Not Processed';
		oppHeaderStaging.Status__c = currentStatus;
		Id recordId = getOppHeaderStagingId();
		System.assertNotEquals(null,recordId);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		r.getParameters().put('status__c',Order_Opportunity_Batchable.READY_STATUS);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Test.startTest();
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		controller.matching();
		Test.stopTest();
		Opportunity_Header_Staging__c record = [
			select Status__c
			from Opportunity_Header_Staging__c
			where Id = :recordId ];
		System.assertNotEquals(currentStatus,record.Status__c);
	}

	@isTest
	static void matchingExceptionCoverageTest() {
		oppHeaderStaging.Status__c = 'ERROR';
		// lets generate an exception by processing with a new record
		// that has not been inserted
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('status__c',Order_Opportunity_Batchable.READY_STATUS);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Test.startTest();
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		controller.matching();
		Test.stopTest();
	}

	@isTest
	static void autocreateTest() {
		assignSalesAccounts();
		Id recordId = getOppHeaderStagingId();
		System.assertNotEquals(null,recordId);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		System.assert(controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should be allowed');
		System.assert(controller.isBillToAddressCreateAllowed(),'Bill To Address create should be allowed');
		System.assert(controller.isBillToContactCreateAllowed(),'Bill To Contact create should be allowed');
		System.assert(controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should be allowed');
		System.assert(controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should be allowed');
		System.assert(controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should be allowed');
		System.assert(controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should be allowed');
		System.assert(controller.isShipToAddressCreateAllowed(),'Ship To Address create should be allowed');
		System.assert(controller.isShipToContactCreateAllowed(),'Ship To Contact create should be allowed');
		System.assert(controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should be allowed');
		System.assert(controller.isSoldToAddressCreateAllowed(),'Sold To Address create should be allowed');
		System.assert(controller.isSoldToContactCreateAllowed(),'Sold To Contact create should be allowed');
		Opportunity_Header_Staging__c ohs = controller.getQueriedRecord();
		System.assertEquals(salesAccounts[0].Id,ohs.Bill_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[0].Name,ohs.Bill_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[0].Name,ohs.Bill_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[1].Id,ohs.Entitle_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[1].Name,ohs.Entitle_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[1].Name,ohs.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[2].Id,ohs.Ship_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[2].Name,ohs.Ship_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[2].Name,ohs.Ship_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[3].Id,ohs.Sold_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[3].Name,ohs.Sold_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[3].Name,ohs.Sold_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(oppLineStagingList.size(),ohs.Opportunities_Line_Staging__r.size());
		Integer lineCount = oppLineStagingList.size();
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Integer i=0;i < lineCount;i++) {
			Opportunity_Line_Staging__c ols = ohs.Opportunities_Line_Staging__r[i];
			System.assertEquals(salesAccounts[i+4].Id,ols.Entitle_To_Sales_Account__c);
			System.assertEquals(cdhPartyList[i+4].Name,ols.Entitle_To_CDH_Party_Number_Account__c);
			System.assertEquals(cdhPartyList[i+4].Name,ols.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should be allowed');
		}
		System.assert(controller.isAutoCreateAllowed,'Auto-create should be allowed');
		Test.startTest();
		controller.autocreate();
		Test.stopTest();
		ohs = controller.getQueriedRecord();
		System.assertNotEquals(null,ohs.Bill_To_Account__c);
		System.assertNotEquals(null,ohs.Bill_To_Address__c);
		System.assertNotEquals(null,ohs.Bill_To_Contact__c);
		System.assertNotEquals(null,ohs.Entitle_To_Account__c);
		System.assertNotEquals(null,ohs.Entitle_To_Address__c);
		System.assertNotEquals(null,ohs.Entitle_To_Contact__c);
		System.assertNotEquals(null,ohs.Ship_To_Account__c);
		System.assertNotEquals(null,ohs.Ship_To_Address__c);
		System.assertNotEquals(null,ohs.Ship_To_Contact__c);
		System.assertNotEquals(null,ohs.Sold_To_Account__c);
		System.assertNotEquals(null,ohs.Sold_To_Address__c);
		System.assertNotEquals(null,ohs.Sold_To_Contact__c);
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assertNotEquals(null,ols.Entitle_To_Account__c);
			System.assertNotEquals(null,ols.Entitle_To_Address__c);
			System.assertNotEquals(null,ols.Entitle_To_Contact__c);
		}
		System.assert(! controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should not be allowed');
		System.assert(! controller.isBillToAddressCreateAllowed(),'Bill To Address create should not be allowed');
		System.assert(! controller.isBillToContactCreateAllowed(),'Bill To Contact create should not be allowed');
		System.assert(! controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should not be allowed');
		System.assert(! controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should not be allowed');
		System.assert(! controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should not be allowed');
		System.assert(! controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should not be allowed');
		System.assert(! controller.isShipToAddressCreateAllowed(),'Ship To Address create should not be allowed');
		System.assert(! controller.isShipToContactCreateAllowed(),'Ship To Contact create should not be allowed');
		System.assert(! controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should not be allowed');
		System.assert(! controller.isSoldToAddressCreateAllowed(),'Sold To Address create should not be allowed');
		System.assert(! controller.isSoldToContactCreateAllowed(),'Sold To Contact create should not be allowed');
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should not be allowed');
		}
		System.assert(! controller.isAutoCreateAllowed,'Auto-create should not be allowed');
		ohs = controller.getQueriedRecord();
		System.assert(! controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should not be allowed');
		System.assert(! controller.isBillToAddressCreateAllowed(),'Bill To Address create should not be allowed');
		System.assert(! controller.isBillToContactCreateAllowed(),'Bill To Contact create should not be allowed');
		System.assert(! controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should not be allowed');
		System.assert(! controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should not be allowed');
		System.assert(! controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should not be allowed');
		System.assert(! controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should not be allowed');
		System.assert(! controller.isShipToAddressCreateAllowed(),'Ship To Address create should not be allowed');
		System.assert(! controller.isShipToContactCreateAllowed(),'Ship To Contact create should not be allowed');
		System.assert(! controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should not be allowed');
		System.assert(! controller.isSoldToAddressCreateAllowed(),'Sold To Address create should not be allowed');
		System.assert(! controller.isSoldToContactCreateAllowed(),'Sold To Contact create should not be allowed');
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should not be allowed');
		}
		System.assert(! controller.isAutoCreateAllowed,'Auto-create should not be allowed');
	}

	@isTest
	static void autocreateNoSalesAccountsTest() {
		Id recordId = getOppHeaderStagingId();
		oppLineStagingMap.size();
		System.assertNotEquals(null,recordId);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		System.assert(! controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should not be allowed');
		System.assert(! controller.isBillToAddressCreateAllowed(),'Bill To Address create should not be allowed');
		System.assert(! controller.isBillToContactCreateAllowed(),'Bill To Contact create should not be allowed');
		System.assert(! controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should not be allowed');
		System.assert(! controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should not be allowed');
		System.assert(! controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should not be allowed');
		System.assert(! controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should not be allowed');
		System.assert(! controller.isShipToAddressCreateAllowed(),'Ship To Address create should not be allowed');
		System.assert(! controller.isShipToContactCreateAllowed(),'Ship To Contact create should not be allowed');
		System.assert(! controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should not be allowed');
		System.assert(! controller.isSoldToAddressCreateAllowed(),'Sold To Address create should not be allowed');
		System.assert(! controller.isSoldToContactCreateAllowed(),'Sold To Contact create should not be allowed');
		Opportunity_Header_Staging__c ohs = controller.getQueriedRecord();
		Integer lineCount = oppLineStagingList.size();
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should not be allowed');
		}
		System.assert(! controller.isAutoCreateAllowed,'Auto-create should not be allowed');
		Test.startTest();
		controller.autocreate();
		Test.stopTest();
		ohs = controller.getQueriedRecord();
		System.assert(! controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should not be allowed');
		System.assert(! controller.isBillToAddressCreateAllowed(),'Bill To Address create should not be allowed');
		System.assert(! controller.isBillToContactCreateAllowed(),'Bill To Contact create should not be allowed');
		System.assert(! controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should not be allowed');
		System.assert(! controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should not be allowed');
		System.assert(! controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should not be allowed');
		System.assert(! controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should not be allowed');
		System.assert(! controller.isShipToAddressCreateAllowed(),'Ship To Address create should not be allowed');
		System.assert(! controller.isShipToContactCreateAllowed(),'Ship To Contact create should not be allowed');
		System.assert(! controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should not be allowed');
		System.assert(! controller.isSoldToAddressCreateAllowed(),'Sold To Address create should not be allowed');
		System.assert(! controller.isSoldToContactCreateAllowed(),'Sold To Contact create should not be allowed');
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should not be allowed');
			System.assert(! Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should not be allowed');
		}
		System.assert(! controller.isAutoCreateAllowed,'Auto-create should not be allowed');
	}

	@isTest
	static void autocreateDeletedSalesAccountsTest() {
		assignSalesAccounts();
		Id recordId = getOppHeaderStagingId();
		System.assertNotEquals(null,recordId);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		Opportunity_Header_Staging__c ohs = controller.getQueriedRecord();
		delete salesAccounts;
		System.assert(controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should be allowed');
		System.assert(controller.isBillToAddressCreateAllowed(),'Bill To Address create should be allowed');
		System.assert(controller.isBillToContactCreateAllowed(),'Bill To Contact create should be allowed');
		System.assert(controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should be allowed');
		System.assert(controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should be allowed');
		System.assert(controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should be allowed');
		System.assert(controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should be allowed');
		System.assert(controller.isShipToAddressCreateAllowed(),'Ship To Address create should be allowed');
		System.assert(controller.isShipToContactCreateAllowed(),'Ship To Contact create should be allowed');
		System.assert(controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should be allowed');
		System.assert(controller.isSoldToAddressCreateAllowed(),'Sold To Address create should be allowed');
		System.assert(controller.isSoldToContactCreateAllowed(),'Sold To Contact create should be allowed');
		System.assertEquals(salesAccounts[0].Id,ohs.Bill_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[0].Name,ohs.Bill_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[0].Name,ohs.Bill_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[1].Id,ohs.Entitle_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[1].Name,ohs.Entitle_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[1].Name,ohs.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[2].Id,ohs.Ship_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[2].Name,ohs.Ship_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[2].Name,ohs.Ship_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[3].Id,ohs.Sold_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[3].Name,ohs.Sold_To_CDH_Party_Number_Account__c);
		System.assertEquals(cdhPartyList[3].Name,ohs.Sold_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(oppLineStagingList.size(),ohs.Opportunities_Line_Staging__r.size());
		for(Integer i=0;i < ohs.Opportunities_Line_Staging__r.size();i++) {
			Opportunity_Line_Staging__c ols = ohs.Opportunities_Line_Staging__r[i];
			System.assertEquals(salesAccounts[i+4].Id,ols.Entitle_To_Sales_Account__c);
			System.assertEquals(cdhPartyList[i+4].Name,ols.Entitle_To_CDH_Party_Number_Account__c);
			System.assertEquals(cdhPartyList[i+4].Name,ols.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should be allowed');
		}
		System.assert(controller.isAutoCreateAllowed,'Auto-create should be allowed');
		Test.startTest();
		controller.autocreate();
		Test.stopTest();
		ohs = controller.getQueriedRecord();
		System.assertEquals(null,ohs.Bill_To_Account__c);
		System.assertEquals(null,ohs.Bill_To_Address__c);
		System.assertEquals(null,ohs.Bill_To_Contact__c);
		System.assertEquals(null,ohs.Entitle_To_Account__c);
		System.assertEquals(null,ohs.Entitle_To_Address__c);
		System.assertEquals(null,ohs.Entitle_To_Contact__c);
		System.assertEquals(null,ohs.Ship_To_Account__c);
		System.assertEquals(null,ohs.Ship_To_Address__c);
		System.assertEquals(null,ohs.Ship_To_Contact__c);
		System.assertEquals(null,ohs.Sold_To_Account__c);
		System.assertEquals(null,ohs.Sold_To_Address__c);
		System.assertEquals(null,ohs.Sold_To_Contact__c);
		System.assertEquals(oppLineStagingList.size(),ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assertEquals(null,ols.Entitle_To_Account__c);
			System.assertEquals(null,ols.Entitle_To_Address__c);
			System.assertEquals(null,ols.Entitle_To_Contact__c);
		}
	}

	@isTest
	static void autocreateWrongSalesAccountsTest() {
		Account a = salesAccounts.remove(0);
		salesAccounts.add(a);
		assignSalesAccounts();
		Id recordId = getOppHeaderStagingId();
		System.assertNotEquals(null,recordId);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(Order_Opportunity_BatchableTest.oppHeaderStaging);
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		System.assert(controller.isBillToEBSAccountCreateAllowed(),'Bill To EBS Account create should be allowed');
		System.assert(controller.isBillToAddressCreateAllowed(),'Bill To Address create should be allowed');
		System.assert(controller.isBillToContactCreateAllowed(),'Bill To Contact create should be allowed');
		System.assert(controller.isEntitleToEBSAccountCreateAllowed(),'Entitle To EBS Account create should be allowed');
		System.assert(controller.isEntitleToAddressCreateAllowed(),'Entitle To Address create should be allowed');
		System.assert(controller.isEntitleToContactCreateAllowed(),'Entitle To Contact create should be allowed');
		System.assert(controller.isShipToEBSAccountCreateAllowed(),'Ship To EBS Account create should be allowed');
		System.assert(controller.isShipToAddressCreateAllowed(),'Ship To Address create should be allowed');
		System.assert(controller.isShipToContactCreateAllowed(),'Ship To Contact create should be allowed');
		System.assert(controller.isSoldToEBSAccountCreateAllowed(),'Sold To EBS Account create should be allowed');
		System.assert(controller.isSoldToAddressCreateAllowed(),'Sold To Address create should be allowed');
		System.assert(controller.isSoldToContactCreateAllowed(),'Sold To Contact create should be allowed');
		Opportunity_Header_Staging__c ohs = controller.getQueriedRecord();
		System.assertEquals(salesAccounts[0].Id,ohs.Bill_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[0].Name,ohs.Bill_To_CDH_Party_Number_Account__c);
		System.assertNotEquals(cdhPartyList[0].Name,ohs.Bill_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[1].Id,ohs.Entitle_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[1].Name,ohs.Entitle_To_CDH_Party_Number_Account__c);
		System.assertNotEquals(cdhPartyList[1].Name,ohs.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[2].Id,ohs.Ship_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[2].Name,ohs.Ship_To_CDH_Party_Number_Account__c);
		System.assertNotEquals(cdhPartyList[2].Name,ohs.Ship_To_Sales_Account__r.CDH_Party_Name__r.Name);
		System.assertEquals(salesAccounts[3].Id,ohs.Sold_To_Sales_Account__c);
		System.assertEquals(cdhPartyList[3].Name,ohs.Sold_To_CDH_Party_Number_Account__c);
		System.assertNotEquals(cdhPartyList[3].Name,ohs.Sold_To_Sales_Account__r.CDH_Party_Name__r.Name);
		Integer lineCount = oppLineStagingList.size();
		System.assertEquals(lineCount,ohs.Opportunities_Line_Staging__r.size());
		for(Integer i=0;i < lineCount;i++) {
			Opportunity_Line_Staging__c ols = ohs.Opportunities_Line_Staging__r[i];
			System.assertEquals(salesAccounts[i+4].Id,ols.Entitle_To_Sales_Account__c);
			System.assertEquals(cdhPartyList[i+4].Name,ols.Entitle_To_CDH_Party_Number_Account__c);
			System.assertNotEquals(cdhPartyList[i+4].Name,ols.Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name);
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToEBSAccountCreateAllowed(ols),'Entitle To EBS Account create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToAddressCreateAllowed(ols),'Entitle To Address create should be allowed');
			System.assert(Order_Opportunity_ControllerExtension.isEntitleToContactCreateAllowed(ols),'Entitle To Contact create should be allowed');
		}
		System.assert(controller.isAutoCreateAllowed,'Auto-create should be allowed');
		Test.startTest();
		controller.autocreate();
		Test.stopTest();
		ohs = controller.getQueriedRecord();
		System.assertEquals(null,ohs.Bill_To_Account__c);
// do not test the results for addresses and contacts, because a required filter may be added to cause these to fail
//		System.assertNotEquals(null,ohs.Bill_To_Address__c);
//		System.assertNotEquals(null,ohs.Bill_To_Contact__c);
		System.assertEquals(null,ohs.Entitle_To_Account__c);
//		System.assertNotEquals(null,ohs.Entitle_To_Address__c);
//		System.assertNotEquals(null,ohs.Entitle_To_Contact__c);
		System.assertEquals(null,ohs.Ship_To_Account__c);
//		System.assertNotEquals(null,ohs.Ship_To_Address__c);
//		System.assertNotEquals(null,ohs.Ship_To_Contact__c);
		System.assertEquals(null,ohs.Sold_To_Account__c);
//		System.assertNotEquals(null,ohs.Sold_To_Address__c);
//		System.assertNotEquals(null,ohs.Sold_To_Contact__c);
		System.assertEquals(oppLineStagingList.size(),ohs.Opportunities_Line_Staging__r.size());
		for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
			System.assertEquals(null,ols.Entitle_To_Account__c);
//			System.assertNotEquals(null,ols.Entitle_To_Address__c);
//			System.assertNotEquals(null,ols.Entitle_To_Contact__c);
		}
	}
}