/**
 * Test class created for CampaignTriggerBefore class.
 *
 * @version 2014-07-15
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-07-15 - updated for campaign tracking id url update
 * 2014-06-02 - Only run assignName after an update
 * 2014-05-28 - Commented out usage of mkt_cl_cmp_media_name__c
 * 2014-05-27 - Further updates for campaign names
 * 2014-05-02 - Updated for new campaign names
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 * 2013-05-14 - Removed the maintain hierarchy test method
 * 2012-12-11 - Updated to allow other classes to construct the campaign from this class
 * 2012-12-11 - Modified so most tests do not require all data access
 * 2012-04-18 - Update for Security Model Redesign
 * Scott Coleman <scoleman@redhat.com>
 * 2014-06-19 - Update to explcitly set record type in assignUrlTest()
 * 2014-06-10 - Fix case of offer_id querystring parameter in tracking campaign url (US49842). 
 * 2014-05-23 - Derive tracking url on insert as well as update (US38535). New URL format for Onpage Promo and Offers (US43864).
 * 2013-05-17 - Added test for assignActive()
 * 2013-05-17 - Updated rules in assignStatus() 
 * 2013-01-29 - Implement test for maintenance of hierarchy data that supports custom rollups
 * 2013-01-24 - Implement tests for new naming convention for Parent Campaign, Offer, Tactic
 */
@isTest
public class CampaignTriggerBeforeTest {
	static final String mkt_cl_cmp_category = 'GLS';
	static final String mkt_cl_parent_campaign_name = 'Parent1';

	static User salesUser {
		get {
			if(salesUser == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				salesUser = [
					select Email from User 
					where profileId = :salesUserProfileTesting.Id__c
						and IsActive = true 
					limit 1 ];
				salesUser.Email += '.testing';
				update salesUser;
			}
			return salesUser;
		}
	}

	public static Campaign createCampaign(String email) {
		return createCampaign(email,null);
	}

	public static Campaign createCampaign(String email,Id dummyId) {
		Id userId = UserInfo.getUserId();
		if(email == null) {
			email = [select Email from User where Id=:userId ].Email;
		}
		return new Campaign(
			Id=dummyId,
			Type='Onsite Promo',
			mkt_cl_cmp_ad_name__c ='Acn',
			mkt_cl_parent_campaign_name__c=mkt_cl_cmp_category+'_'+mkt_cl_parent_campaign_name,
//			mkt_cl_cmp_media_name__c='Star',
			mkt_cl_cmp_owner__c=email,
			mkt_cl_cmp_is_internal__c=true,
			mkt_cl_cmp_audience__c='VP',
			mkt_cl_cmp_director__c='Emma Battle',
			mkt_cl_cmp_category__c = 'Anything',
			mkt_cl_cmp_vertical__c = 'Manufacturing',
			Campaign_Partner__c = 'OEM',
			mkt_cl_cmp_geo__c='NA',
//			mkt_cl_cmp_cta__c='Renew',
			mkt_cl_cmp_product_group__c= 'Multiple',
			Origin__c= 'Sales',
			Media_Source__c='CNET',
			Landing_Page_URL__c= 'http://Sf.com',
			Notes_for_Sales__c = 'Text',
			Description = 'Text',
			Status = 'Plannned',
			IsActive = false,
			StartDate = Date.Today(),
			EndDate = Date.Today()+1,
			OwnerId = userId,
			Solution_Code__c = 'SC',
			Title__c = 'Title',
			Expected_Number_of_Responses__c = 1,
			Name = 'Name');
	}

	static Campaign campaign {
		get {
			if(campaign == null) {
				campaign = createCampaign(null);
			}
			return campaign;
		}
		set;
	}

	static CampaignTriggerBefore insertCTB {
		get {
			if(insertCTB == null) {
				insertCTB = new CampaignTriggerBefore(null,new List<Campaign>{campaign});
			}
			return insertCTB;
		}
		set;
	}

	static CampaignTriggerBefore updateCTB {
		get {
			if(updateCTB == null) {
				updateCTB = new CampaignTriggerBefore(new Map<Id,Campaign>{null=>campaign},new List<Campaign>{campaign});
			}
			return updateCTB;
		}
		set;
	}

	@isTest
	static void assignInitiativeTest() {
		insertCTB.assignInitiative();
		System.assertEquals(mkt_cl_cmp_category,campaign.mkt_cl_cmp_category__c);
		System.assertEquals(mkt_cl_parent_campaign_name,campaign.mkt_cl_parent_campaign_name__c);
	}

	@isTest
	static void assignNameTest() {
		List<RecordType> recordTypes = [SELECT Id, DeveloperName from RecordType where SObjectType = 'Campaign'];
		for (RecordType rt : recordTypes) {
			campaign.RecordTypeId = rt.Id;
			updateCTB = null;
			updateCTB.assignName();
			System.assertEquals('_Onsite Promo_Title',campaign.Name);
		}
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void assignOwnerTest() {
		campaign = createCampaign(salesUser.Email);
		insertCTB.assignOwner();
		if(insertCTB.users.size() == 1) {
			System.assertEquals(salesUser.Id,campaign.OwnerId);
		}

		campaign.OwnerId = salesUser.Id;
		updateCTB.assignOwner();
		System.assertEquals(salesUser.Id, campaign.OwnerId);
		System.assertEquals(salesUser.email, campaign.mkt_cl_cmp_owner__c);
		campaign.OwnerId = UserInfo.getUserId();
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void assignOwnerEmailTest() {
		campaign = createCampaign(salesUser.Email);
		insertCTB.assignOwnerEmail();
		System.assertEquals([select Email from User where Id = :UserInfo.getUserId()].Email, campaign.mkt_cl_cmp_owner__c);
	}

	@isTest
	static void assignStatusTest() {
		insertCTB.assignStatus();
		System.assertEquals('In Progress',campaign.Status);
		campaign.StartDate = Date.Today()+1;
		insertCTB.assignStatus();
		System.assertEquals('Planned',campaign.Status);
		campaign.StartDate = Date.Today()-2;
		campaign.EndDate = Date.Today()-1;
		insertCTB.assignStatus();
		System.assertEquals('Completed',campaign.Status);
	}

	@isTest
	static void assignUrlTest() {
		RecordType campaignRecordType = [SELECT Id, DeveloperName from RecordType where SObjectType = 'Campaign' and DeveloperName = :CampaignTriggerBefore.RECORD_TYPE_CAMPAIGN LIMIT 1];
		campaign.RecordTypeId = campaignRecordType.Id;
		Campaign c = createCampaign(null,'701000000000000AAA');
		c.RecordTypeId = campaign.RecordTypeId;
		CampaignTriggerBefore insertCTB2 = new CampaignTriggerBefore(null,new List<Campaign>{c});
		insertCTB.assignUrls();
		System.assertEquals('http://Sf.com',campaign.Tracking_Campaign_Id_URL__c);
		c.Type = campaign.Type;
		c.Tracking_Campaign_ID_URL__c = campaign.Tracking_Campaign_Id_URL__c;
		insertCTB2.assignUrls(true);
		System.assertEquals('http://Sf.com?sc_cid='+c.Id,c.Tracking_Campaign_Id_URL__c);
		campaign.Tracking_Campaign_ID_URL__c = null;
		campaign.Type = 'Homepage Promo';
		insertCTB.assignUrls();
		System.assertEquals('http://Sf.com',campaign.Tracking_Campaign_Id_URL__c);
		c.Type = campaign.Type;
		c.Tracking_Campaign_ID_URL__c = campaign.Tracking_Campaign_Id_URL__c;
		insertCTB2.assignUrls(true);
		System.assertEquals('http://Sf.com?intcmp='+c.Id,c.Tracking_Campaign_Id_URL__c);
		campaign.Tracking_Campaign_ID_URL__c = null;
		campaign.Type = 'Onpage Promo';
		insertCTB.assignUrls();
		System.assertEquals('http://Sf.com',campaign.Tracking_Campaign_Id_URL__c);		
		c.Type = campaign.Type;
		c.Tracking_Campaign_ID_URL__c = campaign.Tracking_Campaign_Id_URL__c;
		insertCTB2.assignUrls(true);
		System.assertEquals('http://Sf.com?intcmp='+c.Id,c.Tracking_Campaign_Id_URL__c);		
		campaign.Tracking_Campaign_ID_URL__c = null;
		campaign.Type = 'Anything Else';
		insertCTB.assignUrls();
		System.assertEquals('http://Sf.com',campaign.Tracking_Campaign_Id_URL__c);
		c.Type = campaign.Type;
		c.Tracking_Campaign_ID_URL__c = campaign.Tracking_Campaign_Id_URL__c;
		insertCTB2.assignUrls(true);
		System.assertEquals('http://Sf.com?sc_cid='+c.Id,c.Tracking_Campaign_Id_URL__c);
		campaign.Landing_Page_URL__c= 'http:';
		updateCTB.assignUrls();
		System.assertEquals('',campaign.Tracking_Campaign_Id_URL__c);
		campaign.RecordTypeId = CampaignTriggerBefore.offerRecordTypeId;
		campaign.Tracking_Campaign_ID_URL__c = null;
		updateCTB.assignUrls();
		System.assertEquals('http://www.redhat.com/forms/',campaign.Tracking_Campaign_Id_URL__c);
		c.RecordTypeId = campaign.RecordTypeId;
		c.Type = campaign.Type;
		c.Tracking_Campaign_ID_URL__c = campaign.Tracking_Campaign_Id_URL__c;
		insertCTB2.assignUrls(true);
		System.assertEquals('http://www.redhat.com/forms/?offer_id='+c.Id,c.Tracking_Campaign_Id_URL__c);
	}

	@isTest
	static void assignLegacyTest() {
		AbstractTriggerTest.assignLegacyTest(insertCTB);
	}

//	@isTest
//	static void testMaintainHierarchyData() {
//		AbstractTrigger.setBooleanSettings(CampaignTriggerBefore.MAINTAIN_HIERARCHY_DATA_SETTING,true);
//		AbstractTrigger.setBooleanSettings(CampaignTriggerAfter.MAINTAIN_HIERARCHY_DATA_SETTING,true);
//		Campaign campaign1 = createCampaign('test@test.test');
//		insert campaign1;
//		Campaign campaign2 = createCampaign('test@test.test');
//		campaign2.ParentId = campaign1.Id;
//		insert campaign2;
//		Campaign campaign3 = createCampaign('test@test.test');
//		campaign3.ParentId = campaign2.Id;
//		insert campaign3;
//		System.assertEquals(3,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign1.Id]);
//		System.assertEquals(2,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign2.Id]);
//		Id campaign2Id = campaign2.Id;
//		delete campaign2;
//		System.assertEquals(1,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign1.Id]);
//		System.assertEquals(0,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign2Id]);
//	}

	@isTest
	static void assignActiveTest() {
		insertCTB.assignActive();
		System.assert(campaign.IsActive);
	}


	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('Campaign_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		campaign = createCampaign(salesUser.Email);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Campaign_Before.',true);
		// insert test
		CampaignTriggerBefore.processTrigger(null,new List<Campaign>{campaign});
		// update test
		CampaignTriggerBefore.processTrigger(new Map<Id,Campaign>{null=>campaign},new List<Campaign>{campaign});
		// delete test
		CampaignTriggerBefore.processTrigger(new Map<Id,Campaign>{null=>campaign},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Campaign_Before.');
//		System.assertEquals('http://Sf.com?sc_cid=null',campaign.Tracking_Campaign_Id_URL__c);
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		campaign = createCampaign(salesUser.Email);
		AbstractTriggerTest.deployTest('Campaign_Before.',new List<Campaign>{campaign});
	}
}