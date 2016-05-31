trigger User_EmailDomainCheck on User (before update) {

	//
	// Build list of users who changed email address
	//
	User[] userlist = new List<User>();
	for (User u : Trigger.new) {
		User oldu = Trigger.oldMap.get(u.Id);
		if (u.Email != oldu.Email) {
			userlist.add(u);
		}
	}

	if (userlist.isEmpty()) {
		return;
	}

	Contact[] contactlist = [select Id, AccountId from Contact where Id in :PartnerUtil.getStringFieldSet(userlist, 'ContactId')];
	Set<String> accountidlist = PartnerUtil.getStringFieldSet(contactlist, 'AccountId');
	if (accountidlist.size() == 0) {
		System.debug('*****[debug]***** accountidlist is EMPTY');
	}

	//ID oemId = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.OEM').ObjectId__c;
	//ID siId = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SI').ObjectId__c;
	//System.assert(oemId != null, 'oemId is NULL');
	//System.assert(siId != null, 'siId is NULL');

	//
	// Get user accounts that are of type OEM or SI
	//
	Map<ID, Account> accountMap = new Map<ID, Account>([
		select	Id, AllowedEmailDomains__c
		from	Account
		where	Id in :accountidlist
		and		AllowedEmailDomains__c != null
		//and		(Finder_Partner_Type__c = :oemId
		//or		Finder_Partner_Type__c = :siId)
	]);

	for (User u : userlist) {
		Account acct = accountMap.get(u.AccountId);
		if (acct != null) {
			// it is an OEM or SI User - verify email domain
			String[] domains = acct.AllowedEmailDomains__c.split(';');
			boolean pass = false;
			for (String domain : domains) {
				domain = domain.trim();
				if (u.Email.endsWith(domain)) {
					pass = true;
				}
			}
			if (!pass) {
				u.addError(System.Label.OEM_SI_Email_Change_Error + ': ' + u.Email);
			}
			else {
				//
				// For email changes always reset email notice count to 0
				//
				u.Compliant_Email_Notices__c = 0;
			}
		}
	}
}