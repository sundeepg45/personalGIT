trigger PP_UserPointsRecalculate on PP_User_Points__c (after update) {

	//
	// This trigger only recalculates user points when the point record status changes
	// All other changes are ignore.
	//
	Set<String> contactIdList = new Set<String>();
	Set<String> accountIdList = new Set<String>();
	for (PP_User_Points__c point : Trigger.new) {
		if (point.IsActive__c != Trigger.oldMap.get(point.Id).IsActive__c) {
			contactIdList.add(point.Contact__c);
			accountIdList.add(point.Account__c);
		}
	}
	if (!contactIdList.isEmpty()) {
		PPScoringUtil sutil = new PPScoringUtil();
		sutil.updateUserPoints(contactIdList);
		sutil.updateAccountPoints(accountIdList);
	}
}