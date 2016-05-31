/*
* Name : CustomerRefPopulatePartnerDetails
* Author : Rohit Mehta (Apprivo)
* Date : 03192010
* Usage : Sets the Partners/Account/Contact on the Cust ref.
* Also gives Edit access to the partners account owner.
*/
trigger CustomerRefPopulatePartnerDetails on Customer_Reference__c (before insert, after update) {

	Set<Id> ownerIds = new Set<Id>();
	List<Customer_Reference__Share> custRefShares = new List<Customer_Reference__Share>();

	for (Customer_Reference__c custRef : trigger.new) {
		ownerIds.add(custRef.OwnerId);
	}
	
	Map<Id, User> users = new Map<Id, user>([
		select	Id, ContactId, Contact.AccountId, Contact.Account.OwnerId 
		from	User 
		where	id In :ownerIds
		and	ContactId != null
	]);

	if (Trigger.isBefore && Trigger.isInsert) {
		for (Customer_Reference__c custRef : trigger.new) {
			User u = users.get(custRef.OwnerId);
			if (u == null) {
				continue;
			}
			custRef.Account__c = u.Contact.AccountId;
			custRef.Contact__c = u.ContactId;
		}
	}
	else {

		Customer_Reference__c[] approvedRefs = new List<Customer_Reference__c>();
		for (Customer_Reference__c custRef : trigger.new) {
	        if (custRef.Approval_Status__c == 'Accepted' && Trigger.OldMap.get(custRef.Id).Approval_Status__c != 'Accepted') {
	        	approvedRefs.add(custRef);
	        }
		}
		if (!approvedRefs.isEmpty()) {
		
			List<ID> accountIdList = new List<ID>();
			for (User u : users.values()) {
				accountIdList.add(u.Contact.AccountId);
			}
			
		    Map<Id,Id> accountIdUserRoleIdMap = SharingUtil.getRoles(accountIdList);
		    Map<Id,Id> gmap = SharingUtil.getGroups(accountIdUserRoleIdMap.values());
		
			for (Customer_Reference__c custRef : approvedRefs) {
				User u = users.get(custRef.OwnerId);
				if (u == null) {
					continue;
				}
		        Id roleId = accountIdUserRoleIdMap.get(u.Contact.AccountId);
		        Id groupId = gMap.get(roleId);
		        if (groupId == null) {
		            continue;
		        }
	
				custRefShares.add(new Customer_Reference__Share(UserOrGroupId = groupId, 
	//			custRefShares.add(new Customer_Reference__Share(UserOrGroupId = u.Contact.Account.OwnerId, 
					ParentId = custRef.Id,
					AccessLevel = 'Edit',
					RowCause = Schema.Customer_Reference__Share.rowCause.Partner_Account_Owner__c));
			}
			
			if (! custRefShares.isEmpty()) {
				insert custRefShares;
			}
		}
	}
}