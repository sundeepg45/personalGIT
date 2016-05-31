/**
 * This is the test class for CampaignHierarchy.cls
 *
 * @version 2013-05-15
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-02-07 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-05-15 - Depreciated
 */
@isTest
private class CampaignHierarchyTest {

//	static Campaign campaignA, campaignA_1, campaignA_2, campaignA_3, campaignA_1_1, campaignA_1_2, 
//		campaignA_1_3, campaignA_2_1, campaignA_2_2, campaignA_2_3, campaignB, campaignB_1;

//	static Set<Id> campaignIds {
//		get {
//			if(campaignIds == null) {
//				campaignA = CampaignTriggerBeforeTest.createCampaign('campaignA@test.test');
//				insert campaignA;
//				campaignA_1 = campaignA.Clone();
//				campaignA_2 = campaignA.Clone();
//				campaignA_3 = campaignA.Clone();
//				campaignA_1.ParentId = campaignA_2.ParentId = campaignA_3.ParentId = campaignA.Id;
//				insert new List<Campaign>{campaignA_1, campaignA_2, campaignA_3};
//				campaignA_1_1 = campaignA.Clone();
//				campaignA_1_2 = campaignA.Clone();
//				campaignA_1_3 = campaignA.Clone();
//				campaignA_1_1.ParentId = campaignA_1_2.ParentId = campaignA_1_3.ParentId = campaignA_1.Id;
//				insert new List<Campaign>{campaignA_1_1, campaignA_1_2, campaignA_1_3};
//				campaignA_2_1 = campaignA.Clone();
//				campaignA_2_2 = campaignA.Clone();
//				campaignA_2_3 = campaignA.Clone();
//				campaignA_2_1.ParentId = campaignA_2_2.ParentId = campaignA_2_3.ParentId = campaignA_2.Id;
//				insert new List<Campaign>{campaignA_2_1, campaignA_2_2, campaignA_2_3};
//				Campaign campaignA_3_1 = campaignA.Clone();
//				Campaign campaignA_3_2 = campaignA.Clone();
//				Campaign campaignA_3_3 = campaignA.Clone();
//				campaignA_3_1.ParentId = campaignA_3_2.ParentId = campaignA_3_3.ParentId = campaignA_3.Id;
//				insert new List<Campaign>{campaignA_3_1, campaignA_3_2, campaignA_3_3};
//				/*Campaign campaignA_1_1_1 = campaignA.Clone();
//				Campaign campaignA_1_1_2 = campaignA.Clone();
//				Campaign campaignA_1_1_3 = campaignA.Clone();
//				campaignA_1_1_1.ParentId = campaignA_1_1_2.ParentId = campaignA_1_1_3.ParentId = campaignA_1_1.Id;
//				insert new List<Campaign>{campaignA_1_1_1, campaignA_1_1_2, campaignA_1_1_3};*/
//				/*Campaign campaignA_1_1_1_1 = campaignA.Clone();
//				Campaign campaignA_1_1_1_2 = campaignA.Clone();
//				Campaign campaignA_1_1_1_3 = campaignA.Clone();
//				campaignA_1_1_1_1.ParentId = campaignA_1_1_1_2.ParentId = campaignA_1_1_1_3.ParentId = campaignA_1_1_1.Id;
//				insert new List<Campaign>{campaignA_1_1_1_1, campaignA_1_1_1_2, campaignA_1_1_1_3};*/
//				campaignB = CampaignTriggerBeforeTest.createCampaign('campaignB@test.test');
//				insert campaignB;
//				campaignB_1 = campaignB.Clone();
//				campaignB_1.ParentId = campaignB.Id;
//				insert campaignB_1;
//				campaignIds = new Set<Id>{campaignA_2_1.Id,campaignA_1.Id,campaignB_1.Id};
//			}
//			return campaignIds;
//		}
//	}

//	@isTest
//	static void testCampaignHierarchy() {
//		Set<Id> ids = campaignIds;
//		Test.startTest();
//		//test constructor
//		CampaignHierarchy hierarchy = new CampaignHierarchy(ids);
//		//test get of parent campaign
//		Campaign parentCampaign = hierarchy.getParentCampaign(campaignA_2_2.Id);
//		System.assertEquals(campaignA_2.Id, parentCampaign.Id);
//		//test get of child campaigns
//		List<Campaign> childCampaigns = hierarchy.getChildCampaigns(campaignB.Id);
//		System.assertEquals(1,childCampaigns.size());
//		System.assertEquals(campaignB_1.Id,childCampaigns[0].Id);
//		childCampaigns = hierarchy.getChildCampaigns(campaignA_2.Id);
//		System.assertEquals(3,childCampaigns.size());
//		childCampaigns = hierarchy.getChildCampaigns(campaignA.Id);
//		System.assertEquals(12,childCampaigns.size());
//		List<Campaign_Hierarchy_Details__c> childDetails = hierarchy.getHierarchyDetails(campaignA.Id);
//		System.assertEquals(13,childDetails.size());
//		Campaign_Hierarchy_Details__c details1 = hierarchy.putHierarchyDetails(campaignA_2_3.Id, campaignB.Id, 2);
//		Campaign_Hierarchy_Details__c details2 = hierarchy.getHierarchyDetails(campaignA_2_3.Id, campaignB.Id);
//		List<Campaign_Hierarchy_Details__c> upsertList = hierarchy.upsertList;
//		System.assertEquals(2,details1.Expected_Number_of_Responses__c);
//		System.assertEquals(campaignA_2_3.Id + '.' + campaignB.Id, details1.External_ID__c);
//		System.assertEquals(2,details2.Expected_Number_of_Responses__c);
//		System.assertEquals(1,upsertList.size());
//		Campaign_Hierarchy_Details__c details3 = hierarchy.removeHierarchyDetails(campaignA.Id, campaignA_3.Id);
//		List<Campaign_Hierarchy_Details__c> deleteList = hierarchy.deleteList;
//		System.assertEquals(1,deleteList.size());
//		Test.stopTest(); 
//	}
}