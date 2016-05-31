/**
 * Test class for OpportunityTeamMemberTriggerAfter
 *
 * @version 2013-11-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-05 - updated setPOCStatusTest() to reflect that this is now handed by an approval process
 * 2013-10-01 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-11-18 - Moved methods to the OpportunityTeamMemberCloneTrigAfterTest
 */
@isTest
private class OpportunityTeamMemberTriggerAfterTest {

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

	@isTest
	static void syncClonesTest() {
		Opportunity opp = opportunity.clone(false);
		opp.RecordTypeId = OpportunityTeamMemberCloneTriggerAfter.pocRecordTypeId;
		insert opp;
		teamMember.TeamMemberRole = OpportunityTeamMemberCloneTriggerAfter.POC_ENGAGEMENT_SA_ROLE;
		teamMember.OpportunityId = opp.Id;
		AbstractTrigger.setBooleanSettings('OppTeam_After.',false);
		insert teamMember;
		//test Engagement SA insert
		OpportunityTeamMemberTriggerAfter afterTrigger = new OpportunityTeamMemberTriggerAfter(null,new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember});
		afterTrigger.syncClones();
		OpportunityTeamMemberClone__c teamMemberClone = [
			select
				Opportunity__c,
				TeamMemberRole__c,
				User__c
			from OpportunityTeamMemberClone__c
			where OpportunityTeamMemberId__c = :teamMember.Id];
		System.assertEquals(teamMember.OpportunityId,teamMemberClone.Opportunity__c);
		System.assertEquals(teamMember.TeamMemberRole,teamMemberClone.TeamMemberRole__c);
		System.assertEquals(teamMember.UserId,teamMemberClone.User__c);
		afterTrigger = new OpportunityTeamMemberTriggerAfter(new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember},null);
		afterTrigger.syncClones();
		System.assertEquals(0,[select count() from OpportunityTeamMemberClone__c where OpportunityTeamMemberId__c = :teamMember.Id]);
	}

	@isTest(SeeAllData=true)
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('OppTeam_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityTeamMemberTriggerAfter.processTrigger(null,new Map<Id,OpportunityTeamMember>{null=>teamMember});
		// insert the teamMember, again with the triggers off
		insert teamMember;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('OppTeam_After.',true);
		OpportunityTeamMember teamMember2 = teamMember.clone(true);
		Test.startTest();
		// insert test
		OpportunityTeamMemberTriggerAfter.processTrigger(null,new Map<Id,OpportunityTeamMember>{teamMember2.Id=>teamMember2});
		// update test
		OpportunityTeamMemberTriggerAfter.processTrigger(new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember},new Map<Id,OpportunityTeamMember>{teamMember2.Id=>teamMember2});
		// delete test
		OpportunityTeamMemberTriggerAfter.processTrigger(new Map<Id,OpportunityTeamMember>{teamMember.Id=>teamMember},null);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('OppTeam_After.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('OppTeam_After.',new List<OpportunityTeamMember>{teamMember});
	}
}