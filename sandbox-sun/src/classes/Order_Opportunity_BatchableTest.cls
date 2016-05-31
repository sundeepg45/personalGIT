/**
 * This is a test class for Opportunity_Batchable.
 *
 * @version 2015-07-07
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-07-07 - Updated to run tests as intadmin
 */
@isTest
public class Order_Opportunity_BatchableTest {

	public static Opportunity_Header_Staging__c oppHeaderStaging {
		get {
			if(oppHeaderStaging == null) {
				oppHeaderStaging = new Opportunity_Header_Staging__c(
					Bill_To_Account_Number__c = '-1',
					Bill_To_Address_CDH_Party_Site_Number__c = '-2',
					Bill_To_Address_Line_1__c = 'bline 1',
					Bill_To_Address_Line_2__c = 'bline 2',
					Bill_To_Address_Line_3__c = 'bline 3',
					Bill_To_Address_Line_4__c = 'bline 4',
					Bill_To_CDH_Party_Number__c = '-3',
					Bill_To_City__c = 'bcity',
					Bill_To_Contact_Email__c = 'bemail@nowhere.com',
					Bill_To_Contact_First_Name__c = 'bfirst',
					Bill_To_Contact_Last_Name__c = 'blast',
					Bill_To_Contact_Phone__c = '911',
					Bill_To_Country__c = 'US',
					Bill_To_County__c = 'Kalamazoo',
					Bill_To_Party_Name__c = 'bparty',
					Bill_To_Party_Number__c = '-4',
					Bill_To_Party_Type__c = 'None',
					Bill_To_State__c = 'MI',
					Bill_To_Zip_Postal_Code__c = '49001',
					Channel__c = 'None',
					CurrencyIsoCode = 'USD',
					Date_Ordered__c = Date.today(),
					Employee_Number__c = '-103',
					Entitle_To_Account_Number__c = '-6',
					Entitle_To_Address_CDH_Party_Site_Number__c = '-7',
					Entitle_To_Address_Line_1__c = 'eline 1',
					Entitle_To_Address_Line_2__c = 'eline 2',
					Entitle_To_Address_Line_3__c = 'eline 3',
					Entitle_To_Address_Line_4__c = 'eline 4',
					Entitle_To_CDH_Party_Number__c = '-8',
					Entitle_To_City__c = 'Toronto',
					Entitle_To_Contact_Email__c = 'email@nowhere.com',
					Entitle_To_Contact_First_Name__c = 'efirst',
					Entitle_To_Contact_Last_Name__c = 'elast',
					Entitle_To_Contact_Phone__c = '411',
					Entitle_To_Country__c = 'Canada',
					Entitle_To_County__c = null,
					Entitle_To_Party_Name__c = 'epname',
					Entitle_To_Party_Number__c = '-9',
					Entitle_To_Party_Type__c = 'None',
					Entitle_To_Province__c = 'Ontario',
					Entitle_To_State__c = null,
					Entitle_To_Zip_Postal_Code__c = 'L8J 3S8',
					Operating_Unit__c = 'op unit',
//					Opportunity_Name__c = 'unknown',
					Opportunity_Number__c = '-10',
					Opportunity_Owner__c = UserInfo.getUserId(),
					Oracle_Order_ID__c = '-11',
					Oracle_Order_Number__c = '-12',
					Order_Last_Update_Date__c = Date.today(),
					Order_Source__c = 'Channel Load',
					Order_Status__c = 'Pending',
					Order_Type__c = 'Direct - Web',
					OwnerId = UserInfo.getUserId(),
					Payment_Type__c = 'Paynow',
					PO_Number__c = '-13',
					Resller_PO__c = '-14',
					Ship_To_Account_Number__c = '-15',
					Ship_To_Address_CDH_Party_Site_Number__c = '-16',
					Ship_To_Address_Line_1__c = 'sline 1',
					Ship_To_Address_Line_2__c = 'sline 2',
					Ship_To_Address_Line_3__c = 'sline 3',
					Ship_To_Address_Line_4__c = 'sline 4',
					Ship_To_CDH_Party_Number__c = '-17',
					Ship_To_City__c = 'London',
					Ship_To_Contact_Email__c = 'cmail@nowhere.com',
					Ship_To_Contact_First_Name__c = 'cfirst',
					Ship_To_Contact_Last_Name__c = 'clast',
					Ship_To_Contact_Phone__c = '999',
					Ship_To_Country__c = 'UK',
					Ship_To_County__c = 'Any',
					Ship_To_Party_Name__c = 'pname',
					Ship_To_Party_Number__c = '-18',
					Ship_To_Party_Type__c = 'None',
					Ship_To_Province__c = 'None',
					Ship_To_State__c = 'None',
					Ship_To_Zip_Postal_Code__c = '4321',
					Sold_To_Account_Number__c = '-19',
					Sold_To_Address_CDH_Party_Site_Number__c = '-20',
					Sold_To_Address_Line_1__c = 'soline1',
					Sold_To_Address_Line_2__c = 'soline2',
					Sold_To_Address_Line_3__c = 'soline3',
					Sold_To_Address_Line_4__c = 'soline4',
					Sold_To_CDH_Party_Number__c = '-21',
					Sold_To_City__c = 'Tokeyo',
					Sold_To_Contact_Email__c = 'somail@nowhere.com',
					Sold_To_Contact_First_Name__c = 'sofirst',
					Sold_To_Contact_Last_Name__c = 'solast',
					Sold_To_Contact_Phone__c = '666',
					Sold_To_Country__c = 'JAPAN',
					Sold_To_County__c = 'None',
					Sold_To_Party_Name__c = 'soparty',
					Sold_To_Party_Number__c = '-22',
					Sold_To_Party_Type__c = 'None',
					Sold_To_Province__c = 'None',
					Sold_To_State__c = null,
					Sold_To_Zip_Postal_Code__c = '12345',
					Status__c = Order_Opportunity_Batchable.READY_STATUS );
			}
			return oppHeaderStaging;
		}
	}

	public static Id getOppHeaderStagingId() {
		if(oppHeaderStaging.Id == null) {
			insert oppHeaderStaging;
		}
		return oppHeaderStaging.Id;
	}

	@isTest
	static void executeTest1() {
		System.runAs(intadmin) {
			Id oppHeaderStagingId = getOppHeaderStagingId();
			Order_Opportunity_Batchable batchable = new Order_Opportunity_Batchable();
			ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
			ssc.setPageSize(100);
			List<Opportunity_Header_Staging__c> orders = ssc.getRecords();
			System.assertEquals(1,orders.size());
			System.assertEquals(oppHeaderStagingId,orders[0].Id);
			Test.startTest();
			batchable.execute(null,orders);
			batchable.errorList.add('Anything');
			batchable.execute(null,orders);
			Test.stopTest();
		}
	}

	@isTest
	static void processOrdersConverageTest() {
		System.runAs(intadmin) {
			Id oppHeaderStagingId = getOppHeaderStagingId();
			Test.startTest();
			Order_Opportunity_Batchable.processOrders(new List<Opportunity_Header_Staging__c>{ oppHeaderStaging } );
			Test.stopTest();
		}
	}

	@isTest
	static void processOrdersExceptionConverageTest() {
		System.runAs(intadmin) {
			Test.startTest();
			Order_Opportunity_Batchable.processOrders(new List<Opportunity_Header_Staging__c>{ null } );
			Test.stopTest();
		}
	}

	@isTest
	static void finishTest() {
		System.runAs(intadmin) {
			Order_Opportunity_Batchable batchable = new Order_Opportunity_Batchable();
			Test.startTest();
			try {
				batchable.finish((Database.BatchableContext)null);
			}
			catch(Exception e) {}
			batchable.finish((AsyncApexJob)null);
			Test.stopTest();
		}
	}

	@isTest
	static void sendErrorsTest() {
		Order_Opportunity_Batchable batchable = new Order_Opportunity_Batchable();
		batchable.errorList.add('anything');
		System.runAs(intadmin) {
			Test.startTest();
			System.assertNotEquals(null,batchable.sendErrors(null));
			Test.stopTest();
		}
	}

	@IsTest
	static void coverageTest() {
		System.runAs(intadmin) {
			Test.startTest();
			AbstractBatchableTest.coverageTest(new Order_Opportunity_Batchable(),new List<Opportunity_Header_Staging__c>());
			AbstractBatchableTest.coverageTest(new Order_Opportunity_Batchable(),new List<Opportunity_Header_Staging__c>());
			Test.stopTest();
		}
	}

	static User intadmin {
		get {
			if(intadmin == null) {
				intadmin = [select Id, ProfileId from User where Alias = 'intadmin' and IsActive = true limit 1];
			}
			return intadmin;
		}
	}
}