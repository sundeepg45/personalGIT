trigger Lead_AccountSharing on Lead (after insert, after update) {
    // The group related to the All Partners Portal Role and Subordinates
    // Change this value to expand/ restrict visibility to the customer reference


    List<Lead> leads = new List<Lead>();
    if (Trigger.isUpdate) {
    	for (Lead lead : Trigger.new) {
    		if (lead.OwnerId != Trigger.oldMap.get(lead.Id).OwnerId) {
    			// owner changed, add to set
    			leads.add(lead);
    		}
    	}
    }
    else {
    	for (Lead lead : Trigger.new) {
    		leads.add(lead);
    	}
    }
    if (leads.isEmpty()) {
    	return;
    }
    //
    // We only want to enable Lead sharing at the Account level for leads created by partner users.
    // So we have to get the user info first
    //
    Set<Id> userIdList = new Set<Id>();
    for (Lead lead : leads) {
        userIdList.add(lead.OwnerId);
    }
    Map<Id,User> users = new Map<Id,User>([select Id, Contact.Account.isPartner, Contact.Account.OwnerId, Contact.Account.Id from User where Id in :userIdList]);

    Id[] acctIdList = new List<Id>();
    for (User user : users.values()) {
    	if (user.Contact != null && user.Contact.Account.isPartner) acctIdList.add(user.Contact.Account.Id);
    }
    Map<Id,Id> accountIdUserRoleIdMap = SharingUtil.getRoles(acctIdList);
    Map<Id,Id> gmap = SharingUtil.getGroups(accountIdUserRoleIdMap.values());

    List<LeadShare> leadShares = new List<LeadShare>();
    for (Lead lead : leads) {
        if (users.get(lead.OwnerId) == null) continue;
        Contact c = users.get(lead.OwnerId).Contact;
        if (c != null && c.Account.isPartner) {
	        Id roleId = accountIdUserRoleIdMap.get(c.Account.Id);
	        Id groupId = gMap.get(roleId);
	        if (groupId == null) {
	            continue;
	        }
	        leadShares.add(new LeadShare(UserOrGroupId = groupId, LeadId = lead.Id, LeadAccessLevel = 'Edit'));
        }
    }

    if (!leadShares.isEmpty()) {
        insert leadShares;
    }
}