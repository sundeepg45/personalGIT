global class RequalificationExtendService {

	WebService static void extendRequalificationDate(String accountId) {
		Account acct = [select id, RequalificationDate__c, Requalification_Extended__c from Account where Id = :accountId];
		if (acct.Requalification_Extended__c) {
			System.debug('Requalification already extended -- skipping');
			return;
		}
		if (acct.RequalificationDate__c != null) {
			acct.Requalification_Extended__c = true;
			acct.RequalificationDate__c = acct.RequalificationDate__c.addMonths(1);
			update acct;
		}
	}
	
}