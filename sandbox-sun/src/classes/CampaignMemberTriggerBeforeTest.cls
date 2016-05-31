/**
 * This class contains unit tests for CampaignMemberTriggerBefore
 *
 * @version 2014-04-28
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-04-30 - created
 * Bill Riemers <briemers@redhat.com>
 * 2014-04-28 - Commented out usage of mkt_cl_cmp_media_name__c
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 * 2014-04-19 - Fixed broken tests.  I can't see how this ever worked.
 */
@isTest
private class CampaignMemberTriggerBeforeTest {

	static Campaign createCampaign(String email) {
		Id userId = UserInfo.getUserId();
		if(email == null) {
			email = [select Email from User where Id=:userId ].Email;
		}
		return new Campaign(
			Type='Onsite Promo',
			mkt_cl_cmp_ad_name__c ='Acn',
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
			IsActive = true,
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

	static Lead createLead() {
		return new Lead(
			OwnerId = UserInfo.getUserId(),
			LastName='Accenture',
			RecordTypeId = Lead_GlobalManagement.NA_SALES_LEAD_RECORDTYPE_ID,
			Company='Accenture',
			Status='New',
			Stage__c='Marketing Disqualified',
			Lead_Ranking__c = 'P1',
			Products_of_Interest__c='JBoss',
			LeadSourceDetail__c='SD_RONA',
			Country = 'Narnia',
			Country_of_Order__c = 'Narnia',
			Partner_Opt_In__c=true);
	}

	static Lead lead {
		get {
			if(lead == null) {
				lead = createLead();
			}
			return lead;
		}
		set;
	}

	static CampaignMember member {
		get {
			if(member == null) {
				Campaign testCampaign = campaign;
				insert testCampaign;
				Lead testLead = lead;
				insert testLead;
				member = new CampaignMember(
					LeadId = testLead.Id,
					CampaignId = testCampaign.Id,
					Status = 'Sent');
			}
			return member;
		}
		set;
	}

	@isTest
	static void setActiveLeadTest() {
		CampaignMember testMember = member;
//		insert testMember;
		Lead testLead = lead;
		CampaignMemberTriggerBefore triggerBefore = new CampaignMemberTriggerBefore(null,new List<CampaignMember>{testMember});
		triggerBefore.setActiveLead();
		system.assert(!testMember.IsLeadActive__c);
		testLead.Stage__c = 'Inquiry';
		update testLead;
		triggerBefore = new CampaignMemberTriggerBefore(null,new List<CampaignMember>{testMember});
		triggerBefore.setActiveLead();
		system.assert(testMember.IsLeadActive__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		CampaignMember testMember = member;
		// Turn off all the triggers, so we don't activate them prematurely
		AbstractTrigger.setBooleanSettings('CampaignMember_Before.',false);
		insert testMember;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('CampaignMember_Before.',true);
		// insert
		CampaignMemberTriggerBefore.processTrigger(null,new List<CampaignMember>{testMember});
		// update
		CampaignMemberTriggerBefore.processTrigger(new Map<Id,CampaignMember>{testMember.Id=>testMember.clone(true)},new List<CampaignMember>{testMember});
		// delete
		CampaignMemberTriggerBefore.processTrigger(new Map<Id,CampaignMember>{testMember.Id=>testMember},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('CampaignMember_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('CampaignMember_Before.',new List<CampaignMember>{member});
	}

}