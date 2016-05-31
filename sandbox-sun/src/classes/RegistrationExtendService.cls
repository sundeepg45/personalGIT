global class RegistrationExtendService {

	WebService static void extendExpiration(String regId) {
		Partner_Registration__c reg = [
			select	Id, Expiration_Extended__c, Expiration_Date__c
			from	Partner_Registration__c
			where	Id = :regId
		];
		User me = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
		if (me.Contact.AccountId != null) {
			// partner user, don't allow
			return;
		}
		if (reg.Expiration_Extended__c) {
			System.debug('expiration already extended -- skipping');
			return;
		}
		if (reg.Expiration_Date__c != null) {
			reg.Expiration_Extended__c = true;
			reg.Expiration_Date__c = reg.Expiration_Date__c.addDays(270);
			update reg;
		}
	}
	
}