/**
 * This class contains unit tests for validating the DailyScheduler class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2016-01-19
 * @author Bill C Riemers <briemers@redhat.com>
 * 2016-01-19 - Added Test_Batchable to avoid dependancies on real batch classes
 * 2013-07-30 - Auto-increase concurrent limit to allow this test to succeed
 * 2011-09-30 - Created
 */
@isTest
global class DailySchedulerTest  implements Database.Batchable<SObject> {
	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @return	List<SObject> list of credit objects to expire
	 */
	global List<User> start(Database.BatchableContext bc) 
	{
		return new List<User>();
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @param	List<SObject> credit objects
	 */
	global void execute(Database.BatchableContext bc, List<SObject> objects) {}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 */
	global void finish(Database.BatchableContext bc) {}

	@isTest
	static void isJobActiveTest() {
		DailyScheduler ds = new DailyScheduler(30,6);
		Time currentTime = Time.newInstance(5,0,0,0);
		for(DailyScheduler.ScheduledTime st : new List<DailyScheduler.ScheduledTime>{
				new DailyScheduler.ScheduledTime('Foo1','*','0,30',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo2','5','*',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo3','1-3,4,5,7-9','29,31',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo4','1-9,10-20','0-10,15,25,35,40,50,55',UserInfo.getUserId(),200.0,0.0,true)})
		{
			System.assert(ds.isJobActive(currentTime,st),'Failed test with: '+st);
		}
		for(DailyScheduler.ScheduledTime st : new List<DailyScheduler.ScheduledTime>{
				new DailyScheduler.ScheduledTime('Foo5','-','0,30',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo6','1-3','*',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo7','1-4,10-20','29,31',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo8','20,1-4,10-20','0-10,15,25,35,40,50,55',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo9','*','0,20,40',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo10','5','-',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo11','1-3,4,5,7-9','1-29,40-59',UserInfo.getUserId(),200.0,0.0,true),
				new DailyScheduler.ScheduledTime('Foo12','1-9,10-20','12,24,36,48',UserInfo.getUserId(),200.0,0.0,true)})
		{
			System.assert(! ds.isJobActive(currentTime,st),'Failed test with: '+st);
		}
	}

	@isTest
	static void executeTest() {
		LongSetting__c ls = new LongSetting__c(Name=DailyScheduler.MAX_CONCURRENT_JOBS_SETTING,Value__c=DailyScheduler.CONCURRENT_JOB_LIMIT);
		upsert ls;
		ScheduledApex__c sa = new ScheduledApex__c(Name='DailySchedulerTest',Hour__c='*',Minute__c='*');
		insert sa;
		DailyScheduler ds = new DailyScheduler(0,60);
		MonitoredActivity__c ma = new MonitoredActivity__c(
			Subject__c=DailyScheduler.SUBJECT_HEADER+'DailySchedulerTest',
			RecordTypeId__c=DailyScheduler.SCHEDULED_TASK_RECORDTYPE_ID,
			SkippedCount__c = 20);
		DailyScheduler.classNameMap.put(ma.Subject__c,'DailySchedulerTest');
		DailyScheduler.injectBatchable(new List<MonitoredActivity__c>{ma},'DailySchedulerTest',new Test_Batchable());
		ds.execute(null);
		Task t = [select Subject from Task where Subject = :ma.Subject__c];
		MonitoredActivity__c ma2 = [select Subject__c from MonitoredActivity__c where TaskId__c = :t.Id];
		System.assertEquals(t.Subject,ma2.Subject__c);
		// now lets try again
		ds = new DailyScheduler(0,60);
		DailyScheduler.classNameMap.put(ma.Subject__c,'DailySchedulerTest');
		DailyScheduler.injectBatchable(new List<MonitoredActivity__c>{ma},'DailySchedulerTest',new Test_Batchable());
		ds.execute(null);
		Task t2 = [select Id from Task where Subject = :ma.Subject__c];
		System.assertNotEquals(t.Id,t2.Id);
		// finally try again, this time a failure case
		ds = new DailyScheduler(0,60);
		ds.execute(null);
		Task t3 = [select Id from Task where Subject = :ma.Subject__c];
		System.assertEquals(t2.Id,t3.Id);
		ds = new DailyScheduler(0,60);
		DailyScheduler.classNameMap.put(ma.Subject__c,'DailySchedulerTest');
		DailyScheduler.injectBatchable(new List<MonitoredActivity__c>{ma},'DailySchedulerTest',new Test_Batchable());
		DailyScheduler.setExcludedSubject(ma.Subject__c,false);
		DailyScheduler.setExcludedSubject(ma.Subject__c,true);
		ds.execute(null);
	}

	@isTest
	static void scheduleTest() {
		LongSetting__c ls = new LongSetting__c(Name=DailyScheduler.MAX_CONCURRENT_JOBS_SETTING,Value__c=0);
		upsert ls;
		DailyScheduler.schedule(0);
	}

	global class Test_Batchable extends AbstractBatchable {
		global Test_Batchable() {
			super('Test_Batchable');
		}

		global List<User> start(Database.BatchableContext bc) {
			return [select Id from User limit 10];
		}

		global void execute(Database.BatchableContext bc, List<User> users) {
		}
	}
}