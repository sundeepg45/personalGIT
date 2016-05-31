trigger SumTotal_UpdateAccount on Account (after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	ID[] changed = new List<ID>();
    for (Account acct : Trigger.new) {
        Account old = Trigger.oldmap.get(acct.Id);
        //
        // these are the only fields we care about updating in SumTotal
        //
        if (acct.Name != old.Name ||
            acct.Finder_Partner_Type_Name__c != old.Finder_Partner_Type_Name__c ||
            acct.Finder_Partner_Tier_Name__c != old.Finder_Partner_Tier_Name__c ||
            acct.ShippingCountry != old.ShippingCountry ||
            acct.BillingCountry != old.BillingCountry ||
            acct.Global_Region__c != old.Global_Region__c ||
            acct.Subregion__c != old.Subregion__c)
        {
            changed.add(acct.Id);
        }
    }
    
    if (!changed.isEmpty()) {
        User[] userlist = [
            select	Id
            from	User
            where	SumTotal_ID__c != null
            and		Contact.AccountId in :changed
            and		IsActive = True
        ];
        ID[] idlist = new List<ID>();
        for (User u : userlist) idlist.add(u.Id);
        STConnector.enqueue(idlist, STConnector.ACTION_UPDATE_USER);
    }
}