trigger PP_TypeTierChange on Account (after update) {
/*
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    Set<String> acctIdList = new Set<String>();
    for (Account acct : Trigger.new) {
        Account old = Trigger.oldMap.get(acct.Id);
        if (acct.IsPartner &&
            (acct.Finder_Partner_Type__c != old.Finder_Partner_Type__c || acct.Finder_Partner_Tier__c != old.Finder_Partner_Tier__c)) {
            acctIdList.add(acct.Id);
        }
    }

    if (acctIdList.size() > 0) {
        PPScoringUtil sutil = new PPScoringUtil();
        Set<String> contactIdList = PartnerUtil.getIdSet([select Id from Contact where Contact.Account.Id in :acctIdList]);
        sutil.updateUserPoints(contactIdList);
        sutil.updateAccountPoints(acctIdList);
    }
*/
}