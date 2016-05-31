trigger PP_LMSStageScore on PP_LMS_Stage__c (after insert) {

	Map<ID,Contact> contacts = new Map<ID,Contact>([
		select	Id, Point_Accrual_Start__c, Account.Global_Region__c, Account.IsPartner
		from	Contact
		where	Id in :PartnerUtil.getStringFieldSet(Trigger.new, 'Contact__c')
	]);

	Contact[] toupdate = new List<Contact>();
	for (PP_LMS_Stage__c item : Trigger.new) {
		for (Contact c : contacts.values()) {
			if (c.Id != item.Contact__c) {
				continue;
			}
			System.debug('*****[debug]***** contactid=' + c.Id);
			System.debug('*****[debug]***** accrual_start=' + c.Point_Accrual_start__c);
			if (c.Point_Accrual_Start__c == null) {
				String courseIds = PPScoringUtil.getRequiredCourseIds(c.Account.Global_Region__c);
				System.debug('*****[debug]***** courseIds=' + courseIds);
				if (courseIds == null || courseIds.length() == 0 || courseIds.indexOf(item.Course_Id__c) != -1) {
					c.Point_Accrual_Start__c = item.When_Earned__c;
					toupdate.add(c);
				}
			}
			break;
		}
	}
	//
	// update contacts who took the required course
	//
	if (!toupdate.isEmpty()) {
		update toupdate;
	}

	PPLMSPlugin plugin = new PPLMSPlugin();
		
	PP_Scores__c[] existing = [
		select	Id, LMS_Ref__c
		from	PP_Scores__c
		where	LMS_Ref__c in :PartnerUtil.getIdSet(Trigger.new)
	];
	
	for (PP_LMS_Stage__c stage : Trigger.new) {
		if (stage.Scorable__c == false) {
			continue;
		}
		Contact contact = contacts.get(stage.Contact__c);
		if (contact.Point_Accrual_Start__c == null || contact.Point_Accrual_Start__c > stage.When_Earned__c) {
	       	continue;
       	}

		PP_Scores__c[] to_remove = new List<PP_Scores__c>();
		for (PP_Scores__c score : existing) {
			if (score.LMS_Ref__c == stage.Id) {
				to_remove.add(score);
			}
		}
		if (to_remove.size() > 0) {
			delete to_remove;
		}

		plugin.scoreObject(contacts.get(stage.Contact__c), stage.Id);
	}
}