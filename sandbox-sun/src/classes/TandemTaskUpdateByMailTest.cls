/**
 * Test Class created for TandemTaskUpdateByMail business Class
 *
 * @author Accenture
 * 
 * @version 2012-04-18
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Abhijeet Anand
 * 2011-09-13 - Code coverage enhancement.
 * 2011-09-13 - Assert statements also added.
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class TandemTaskUpdateByMailTest
{
	static testmethod void deployTandemTaskUpdateByMail()
	{
		List<Task> tasks = new List<Task>();
		Task  tandem_task ;
		tandem_task = new Task(subject= 'Track Due date',ActivityDate=System.today(),recordtypeid=Util.tandemRecordTypeId,description= 'Important Message');
		tasks.add(tandem_task);
		insert tasks;

		TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
		System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
		User u = new User(
			alias = 'st0184',
			email='standarduser0184@testorg.com',
			emailencodingkey='UTF-8',
			lastname='Testing',
			languagelocalekey='en_US',
			localesidkey='en_US',
			profileid = salesUserProfileTesting.Id__c,
			isActive=true,
			timezonesidkey='America/Los_Angeles',
			username='standarduser0184@testorg.com');
			
		// use a runAs statement to create a new context to avoid mixed DML errors
		System.runAs(new User(Id = UserInfo.getUserId())) {	
			insert u;
		}

		String account_id=Util.ldAccount;
		String task_id=tandem_task.id;
		String correct_mail_id='brijesh.bohidar@accenture.com';
		String email= u.Email;

		Messaging.InboundEmail tandem_task_email = new Messaging.InboundEmail();
		String subject='RE: [SFDC #['+task_id+'] NewTask for '+account_id+']';
		String body='Status: Resolved\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+ correct_mail_id +' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n'+
		'===================================================';

		tandem_task_email.PlainTextBody=body;
		tandem_task_email.Subject=subject;

		//new TandemTaskUpdateByMail().doResolved(tandem_task_email);

		Messaging.InboundEmail tandm_task_email = new Messaging.InboundEmail();
		subject='RE: [SFDC #['+task_id+'] NewTask for '+account_id;
		body='Assign To: bbohidar@accenture.com\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+correct_mail_id+' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n'+
		'===================================================';

		tandm_task_email.PlainTextBody=body;
		tandm_task_email.Subject=subject;

		Messaging.InboundEmail tande_task_email = new Messaging.InboundEmail();
		subject='RE: [SFDC #['+Null+'] NewTask for '+account_id;
		body='Assign To: bbohidar@accenture.com\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+correct_mail_id+' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id+ '\n'+
		'Comments: hi\n'+
		'hi1\n'+
		'===================================================';

		tande_task_email.PlainTextBody=body;
		tande_task_email.Subject=subject;


		Messaging.InboundEmail tand_task_email = new Messaging.InboundEmail();
		body='Assign To: bbohidar@accenture.com\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n';
		subject='1';
		tand_task_email.Subject=subject;
		tand_task_email.PlainTextBody=body;

		Messaging.InboundEmail tandem_tsk_email = new Messaging.InboundEmail();
		subject='RE: [SFDC #['+task_id+'] NewTask for '+account_id;
		body='Assign To: standarduser0184@testorg.com\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Abhijeet 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+email+' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n'+
		'===================================================';

		tandem_tsk_email.PlainTextBody=body;
		tandem_tsk_email.Subject=subject;
		//new TandemTaskUpdateByMail().doReassign(tandem_task_email);

		Messaging.InboundEmail tandem_tak_email = new Messaging.InboundEmail();
		subject='RE: [SFDC #['+task_id+'] NewTask for '+account_id;
		body='Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+correct_mail_id+' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n';

		tandem_tak_email.PlainTextBody=body;
		tandem_tak_email.Subject=subject;


		Messaging.InboundEmail tandem_tk_email = new Messaging.InboundEmail();
		subject='2';
		body='Status: Resolved\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+ correct_mail_id +' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n';
		tandem_tk_email.PlainTextBody=body;
		tandem_tk_email.Subject=subject;


		Messaging.InboundEmail tandem_t_email = new Messaging.InboundEmail();
		subject='RE: [SFDC #['+Null+'] NewTask for '+account_id;
		body='Status: Resolved\n'+
		'Account: Metro\n'+
		'AccountId: '+account_id+'\n'+
		'Subject: Test From Prasad 123\n'+
		'DueDate: 2008-05-11\n'+
		'Owner:'+ correct_mail_id +' \n'+
		'Category: Hi\n'+
		'Task Id: ' +task_id + '\n'+
		'Comments: hi\n'+
		'hi1\n';
		tandem_t_email.PlainTextBody=body;
		tandem_t_email.Subject=subject;

		Messaging.InboundEmail tandem_email = new Messaging.InboundEmail();
		body='1';
		subject=null;
		tandem_email.PlainTextBody=body;
		tandem_email.Subject=subject;


		test.startTest();

		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result1 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result2 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result3 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result4 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result5 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult result6 = new Messaging.InboundEmailResult();
		Messaging.InboundEmailResult resultTrue = new Messaging.InboundEmailResult();

		new TandemTaskUpdateByMail().handleInboundEmail(tandem_email, new Messaging.InboundEnvelope());

		new TandemTaskUpdateByMail().handleInboundEmail(tandm_task_email, new Messaging.InboundEnvelope());
		result = new TandemTaskUpdateByMail().doReassign(tandm_task_email);
		System.assertEquals(false, result.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tande_task_email, new Messaging.InboundEnvelope());
		result1 = new TandemTaskUpdateByMail().doReassign(tande_task_email);
		System.assertEquals(false, result1.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tandem_task_email, new Messaging.InboundEnvelope());
		result2 = new TandemTaskUpdateByMail().doReassign(tandem_task_email);
		System.assertEquals(false, result2.success);

		resultTrue = new TandemTaskUpdateByMail().handleInboundEmail(tandem_tsk_email, new Messaging.InboundEnvelope());
		System.assertEquals(true, resultTrue.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tandem_tak_email, new Messaging.InboundEnvelope());
		result3 = new TandemTaskUpdateByMail().doReassign(tandem_tak_email);
		System.assertEquals(false, result3.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tandem_tk_email, new Messaging.InboundEnvelope());
		result4 = new TandemTaskUpdateByMail().doReassign(tandem_tk_email);
		System.assertEquals(false, result4.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tandem_t_email, new Messaging.InboundEnvelope());
		result5 = new TandemTaskUpdateByMail().doReassign(tandem_t_email);
		System.assertEquals(false, result5.success);

		new TandemTaskUpdateByMail().handleInboundEmail(tand_task_email, new Messaging.InboundEnvelope());
		result6 = new TandemTaskUpdateByMail().doReassign(tandm_task_email);
		System.assertEquals(false, result6.success);

		test.stopTest();
	}
}