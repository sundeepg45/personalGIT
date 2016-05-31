/*
 * When a contact is removed we need to remove related scores and ranking.
 */

trigger PP_ContactDeleted on Contact (before delete, after undelete) {
	if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

	Set<String> idlist = new Set<String>();
	Set<String> accountIdList = new Set<String>();
	Contact[] theList = Trigger.old;
	if (theList == null) theList = Trigger.new;

	for (Contact c : theList) {
		idlist.add(c.Id);
		accountIdList.add(c.AccountId);
	}

	PPScoringUtil sutil = new PPScoringUtil();

	//
	// Take extreme care changing the following. Everything here is part of a brittle chain of triggers and method calls
	// that perform recalculations of points.  It is very touchy.
	//
	
	if (Trigger.isDelete) {
		PP_User_Points__c[] rankings = [select Id from PP_User_Points__c where Contact__c in :idlist];
		if (!rankings.isEmpty()) {
			for (PP_User_Points__c ranking : rankings) {
				ranking.IsActive__c = false;
			}
			update rankings;
			sutil.updateAccountPoints(accountIdList);
		}

	}
	if (Trigger.isUnDelete) {
		PP_User_Points__c[] rankings = [select Id from PP_User_Points__c where Contact__c in :idlist];
		if (!rankings.isEmpty()) {
			for (PP_User_Points__c ranking : rankings) {
				ranking.IsActive__c = true;
			}
			update rankings;
		}
		sutil.updateUserPoints(idList);
		sutil.updateAccountPoints(accountIdList);
	}
	
}