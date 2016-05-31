trigger SumTotal_UserChangeTrigger on User (after update) {

    private static String[] fields = new String[] { 'Email', 'FirstName', 'LastName', 'LanguageLocaleKey', 'ManagerId', 'Channel_Role__c', 'Region__c' };

    if (System.isFuture()) {
    	// let the non-future trigger call handle it
    	return;
    }
    User[] stdUsers = new List<User>();
    //
    // Make a list of likely CAMs that had a sumtotal ID assigned or changed
    //
    for (User newu : Trigger.new) {
        User oldu = Trigger.oldMap.get(newu.Id);
        System.debug('***** [debug] ***** id=' + newu.Id);
        if (newu.SumTotal_ID__c == null) {
            System.debug('**** [debug] sumtotal_id is null');
            continue;
        }
        System.debug('***** [debug] usertype=' + newu.UserType);
        System.debug('***** [debug] newid=' + newu.SumTotal_ID__c);
        System.debug('***** [debug] oldid=' + oldu.SumTotal_ID__c);
        if (newu.UserType == 'Standard' && newu.SumTotal_ID__c != oldu.SumTotal_ID__c) {
            stdUsers.add(newu);
        }
    }

    ID[] changed = new List<ID>();
    ID[] inactive = new List<ID>();
    ID[] active = new List<ID>();
    for (User newu : Trigger.new) {
	    if (!ThreadLock.lock('SumTotalUserChange' + newu.Id)) {
	        continue;
	    }
        // only act on users already provisioned
        if (newu.SumTotal_Id__c == null) continue;
        User oldu = Trigger.oldMap.get(newu.Id);

        if (newu.IsActive && !oldu.IsActive) {
            active.add(newu.Id);
            continue;
        }
        if (!newu.IsActive && oldu.IsActive) {
            inactive.add(newu.Id);
            continue;
        }
        for (String fieldname : fields) {
            if (newu.get(fieldname) != oldu.get(fieldname)) {
                changed.add(newu.Id);
                break;
            }
        }
    }
    if (!changed.isEmpty()) SumTotal_UpdateUser.doUpdate(changed);
    if (!inactive.isEmpty()) SumTotal_UpdateUser.doInactivate(inactive);
    if (!active.isEmpty()) SumTotal_UpdateUser.doActivate(active);

    //
    // check everyone that is likely a CAM and update everyone they manage if their sumtotal ID changed
    //
    if (!stdUsers.isEmpty()) {
        User[] managed = [select Id from User where Contact.OwnerId in :PartnerUtil.getIdSet(stdUsers) and Contact.Owner.SumTotal_ID__c != null];
        System.debug('***** [debug] managed users = ' + managed.size());
        if (!managed.isEmpty()) {
            ID[] managedIdlist = new List<ID>();
            for (User u : managed) {
                managedIdList.add(u.Id);
            }
            SumTotal_UpdateUser.doUpdate(managedIdList);
        }
    }

}