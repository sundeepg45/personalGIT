/**
 * This is a test class for CampaignStatus_Batchable
 *
 * @version 2014-04-28
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-05-17 - created
 * 2013-06-19 - updated to specify record type of test campaign
 * Bill Riemers <briemers@redhat.com>
 * 2014-04-28 - Commented out usage of Offer_Name__c and mkt_cl_cmp_media_name__c
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 */
@isTest
private class CampaignStatus_BatchableTest {

	static Campaign createCampaign(String name) {
		RecordType parentCampaignType = [select Id from RecordType where SObjectType = 'Campaign' and DeveloperName ='Parent_Campaign' limit 1];
		return new Campaign(
			Name = name,
			mkt_cl_cmp_category__c = 'Cloud',
			StartDate = Date.Today() - 5,
			EndDate = Date.Today() + 10,
			IsActive = TRUE,
			Status = 'Planned',
//			Offer_Name__c = 'Offer',
//			mkt_cl_cmp_cta__c = 'Tactic',
//			mkt_cl_cmp_media_name__c = 'Awareness',
			Type = 'Banner',
			RecordTypeId = parentCampaignType.Id,
			Owner = [select Id, IsActive from User where Id = :UserInfo.getUserId() limit 1]
		);
	}

	@isTest
	static void startTest() {
		Campaign campaign = createCampaign('test');
		insert new BooleanSetting__c(
			Name=CampaignTriggerBefore.ASSIGN_STATUS_SETTING,
			Value__c = false);
		insert campaign;
		CampaignStatus_Batchable batchable = new CampaignStatus_Batchable();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Campaign> campaigns = ssc.getRecords();
		System.assertEquals(1,campaigns.size());
		System.assertEquals(campaign.Id,campaigns[0].Id);
	}

	@isTest
	static void executeTest() {
		Campaign campaign = createCampaign('test');
		AbstractTrigger.setBooleanSettings(CampaignTriggerBefore.ASSIGN_STATUS_SETTING,false);
		insert campaign;
		AbstractTrigger.setBooleanSettings(CampaignTriggerBefore.ASSIGN_STATUS_SETTING,true);
		CampaignStatus_Batchable batchable = new CampaignStatus_Batchable();
		Test.startTest();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		List<Campaign> campaigns = ssc.getRecords();
		System.assertEquals(1,campaigns.size());
		System.assertEquals(campaign.Id,campaigns[0].Id);
		batchable.execute(null,campaigns);
		System.assert(batchable.errorList.isEmpty());
		ssc = new ApexPages.StandardSetController(batchable.start(null));
		ssc.setPageSize(100);
		campaigns = ssc.getRecords();
		System.assertEquals(0,campaigns.size());
	}

	@isTest
	static void finishTest() {
		CampaignStatus_Batchable batchable = new CampaignStatus_Batchable();
		Test.startTest();
		try {
			batchable.finish((Database.BatchableContext)null);
		}
		catch(Exception e) {}
		Test.stopTest();
	}

	@isTest
	static void sendErrorsTest() {
		CampaignStatus_Batchable batchable = new CampaignStatus_Batchable();
		batchable.errorList.add('anything');
		Test.startTest();
		System.assertNotEquals(null,batchable.sendErrors(null));
		Test.stopTest();
	}
}