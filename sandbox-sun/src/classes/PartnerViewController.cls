public with sharing class PartnerViewController {

    public PartnerViewController(ApexPages.StandardController stdController) {
 		Account acct = (Account)stdController.getRecord();
 		acct = [select Id, IsPartner from Account where Id = :acct.Id];
		/**
		 * Enforce that account details are visible only by its own users.
		 * Story US37736 - mls 2/2014
		 */
		 if (acct.IsPartner) {
			User me = [select Id, IsPortalEnabled, ContactId from User where Id = :UserInfo.getUserId()];
			if (me.ContactId != null) {
				Contact[] acctcontacts = [select Id from Contact where AccountId = :acct.Id and Id = :me.ContactId];
				if (acctcontacts.size() == 0) {
					throw new NoAccessException();
				}
			}
		 }
    }
}