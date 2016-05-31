trigger TeamingAgreement_AddSalesRepToAccountTeam on Teaming_Agreement__c (after insert, after undelete, after update) {
	Map<Id,Set<Id>> accountSalesUserMap = new Map<Id,Set<Id>>();
	if (Trigger.isInsert){
		for (Teaming_Agreement__c ta : Trigger.new){
			Set<Id> teamSet = new Set<Id>();
			// Check for set
			if (ta.Red_Hat_Sales_Rep__c != null){
				teamSet.add(ta.Red_Hat_Sales_Rep__c);
			}
			if (ta.Regional_Sales_Manager__c != null){
				teamSet.add(ta.Regional_Sales_Manager__c);
			}
			if (teamSet.size() > 0){
				accountSalesUserMap.put(ta.Partner_Name__c,teamSet);
			}
		}
	} else {
		for (Teaming_Agreement__c ta : Trigger.new){
			Set<Id> teamSet = new Set<Id>();
			// Check for set and changed
			if (ta.Red_Hat_Sales_Rep__c != null && Trigger.oldMap.get(ta.Id).Red_Hat_Sales_Rep__c != ta.Red_Hat_Sales_Rep__c){
				teamSet.add(ta.Red_Hat_Sales_Rep__c);
			}
			if (ta.Regional_Sales_Manager__c != null && Trigger.oldMap.get(ta.Id).Regional_Sales_Manager__c != ta.Regional_Sales_Manager__c){
				teamSet.add(ta.Regional_Sales_Manager__c);
			}
			if (teamSet.size() > 0){
				accountSalesUserMap.put(ta.Partner_Name__c,teamSet);
			}
		}
	}
	if (accountSalesUserMap.size() > 0){
		List<AccountTeamMember> acctMemberList = [select Id, AccountId, UserId from AccountTeamMember where AccountId in :accountSalesUserMap.keySet()];
		
		Set<String> existingRules = new Set<String>();
		for (AccountTeamMember atm : acctMemberList){
			// Remove any recocords that already exist
			if (accountSalesUserMap.containsKey(atm.AccountId)){
				Set<Id> teamSet = accountSalesUserMap.get(atm.AccountId);
				teamSet.remove(atm.userId);
				if (teamSet.size() == 0){
					accountSalesUserMap.remove(atm.AccountId);
				}
			}
		}
		
		if (accountSalesUserMap.size() > 0){
			acctMemberList = new List<AccountTeamMember>();
			List<AccountShare> acctShareList = new List<AccountShare>();
			for (Id acctId : accountSalesUserMap.keySet()){
				for (Id userId : accountSalesUserMap.get(acctId)){
					acctMemberList.add(new AccountTeamMember(
						AccountId = acctId, 
						UserId = userId, 
						TeamMemberRole = 'Inside Rep')
					);
	                acctShareList.add(new AccountShare(
	                    AccountId = acctId,
	                    UserOrGroupId = userId,
	                    AccountAccessLevel = 'Read',
	                    CaseAccessLevel = 'None',
	                    OpportunityAccessLevel = 'None'
	                ));
				}
			}
			insert acctMemberList;
			insert acctShareList;
		}
	}
}