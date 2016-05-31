trigger Lead_ProdOpsCheckAntiCorruption on Lead (before update) {

	for (Lead l : Trigger.new)
	{
		if (l.Channel_Ops_Approved__c && !Trigger.oldMap.get(l.Id).Channel_Ops_Approved__c){
			if (l.AntiCorruption_Review_Channel_Ops__c == '' || l.AntiCorruption_Review_Channel_Ops__c == null){
				l.addError('Please indicate on the field named "AntiCorruption Channel Review" under the "AntiCorruption" section whether you believe this record should be reviewed by legal for Anti Corruption screening.');
			}
		}
	}

}