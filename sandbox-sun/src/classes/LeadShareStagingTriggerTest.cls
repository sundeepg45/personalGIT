@isTest
private class LeadShareStagingTriggerTest {

	static public testmethod void mytest() {
		Lead[] leads = [select Id, OwnerId from Lead limit 10];
		LeadShareStaging__c[] shares = new List<LeadShareStaging__c>();
		for (Lead lead : leads) {
			shares.add(new LeadShareStaging__c(Lead_Id__c = lead.Id));
		}
		insert shares;
	}
}