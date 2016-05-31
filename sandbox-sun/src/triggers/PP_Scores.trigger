trigger PP_Scores on PP_Scores__c (after delete, after undelete, after insert, after update) {

	//
	// After any batch operation on the scores object go ahead and update
	// all user rankings for affected regions.
	//
	
	PP_Scores__c[] scores = null;
	if (Trigger.isDelete) {
		scores = Trigger.old;
	}
	else {
		scores = Trigger.new;
		
	}
	
	System.debug('****[debug]***** batch size is ' + scores.size());

	Account[] accounts = [select Id, Global_Region__c from Account where Id in :PartnerUtil.getStringFieldSet(scores, 'Account__c')];
	Set<String> accountIdList = PartnerUtil.getIdSet(accounts);
	Set<String> contactIdList = PartnerUtil.getStringFieldSet(scores, 'Contact__c');
	
	PPScoringUtil sutil = new PPScoringUtil();
	sutil.updateUserPoints(contactIdList);
	sutil.updateAccountPoints(accountIdList);

}