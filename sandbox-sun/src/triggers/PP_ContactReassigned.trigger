trigger PP_ContactReassigned on Contact (after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	PP_ContactReassignment.reassignContacts();
	/*
    Set<String> contactIdList = new Set<String>();
    Set<String> accountIdList = new Set<String>();
    for (Contact c : Trigger.new) {
        if (c.AccountId != null && c.AccountId != Trigger.oldMap.get(c.Id).AccountId) {
            contactIdList.add(c.Id);
            accountIdList.add(c.AccountId);
        }
    }
    Map<ID,Account> partnermap = new Map<ID,Account>([select Id from Account where Id in :accountIdList and IsPartner = true]);

    if (!partnermap.isEmpty()) {
        String soql = PartnerUtil.getWritableFieldsSOQL('PP_Scores__c', 'Contact__c in :contactIdList and Account__c in :partnermap.keySet()');
        System.debug('++++[debug]++++ soql=' + soql);
        PP_Scores__c[] scores = (PP_Scores__c[]) Database.query(soql);

        PP_Scores__c[] newscores = new List<PP_Scores__c>();

        for (PP_Scores__c up : scores) {
            PP_Scores__c ns = up.clone(false, true);
            ns.Account__c = Trigger.newMap.get(up.Contact__c).AccountId;
            newscores.add(ns);
            System.debug('++++[debug]++++ inserting ' + ns.Points__c);
        }
        if (!newscores.isEmpty()) {
            delete scores;
            delete [select Id from PP_User_Points__c where Contact__c in :contactIdList];
            insert newscores;
        }

    }
    */
}