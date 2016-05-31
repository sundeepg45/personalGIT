trigger Account_ToLowerCaseAllowedDomains on Account (before insert, before update) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	for (Account a : Trigger.New){
		if (a.AllowedEmailDomains__c != null){
			a.AllowedEmailDomains__c = a.AllowedEmailDomains__c.toLowerCase();
		}
	}
}