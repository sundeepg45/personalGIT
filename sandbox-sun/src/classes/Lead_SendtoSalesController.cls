/**
* Class Name:Lead_SendtoSalesController 
* Author : Prajakta Samant
* Date:08/10/2011
* Description: Controller class for Send to Sales VF page
*
* Modificaton History:
* Bill Riemers 08/25/2011
* Change of history object
*
* Bryan Bosely 09/02/2011
* implement the ability to update lead owner
*
* Bill Riemers 09/19/2011
* Simplified by moving the validation logic into to the visual force page
*
* Scott Coleman <scoleman@redhat.com> 07/16/2012
* Recording the ID of the Marketing user that qualifies the lead
*/
public with sharing class Lead_SendtoSalesController extends Lead_GlobalManagement {
	Lead objLead;
	ApexPages.StandardController controller;

	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [
					select Id, Is_Marketing_User__c
					from User
					where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}

	public static EmailTemplate EMAIL_TEMPLATE {
		get {
			if(EMAIL_TEMPLATE == null) {
				for(EmailTemplate et : [
					select Name, Body, Subject, Description
					from EmailTemplate
					where
						Folder.Type = 'Email'
						and Folder.Name = 'Alerts' 
						and DeveloperName = 'LeadSendToSalesNotification'
						and IsActive = true
					order by LastModifiedDate desc limit 1 ] )
				{
					EMAIL_TEMPLATE = et;
				}
			}
			return EMAIL_TEMPLATE;
		}
		set;
	}

	/**
	 * Query the Enterprise Server Url from any user.
	 */
	public static String ENTERPRISE_SERVER_URL {
		get {
			if(ENTERPRISE_SERVER_URL == null) {
				User u = [select EnterpriseServerUrl__c from User limit 1];
				ENTERPRISE_SERVER_URL = u.EnterpriseServerUrl__c;
			}
			return ENTERPRISE_SERVER_URL;
		}
		set;
	}

	public Lead_SendtoSalesController(ApexPages.StandardController controller) {
		this.controller = controller;
		this.objLead = (Lead)controller.getRecord();
	}

	public Boolean isRouteLead {
		get { return ( isRouteLead != false ); }
		set;
	}

	public Boolean sendNotification {
		get { return (sendNotification == true); }
		set;
	}

	public static String templateSubstitute(Lead ld,String value) {
		if(value != null) {
			value = value
				.replace('{!Lead.Link}',ENTERPRISE_SERVER_URL+ld.Id)
				.replace('{!Lead.Name}',ld.Name)
				.replace('{!Lead.Company}',ld.Company);
		}
		return value;
	}

	static Set<Id> getUserIds(Set<Id> groupOrUserIds) {
		Set<Id> groupIds = new Set<Id>();
		Set<Id> retval = new Set<Id>();
		for(Id id : groupOrUserIds) {
			if(id != null) {
				if((''+id).startsWith('005')) {
					retval.add(id);
				}
				else {
					groupIds.add(id);
				}
			}
		}
		while(! groupIds.isEmpty()) {
			Set<Id> groupIds2 = new Set<Id>();
			for(GroupMember gm : [select UserOrGroupId 
				from GroupMember 
				where GroupId in :groupIds 
					and UserOrGroupId != null
					and (not UserOrGroupId in :retval)
					and (not UserOrGroupId in :groupIds) ])
			{
				Id id = gm.UserOrGroupId;
				if((''+id).startsWith('005')) {
					retval.add(id);
				}
				else {
					groupIds2.add(id);
				}
			}
			groupIds = groupIds2;
		}
		return retval;
	}

	public PageReference processLead() {
		PageReference pageRef = null;
		try {
			Lead lead = objLead.clone(true);
			lead.Stage__c = MARKETING_QUALIFIED;
			if(currentUser.Is_Marketing_User__c) {
				lead.Qualified_By__c = currentUser.Id;
			}
			if(isRouteLead) {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule= true;
				lead.setOptions(dmo);
			}
			System.Savepoint sp = Database.setSavepoint();
			try {
				if( updateLead( lead, Lead_GlobalManagement.createSentToSalesHistory(lead.Id)) )  {
					if(sendNotification && ! isRouteLead) {
						Set<String> emails = new Set<String>();
						for(User u : [select Email from User where Id in :getUserIds(new Set<Id>{lead.OwnerId})]) {
							if(u.Email != null) {
								emails.add(u.Email);
							}
						}
						if(! emails.isEmpty()) {
							EmailTemplate et = EMAIL_TEMPLATE;
							String body = templateSubstitute(lead,et.Body);
							String subject = templateSubstitute(lead,et.Subject);
							Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
							mail.setPlainTextBody(body);
							mail.setSubject(subject);
							mail.setToAddresses(new List<String>(emails));
							Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail},true);
						}
					}
					pageRef = getLeadPageReference(lead.Id);
					objLead = lead;
				}
				sp = null;
			}
			finally {
				if(sp != null) {
					Database.rollback(sp);
				}
			}
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
		}
		return pageRef;
	}
}