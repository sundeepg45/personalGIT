trigger PP_CapChangeRecalc on PP_Cap__c (after update, after insert, before delete) {

	if (Trigger.isDelete) {
		for (PP_Cap__c cap : Trigger.old) {
			cap.Name.addError('Partner Points caps cannot be removed');
		}
		return;
	}
	for (PP_Cap__c cap : Trigger.new) {
		String region = cap.Global_Region__c;
		String ptype = cap.Partner_Type__c;
		String ptier = cap.Partner_Tier__c;
		
		Account[] accounts = [select Id from Account where Global_Region__c = :region and Finder_Partner_Type__c = :ptype and Finder_Partner_Tier__c = :ptier];
		Set<String> accountIdList = (Set<String>) PartnerUtil.getIdSet(accounts);
		PP_User_Points__c[] userPointList = [select Contact__c from PP_User_Points__c where Account__c in :accountIdList];
		Set<String> contactIdList = (Set<String>) PartnerUtil.getStringFieldSet(userPointList, 'Contact__c');
		PPScoringUtil sutil = new PPScoringUtil();
		sutil.updateUserPoints(contactIdList);
		sutil.updateAccountPoints(accountIdList);
	}
}