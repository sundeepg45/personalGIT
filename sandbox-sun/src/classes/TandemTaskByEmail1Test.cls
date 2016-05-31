/**
* Class Name:TandemTaskByEmail1Test
* Author:Accenture
* Date:4/11/2011
* Description: Test Class created for TandemTaskByEmail1 business Class
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :09/09/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/

@isTest
private class TandemTaskByEmail1Test
{
    
    public static testmethod void deployTandemTaskCreation()
    {
        String incorrect_mail_id='nitesh.dokania@accenture.com';
        String correct_mail_id='bohidar@acenture.com';
        Account acc = new Account(Name='Test Account');
        insert acc;       
        
        test.startTest();
        
        Messaging.InboundEmail tandem_task_email = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject='[SFDC #'+acc.Id+'] NewTask for '+acc.Id;
        String body='Account: Metro\n'+
            'AccountId: '+acc.Id+'\n'+
            'Subject: Test From Nitesh 123\n'+
            'DueDate: 2008-05-11\n'+
            'Owner:'+incorrect_mail_id+' \n'+
            'Category: Goal\n'+
            'Comments: Goal\n'+
            'hi1\n'+
            'hi2\n';

        tandem_task_email.PlainTextBody=body;
        tandem_task_email.Subject=subject;
        result = new TandemTaskByEmail1().handleInboundEmail(tandem_task_email, new Messaging.InboundEnvelope());
        
        test.stopTest();
    }
    public static testmethod void deployTandemTskCreation()
    {    
        String account_id=Util.ldAccount;
        String incorrect_mail_id='nitesh.dokania@accenture.com';
        String correct_mail_id='bohidar@acenture.com';
        
        test.startTest();   
        
        Messaging.InboundEmail tndem_task_email = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject='[SFDC #'+account_id+'] NewTask for '+account_id;
        String body='Account: Metro\n'+
            'AccountId: '+account_id+'\n'+
            'Subject: Test From Prasad 123\n'+
            'DueDate: 2008-05-11\n'+
            'Owner:'+incorrect_mail_id+' \n'+
            'Category: Goal\n'+
            'Comments: Goal\n'+
            'hi1\n'+
            'hi2\n';

        tndem_task_email.PlainTextBody=body;
        tndem_task_email.Subject=subject;
        result = new TandemTaskByEmail1().handleInboundEmail(tndem_task_email, new Messaging.InboundEnvelope());
        
        test.stopTest();
        
    }
    
    public static testmethod void deployTandemTskCreate()
    {    
        String account_id=Util.ldAccount;
        String incorrect_mail_id='nitesh.dokania@accenture.com';
        String correct_mail_id='bohidar@acenture.com';
        
        test.startTest();   
        
        Messaging.InboundEmail tndem_task_email = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject='[SFDC #'+account_id+'] NewTask for '+account_id;
        String body='Account: Metro\n'+
            'AccountId: '+account_id+'\n'+
            'Subject: Test From Prasad 123\n'+
            'DueDate: 2008-05-11\n'+
            'Owner:'+correct_mail_id+' \n'+
            'Category: Goal\n'+
            'Comments: Goal\n'+
            'hi1\n'+
            'hi2\n';

        tndem_task_email.PlainTextBody=body;
        tndem_task_email.Subject=subject;
        result = new TandemTaskByEmail1().handleInboundEmail(tndem_task_email, new Messaging.InboundEnvelope());
        
        test.stopTest();
    }
    
    public static testmethod void dplyTandemTaskCreation()
    {
        String account_id=Util.ldAccount;
        String incorrect_mail_id='nitesh.dokania@accenture.com';
        String correct_mail_id='bohidar@acenture.com';
        
        test.startTest();
        
        Messaging.InboundEmail tndem_tsk_email = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject='[SFDC #'+account_id+'] NewTask for '+account_id;
        String body='Account: Metro\n'+
            'AccountId: '+account_id+'\n'+
            'Subject: Test From Arti 123\n'+
            'DueDate: 2008-11\n'+
            'Owner: bohidar@acenture.com \n'+
            'Category: Goal\n'+
            'Comments: Goal\n'+
            'hi1\n'+
            'hi2\n';

        tndem_tsk_email.PlainTextBody=body;
        tndem_tsk_email.Subject=subject;
        result = new TandemTaskByEmail1().handleInboundEmail(tndem_tsk_email, new Messaging.InboundEnvelope());
        
        test.stopTest();
        
    }
    
    public static testmethod void dplyTandemTaskException()
    {
        String account_id=Util.ldAccount;
        String incorrect_mail_id='nitesh.dokania@accenture.com';
        String correct_mail_id='bohidar@acenture.com';
        
        test.startTest();
        
        Messaging.InboundEmail tndem_tsk_email = new Messaging.InboundEmail();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject='';
        String body='';

        tndem_tsk_email.PlainTextBody=body;
        tndem_tsk_email.Subject=subject;
        result = new TandemTaskByEmail1().handleInboundEmail(tndem_tsk_email, new Messaging.InboundEnvelope());
        
        test.stopTest();
        
        //System.assertEquals(false,result.success);
    }
}