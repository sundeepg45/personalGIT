trigger Account_FinancialReview on Account (before update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	/*
	 * for the PAR program...
	 * After registration financial terms are reviewed outside Salesforce, the account manager will check the
	 * is_financials_approved flag. Here we just record some additional audit info
	 */
	for (Account acct : Trigger.new) {
		Account oldacct = Trigger.oldMap.get(acct.Id);
		if (UserInfo.getUserType() == 'Partner' || UserInfo.getUserType() == 'PowerPartner') {
			// don't allow partner users to change this flag
			continue;
		}
		if (acct.Is_Financials_Approved__c == True && oldacct.Is_Financials_Approved__c == False) {
			acct.Financial_Terms_Approve_Date__c = System.now();
			acct.Financial_Terms_Approver__c = UserInfo.getUserId();
		}
	}
}