/**
 * Test class created for CampaignTriggerAfter class.
 *
 * @version 2014-06-02
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-05-28 - Updated now that Parent Campaign lookup is fildered by record type
 * 2013-05-02 - Now touching related CampaignMember objects to invoke their triggers
 * 2013-01-29 - Created with test for maintenance of hierarchy data that supports custom rollups
 * Bill Riemers <briemers@redhat.com>
 * 2014-06-02 - Only run updateName after an update
 * 2014-05-29 - Added test for updateName, and merged in Scott's change from PEN
 * 2013-05-14 - updated for new maintenance of hierarchy, and a bit of refactoring
 */
@isTest
private class CampaignTriggerAfterTest {
	static Id parentCampaignRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId(CampaignTriggerBefore.RECORD_TYPE_PARENT_CAMPAIGN,'Campaign');
		}
	}

	static Campaign campaign {
		get {
			if(campaign == null) {
				campaign = CampaignTriggerBeforeTest.createCampaign(null);
				AbstractTrigger.setBooleanSettings('Campaign_Before.',false);
				AbstractTrigger.setBooleanSettings('Campaign_After.',false);
				insert campaign;
				AbstractTrigger.setBooleanSettings('Campaign_Before.',true);
				AbstractTrigger.setBooleanSettings('Campaign_After.',true);
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
				insert lead;
			}
			return lead;
		}
		set;
	}

	static CampaignMember member {
		get {
			if(member == null) {
				member = new CampaignMember(
					LeadId = lead.Id,
					CampaignId = campaign.Id,
					Status = 'Sent');
				insert member;
			}
			return member;
		}
		set;
	}

	@isTest
	static void updateNameTest() {
		campaign.Name = null;
		Campaign campaignBefore = campaign.clone(true);
		CampaignTriggerBefore beforeTrigger = new CampaignTriggerBefore(new Map<Id,Campaign>{campaignBefore.Id=>campaignBefore},new List<Campaign>{campaignBefore});
		CampaignTriggerAfter afterTrigger = new CampaignTriggerAfter(new Map<Id,Campaign>{campaign.Id=>campaign},new Map<Id,Campaign>{campaign.Id=>campaign},false);
		beforeTrigger.assignName();
		System.assertNotEquals(null,campaignBefore.Name);
		List<Campaign> campaigns = afterTrigger.getUpdateNameAndUrlList();
		System.assertEquals(1,campaigns.size());
		System.assertEquals(campaignBefore.Name,campaigns[0].Name);
		// the rest is strictly coverage testing
		// We don't need to actually update a record..., so generate an error by trying to update a new Campaign
		afterTrigger = new CampaignTriggerAfter(null,new Map<Id,Campaign>{null=>new Campaign()},false);
		System.assertEquals(true,afterTrigger.updateCampaigns(new List<Campaign>{new Campaign()}));
		// processes the trigger with an empty map
		afterTrigger = new CampaignTriggerAfter(new Map<Id,Campaign>(),new Map<Id,Campaign>(),false);
		afterTrigger.updateName();
	}

	@isTest 
	static void maintainHierarchyDataTest() {
		// Turn off all triggers, as we are going to test methods by explicit calls
		AbstractTrigger.setBooleanSettings('Campaign_Before.',false);
		AbstractTrigger.setBooleanSettings('Campaign_After.',false);
		Test.startTest();
		CampaignTriggerAfter.useFuture = false; // we don't want to invoke the future method more than once
		Campaign campaign1 = CampaignTriggerBeforeTest.createCampaign('test@test.fte2');
		campaign1.RecordTypeId = parentCampaignRecordTypeId;
		insert campaign1;
		CampaignTriggerAfter afterTrigger = new CampaignTriggerAfter(null,new Map<Id,Campaign>{campaign1.Id=>campaign1},false);
		afterTrigger.maintainHierarchyData();
		Campaign campaign2 = CampaignTriggerBeforeTest.createCampaign('test@test.fte2');
		campaign2.ParentId = campaign1.Id;
		campaign2.RecordTypeId = parentCampaignRecordTypeId;
		insert campaign2;
		afterTrigger = new CampaignTriggerAfter(null,new Map<Id,Campaign>{campaign2.Id=>campaign2},false);
		afterTrigger.maintainHierarchyData();
		Campaign campaign3 = CampaignTriggerBeforeTest.createCampaign('test@test.fte2');
		campaign3.ParentId = campaign2.Id;
		insert campaign3;
		afterTrigger = new CampaignTriggerAfter(null,new Map<Id,Campaign>{campaign3.Id=>campaign3},false);
		afterTrigger.maintainHierarchyData();
		delete campaign2;
		afterTrigger = new CampaignTriggerAfter(new Map<Id,Campaign>{campaign2.Id=>campaign2},null,false);
		afterTrigger.maintainHierarchyData();
		undelete campaign2;
		CampaignTriggerAfter.neededDML = Limits.getLimitDMLStatements();
		CampaignTriggerAfter.useFuture = true; // ok, we'll do the future call this time
		afterTrigger = new CampaignTriggerAfter(null,new Map<Id,Campaign>{campaign2.Id=>campaign2},true);
		afterTrigger.maintainHierarchyData();
		Test.stopTest();
		System.assertEquals(1,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign1.Id]);
		System.assertEquals(1,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign2.Id]);
		System.assertEquals(0,[SELECT Count() FROM Campaign_Hierarchy_Details__c WHERE Campaign__c = :campaign3.Id]);
	}

	@isTest
	static void touchCampaignMembersTest() {
		RecordType rt = [select Id from RecordType where SobjectType='Campaign' and DeveloperName='Tactic' limit 1];
		CampaignMember testMember = member;
		Campaign testCampaign = campaign;
		Campaign updatedCampaign = testCampaign.clone(true);
		updatedCampaign.RecordTypeId = rt.Id;
		CampaignTriggerAfter afterTrigger = new CampaignTriggerAfter(new Map<Id,Campaign>{testCampaign.Id=>testCampaign},new Map<Id,Campaign>{testCampaign.Id=>updatedCampaign},false);
		afterTrigger.touchCampaignMembers();
	}	

	@isTest // (SeeAllData=true) no longer needed 
	static void processTriggerTest() {
		Campaign camp = CampaignTriggerBeforeTest.createCampaign('test@test.test');
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Campaign_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		CampaignTriggerAfter.processTrigger(null,new Map<Id,Campaign>{null=>camp},false);
		// insert the opportunity, again with the triggers off
		insert camp;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Campaign_After.',true);
		Campaign camp2 = camp.clone(true);
		Test.startTest();
		// insert test
		CampaignTriggerAfter.processTrigger(null,new Map<Id,Campaign>{camp2.Id=>camp2},false);
		// update test
		CampaignTriggerAfter.processTrigger(new Map<Id,Campaign>{camp.Id=>camp},new Map<Id,Campaign>{camp2.Id=>camp2},false);
		// delete test
		CampaignTriggerAfter.processTrigger(new Map<Id,Campaign>{camp.Id=>camp},null,false);
		// undelete test
		CampaignTriggerAfter.processTrigger(null,new Map<Id,Campaign>{camp2.Id=>camp2},true);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('Campaign_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest(SeeAllData=true) // need all data to access custom settings
	static void deployTest() {
		Campaign testCampaign = CampaignTriggerBeforeTest.createCampaign('test@test.test');
		AbstractTriggerTest.deployTest('Campaign_After.',new List<Campaign>{testCampaign});
	}
}