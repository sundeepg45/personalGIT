trigger PP_SumTotal_Training on SumTotal_Training__c (after insert, after update) {

	//
	// Not going to treat this as a standard batch because
	// training certification won't happen in batch mode anyhow
    // ie. only 1 record will be committed per transaction here
	//
    
    Map<String,SumTotal_Catalog__c> catmap = new Map<String,SumTotal_Catalog__c>();
    for (SumTotal_Catalog__c cat : [
        select	Id, Language__c, Training_Type__c, Activity_Name__c, Global_Region__c, SumTotal_ID__c
        from	SumTotal_Catalog__c
        where	SumTotal_ID__c in :PartnerUtil.getStringFieldSet(Trigger.new, 'SumTotal_Activity_ID__c')
        and		IsActive__c = true
    ]) {
        catmap.put(cat.SumTotal_ID__c, cat);
    }
    for (Integer i = 0; i < Trigger.new.size(); i++) {
		SumTotal_Training__c item = Trigger.new[i];

        if (!catmap.containsKey(item.SumTotal_Activity_ID__c)) {
            continue;
        }
        SumTotal_Catalog__c catrecord = catmap.get(item.SumTotal_Activity_ID__c);

        User trainee = [select Id, ContactId, AccountId from User where Id = :item.User__c];
        if (trainee.ContactId == null) {
            continue;
        }
        Contact c = [select Id, AccountId, Account.Global_Region__c, Account.IsPartner from Contact where Id = :trainee.ContactId];
        if (!c.Account.IsPartner) {
            continue;
        }

        PP_LMS_Stage__c[] existing = [select Id from PP_LMS_Stage__c where Contact__c = :trainee.ContactId and Course_Id__c = :item.Sumtotal_Activity_ID__c];

        PP_LMS_Stage__c stage = new PP_LMS_Stage__c();
        stage.Contact__c = trainee.ContactId;
        stage.Course_Id__c = catrecord.SumTotal_ID__c;
        stage.Transcript_Item__c = item.Id;
        stage.Language__c = catrecord.Language__c;
        stage.When_Earned__c = item.When_Earned__c;
        stage.Catalog__c = catrecord.Id;
        if (stage.When_Earned__c == null) stage.When_Earned__c = System.now();
        if (catrecord.Activity_Name__c.length() > 80)
            stage.name = catrecord.Activity_Name__c.substring(0, 79);
        else
            stage.name = catrecord.Activity_Name__c;
        stage.Training_Type__c = catrecord.Training_Type__c;
        stage.Global_Region__c = catrecord.Global_Region__c; //c.Account.Global_Region__c;
        insert stage;
    }
    
}