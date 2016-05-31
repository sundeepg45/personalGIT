/**
 * This class is used to send notification e-mails on task updates.
 * 
 * @author unknown
 * @version 2011-09-22
 *
 * Modificaton History:
 * Modified By :Bill C. Riemers
 * Modified date :2011-09-22
 * Reason for Modification: Updated to support bulk operations.
 */
public class TandemTaskNotifcationMail
{
	static final Map<String,String> relatedMap = new Map<String,String>{
		'001'=>'Account',
		'006'=>'Opportunity'};
	List<NotificationMail> notificationMailList = new List<NotificationMail>();
	Map<Id,String> bodyMap = new Map<Id,String>();
	Map<Id,String> subjectMap = new Map<Id,String>();
	Messaging.SingleEmailMessage[] messages = new Messaging.SingleEmailMessage[0];

	public void sendMail() {
		getAccounts();
		createToAddresses();
		Messaging.SingleEmailMessage [] mails = new Messaging.SingleEmailMessage[0];
		for(NotificationMail nm : notificationMailList) {
			mails.add(nm.createMessage());
		}
		for(Messaging.SendEmailResult r : Messaging.sendEmail(mails,false)) {
			NotificationMail nm = notificationMailList.remove(0);
			Messaging.SingleEmailMessage mail = mails.remove(0);
			for(Messaging.SendEmailError e : r.getErrors()) {
				System.debug('Failed to send '+mail+' for '+nm.tk+': '+e);
			}
		}
	}

	public void addTask(Task tk) {
		notificationMailList.add(new NotificationMail(tk,'created'));
	}

	void getAccounts(){
		Set<Id> accountIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		Map<String,Set<Id>> idsMap = new Map<String,Set<Id>>();
		for(String value :relatedMap.values()) {
			idsMap.put(value,new Set<Id>());
		}
		for(NotificationMail nm : notificationMailList) {
			String relatedTo = relatedMap.get((nm.tk.WhatId+'000').substring(0,3));
			if(relatedTo != null) {
				nm.relatedTo = relatedTo;
				idsMap.get(relatedTo).add(nm.tk.WhatId);
			}
		}
		Map<Id,String> nameMap = new Map<Id,String>();
		for(String relatedTo : idsMap.keySet()) {
			Set<Id> ids = idsMap.get(relatedTo);
			if(!ids.isEmpty()) {
				for(SObject so : Database.query('select Id, Name from '
					+relatedTo+' where Id in :ids') )
				{
					nameMap.put((Id)so.get('Id'),(String)so.get('Name'));
				}
			}
		}
		for(NotificationMail nm : notificationMailList) {
			Id whatId = nm.tk.WhatId;
			String name = nameMap.get(nm.tk.WhatId);
			if(name != null) {
				nm.whatName = name;
			}
		}
	}

	void createToAddresses() {
		Set<Id> ownerIds = new Set<Id>();
		for(NotificationMail nm : notificationMailList) {
			ownerIds.add(nm.tk.OwnerId);
		}
		Map<Id,User> userMap = new Map<Id,User>([Select email from User where Id in :ownerIds]);
		for(NotificationMail nm : notificationMailList) {
			User u = userMap.get(nm.tk.OwnerId);
			if(u != null && u.Email != null) {
				nm.toAddresses.add(u.Email);
			}
		}
	}

	class NotificationMail {
		final Task tk;
		final String operation;
		String[] toAddresses =new String[0];
		String relatedTo;
		String body='';
		String whatName='';

		NotificationMail(Task tk,String operation) {
			this.tk = tk;
			this.operation = operation;
			this.relatedTo = tk.Id;
		}

		String getBody(){
			return 'A Tandem task was created for you:\n'+
			'\nRelated to:' +relatedTo+
			'\nName:'+whatName+
			'\nTask Id:'+tk.id+
			'\nCategory:'+tk.Category__c+
			'\nDueDate:'+tk.ActivityDate+
			'\nTask:' +tk.Subject+
			'\nURL:'+Util.sfdcurl + tk.id +
			'\nComment:'+tk.Description +
			'\n========================================================================' +
			'\n To complete this task please forward the mail to update_tandem_task@1z8m0f71tatwfxrhqelan385t.in.salesforce.com with "Resolved" on new line in body.\n'+
			'\n To reassign this task please forward the mail to update_tandem_task@1z8m0f71tatwfxrhqelan385t.in.salesforce.com with "Assign To:<owner email id>" on new line in body.';  
		}

		String getSubject() {
			return ' Tandem Task #['+tk.id+']'+operation +' on '+ whatName;
		}

		Messaging.SingleEmailMessage createMessage() {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			// Specify the name used as the display name.
			mail.setSenderDisplayName('SALES FORCE');

			// Specify the subject line for your email address.
			mail.setSubject(getSubject());

			// Set to True if you want to BCC yourself on the email.
			mail.setBccSender(false);
			// Optionally append the salesforce.com email signature to the email.
			// The email address of the user executing the Apex Code will be used.
			mail.setUseSignature(false);
			// Specify the text content of the email.
			mail.setPlainTextBody(getBody());
			return mail;
		}
	}
}