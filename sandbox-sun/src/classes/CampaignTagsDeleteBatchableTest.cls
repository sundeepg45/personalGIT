/**
 * This is a test class for CampaignTagsDeleteBatchable class.
 *
 * @version 2014-04-28
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * 2012-10-01 - created
 * Bill Riemers <briemers@redhat.com>
 * 2014-04-28 - Commented out usage of Offer_Name__c and mkt_cl_cmp_media_name__c
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 */

@isTest
private class CampaignTagsDeleteBatchableTest {
	
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
		
	static CampaignTag createCT(Id item, String tagName) {
		return new CampaignTag(
			Name = tagName,
			ItemId = item,
			Type = 'Public'			
		);
	}
	
	static CampaignTag__c createCT_custom(Id tagId, Id item, String tagName) {
		return new CampaignTag__c(
			Name = tagName,
            Campaign__c = item,
            Campaign_Tag_Id__c = tagId		
		);
	}
	
	static testMethod void testBatch1() {
		Campaign c = createCampaign('TestCampaign1');
		Insert c;
		CampaignTag ct1 = createCT(c.Id, 'TestTag1');		
		Insert ct1;
		CampaignTag ct2 = createCT(c.Id, 'TestTag2');		
		Insert ct2;
		CampaignTag__c ct_custom1 = createCT_custom(ct1.Id, ct1.ItemId, ct1.Name);
		Insert ct_custom1;
		CampaignTag__c ct_custom2 = createCT_custom(ct2.Id, ct2.ItemId, ct2.Name);
		Insert ct_custom2;
		Delete ct2;
		System.Test.startTest();
		CampaignTagsDeleteBatchable obj = new  CampaignTagsDeleteBatchable();
		ID batchId = Database.executeBatch(obj);
		System.Test.stopTest();		
	}
		
	static testMethod void testSendMail() {
		CampaignTagsDeleteBatchable obj = new CampaignTagsDeleteBatchable();
		obj.errorList.add('test error');
		System.Test.startTest();
		System.assertNotEquals(null,  obj.sendErrors(null));
		System.Test.stopTest();
	}
}