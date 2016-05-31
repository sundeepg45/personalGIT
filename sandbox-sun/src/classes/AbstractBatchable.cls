/**
 * This is an abstract class to help reduce the efforts in implementing batchable classes. 
 *
 * @version 2014-11-04
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-11-04 - Add CreatedDate to the lookupJob query
 * 2014-09-19 - Added lookupJob method
 * 2014-09-18 - Removed implements stateful from the base class
 * 2014-04-01 - Created
 */
global abstract class AbstractBatchable implements Database.Batchable<SObject> {
    /** The name of this batch job */
    global final String batchName;

    /** Keep track of any errors. */
    global List<String> errorList = new List<String>();

    /**
     * Constructor that assigns a name.
     */
    global AbstractBatchable(String batchName) {
        this.batchName = batchName;
    }

    /**
     * Check if there is work for this job to do.  The purpose of this method is to allow the trigger
     * invoked by the daily scheduler to tell the daily scheduler if this job can be skipped.  In
     * order to take advantage of this feature one would want a trigger of the form:
     * 
     * <pre>
     *  trigger MA_Foo on MonitoredActivity__c (after insert) {
     *      AbstractBatchable batchable = new Foo();
     *      String subject = DailyScheduler.injectBatchable(Trigger.new,'Foo',batchable);
     *      if(subject != null) {
     *          DailyScheduler.setExcludedSubject(subject,batchable.hasWork());
     *      }
     *  }
     * </pre>
     * 
     * @return false if there is no work to do.
     */
    global virtual Boolean hasWork() { return true; }

    /**
     * Called to find the AsyncApexJob
     */
    global AsyncApexJob lookupJob(Database.BatchableContext bc) {
        AsyncApexJob job = null;
        try {
            job = [
                SELECT
                    Status,
                    NumberOfErrors,
                    JobItemsProcessed,
                    TotalJobItems,
                    CreatedBy.Email,
                    CreatedDate
                FROM AsyncApexJob 
                WHERE Id = :bc.getJobId() ];
        }
        catch(Exception ignored) {}
        return job;
    }

    /**
     * The finish method impl for Database.Batchable interface.  If your interface is stateless (default), then
     * you will want call this from execute() to email errors.
     *
     * @param bc database context
     */
    global virtual void finish(Database.BatchableContext bc) {
        System.debug('Finish called');
        finish(lookupJob(bc));
    }


    /**
     * finish method
     *
     * @param job the async apex job
     */
    global virtual void finish(AsyncApexJob job) {
        sendErrors(job);
    }

    /**
     * Called to send error message by e-mail.   *
     * @param job the async apex job
     * @return the message which was sent
     */
    global virtual Messaging.SingleEmailMessage sendErrors(AsyncApexJob job) {
        Messaging.SingleEmailMessage mail = null;
        // Send an email to notify us of the jobs status
        if(job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0 || ! errorList.isEmpty()) {
            if(job == null) {
                job = new AsyncApexJob();
            }
            mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
            mail.setToAddresses( toAddresses );
            mail.setSubject( batchName+' failures ' + job.Status +' run as '+UserInfo.getUserName() );
            String body = 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n';
            for(String e : errorList) {
                body += e+'\n';
            }
            errorList.clear();
            mail.setPlainTextBody( body );
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
        }
        return mail;
    }
}