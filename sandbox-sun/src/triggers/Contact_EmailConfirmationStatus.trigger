trigger Contact_EmailConfirmationStatus on Contact (before update, after update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	if (!ThreadLock.lock('Contact_EmailConfirmationStatus')) {
		return;
	}
	Contact[] expiringContacts = new List<Contact>();
	Contact[] expiredContacts = new List<Contact>();
	for (Contact c : Trigger.new) {
		Contact oldc = Trigger.oldMap.get(c.Id);
		if (c.Email_Confirmation_Status__c == 'Send' && oldc.Email_Confirmation_Status__c != 'Send') {
			expiringContacts.add(c);
		}
		if (c.Email_Confirmation_Status__c == 'Expired' && oldc.Email_Confirmation_Status__c != 'Expired') {
			expiredContacts.add(c);
		}
	}

	if (Trigger.isAfter && expiredContacts.size() > 0) {
		User[] users = [select Id from User where ContactId in :PartnerUtil.getIdSet(expiredContacts)];
		PartnerEmailUtils.deactivateUsers(PartnerUtil.getIdSet(users));
	}

	if (Trigger.isBefore && expiringContacts.size() > 0) {
	    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    	OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];

		User[] users = [select Id, ContactId, Email from User where ContactId in :PartnerUtil.getIdSet(expiringContacts) and IsActive = true];
		Map<ID, User> usermap = new Map<ID, User>();
		for (User u : users) usermap.put(u.ContactId, u);

		PartnerUser_Email_Token__c[] tokens = new List<PartnerUser_Email_Token__c>();
//		EmailTemplate tpl = [select Id from EmailTemplate where DeveloperName = 'OEM_SI_Email_Confirmation'];
		String template = System.Label.OEM_SI_Onboarding_Email_Body;
		for (Contact c : expiringContacts) {
			if (!usermap.containsKey(c.Id)) continue;
			
			User u = usermap.get(c.Id);
			PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
			token.User__c = u.Id;
			token.Email__c = u.Email;
			token.Token__c = PartnerEmailUtils.generateEmailToken(u.Id, token.Email__c);
	        token.Email_Confirmation_URL__c = PartnerEmailUtils.getEmailConfirmationFullURL(token.Token__c);
	        System.debug('*****[debug]***** url=' + token.Email_Confirmation_URL__c);
			tokens.add(token);

	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		    String[] tmp = new List<String>();
		    tmp.add(u.Email);
		    mail.setSubject('Red Hat Partner Center Access Confirmation');
		    String body = template;
		    body = body.replace('{0}', token.Email_Confirmation_URL__c);
		    mail.setHtmlBody(body);
		    mail.setToAddresses(tmp);
	        mail.setReplyTo('noreply@redhat.com');
	        mail.setOrgWideEmailAddressId(owe.id);
	        mail.saveAsActivity = FALSE;

/*
	        mail.setTargetObjectId(u.Id);
	        mail.setTemplateId(tpl.Id);
	        mail.setReplyTo('noreply@redhat.com');
	        mail.setOrgWideEmailAddressId(owe.id);
	        mail.saveAsActivity = FALSE;
	        //mail.setWhatID(u.Id);
*/
	        emails.add(mail);

			c.Email_Confirmation_Status__c = 'Sent';
			c.Email = u.Email;

		}
		insert tokens;
        Messaging.sendEmail(emails);
	}
	

}