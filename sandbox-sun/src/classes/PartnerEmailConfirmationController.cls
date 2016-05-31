public without sharing class PartnerEmailConfirmationController {

	public Integer status { get; set; }

	public void processConfirmation() {
		String tokenParam = ApexPages.currentPage().getParameters().get('token');
		if (tokenParam != null) {
			PartnerUser_Email_Token__c[] tokens = [select Id, User__r.Id, Email__c, Lead__c, Partner_Onboarding__c from PartnerUser_Email_Token__c where Token__c = :tokenParam and Is_Active__c = True];
			if (!tokens.isEmpty()) {
				PartnerUser_Email_Token__c token = tokens[0];
				token.Date_Confirmed__c = Datetime.now();
				//token.Referrer__c = ApexPages.currentPage().getHeaders().get('Referer');

				if (token.Lead__c != null) {
					// automatically onboard the lead
					onboardLead(token.Lead__c);
				}
				else if (token.Partner_Onboarding__c != null) {
					onboardRegistration(token.Partner_Onboarding__c);
				}
				else {
					User u = [select Id, ContactId, IsActive from User where Id = :token.User__r.Id];
					if (!u.IsActive) {
						PartnerEmailUtils.activateUser(u.Id);
					}
					if (u.ContactId != null) {
						Contact c = [select Id from Contact where Id = :u.ContactId];
						c.Email_Confirmation_Date__c = token.Date_Confirmed__c;
						c.Email_Confirmation_Status__c = 'Confirmed';
						update c;
					}
				}
				status = 0;
				token.Is_Active__c = false;
				update token;
			}
			else {
				// nonexistent token
				System.debug('****[debug]**** token not found: ' + tokenParam);
				status = 2;
			}
		}
		else {
			// missing url parameter
			status = 3;
		}
	}

	public void onboardLead(ID leadId) {
		Lead lead = [select Id, Partner_Onboarding_Status__c from Lead where Id = :leadId];
		lead.Partner_Onboarding_Status__c = 'Approved';
		update lead;
	}

	public void onboardRegistration(ID regId) {
		Partner_Onboarding_Registration__c reg = [select Id, Partner_Onboarding_Status__c from Partner_Onboarding_Registration__c where Id = :regId];
		reg.Partner_Onboarding_Status__c = 'Approved';
		update reg;
	}

	static public testmethod void mytest() {
		PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
		token.User__c = UserInfo.getUserId();
		token.Email__c = 'masmith@null.com';
		token.Token__c = PartnerEmailUtils.generateEmailToken(UserInfo.getUserId(), token.Email__c);
		insert token;

		System.debug('*****[debug]***** token=' + token.Token__c);

		PartnerEmailConfirmationController ctrl = new PartnerEmailConfirmationController();
		ApexPages.currentPage().getParameters().put('token', token.Token__c);
		ctrl.processConfirmation();

		token = [select Id, Date_Confirmed__c from PartnerUser_Email_Token__c where Id = :token.Id];
		System.assert(token.Date_Confirmed__c != null);
	}
}