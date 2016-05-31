/**
 * DailyScheduler
 * 
 * This class schedules the batches for any apex jobs designed to run at least once
 * per day.  The ScheduledApex__c custom settings are used to determine actual 
 * invocation schedule.  To help limit dependancies and ensure notification should 
 * the job fail to run, this class works by updating or creating tasks.  A Monitored 
 * Activities trigger call the DailyScheduler.insertBatchable.  The trigger can be as 
 * simple as:
 *
 * 	trigger MA_Foo on MonitoredActivity__c (after insert) {
 * 		DailyScheduler.injectBatchable(Trigger.new,'Foo',new Foo());
 * 	}
 *
 * Should there be more than one task for the job the oldest will be delete
 * on success and the newest on failure.  This way a time based trigger can 
 * be used to notify when the task is significantly over due.
 *
 * If a batchable interferace is extented from AbstractBatchable, there is a 
 * skipBatchable method that may be called to determine if the batch may be
 * skipped this iteration (because there is no work to do).  If a batch that is
 * skipped for this reason is treated the same as a batch that ran successfully.
 *
 * After removing existing scheduled instances, execute the following commands 
 * within system log or anonymously  within Eclipse to schedule this job. This 
 * schedules the job to run every 1 minute.
 *
 * 		DailyScheduler.schedule(1);
 *
 * @version 2014-04-25
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-04-24 - Refactored for better test coverage
 * 2014-04-21 - Update to use AbstractBatchable
 * 2013-07-30 - Correcting defect.  We must leave at least one jobs slot available.
 * 2013-07-05 - Added must run logic to process skipped jobs as soon as possible
 * 2013-02-13 - Added stack trace to generic error email
 * 2012-06-11 - Updated to use tasks and allow scheduling more than once an hour
 * 2011-09-30 - Created
 */
global class DailyScheduler implements Schedulable {
	global final static String MAX_CONCURRENT_JOBS_SETTING = 'DailyScheduler.MaxConcurrentJobs';
	// There really should be a Limit method for this value...
	global static Integer CONCURRENT_JOB_LIMIT = 5;
	// This is a code limitation. 
	global static Integer RESERVED_DML = 10;
	// This subject prefix is used to identify our special tasks.
	global final static String SUBJECT_HEADER = 'Scheduled Job Task: ';
	// This is the record type we use for scheduled job tasks.
	global static Id SCHEDULED_TASK_RECORDTYPE_ID {
		get {
			if(SCHEDULED_TASK_RECORDTYPE_ID == null) {
				for(RecordType rt :[
					select Id 
					from RecordType 
					where DeveloperName = 'Scheduled_Task'
						and SObjectType = 'Task'
						and IsActive = true
					limit 1] )
				{
					SCHEDULED_TASK_RECORDTYPE_ID = rt.Id;
				}
			}
			return SCHEDULED_TASK_RECORDTYPE_ID;
		}
		private set {}
	}
	// This is the map which will store the batchable objects
	global static Map<String,Database.Batchable<SObject>> batchableMap = new Map<String,Database.Batchable<SObject>>();
	global static Set<String> excludedSubjects = new Set<String>();
	global static Map<String,String> classNameMap = new Map<String,String>();
	global Integer startMinute;
	global Integer frequency;
	global Set<Id> ownerIds = new Set<Id>();
	global String errorMessageBody = '';

	/**
	 * Constructor which includes scheduling information.
	 *
	 * @param start how many minute past the hour in which this job has been scheduled to start
	 * @param frequency how many minutes until the next time the job runs
	 */
	global DailyScheduler(Integer start,Integer frequency) {
		this.startMinute = start;
		this.frequency = frequency;
	}

	global static Integer maxConcurrentJobs {
		get {
			if(maxConcurrentJobs == null) {
				LongSetting__c ls = LongSetting__c.getInstance(MAX_CONCURRENT_JOBS_SETTING);
				if(ls != null && ls.Value__c != null) {
					maxConcurrentJobs = ls.Value__c.intValue();
				}
			}
			if(maxConcurrentJobs == null) {
				maxConcurrentJobs = CONCURRENT_JOB_LIMIT - 1;
			}
			return maxConcurrentJobs;
		}
	}

	/**
	 * This method is called from the Task triggers to inject the Database.Batchable<Object>.
	 *
	 * @param tasks a listing of tasks to process
	 * @param className the name of the class being injected
	 * @param batchable object to inject
	 *
	 * @return subject if not previous injected and there is enough reserved queries to to check if there is work to do.
	 */ 
	global static String injectBatchable(List<MonitoredActivity__c> monitoredActivities,String className,Database.Batchable<SObject> batchable) {
		String retval = null;
		for(MonitoredActivity__c ma : monitoredActivities) {
			if(classNameMap.get(ma.Subject__c) == className && ma.RecordTypeId__c == SCHEDULED_TASK_RECORDTYPE_ID) {
				batchable = batchableMap.put(ma.Subject__c,batchable);
				if(batchable == null && Limits.getDmlStatements()+RESERVED_DML < Limits.getLimitDmlStatements()) {
					retval = ma.Subject__c;
				}
				break;
			}
		}
		return retval;
	}

	/**
	 * Called to add or remove a value to the excluded subject set.  This set is used to 
	 * by-pass running a job when there is no work to do.
	 * @param subject the subject name of the monitored activity
	 * @param hasWork false to add to the set, true to remove
	 */
	global static void setExcludedSubject(String subject,Boolean hasWork) {
		if(subject != null) {
			if(hasWork == true) {
				excludedSubjects.remove(subject);
			}
			else if(hasWork == false){
				excludedSubjects.add(subject);
			}
		}
	}

	/**
	 * Convience function to schedule the this class.
	 */
	global static void schedule(Integer frequency) {
		if(frequency >= 1 && frequency <= 60) {
			for(Integer start=0;start < 60;start+=frequency) {
				String name = 'Daily Scheduler '+String.valueOf(start+100).substring(1);
				System.schedule(name, '0 '+start+' * * * ?', new DailyScheduler(start,frequency));
			}
		}
	}

	/**
	 * This should only be assigned for test purposes.
	 */
	global Map<String,ScheduledTime> scheduledTimeMapTestData = null;

	/**
	 * Normally this is created for each use.  But for test purposes a value may be assigned.
	 */
	global Map<String,ScheduledTime> createScheduledTimeMap() {
		Map<String,ScheduledTime> retval = scheduledTimeMapTestData;
		if(retval == null) {
			retval = new Map<String,ScheduledTime>();
			for(ScheduledApex__c sa : ScheduledApex__c.getAll().values()) {
				retval.put(sa.Name,new ScheduledTime(sa.Name,sa.Hour__c,sa.Minute__c,sa.OwnerId__c,sa.Scope__c,sa.Priority__c,sa.MustRun__c));
			}
		}
		return retval;
	}

	/**
	 * This should only be assigned for test purposes.
	 */
	global Time currentTimeTestData = null;

	/**
	 * Returns the current time.
	 */
	global Time getCurrentTime() {
		Time retval = currentTimeTestData;
		if(retval == null) {
			retval = DateTime.now().time();
		}
		return retval;
	}

	/**
	 * Test BatchableFactory if a value is in the active range.
	 */
	global static Boolean isActiveRange(Integer value,Integer endValue,String saRange) {
		Boolean retval = false;
		// Both '*' and '?' will match anything'
		if(saRange == '*' || saRange == '?') {
			retval = true;
		}
		// A '-' will match nothing
		else if(saRange == '-') {
			retval = false;
		}
		else if(saRange != null) {
			// find out if the job is scheduled during this time frame
			for(;(!retval)&&(value < endValue);value++) {
				// the range can be comma separeted expressions
				for(String range : saRange.split(',')) {
					// each expression can be a range
					String [] a = range.split('-');
					Integer len = a.size();
					if(len >= 1) {
						Integer startTime = Integer.valueOf(a[0]);
						if(startTime <= value) {
							Integer endTime = startTime;
							if(len >= 2) {
								endTime = Integer.valueOf(a[1]);
							}
							if(endTime >= value) {
								retval = true;
								break;
							}
						}
					}
				}
			}
		}
		return retval;
	}

	/**
	 * Test if a className is scheduled to run at this time.
	 */
	global Boolean isJobActive(Time currentTime,ScheduledTime st) {
		Integer h = currentTime.hour();
		Boolean retval = isActiveRange(h,h+1,st.hourRange);
		if(retval == true) {
			retval = isActiveRange(startMinute,startMinute+frequency,st.minuteRange);
		}
		return retval;
	}

	/**
	 * execute method impl for Schedulable interface
	 *
	 */
	global void execute( SchedulableContext sc ) {
		Map<Id,Id> jobIdMap = null;
		try {
			Map<String,Id> taskIdMap = new Map<String,Id>();
			final Map<String,ScheduledTime> scheduledTimeMap = new Map<String,ScheduledTime>();
			try {
				taskIdMap = prepareJobs( scheduledTimeMap );
				jobIdMap = submitJobs(sc,taskIdMap,scheduledTimeMap);
			}
			catch(Exception e) {
				System.debug(e);
				errorMessageBody += 'Caught Exception: \n'+e.getStackTraceString();
			}
			finally {
				try {
					deleteOldTasks( taskIdMap );
				}
				finally {
					mailErrorMessage(scheduledTimeMap);
				}
			}
		}
		finally {
			errorMessageBody = '';
			ownerIds.clear();
			classNameMap.clear();
			batchableMap.clear();
			excludedSubjects.clear();
			// update all the monitored activies with the new job ids.
			if(jobIdMap != null && ! jobIdMap.isEmpty()) {
				List<MonitoredActivity__c> monitoredActivities = [
					select TaskId__c
					from MonitoredActivity__c
					where TaskId__c in :jobIdMap.keySet() ];
				for(MonitoredActivity__c ma : monitoredActivities) {
					Id jobId = jobIdMap.remove(ma.TaskId__c);
					// excluded jobs won't have a new job id, so retain the old value
					if(jobId != null) {
						ma.AsyncApexJobId__c = jobId;
					}
				}
				Database.update(monitoredActivities,false);
			}
		}
	}

	/**
	 * Called to fill the skippedMap and lastRunMap.
	 * 
	 * @param skippedMap map to be filled with monitored activities that have been skipped.
	 * @param lastRunMap map filled with monitored activies that have not been skipped.
	 * @return map of monitored activites
	 */
	global Map<Id,MonitoredActivity__c> getMonitoredActivityMap(
		Map<String,MonitoredActivity__c> skippedMap,
		Map<String,MonitoredActivity__c> lastRunMap)
	{
		Map<Id,MonitoredActivity__c> monitoredActivityMap = new Map<Id,MonitoredActivity__c>();
		for(MonitoredActivity__c ma : [
			select AsyncApexJobId__c, SkippedCount__c, Subject__c, Task__c
			from MonitoredActivity__c
			where Subject__c like :SUBJECT_HEADER+'%' ])
		{
			if(ma.AsyncApexJobId__c != null) {
				monitoredActivityMap.put(ma.AsyncApexJobId__c,ma);
			}
			Map<String,MonitoredActivity__c> bySubjectMap = lastRunMap;
			if(ma.SkippedCount__c != null && ma.SkippedCount__c > 0) {
				bySubjectMap = skippedMap;
			}
			bySubjectMap.put(ma.Subject__c,ma);
		}
		return monitoredActivityMap;
	}

	/**
	 * Called fill the status map of AsyncApexJobs and count how many are still active.
	 * 
	 * @param monitoredActivityMap map of monitored activides by job id
	 * @param statusMap map to fill with job status
	 * @return count of number of active jobs
	 */
	global Integer getActiveCount(Map<Id,MonitoredActivity__c> monitoredActivityMap,Map<String,String> statusMap) {
		Integer activeCount = 0;
		Set<String> activeJobStatuses = new Set<String>{'QUEUED','PREPARING','PROCESSING'};
		for(AsyncApexJob job : [
			select Status
			from AsyncApexJob
			where Id in :monitoredActivityMap.keySet()
				or (Status in :activeJobStatuses and JobType = 'BatchApex')])
		{
			if(job.Status != null) {
				MonitoredActivity__c ma = monitoredActivityMap.get(job.Id);
				if(ma != null) {
					statusMap.put(ma.Subject__c,job.Status);
				}
				if(activeJobStatuses.contains(job.Status.toUpperCase())) {
					activeCount++;
				}
			}
		}
		return activeCount;
	}

	/**
	 * Called to create all the neccessary tasks.
	 * 
	 * @param taskIdMap map to fill with all the newly created tasks
	 * @param currentTime timestamp to use for queueing requests
	 * @param stSorted a sorted list of scheduledtimes
	 * @param statusMap a map with the status of jobs
	 * @param skippedMap a map of jobs that have been previously skipped
	 * @param lastRunMap a map of jobs that have not been previously skipped
	 * @param jobsRemaining the maximum number of jobs we can add to the queue
	 * @return the savePoint if we have too many jobs queued up.
	 */
	global Savepoint prepareTasks(
		Savepoint savePoint,
		Map<String,Id> taskIdMap,
		final Time currentTime,
		List<ScheduledTime> stSorted,
		Map<String,String> statusMap,
		Map<String,MonitoredActivity__c> skippedMap,
		Map<String,MonitoredActivity__c> lastRunMap,
		Integer jobsRemaining )
	{
		taskIdMap.clear();
		skippedMap = skippedMap.clone();
		List<Task> tasks = new List<Task>();
		List<MonitoredActivity__c> skippedActivities = new List<MonitoredActivity__c>();
		for(ScheduledTime st : stSorted) {
			String className = st.Name;
			String subject = SUBJECT_HEADER+className;
			String status = statusMap.get(subject);
			try {
				MonitoredActivity__c skippedActivity = skippedMap.remove(subject);
				Database.Batchable<SObject> batchable = batchableMap.remove(subject);
				if(isJobActive(currentTime,st) || (st.mustRun && skippedActivity != null)) {
					// We don't run excluded jobs, but we will update the tasks as if we ran them
					// Unfortunately, excluded will always be false the first time through.
					Boolean excluded = excludedSubjects.contains(subject);
					if( savePoint != null || (( batchable != null) && ( excluded || jobsRemaining > 0 )) ) {
						// if there is no savePoint, then we need to keep track of jobs as there is no undo 
						// when too many end-up queued.
						if(savePoint == null && ! excluded) {
							jobsRemaining--;
						}
						if(status == null || status == 'Completed' || status == 'Aborted' || status == 'Failed') {
							classNameMap.put(subject,className);
							tasks.add(new Task(
								ActivityDate=System.today().addDays(1),
								IsReminderSet = true,
								ReminderDateTime = DateTime.now().addDays(1).addMinutes(frequency),
								Monitor__c = true,
								OwnerId=st.OwnerId,
								RecordTypeId = SCHEDULED_TASK_RECORDTYPE_ID,
								Subject=subject));
							if(batchable != null) {
								batchableMap.put(subject,batchable);
							}
						}
						// Normally jobs should complete by the next scheduled start time...
						if(savePoint == null && (status == 'Processing' || status == 'Failed')) {
							errorMessageBody += 'Job status '+status+' for '+className+'\n\n';
							ownerIds.add(st.OwnerId);
						}
					}
					else if( st.mustRun ) {
						// we can't run an activity that must be run, so we'll update the activity
						// so it will return the the queue again next time
						if(skippedActivity == null) {
							// skipping this activity
							skippedActivity = lastRunMap.get(subject);
						}
						if(skippedActivity.SkippedCount__c == null || skippedActivity.SkippedCount__c == 0) {
							skippedActivity.SkippedCount__c = 1;
						}
						else {
							skippedActivity.SkippedCount__c = skippedActivity.SkippedCount__c + 1;
						}
						skippedActivities.add(skippedActivity);
					}
				}
			}
			catch(Exception e) {
				System.debug(e);
				errorMessageBody += 'Error parsing range for '+className+':\n'+e+'\n\n';
				ownerIds.add(st.OwnerId);
			}
		}
		// update skipped activities
		if(! skippedActivities.isEmpty()) {
			Database.update(skippedActivities,false);
		}
		// insert the new tasks
		for(Database.SaveResult sr : Database.insert(tasks,false)) {
			Task t = tasks.remove(0);
			if(sr.isSuccess()) {
				taskIdMap.put(t.Subject,t.Id);
			}
			else if(! sr.isSuccess()) {
				String className = classNameMap.remove(t.Subject);
				String e = 'Failed to insert '+t+':\n'+sr.getErrors();
				System.debug(e);
				errorMessageBody += e+'\n\n';
			}
		}
		// if we succeeded in queuing everything needed, clear the savePoint,
		// as there is no need for an undo.
		if(batchableMap.size()-excludedSubjects.size() <= jobsRemaining) {
			savePoint = null;
		}
		return savePoint;
	}

	/**
	 * Called to prepare all the jobs.
	 * 
	 * @param jobIdMap
	 * @return map filled with newly created tasks by subject.
	 */
	global Map<String,Id> prepareJobs( Map<String,ScheduledTime> scheduledTimeMap ) {
		// find the job statuses
		Map<String,MonitoredActivity__c> skippedMap = new Map<String,MonitoredActivity__c>();
		Map<String,MonitoredActivity__c> lastRunMap = new Map<String,MonitoredActivity__c>();
		// We need to kee track of the number of concurrent jobs manually
		Map<String,String> statusMap = new Map<String,String>();
		Integer jobsRemaining = maxConcurrentJobs - getActiveCount(getMonitoredActivityMap(skippedMap,lastRunMap),statusMap);
		System.debug('Jobs Remaining: '+jobsRemaining);
		// examine the schedule and add tasks for jobs ready to run
		scheduledTimeMap.putAll(createScheduledTimeMap());

		Map<String,Id> taskIdMap = new Map<String,Id>();
		List<ScheduledTime> stSorted = scheduledTimeMap.values();
		stSorted.sort();
		Savepoint savePoint = null;
		final Time currentTime = getCurrentTime();
		if(jobsRemaining > 0) {
			// First try quering up everything available
			try {
				savePoint = Database.setSavepoint();
				savePoint = prepareTasks(savePoint,taskIdMap,currentTime,stSorted,statusMap,skippedMap,lastRunMap,jobsRemaining);
			}
			finally {
				if(savePoint != null) {
					Database.rollback(savePoint);
					classNameMap.clear();
				}
			}
		}
		// if we have too many jobs we need to repeat the process this time
		// removing lower priority jobs from our list
		if(savePoint != null || jobsRemaining <= 0) {
			prepareTasks(null,taskIdMap,currentTime,stSorted,statusMap,skippedMap,lastRunMap,jobsRemaining);
		}
		return taskIdMap;
	}

	/**
	 * submit jobs
	 *
	 * @return map of newly submitted job ids by task id
	 */
	global Map<Id,Id> submitJobs(SchedulableContext sc, Map<String,Id> taskIdMap, Map<String,ScheduledTime> scheduledTimeMap ) {
		Map<Id,Id> jobIdMap = new Map<Id,Id>();
		// process the batchable instances created by the task triggers
		for(String subject : batchableMap.keySet()) {
			try {
				Database.Batchable<SObject> b = batchableMap.remove(subject);
				Id jobId = null;
				// We attempt to submit the job with b is null, just so test coverage can 
				// capture this error with an exception.
				if((sc != null || b == null) && ! excludedSubjects.contains(subject)) {
					jobId = Database.executeBatch(b,scheduledTimeMap.get(classNameMap.get(subject)).scope);
				}
				classNameMap.remove(subject);
				// Anything left in the map will be removed if there
				// is an older task left.  So remove this map entry.
				jobIdMap.put(taskIdMap.remove(subject),jobId);
			}
			catch(Exception e) {
				System.debug(e);
				String className = classNameMap.remove(subject);
				errorMessageBody += 'Error Invoking '+className+':\n'+e+'\n\n';
				ownerIds.add(scheduledTimeMap.get(className).OwnerId);
			}
		}
		return jobIdMap;
	}

	/**
	 * Delete all but the most recent task for each subject if the task was assigned a job id or
	 * excluded.  Otherwise delete all but the second most recent task.
	 * 
	 * @param taskIdMap map of newly inserted tasks which were not assigned a job id.
	 */
	global void deleteOldTasks( Map<String,Id> taskIdMap ) {
		if(taskIdMap != null) {
			Set<Id> taskIds = new Set<Id>();
			// Find tasks to delete
			for( Task t : [
				select Subject from Task
				where Subject like :SUBJECT_HEADER+'%'
					and RecordTypeId = :SCHEDULED_TASK_RECORDTYPE_ID
					and Id not in :taskIdMap.values()
				order by CreatedDate ] )
			{
				taskIds.add(taskIdMap.get(t.Subject));
				// Add this task id to the map.
				// If there is a newer task selected with the same
				// subject this task will be deleted.
				taskIdMap.put(t.Subject,t.Id);
			}
			taskIds.remove(null);
			Database.delete(new List<Id>(taskIds),false);
		}
	}

	/**
	 * send an email with error messages
	 *
	 */
	global void mailErrorMessage( Map<String,ScheduledTime> scheduledTimeMap ) {
		// If there are any users, send a failure notification
		if(errorMessageBody != '' || ! classNameMap.isEmpty()) {
			// report any classes which were not created by triggers
			for(String className : classNameMap.values()) {
				ScheduledTime st = scheduledTimeMap.get(className);
				errorMessageBody += 'Trigger failed to create '+className+'\n\n';
				ownerIds.add(st.OwnerId);
			}
			Set<String> toAddresses = new Set<String>{ 'sf-error-list@redhat.com' };
			if(! ownerIds.isEmpty()) {
				for(User u : [select Email from User where Id in :ownerIds and Email <> null]) {
					toAddresses.add(u.Email);
				}
			}
			//TODO: uncomment this code when we can turn on email
			//Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			//mail.setToAddresses( new List<String>(toAddresses) );
			//mail.setSubject('Daily Scheduler failure when run as '+UserInfo.getUserName());
			//mail.setPlainTextBody( errorMessageBody );
			//Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
	}

	global class ScheduledTime implements Comparable {
		global String name;
		global Id ownerId;
		global String hourRange;
		global String minuteRange;
		global Integer scope;
		global Integer priority = 0;
		global Boolean mustRun;
		global ScheduledTime(String name,String hourRange,String minuteRange,Id ownerId,Decimal scope,Decimal priority,Boolean mustRun) {
			this.name = name;
			this.hourRange = hourRange;
			this.minuteRange = minuteRange;
			this.ownerId = ownerId;
			this.scope = 200;
			if(scope != null) {
				this.scope = scope.intValue();
			}
			this.priority = 0;
			if(priority != null) {
				this.priority = priority.intValue();
			}
			this.mustRun = (mustRun == true);
		}
		global Integer compareTo(Object compareTo) {
			Integer retval = -1;
			if(compareTo instanceOf ScheduledTime) {
				final ScheduledTime st = (ScheduledTime)compareTo;
				if(this.priority > st.priority) {
					retval = 1;
				}
				else if(this.priority == st.priority) {
					if(this.name > st.name) {
						retval = 1;
					}
					else if(this.name == st.name) {
						retval = 0;
					}
				}
			}
			return retval;
		}
	}
}