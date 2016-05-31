/**
 * Test class for OpportunityTeamMemberCloneTriggerAfter
 *
 * @version 2013-11-18
 * @author Bill Riemers <briemers@redhat.com>
 * 2013-11-18 - Created by refactoring OpportunityTeamMemberTriggerAfterTest
 * Scott Coleman <scoleman@redhat.com>
 * 2013-11-05 - updated setPOCStatusTest() to reflect that this is now handed by an approval process
 * 2013-10-01 - Created
 */
@isTest
private class OpportunityTeamMemberCloneTrigAfterTest {

	public static Account account {
		get {
			if(account == null) {
				account = new Account(
					CurrencyIsoCode='USD',
					name='Test Account');
				insert account;
			}
			return account;
		}
	}

	public static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CloseDate=System.today(),
					StageName='Unqualified',
					OwnerId=UserInfo.getUserId(),
					AccountId=account.Id,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM',
					Engagement_SA__c=null);
				insert opportunity;
			}
			return opportunity;
		}
	}

	public static OpportunityTeamMember teamMember {
		get {
			if(teamMember == null) {
				teamMember = new OpportunityTeamMember(
					UserId=testUser.Id,
					OpportunityId=opportunity.Id,
					TeamMemberRole='Test Role');
			}
			return teamMember;
		}
	}

	public static OpportunityTeamMemberClone__c getTeamMemberClone(OpportunityTeamMember xteamMember) {
		AbstractTrigger.setBooleanSettings('OppTeam_After.',false);
		upsert xteamMember;
		return new OpportunityTeamMemberClone__c(
			User__c=xteamMember.UserId,
			Opportunity__c=xteamMember.OpportunityId,
			OpportunityTeamMemberId__c = xteamMember.Id,
			TeamMemberRole__c=xteamMember.TeamMemberRole);
	}

	public static OpportunityTeamMemberClone__c teamMemberClone {
		get {
			if(teamMemberClone == null) {
				teamMemberClone = getTeamMemberClone(teamMember);
			}
			return teamMemberClone;
		}
	}

	public static User testUser {
		get {
			if(testUser == null) {
				Profile profile = [select id from profile where Name like '%Sales%' limit 1];
				testUser = new User(
					alias = 'test4870', 
					email='testuser4870@testorg.com',
					emailencodingkey='UTF-8',
					lastname='Testing4870',
					languagelocalekey='en_US',
					localesidkey='en_US',
					profileid = profile.Id,
					timezonesidkey='America/Los_Angeles',
					username='testuser4870@testorg.com');
				system.runAs(new User(Id = userInfo.getUserId())) {
					insert testUser;
				}
			}
			return testUser;
		}
	}

	public static User testUser1 {
		get {
			if(testUser1 == null) {
				Profile profile = [select id from profile where Name like '%Sales%' limit 1];
				testUser1 = new User(
					alias = 'test4871', 
					email='testuser4871@testorg.com',
					emailencodingkey='UTF-8',
					lastname='Testing4871',
					languagelocalekey='en_US',
					localesidkey='en_US',
					profileid = profile.Id,
					timezonesidkey='America/Los_Angeles',
					username='testuser4871@testorg.com');
				system.runAs(new User(Id = userInfo.getUserId())) {
					insert testUser1;
				}
			}
			return testUser1;
		}
	}

	public static User testUser2 {
		get {
			if(testUser2 == null) {
				Profile profile = [select id from profile where Name like '%Sales%' limit 1];
				testUser2 = new User(
					alias = 'test8342', 
					email='testuser8342@testorg.com',
					emailencodingkey='UTF-8',
					lastname='Testing8342',
					languagelocalekey='en_US',
					localesidkey='en_US',
					profileid = profile.Id,
					timezonesidkey='America/Los_Angeles',
					username='testuser8342@testorg.com');
				system.runAs(new User(Id = userInfo.getUserId())) {
					insert testUser2;
				}
			}
			return testUser2;
		}
	}
	
	@isTest(SeeAllData=true)
	//coverage of this test is better when the appropriate approval process is in place
	static void setPOCStatusTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		opp.POC_Status__c = 'New Request';
		insert opp;
		Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
		submitRequest.setObjectId(opp.id);
		try {
			Approval.ProcessResult result = Approval.process(submitRequest);
		}
		catch(Exception e) {}
		teamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		teamMember.OpportunityId = opp.Id;
		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMemberClone;
		opp.Engagement_SA__c = teamMember.UserId;
		update opp;
		OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone});
		afterTrigger.setPOCStatus();
	}

	@isTest
	static void setEngagementSATest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		// to do: DML operations are very time consuming.  If the code is probably refactored,
		// to allow injection, we should not need to do so many for this set of tests.
		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		insert opp;

		teamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		teamMember.OpportunityId = opp.Id;

		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMemberClone;

		Test.startTest();

		//test Engagement SA insert
		OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone});
		afterTrigger.setEngagementSA();

		Test.stopTest();

		Opportunity proofOfConcept = [select Engagement_SA__c from Opportunity where Id = :opp.Id];
		System.assertEquals(testUser.Id,proofOfConcept.Engagement_SA__c);
	}

	@isTest
	static void setEngagementSADeleteTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		insert opp;

		teamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		teamMember.OpportunityId = opp.Id;

		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMemberClone;

		OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone});
		afterTrigger.setEngagementSA();

		OpportunityTeamMember teamMember2 = teamMember.clone(false);
		teamMember2.UserId = testUser2.Id;
		teamMember2.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;

		OpportunityTeamMemberClone__c teamMemberClone2 = getTeamMemberClone(teamMember2);
		insert teamMemberClone2;

		Test.startTest();

		//test Engagement SA delete and automatic replacement
		OpportunityTeamMemberClone__c deletedTeamMemberClone = teamMemberClone.clone(true);
		delete teamMember;
		Database.delete(teamMemberClone,false);

		afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(new Map<Id,OpportunityTeamMemberClone__c>{deletedTeamMemberClone.Id=>deletedTeamMemberClone},null);
		afterTrigger.setEngagementSA();

		Test.stopTest();

		Opportunity proofOfConcept = [select Engagement_SA__c from Opportunity where Id = :opp.Id];
		System.assertEquals(teamMemberClone2.User__c,proofOfConcept.Engagement_SA__c);		
	}

	@isTest
	static void setEngagementSAUpdateTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		insert opp;

		teamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		teamMember.OpportunityId = opp.Id;

		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMemberClone;

		OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone});
		afterTrigger.setEngagementSA();

		Test.startTest();

		//test Engagement SA update
		OpportunityTeamMember updatedTeamMember = teamMember.clone(true);
		OpportunityTeamMemberClone__c updatedTeamMemberClone = teamMemberClone.clone(true);
		updatedTeamMemberClone.TeamMemberRole__c = updatedTeamMember.TeamMemberRole = 'Backup';
		update updatedTeamMember;
		Database.update(updatedTeamMemberClone,false);

		afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone},new Map<Id,OpportunityTeamMemberClone__c>{updatedTeamMemberClone.Id=>updatedTeamMemberClone});
		afterTrigger.setEngagementSA();
		
		Test.stopTest();

		Opportunity proofOfConcept = [select Engagement_SA__c from Opportunity where Id = :opp.Id];
		System.assertEquals(null,proofOfConcept.Engagement_SA__c);		
	}

	@isTest
	static void setEngagementSAUpdate2Test() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		insert opp;

		teamMember.TeamMemberRole = 'Backup'; 
		teamMember.OpportunityId = opp.Id;

		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMemberClone;

		OpportunityTeamMemberCloneTriggerAfter afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone});
		afterTrigger.setEngagementSA();

		Test.startTest();

		//test Engagement SA update
		OpportunityTeamMember updatedTeamMember = teamMember.clone(true);
		OpportunityTeamMemberClone__c updatedTeamMemberClone = teamMemberClone.clone(true);
		updatedTeamMemberClone.TeamMemberRole__c = updatedTeamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		update updatedTeamMember;
		Database.update(updatedTeamMemberClone,false);

		afterTrigger = new OpportunityTeamMemberCloneTriggerAfter(new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone},new Map<Id,OpportunityTeamMemberClone__c>{updatedTeamMemberClone.Id=>updatedTeamMemberClone});
		afterTrigger.setEngagementSA();
		
		Test.stopTest();

		Opportunity proofOfConcept = [select Engagement_SA__c from Opportunity where Id = :opp.Id];
		System.assertEquals(testUser.Id,proofOfConcept.Engagement_SA__c);		
	}

	@isTest(SeeAllData=true)
	static void processTriggerTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityTeamMemberCloneTriggerAfter.processTrigger(null,new Map<Id,OpportunityTeamMemberClone__c>{null=>teamMemberClone});
		// insert the teamMember, again with the triggers off
		insert teamMemberClone;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',true);
		OpportunityTeamMemberClone__c teamMemberClone2 = teamMemberClone.clone(true);
		Test.startTest();
		// insert test
		OpportunityTeamMemberCloneTriggerAfter.processTrigger(null,new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone2.Id=>teamMemberClone2});
		// update test
		OpportunityTeamMemberCloneTriggerAfter.processTrigger(new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone},new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone2.Id=>teamMemberClone2});
		// delete test
		OpportunityTeamMemberCloneTriggerAfter.processTrigger(new Map<Id,OpportunityTeamMemberClone__c>{teamMemberClone.Id=>teamMemberClone},null);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('OppTeamClone_After.');
	}

	@isTest
	static void deployTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		AbstractTriggerTest.deployTest('OppTeamClone_After.',new List<OpportunityTeamMemberClone__c>{teamMemberClone});
	}
}