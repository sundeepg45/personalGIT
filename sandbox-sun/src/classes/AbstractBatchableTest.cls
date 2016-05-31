/**
 * This is the test class for AbstractBatchable.
 *
 * @version 2014-04-21
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-04-21 - created
 */
@isTest
global class AbstractBatchableTest extends AbstractBatchable {
	/**
	 * Default contstructor
	 */
	global AbstractBatchableTest() {
		super('AbstractBatchableTest');
	}

	/**
	 * start method
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) { 
		return Database.getQueryLocator([select Id from User limit 100]);
	}

	/**
	 * dummy execute method
	 */
	global void execute(Database.BatchableContext bc, List<SObject> records) {}

	public static Boolean hasWorkTest(AbstractBatchable batchable) {
		Boolean retval = batchable.hasWork();
		System.assertNotEquals(null,retval);
		return retval;
	}

	@IsTest
	static void startAndExecuteTest() {
		Test.startTest();
		List<SObject> records = startAndExecuteTest(new AbstractBatchableTest(),null);
		Test.stopTest();
		System.assert(! records.isEmpty());
	}

	public static List<SObject> startAndExecuteTest(Database.Batchable<SObject> batchable,List<SObject> records) {
		Iterable<SObject> result = batchable.start(null);
		if(records != null) {
			System.assertNotEquals(null,result);
		}
		else if(result instanceof Database.QueryLocator){
			ApexPages.StandardSetController ssc = new ApexPages.StandardSetController((Database.QueryLocator)result);
			ssc.setPageSize(100);
			records = ssc.getRecords();
		}
		else {
			records = (List<SObject>)records;
		}
		if(batchable instanceof AbstractBatchable) {
			System.assertEquals(0,((AbstractBatchable)batchable).errorList.size(),((AbstractBatchable)batchable).errorList);
		}
		batchable.execute(null,records);
		if(batchable instanceof AbstractBatchable) {
			System.assertEquals(0,((AbstractBatchable)batchable).errorList.size(),((AbstractBatchable)batchable).errorList);
		}
		return records;
	}

	public static void finishTest1(Database.Batchable<SObject> batchable) {
		batchable.finish((Database.BatchableContext)null);
	}

	@isTest
	static void finishTest2() {
		Test.startTest();
		finishTest2(new AbstractBatchableTest());
		Test.stopTest();
	}

	public static void finishTest2(AbstractBatchable batchable) {
		batchable.finish((AsyncApexJob)null);
	}

	@isTest
	static void sendErrorsTest() {
		Test.startTest();
		sendErrorsTest(new AbstractBatchableTest());
		Test.stopTest();
	}

	public static void sendErrorsTest(AbstractBatchable batchable) {
		batchable.errorList.add('anything');
		System.assertNotEquals(null,batchable.sendErrors(null));
	}

	@IsTest
	static void coverageTest() {
		Test.startTest();
		coverageTest(new AbstractBatchableTest(),null);
		Test.stopTest();
	}

	/** 
	 * Quick and dirty testing that will give a class coverage.  One can then implement 
	 * implementation specific functional tests.
	 */
	public static void coverageTest(Database.Batchable<SObject> batchable,List<SObject> records) {
		if(batchable instanceof AbstractBatchable) {
			hasWorkTest((AbstractBatchable)batchable);
		}
		startAndExecuteTest(batchable,records);
		try {
			finishTest1(batchable);
		}
		catch(Exception ex) {}
		if(batchable instanceof AbstractBatchable) {
			try {
				finishTest2((AbstractBatchable)batchable);
			}
			catch(Exception ex) {}
		}
		if(batchable instanceof AbstractBatchable) {
			sendErrorsTest((AbstractBatchable)batchable);
		}
	}
}