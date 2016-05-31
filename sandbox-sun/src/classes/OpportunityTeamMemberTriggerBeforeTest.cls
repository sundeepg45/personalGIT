/**
 * Test class for OpportunityTeamMemberTriggerBefore.cls
 *
 * @version 2013-11-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-05 - Created
 */
@isTest
public class OpportunityTeamMemberTriggerBeforeTest{

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

	public static User testUser {
		get {
			if(testUser == null) {
				testUser = [
					select Alias,
						Email,
						EmailEncodingKey,
						LastName,
						LanguageLocaleKey,
						LocalesIdKey,
						ProfileId,
						TimezonesIdKey,
						UserName
					from User
					where Profile.Name like '%Sales%'
						and IsActive = true
						and Id != :UserInfo.getUserId()
					order by CreatedDate
					limit 1 ];
			}
			return testUser;
		}
	}

	public static User testUser1 {
		get {
			if(testUser1 == null) {
				testUser1 = [
					select Alias,
						Email,
						EmailEncodingKey,
						LastName,
						LanguageLocaleKey,
						LocalesIdKey,
						ProfileId,
						TimezonesIdKey,
						UserName
					from User
					where Profile.Name like '%Sales%'
						and IsActive = true
						and Id != :UserInfo.getUserId()
						and Id != :testUser.Id
					order by CreatedDate
					limit 1 ];
			}
			return testUser1;
		}
	}

	@isTest
	static void requireEngagementSaTest() {
		Opportunity poc = opportunity.clone(false);
		poc.RecordTypeId = OpportunityTeamMemberTriggerBefore.pocRecordTypeId;
		poc.POC_Status__c = OpportunityTeamMemberTriggerBefore.POC_STATUS_SCOPING;
		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		insert poc;
		OpportunityTeamMember pocTeamMember = teamMember;
		pocTeamMember.TeamMemberRole = OpportunityTeamMemberTriggerBefore.POC_ENGAGEMENT_SA_ROLE;
		pocTeamMember.OpportunityId = poc.Id;
		AbstractTrigger.setBooleanSettings('OppTeam_Before.',false);
		insert pocTeamMember;
		//test delete
		OpportunityTeamMemberTriggerBefore beforeTrigger = new OpportunityTeamMemberTriggerBefore(new Map<Id,OpportunityTeamMember>{pocTeamMember.Id=>pocTeamMember},null);
		String errorMessage = beforeTrigger.requireEngagementSA();
		System.assertNotEquals(null, errorMessage);
		System.assertEquals(OpportunityTeamMemberTriggerBefore.POC_REQUIRE_ENGAGEMENT_SA_ERROR, errorMessage);
		//test update
		OpportunityTeamMember pocTeamMember2 = pocTeamMember.clone(true);
		pocTeamMember2.TeamMemberRole = 'Test Role';
		beforeTrigger = new OpportunityTeamMemberTriggerBefore(new Map<Id,OpportunityTeamMember>{pocTeamMember.Id=>pocTeamMember},new List<OpportunityTeamMember>{pocTeamMember2});
		errorMessage = beforeTrigger.requireEngagementSA();
		System.assertNotEquals(null, errorMessage);
		System.assertEquals(OpportunityTeamMemberTriggerBefore.POC_REQUIRE_ENGAGEMENT_SA_ERROR, errorMessage);
		//test non-error scenario where we delete a team member but there is still one remaining
		OpportunityTeamMember pocTeamMember3 = pocTeamMember.clone(false);
		pocTeamMember3.UserId = testUser1.Id;
		insert pocTeamMember3;
		beforeTrigger = new OpportunityTeamMemberTriggerBefore(new Map<Id,OpportunityTeamMember>{pocTeamMember.Id=>pocTeamMember},null);
		errorMessage = beforeTrigger.requireEngagementSA();
		System.assertEquals(null, errorMessage);	   
	}

	@isTest(SeeAllData=true)
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('OppTeam_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityTeamMemberTriggerBefore.processTrigger(null,new List<OpportunityTeamMember>{teamMember});
		// insert the teamMember, again with the triggers off
		insert teamMember;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('OppTeam_Boolean.',true);
		OpportunityTeamMember teamMember2 = teamMember.clone(true);
		Test.startTest();
		// insert test
		OpportunityTeamMemberTriggerBefore.processTrigger(null,new List<OpportunityTeamMember>{teamMember2});
		// update test
		OpportunityTeamMemberTriggerBefore.processTrigger(new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember},new List<OpportunityTeamMember>{teamMember2});
		// delete test
		OpportunityTeamMemberTriggerBefore.processTrigger(new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember},null);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('OppTeam_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('OppTeam_Before.',new List<OpportunityTeamMember>{teamMember});
	}
}