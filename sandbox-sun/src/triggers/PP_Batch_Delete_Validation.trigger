trigger  PP_Batch_Delete_Validation on PP_Batch__c (before delete) {
	User me = [select Region__c, Global_Partner_Points_Admin__c from User where Id = :UserInfo.getUserId()];

    for (PP_Batch__c batch : Trigger.old) {
    	if (me.Global_Partner_Points_Admin__c == false && batch.Region__c != me.Region__c) {
            batch.Name.addError('You cannot delete a Batch outside of your region');
    	}
    	else {
	        integer cnt = [select count() from PP_InboundBatchStage__c where Batch__c = :batch.id];
	        if (cnt > 0){
	            batch.Name.addError('You cannot delete a Batch with associated scores');
	        }
    	}
    }
}