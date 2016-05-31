/**
 * This is a test class for CampaignTagsBatchable class.
 *
 * @version 2014-04-28
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * 2012-09-26 - created
 * Bill Riemers <briemers@redhat.com>
 * 2014-04-28 - Commented out usage of Offer_Name__c and mkt_cl_cmp_media_name__c
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 */
@isTest
private class CampaignTagsBatchableTest {
	
	static Campaign createCampaign(String name) {
		return new Campaign(
			Name = name,
			mkt_cl_cmp_category__c = 'Cloud',
			StartDate = Date.Today(),
			EndDate = Date.Today() + 10,
			IsActive = TRUE,
//			Offer_Name__c = 'Offer',
//			mkt_cl_cmp_cta__c = 'Tactic',
//			mkt_cl_cmp_media_name__c = 'Awareness',
			Type = 'Banner'		
		);
	}
		
	static CampaignTag createCT(Id item, String tag) {
		return new CampaignTag(
			Name = tag,
			ItemId = item,
			Type = 'Public'			
		);
	}
	
	static testMethod void testBatch1() {
		Campaign c = createCampaign('TestCampaign1');
		Insert c;
		CampaignTag ct = createCT(c.Id, 'TestTag1');		
		Insert ct;
		System.Test.startTest();
		CampaignTagsBatchable obj = new  CampaignTagsBatchable();
		ID batchId = Database.executeBatch(obj);
		System.Test.stopTest();		
	}
	
	static testMethod void testBatch2() {
		Campaign c = createCampaign('TestCampaign1');
		Insert c;
		CampaignTag ct1 = createCT(c.Id, 'TestTag1');		
		Insert ct1;
		List<DateTimeSetting__c> dts = new List<DateTimeSetting__c> ();
		dts = [SELECT Id FROM DateTimeSetting__c];
		if(!dts.isEmpty()) {
			delete dts; 
		}
		System.Test.startTest();
		CampaignTagsBatchable obj = new  CampaignTagsBatchable();
		ID batchId = Database.executeBatch(obj);
		System.Test.stopTest();		
	}
		
	static testMethod void testSendMail() {
		CampaignTagsBatchable obj = new CampaignTagsBatchable();
		obj.errorList.add('test error');
		Test.startTest();
		System.assertNotEquals(null, obj.sendErrors(null));
		Test.stopTest();
	}
}