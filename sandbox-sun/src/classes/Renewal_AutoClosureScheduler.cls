/**
 * Renewal_AutoClosureScheduler
 * 
 * author 	Bryan Bosely <bbosely@redhat.com>
 * created	06/21/2011
 * 
 * This class schedules the batch apex job Renewal_AutoClosure
 *
 * Execute the following command within system log or anonymously 
 * within Eclipse to schedule this job. This schedules the job to run daily at 5pm EST.
 *
 * system.schedule('Renewal Auto Closure', '0 0 17 ? * SUN-SAT', new Renewal_AutoClosureScheduler());
 */
 
global class Renewal_AutoClosureScheduler implements Schedulable 
{
	/**
	 * execute method impl for Schedulable interface
	 **/
	 	 
	global void execute( SchedulableContext sc )
	{
		Renewal_AutoClosure rac = new Renewal_AutoClosure();
		database.executeBatch( rac );	
	}
}