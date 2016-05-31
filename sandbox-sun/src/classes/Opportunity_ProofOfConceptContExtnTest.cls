/**
 * Test class for Opportunity_ProofOfConceptControllerExtn.
 *
 * @version 2014-06-24
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-04-23 - Fixes for April prod validation issues
 * 2013-11-05 - Updated test for submitForScoping()
 * 2013-10-17 - Added test for recallPOC()
 * 2013-10-16 - Added test for isOwner, isEngagementSA, isSaManagement
 * 2013-07-10 - Updated test opp to include Primary_Business_Unit_New__c
 * 2013-06-25 - Added test for custom action submitForScoping
 * 2013-06-17 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2014-06-23 - Changed default StageName to POC
 * 2013-11-14 - Add test for savePoc() method
 * 2013-07-18 - In the process of fixing tests for new code
 * 2013-07-08 - Added productLineOptionsTest
 * 2013-07-05 - Added detectRecordLockTest
 * 2013-06-26 - Added test for closing a POC
 * 2013-06-25 - Removed reference to record type string setting
 */
@isTest
private class Opportunity_ProofOfConceptContExtnTest {
	static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name='Test account');
				insert account;
			}
			return account;
		}
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Test Opp',
					AccountId = account.Id,
					FulfillmentChannel__c='Indirect – VAR/VAD',
					CloseDate=System.today(),
					StageName='POC',
					Country_of_Order__c='United States',
					PrimaryBusinessUnit__c=null,
					POC_Primary_Product__c='Dummy Value',
					RecordTypeId = Opportunity_ProofOfConceptControllerExtn.pocRecordTypeId);
				insert opportunity;
			}
			return opportunity;
		}
	}

	@isTest
	static void savePOCTest() {
		OpportunityTeamMember engagementSA = new OpportunityTeamMember(
			OpportunityId = opportunity.Id,
			TeamMemberRole = Opportunity_ProofOfConceptControllerExtn.POC_ENGAGEMENT_SA_ROLE,
			UserId = UserInfo.getUserId());
		insert engagementSA;
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_Edit?sourceOppid='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
		Test.startTest();
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		Opportunity proofOfConcept = (Opportunity)stdController.getRecord();
		System.assertEquals(opportunity.AccountId, proofOfConcept.AccountId);
		System.assertEquals(Opportunity_ProofOfConceptControllerExtn.POC_STATUS_NEW_REQUEST, proofOfConcept.POC_Status__c);
		System.assertEquals('POC', proofOfConcept.StageName);
		System.assertNotEquals(null, proofOfConcept.RecordTypeId);
		proofOfConcept.POC_Status__c = 'Submit for Scoping Assignment';
		System.assertNotEquals(null,extension.savePOC());
		Test.stopTest();
		System.assertNotEquals(null,proofOfConcept.Id);
		System.assertNotEquals(0,[
			select count()
			from OpportunityTeamMember
			where OpportunityId = :proofOfConcept.Id
				and UserId = :engagementSA.UserId
				and TeamMemberRole = :engagementSA.TeamMemberRole ],
			'Failed to find engagementSA');
	}
	
	@isTest
	static void submitForScopingTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_View?id='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		PageReference returnPage = extension.submitForScoping();		
	}

	@isTest
	static void scopingTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_Edit?sourceOppid='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity.clone(false));
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		Opportunity proofOfConcept = (Opportunity)stdController.getRecord();
		proofOfConcept.PrimaryBusinessUnit__c = 'Test';
		proofOfConcept.POC_Status__c = 'Submit for Scoping Assignment';
		insert proofOfConcept;
		OpportunityTeamMember engagementSA = new OpportunityTeamMember(
			OpportunityId = proofOfconcept.Id,
			TeamMemberRole = Opportunity_ProofOfConceptControllerExtn.POC_ENGAGEMENT_SA_ROLE,
			UserId = UserInfo.getUserId());
		insert engagementSA; //status should be updated on POC by trigger on OpportunityTeamMember
		proofOfConcept = [select POC_Status__c from Opportunity where Id = :proofOfConcept.Id];
		System.assert(extension.isEngagementSA);
	}

	@isTest
	static void submitPOCTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_View?id='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		PageReference returnPage = extension.submitPOC();
	}

	@isTest
	static void recallPOCTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_View?id='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		PageReference returnPage = extension.recallPOC();
	}

	@isTest
	static void closePOCTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_Close?sourceOppid='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		Opportunity proofOfConcept = (Opportunity)stdController.getRecord();
		proofOfConcept.POC_Status__c = 'Submit for Scoping Assignment';
		extension.savePOC();
		OpportunityTeamMember engagementSA = new OpportunityTeamMember(
			OpportunityId = proofOfconcept.Id,
			TeamMemberRole = Opportunity_ProofOfConceptControllerExtn.POC_ENGAGEMENT_SA_ROLE,
			UserId = UserInfo.getUserId());
		insert engagementSA; //status should be updated on POC by trigger on OpportunityTeamMember
		Test.startTest();
		proofOfConcept.POC_Close_Comments__c = 'anything';
		PageReference returnPage = extension.closePOC();
		Test.stopTest();
		Opportunity opp = [select POC_Status__c from Opportunity where Id = :proofOfConcept.Id];
		System.assertEquals(Opportunity_ProofOfConceptControllerExtn.POC_STATUS_CLOSED,opp.POC_Status__c);
	}

	@isTest
	static void detectRecordLockTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_Close?id='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		System.assertEquals(null,extension.detectRecordLock());
		Opportunity_ProofOfConceptControllerExtn.RecordAccess recordAccess = extension.getRecordAccess();
		System.assertNotEquals(null,recordAccess);
		System.assert(recordAccess.hasCreateAccess,'Expected create access');
		System.assert(recordAccess.hasReadAccess,'Expected read access');
		System.assert(recordAccess.hasEditAccess,'Expected edit access');
		System.assert(recordAccess.hasDeleteAccess,'Expected delete access');
		System.assert(! extension.isLocked,'Expected unlocked');
		System.assertNotEquals(null,recordAccess.forceSave(),'Expected successful forceSave');
		// the following are just for coverage sake
		extension.getIsPOCNewRequest();
		extension.getIsPOCScoping();
		extension.getIsPOCClosed();
		extension.getIsPOCSubmitted();
		extension.getIsPOCEngaged();
		// now lets force some errors
		delete opportunity;
		extension.detectRecordLock();
		System.assert(extension.isLocked,'Expected locked');
		System.assertEquals(null,recordAccess.forceSave());
		System.assertEquals(null,extension.closePOC());
		System.assertEquals(null,extension.submitPOC());
		System.assertEquals(null,extension.submitForScoping());
	}

	@isTest (SeeAllData=true) // we need to see products
	static void productLineOptionsTest() {
		Test.setCurrentPage(new PageReference('/apex/Opportunity_ProofOfConcept_Close?id='+opportunity.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		List<SelectOption> primaryBusinessUnitOptions = extension.getPrimaryBusinessUnitOptions();
		opportunity.PrimaryBusinessUnit__c = primaryBusinessUnitOptions.get(2).getValue();
		List<SelectOption> productLineOptions = extension.getProductLineOptions();
		System.assertNotEquals(0,productLineOptions.size());
		System.assertNotEquals(1,productLineOptions.size());
		System.assertEquals(null,opportunity.POC_Primary_Product__c);
		// the following is just for coverage
		extension.getPrimaryProductField();
		extension.getIsStorageBusinessUnit();
	}

	//@isTest
	static void processRoleTest() {
		ApexPages.StandardController stdController = new ApexPages.StandardController(opportunity);
		Opportunity_ProofOfConceptControllerExtn extension = new Opportunity_ProofOfConceptControllerExtn(stdController);
		system.assert(!extension.isOwner);
		system.assert(!extension.isEngagementSA);
		system.assert(!extension.isSaManagement);
	}
}