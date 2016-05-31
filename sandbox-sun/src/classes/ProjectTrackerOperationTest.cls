/**
* Class Name:ProjectTrackerOperationTest
* Description:Test Class created for ProjectTrackerOperation business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/14/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/

@isTest
private class ProjectTrackerOperationTest
{
    public static testmethod void deployPT ()
    {
        Messaging.InboundEmail PaperworkCreated_email = new Messaging.InboundEmail();
        Messaging.InboundEmail Allocation_email = new Messaging.InboundEmail();
        Messaging.InboundEmail StatusChange_email = new Messaging.InboundEmail();
        Messaging.InboundEmail failuer_email = new Messaging.InboundEmail();
        Messaging.InboundEmail failuer_email1 = new Messaging.InboundEmail();
        Messaging.InboundEmail failuer_email2 = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Messaging.InboundEmailResult result1 = new Messaging.InboundEmailResult();
        Messaging.InboundEmailResult result2 = new Messaging.InboundEmailResult();
        String subject='';
        String body='';

        String opportunity_no=[select OpportunityNumber__c  from opportunity limit 1].OpportunityNumber__c; 
        
        subject='Subject:  [SFDC #'+opportunity_no+'] New Status: completed';
        body='User: jkunze@redhat.com \n'+
        'URL: /projects-emea/project-events?project%5fid=201892  \n'+
        'Previous Status: on track \n'+
        'New Status: completed \n'+
        'Comment: \n';
        
        StatusChange_email.PlainTextBody=body;
        StatusChange_email.Subject=subject;

        subject='Subject:  [SFDC #'+opportunity_no+'] Allocation';
        body='User: jkunze@redhat.com \n'+
        'URL: /projects-emea/project-events?project%5fid=201892 \n'+ 
        'Previous Status: on track \n'+
        'New Status: completed \n'+
        'Comment: \n';
        Allocation_email.PlainTextBody=body;
        Allocation_email.Subject=subject;
        

        subject='Subject:  [SFDC #'+opportunity_no+'] GPS Paperwork Uploaded';
        body='User: gcapone@redhat.com \n'+
        'URL: /projects-emea/project-events?project_id=324714#324734 \n'+
        'Comment: \n'+
        'Purchase Order \n'+
        'Attached is the purchase order for this project.\n';

        PaperworkCreated_email.PlainTextBody=body;
        PaperworkCreated_email.Subject=subject;
        

        subject='Subject:  [SFDC #00000000] New Status: completed';
        body='User: jkunze@redhat.com \n'+
        'URL: /projects-emea/project-events?project%5fid=201892  \n'+
        'Previous Status: on track \n'+
        'New Status: completed \n'+
        'Comment: \n';

        failuer_email.PlainTextBody=body;
        failuer_email.Subject=subject;
        

        subject='Subject:  [SFDC #'+opportunity_no+'] Allocation';
        body='User: jkunze@redhat.com \n'+
        'URL: /projects-emea/project-events?project%5fid=201892 \n'+ 
        'Previous Status: on track \n'+
        'New Status: completed \n'+
        'Comment: \n';
        
        failuer_email1.PlainTextBody=body;
        failuer_email1.Subject=subject;
        
        subject='Subject:  [SFDC #0000000000] GPS Paperwork Uploaded';
        body='User: gcapone@redhat.com \n'+
        'URL: /projects-emea/project-events?project_id=324714#324734 \n'+
        'Comment: \n'+
        'Purchase Order \n'+
        'Attached is the purchase order for this project.\n';

        failuer_email2.PlainTextBody=body;
        failuer_email2.Subject=subject;
 
        test.startTest();
        
        new ProjectTrackerOperation().doEventStatusChange(StatusChange_email);
        new ProjectTrackerOperation().doEventAllocation(Allocation_email);
        new ProjectTrackerOperation().doEventPaperworkCreated(PaperworkCreated_email);
        
        result = new ProjectTrackerOperation().handleInboundEmail(failuer_email, new Messaging.InboundEnvelope());      
        System.assertEquals(true, result.Success);
        
        result1 = new ProjectTrackerOperation().handleInboundEmail(failuer_email1, new Messaging.InboundEnvelope());       
        System.assertEquals(true, result1.Success);
        
        result2 = new ProjectTrackerOperation().handleInboundEmail(failuer_email2, new Messaging.InboundEnvelope());               
        System.assertEquals(true, result2.Success);
        
        test.stopTest();   
    }
}