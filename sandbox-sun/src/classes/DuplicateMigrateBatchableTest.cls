/**
 * This is a test class for DuplicateMigrateBatchable.
 * 
 * @version 2015-09-04
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-09-04 - Created
 */
@isTest
public class DuplicateMigrateBatchableTest {
	static DuplicateMigrateBatchable batchable {
		get {
			if(batchable == null) {
				batchable = new DuplicateMigrateBatchable();
			}
			return batchable;
		}
		set;
	}

	static Boolean hasWork() {
		return batchable.hasWork();
	}

	static List<DuplicateLog__c> start() {
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(200);
		return ssc.getRecords();
	}

	static Integer startSize() {
//		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
//		return ssc.getResultSize();
		return start().size();
	}

	static Integer getWorkSize() {
		return [select count() from DuplicateLog__c where Status__c != 'Completed' and ObjectType__c in ('EBS Account','Address')];
	}

	@IsTest
	static void hasWorkAndStartTest1() {
		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		Test.startTest();
		System.assert(! hasWork(),'No work expected');
		Test.stopTest();
		System.assertEquals(0,startSize());
	}

	@IsTest
	static void hasWorkAndStartTest2() {
		// create the opportunities, and line items
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.opportunityLineItemMap.size());
		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		Test.startTest();
		System.assert(hasWork(),'Work expected');
		System.assertEquals(getWorkSize(),startSize());
		delete DuplicateLogTriggerBeforeTest.addresses;
		update DuplicateLogTriggerBeforeTest.duplicateLogs;
		System.assert(hasWork(),'Work expected');
		System.assertEquals(getWorkSize(),startSize());
		delete DuplicateLogTriggerBeforeTest.ebsAccounts;
		update DuplicateLogTriggerBeforeTest.duplicateLogs;
		System.assert(! hasWork(),'No work expected');
		Test.stopTest();
		System.assertEquals(0,startSize());
	}

	@IsTest
	static void hasWorkAndStartTest3() {
		DuplicateLogTriggerBeforeTest.contacts = new List<Contact>();
		DuplicateLogTriggerBeforeTest.addresses = new List<Address__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.opportunityLineItemMap.size());
		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		Test.startTest();
		System.assert(hasWork(),'Work expected');
		Test.stopTest();
		System.assertEquals(getWorkSize(),startSize());
	}

	@IsTest
	static void hasWorkAndStartTest4() {
		DuplicateLogTriggerBeforeTest.contacts = new List<Contact>();
		DuplicateLogTriggerBeforeTest.ebsAccounts = new List<EBS_Account__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.opportunityLineItemMap.size());
		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		Test.startTest();
		System.assert(hasWork(),'Work expected');
		Test.stopTest();
		System.assertEquals(getWorkSize(),startSize());
	}

	@IsTest
	static void hasWorkAndStartTest5() {
		DuplicateLogTriggerBeforeTest.addresses = new List<Address__c>();
		DuplicateLogTriggerBeforeTest.ebsAccounts = new List<EBS_Account__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.opportunityLineItemMap.size());
		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		Test.startTest();
		System.assert(! hasWork(),'No work expected');
		Test.stopTest();
		System.assertEquals(0,startSize());
	}

	@IsTest
	static void executeTest() {
		// create the opportunities, and line items
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.opportunityLineItemMap.size());
		// create order management profiles
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.omProfileMap.size());
		// create opportunity lines and header staging records
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.oppLineStagingMap.size());
		// create subscriptions and subscription lines
		System.assertNotEquals(0,DuplicateLogTriggerBeforeTest.subscriptionLineMap.size());

		insert DuplicateLogTriggerBeforeTest.duplicateLogs;
		System.assert(hasWork(),'Work expected');
		List<DuplicateLog__c> records = start();
		System.assertEquals(getWorkSize(),records.size());
		Test.startTest();
		batchable.execute(null,start());
		Test.stopTest();
		System.assert(! hasWork(),'No work expected');
	}
}