public with sharing class RequalificationOverdueController {
	private Id userId;
	public Boolean caseCreated {get; set; }

	public RequalificationOverdueController(){
		caseCreated = false;
	}

	public RequalificationOverdueController(Id userId) {
		this.userId = userId;
	}

	public PageReference createRequalOverdueCase() {
		User u = null;
		if (userId != null) {
        	u = [select Id, ContactId, Contact.AccountId, FederationIdentifier from User where Id = :userId];
		}
		else {
        	u = [select Id, ContactId, Contact.AccountId, FederationIdentifier from User where Id = :UserInfo.getUserId()];
		}
        if (u.Contact.AccountId != null){
	        Account a = [select Id, RequalificationDate__c from Account where Id = :u.Contact.AccountId];

			Id PartnerGeneralIssuesRecordTypeId = [
	            select id
	              from RecordType
	             where sObjectType = 'Case'
	               and Name = 'Partner General Issues'
	        ].id;
	        String subject = 'Requalification Overdue Action Request';
	        a.RequalStatus__c = 'In Progress';
	        a.Requalification_Reinstated__c = true;
	        RequalificationHelper.reinstateOverdueAccounts(new Set<Id>{a.Id});

	        Case c = null;
	        try {
	        	c = [select Id, Comments__c from Case where AccountId = :a.Id and ContactId = :u.ContactId and Subject = :subject and Status != 'Closed'];
	        } catch (Exception e){
	        	// No Existing Case found
	        }
	        if (c == null){
		        c = new Case();
		        c.RecordTypeId = PartnerGeneralIssuesRecordTypeId;
		        c.Issue_Type_Classification__c = 'Requalification Access Request';
		        c.Issue_Type__c = 'Requalification Request';
		        c.Subject = subject;
		        c.Description = 'Partner has requested to be contacted to resolve overdue requalification.';
		        c.Origin = 'Portal';
		        c.RedHatLoginName__c = u.FederationIdentifier;
		        c.Status = 'New';
		        c.Priority = 'Medium';

	            c.AccountId = a.Id;
		        c.ContactId = u.ContactId;

		        Database.Dmloptions dmo = new Database.Dmloptions();
		        dmo.assignmentRuleHeader.useDefaultRule = true;
		        c.setOptions(dmo);

			    try {
			        insert c;
			        update a;
			    }
		        catch (System.DmlException ex) {
					System.debug('----------------------->> RecordTypeId=' + c.RecordTypeId);
					System.debug('----------------------->> ContactId=' + c.ContactId);
					throw ex;
		        }
		        caseCreated = true;
	        } else {
	        	CaseComment cc = new CaseComment();
	        	cc.CommentBody = 'Partner re-requested action.';
	        	cc.ParentId = c.Id;
	        	insert cc;
	        	caseCreated = true;
	        }
       }
	   if (caseCreated) {
		   return new PageReference('/s/Dashboard');
	   }
       return null;
    }
}