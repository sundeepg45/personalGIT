trigger Account_HideUnaffiliatedInFinder on Account (before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    for (Account acct : Trigger.new) {
        if (acct.PartnerStatuses__c != null && acct.PartnerStatuses__c.contains('Unaffiliated')) {
            acct.Is_Partner_Published__c = False;
        }
    }
}