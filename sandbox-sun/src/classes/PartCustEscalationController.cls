public with sharing class PartCustEscalationController {

    public String requestorEmail {get; set; }
    public String requestorPhone {get; set; }
    public String customerName {get; set; }
    public String customerContactEmail {get; set; }
    public String customerContactPhone {get; set; }
    public String customerGEO {get; set; }
    public String customerIssueDescription {get; set; }
    public String expectations {get; set; }
    public String redhatAccountNumber {get; set; }
    public String redhatSupportTicketNumber {get; set; }
    public String alreadyEscalated {get; set; }

    private OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];

	public PageReference submit() {
		sendEmail();
		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Message Sent Successfully.');
        ApexPages.addMessage(myMsg);
		return null;
	}
	
	private void sendEmail()    
    {   
    	List<Messaging.SingleEmailMessage> l = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    	User me = [select Contact.Account.Name, Name, Email from User where Id = :UserInfo.getUserId()];

		mail.setSubject('Partner Customer Escalation for ' + me.Email);
        mail.setReplyTo(requestorEmail);
        mail.setOrgWideEmailAddressId(owe.id);        
        String[] toAddresses = new String[] {StringSetting__c.getInstance('PartCustEscalation.Email').Value__c};
		mail.setToAddresses(toAddresses);

		String body = 'Requestor Info:\n';
		body += 'Email: ' + requestorEmail + '\n';
		body += 'Requestor Phone: ' + requestorPhone + '\n';

		body += '\n';
		body += 'Submitter Name: ' + me.Name + '\n';
		if (me.Contact != null && me.Contact.Account != null){
			body += 'Submitter Partner Name: ' + me.Contact.Account.Name + '\n';
		}
		body += 'Submitter Email: ' + me.Email + '\n';

		body += '\nCustomer Info:\n';
	    body += 'Name: ' + customerName + '\n';
	    body += 'Contact Email: ' + customerContactEmail + '\n';
	    body += 'Contact Phone: ' + customerContactPhone + '\n';
	    body += 'GEO: ' + customerGEO + '\n\n';
	    body += 'Issue Description:\n' + customerIssueDescription + '\n\n';
	    body += 'Expectations:\n' + expectations + '\n\n';
	    body += 'Account Number: ' + redhatAccountNumber + '\n';
	    body += 'Support Ticket Number: ' + redhatSupportTicketNumber + '\n';
	    body += 'Is Already Escalated: ' + alreadyEscalated + '\n';
	    
	    mail.setPlainTextBody(body);

        mail.saveAsActivity = FALSE;
        l.add(mail);
        Messaging.sendEmail(l);                          
    }
    
    @isTest(SeeAllData=false)
    static void partnerEscalationTest() {
    	PartCustEscalationController ctrl = new PartCustEscalationController();

	    ctrl.requestorEmail = 'a@b.com';
	    ctrl.requestorPhone = '9192223333';
	    ctrl.customerName = 'My Customer';
	    ctrl.customerContactEmail = 'a@b.com';
	    ctrl.customerContactPhone = '9192223333';
	    ctrl.customerGEO = 'NA';
	    ctrl.customerIssueDescription = 'Issue';
	    ctrl.expectations = 'Expectations';
	    ctrl.redhatAccountNumber = '1234';
	    ctrl.redhatSupportTicketNumber = '1234';
	    ctrl.alreadyEscalated = 'No';
	    
	    ctrl.submit();
    }
}