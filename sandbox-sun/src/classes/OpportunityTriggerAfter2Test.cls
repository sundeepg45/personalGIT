/**
 * Test class for OpportunityTriggerAfter2.cls
 *
 * @version 2015-11-26
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-04-21 - Added test for removeFinancialPartner() (US65011)
 * 2013-11-05 - Added test for submitForBUApproval() and improved coverage of setEngagementSATest()
 * 2013-10-13 - Added test for syncProofOfConceptFields(), syncProofOfConceptFieldsFuture()
 * 2013-10-01 - Added test for proof of concept engagement SA trigger
 * 2013-02-26 - Added test for proof of concept product copy
 * 2012-08-10 - Updated with additional asserts
 * 2012-07-12 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-11-26 - Added support for delete and undelete
 * 2015-08-07 - Added countryOppSplitAUTest and updateServicesAllocations2Test
 * 2015-05-12 - Add tests for creating order management tasks and to backout an order
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-02-27 - Added sync shipping contact test
 * 2014-02-20 - Added test method for leadHistory
 * 2014-01-17 - Added syncContractsTest
 * 2013-11-19 - Added syncOpportunityTeamMemberCloneTest
 * 2013-11-08 - Added tests for method to notify when the owner of a POC is changed
 * 2013-08-19 - Added test for updateServicesAllocations method
 * 2013-08-08 - Class rename to avoid release conflicts
 * 2013-07-18 - Updating to PrimaryBusinessUnit__c 
 * 2013-06-19 - Correct linkSolutions test.
 * 2013-04-04 - Add test for linkSolutions.  Add missing test methods.
 */
@isTest
public class OpportunityTriggerAfter2Test {
	static StrategicPlan_Solution__c solution {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solution;
		}
	}

	static Id solutionId {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solutionId;
		}
	}

	public static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CloseDate=System.today(),
					StageName='Prepare',
					Probability=1.0,
					OwnerId=UserInfo.getUserId(),
					AccountId=solution.StrategicPlan__r.Account__c,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM',
					RecordTypeId = RecordTypeLookup.getRecordTypeId('EMEA Sales Opportunity','Opportunity'),
					Engagement_SA__c=null);
			}
			return opportunity;
		}
		set;
	}

	public static Id getOpportunityId() {
		if(opportunity.Id == null) {
			AbstractTrigger.setBooleanSettings('Opp_After.',false);
			insert opportunity;
			AbstractTrigger.setBooleanSettings('Opp_After.',true);
		}
		return opportunity.Id;
	}
	
	public static DateTime getOpportunityLastModifiedDate() {
		if(opportunity.LastModifiedDate == null) {
			for(Opportunity opp : [
				select
					Name,
					CloseDate,
					StageName,
					OwnerId,
					AccountId,
					Country_of_Order__c,
					FulfillmentChannel__c,
					RecordTypeId,
					Engagement_SA__c,
					LFR__c,
					Amount,
					CurrencyIsoCode,
					ForecastCategory,
					Id,
					Probability,
					Close_Date_Moved_Details__c,
					ReasonWonLostSalesProcess__c,
					LastModifiedDate
				from Opportunity
				where Id = :getOpportunityId()])
			{
				opportunity = opp.clone(true,true,true,true);
			}
		}
		return opportunity.LastModifiedDate;
	}

	public static OpportunityTeamMember teamMember {
		get {
			if(teamMember == null) {
				teamMember = new OpportunityTeamMember(
					UserId=testUser.Id,
					OpportunityId=getOpportunityId(),
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

	static Contract contract {
		get {
			if (contract == null) {
				contract = new Contract(
					Opportunity__c = getOpportunityId(),
					OwnerId = UserInfo.getUserId(),
					Owner__c = null);
				contract.AccountId = opportunity.AccountId;
			}
			return contract;
		}
		set;
	}

	static Contact contact {
		get {
			if(contact == null) {
				contact = new Contact(
					AccountId=opportunity.AccountId,
					Email='test@redhat.com',
					FirstName='John',
					LastName='Smith',
					Phone='9055551212',
					Title='Dr',
					LoginName__c='test@redhat.com');
			}
			return contact;
		}
	}

	static OpportunityPartner__c getOpportunityPartner(Opportunity opp) {
		Classification__c pType = null;
		Classification__c pTier = null;
		for(Classification__c c : [
			select Name from Classification__c 
			where Name in ('Partner Type','Partner Tier') 
			and Parent__c = null ]
		) {
			if(c.Name == 'Partner Type') {
				pType = c;
			}
			else if(c.Name == 'Partner Tier') {
				pTier = c;
			}
		}
		if(pType == null) {
			pType=new Classification__c(Name='Partner Type');
			insert pType;
		}
		if(pTier == null) {
			pTier = new Classification__c(Name='Partner Tier');
			insert pTier;
		}
		Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
		Classification__c cType = new Classification__c(Name='Child Type',Parent__c=pType.Id);
		insert new List<Classification__c>{cTier,cType};
		OpportunityPartner__c oppPartner = new OpportunityPartner__c(
		Opportunity__c = opp.Id,
		PartnerTier__c = cTier.Id,
		PartnerType__c = cType.Id,
		Partner__c = opp.AccountId,
		RelationshipType__c = 'Financial' );
		insert oppPartner;
		return oppPartner;
	}

	@IsTest
	static void leadHistoryTest() {
		Id currentUserId = UserInfo.getUserId();
		User runAsUser = [
			select Id
			from User
			where ProfileId = :UserInfo.getProfileId()
				and IsActive = true
				and Id != :currentUserId
			limit 1 ];
		Lead lead = LeadTriggerBeforeTest.createLead();
		insert lead;
		LeadForReporting__c lfr = new LeadForReporting__c(
			LeadId__c=lead.Id,
			Lead__c = lead.Id);
		Database.upsert(lfr,LeadForReporting__c.fields.LeadId__c);
		LeadManagementHistory__c lmh = new LeadManagementHistory__c(
			FromOwnerModifiedDateTime__c = DateTime.now(),
			FromStageModifiedDateTime__c = DateTime.now(),
			Interest_Score__c = 0,
			Qualified_By__c = currentUserId,
			Lead_Ranking__c = 'Anything',
			Lead_Source__c = 'Other',
			Lead_Source_Detail__c = 'Anything',
			Lead__c = lead.Id,
			LeadId__c = lead.Id,
			LeadStageFrom__c = 'Marketing Accepted',
			LeadStageTo__c = 'Marketing Qualified',
			LFR__c = lfr.Id,
			OwnerId_From__c = currentUserId,
			OwnerId_To__c = currentUserId,
			Pre_Qualified_To__c = false,
			Qualification_Score__c = 0,
			Route_Around_To__c = false);
		insert lmh;
		opportunity.LFR__c = lfr.Id;
		getOpportunityLastModifiedDate();
		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
		System.assertEquals(lmh.LeadStageTo__c,OpportunityTriggerAfter2.leadStage(opportunities[0],false,lmh.LeadStageTo__c));
		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{ opportunity.Id => opportunity };
		List<Opportunity> newList = opportunities.deepClone(true);
		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>(newList);
		newList[0].OwnerId = runAsUser.Id;
		System.assertEquals(lmh.LeadStageTo__c,OpportunityTriggerAfter2.leadStage(newList[0],false,lmh.LeadStageTo__c));
		OpportunityTriggerAfter2 trig = new OpportunityTriggerAfter2(oldMap,newMap,false);
		Test.startTest();
		trig.leadHistory();
		LeadManagementHistory__c lmh2 = [
			select
				LeadStageTo__c,
				LeadStageFrom__c,
				OwnerId_From__c,
				OwnerId_To__c
			from LeadManagementHistory__c
			where LeadId__c = :lead.Id
				and Opportunity__c = :opportunity.Id ];
		System.assertNotEquals(lmh.Id,lmh2.Id);
		System.assertEquals(currentUserId,lmh2.OwnerId_From__c);
		System.assertEquals(runAsUser.Id,lmh2.OwnerId_To__c);
		System.assertEquals(lmh.LeadStageTo__c,lmh2.LeadStageFrom__c);
		System.assertEquals(lmh.LeadStageTo__c,lmh2.LeadStageTo__c);
		newList = opportunities.deepClone(true);
		newMap = new Map<Id,Opportunity>(newList);
		newList[0].CloseDate = newList[0].CloseDate.addDays(1);
		newList[0].Close_Date_Moved_Details__c = 'Anything';
		System.assertEquals(lmh.LeadStageTo__c,OpportunityTriggerAfter2.leadStage(newList[0],false,lmh.LeadStageTo__c));
		OpportunityTriggerAfter2.isFuture = true;
		System.assert(OpportunityTriggerAfter2.isFuture);
		trig = new OpportunityTriggerAfter2(oldMap,newMap,false);
		trig.leadHistory();
		LeadManagementHistory__c lmh3 = [
			select
				CloseDate_From__c,
				CloseDate_To__c,
				Comments__c,
				LeadStageTo__c,
				LeadStageFrom__c
			from LeadManagementHistory__c
			where LeadId__c = :lead.Id
				and Opportunity__c = :opportunity.Id
				and CloseDate_To__c = :newList[0].CloseDate ];
		System.assertEquals(lmh2.Id,lmh3.Id);
		System.assertEquals(lmh.LeadStageTo__c,lmh3.LeadStageFrom__c);
		System.assertEquals(lmh.LeadStageTo__c,lmh3.LeadStageTo__c);
		System.assertEquals('Anything',lmh3.Comments__c);
		newList = opportunities.deepClone(true);
		newMap = new Map<Id,Opportunity>(newList);
		newList[0].Probability = opportunity.Probability + 1.0;
		System.assertEquals(OpportunityTriggerAfter2.SALES_ACCEPTED,OpportunityTriggerAfter2.leadStage(newList[0],true,lmh.LeadStageTo__c));
		OpportunityTriggerAfter2.isFuture = null;
		trig = new OpportunityTriggerAfter2(oldMap,newMap,false);
		trig.leadHistory();
		Test.stopTest();
		Set<String> expectedStages = new Set<String>{
			OpportunityTriggerAfter2.SALES_ACCEPTED,
			OpportunityTriggerAfter2.SALES_QUALIFIED };
		for(LeadManagementHistory__c lmh4 : [
			select
				LeadStageTo__c,
				LeadStageFrom__c
			from LeadManagementHistory__c
			where LeadId__c = :lead.Id
				and LeadStageTo__c in :expectedStages ])
		{
			System.assertNotEquals(lmh.Id,lmh4.Id);
			System.assertNotEquals(lmh2.Id,lmh4.Id);
			System.assert(expectedStages.contains(lmh4.LeadStageTo__c),'Duplicate LeadStageTo__c record: '+lmh4.LeadStageTo__c);
			expectedStages.remove(lmh4.LeadStageTo__c);
		}
		System.assert(expectedStages.isEmpty(),'Failed to create records for '+expectedStages);
	}

	@IsTest(SeeAllData=true)
	static void insertOpportunitySnapshotTest() {
		Opportunity opp = opportunity;
		insert opp;
		List<Opportunity> opportunities = new List<Opportunity>{opp};
		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{ opp.Id => opp };
		List<Opportunity> newList = opportunities.deepClone(true);
		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>(newList);
		newList[0].Rush_Order__c = true;
		newList[0].Rush_Order_Reason__c = 'test';
		OpportunityTriggerAfter2 trig = new OpportunityTriggerAfter2(oldMap,newMap,false);
		trig.insertOpportunitySnapshot();
		List<OpportunitySnapshot__c> snapshots = [
			select
				Name,
				RushOrderFrom__c,
				RushOrderTo__c,
				RushOrderReasonFrom__c,
				RushOrderReasonTo__c,
				RushOrderSetBySystemFrom__c,
				RushOrderSetBySystemTo__c
			from OpportunitySnapshot__c 
			where Opportunity__c = :opp.Id];
		System.assert(snapshots.size()==1, 'Incorrect number of OpportunitySnapshot__c records generated');
		System.assertEquals(false,snapshots[0].RushOrderFrom__c);
		System.assertEquals(true,snapshots[0].RushOrderTo__c);
		System.assertEquals(null,snapshots[0].RushOrderReasonFrom__c);
		System.assertEquals('test',snapshots[0].RushOrderReasonTo__c);
		System.assertEquals(false,snapshots[0].RushOrderSetBySystemFrom__c);
		System.assertEquals(false,snapshots[0].RushOrderSetBySystemTo__c);
	}

	@IsTest(SeeAllData=true)
	static void copyProofOfConceptProductsTest() {
		Opportunity opp = OpportunityTriggerBefore2Test.opportunity;
		opp.Pricebook2Id = OpportunityTriggerAfter2.globalPricebookId;
		upsert opp;
		Opportunity poc = opp.clone(false,true,false,false);
		poc.Name = 'Test POC';
		poc.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		poc.PrimaryBusinessUnit__c = 'TestBU';
		upsert poc;
		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{OpportunityTriggerBefore2Test.opportunityLineItemGlobal};
		List<OpportunityLineItem> sourceLineItems = lineItems.deepClone(false);
		for(OpportunityLineItem lineItem : sourceLineItems) {
			lineItem.OpportunityId = opp.Id;
			lineItem.TotalPrice = null;
		}
		insert sourceLineItems;
		poc.Cloned_From_Opportunity__c = opp.Id;

		Test.startTest();

		OpportunityTriggerAfter2 trig = new OpportunityTriggerAfter2(null,new Map<Id,Opportunity>{poc.Id=>poc},false);
		trig.copyProofOfConceptProducts();

		Test.stopTest();

		List<OpportunityLineItem> targetLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :poc.Id];
		System.assertNotEquals(opp.Id,poc.Id);
		System.assert(targetLineItems.size() > 0);
	}

	@IsTest
	static void syncOpportunityTeamMemberCloneTest() {
		Opportunity poc = opportunity;
		poc.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		poc.Engagement_SA__c = userInfo.getUserId();
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		AbstractTrigger.setBooleanSettings('OppTeamClone_After.',false);
		insert teamMember;
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{poc.Id=>poc},new Map<Id,Opportunity>{poc.Id=>poc},false);
		afterTrigger.syncOpportunityTeamMemberClone();
		OpportunityTeamMemberClone__c teamMemberClone = [
			select
				Opportunity__c,
				TeamMemberRole__c,
				User__c 
			from OpportunityTeamMemberClone__c
			where OpportunityTeamMemberId__c = :teamMember.Id ];
		System.assertEquals(teamMember.OpportunityId,teamMemberClone.Opportunity__c);
		System.assertEquals(teamMember.TeamMemberRole,teamMemberClone.TeamMemberRole__c);
		System.assertEquals(teamMember.UserId,teamMemberClone.User__c);
		delete teamMember;
		afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{poc.Id=>poc},null,false);
		afterTrigger.syncOpportunityTeamMemberClone();
		System.assertEquals(0,[select count() from OpportunityTeamMemberClone__c where Id = :teamMemberClone.Id ]);
	}

	@IsTest
	static void setEngagementSATest() {
		Opportunity poc = opportunity;
		poc.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		insert poc;
		Opportunity poc2 = poc.Clone(true);
		poc2.Engagement_SA__c = userInfo.getUserId();
		system.assertNotEquals(poc.Engagement_SA__c,poc2.Engagement_SA__c);
		system.assertNotEquals(null,poc2.Engagement_SA__c);
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{poc.Id=>poc},new Map<Id,Opportunity>{poc.Id=>poc2},false);
		system.assert(afterTrigger.isUpdate);
		afterTrigger.setEngagementSA();
		List<OpportunityTeamMember> teamMembers = [SELECT Id, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :poc.Id];
		system.assert(!teamMembers.isEmpty());
		Opportunity poc3 = poc2.Clone(true);
		poc3.Engagement_SA__c = null;
		afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{poc2.Id=>poc2},new Map<Id,Opportunity>{poc.Id=>poc3},false);
		afterTrigger.setEngagementSA();
		teamMembers = [SELECT Id, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :poc.Id];
		system.assert(teamMembers.size() == 1);
	}

	@IsTest
	static void syncProofOfConceptFieldsTest() {
		//this is the pre-update opp
		Opportunity opp = opportunity;
		insert opp;
		//this is a poc related to that opp
		Opportunity poc1 = opp.clone(false);
		poc1.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		poc1.Cloned_From_Opportunity__c = opp.Id;
		insert poc1;
		//this is the post-update opp (account reference is updated)
		Opportunity updatedOpp = opp.clone(true);
		Account account = [SELECT Id, Name, CurrencyIsoCode, RecordTypeId FROM Account WHERE Id = :opp.AccountId LIMIT 1];
		Account newAccount = account.clone(false);
		insert newAccount;
		updatedOpp.AccountId = newAccount.Id;
		update updatedOpp;
		
		Test.startTest();
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{opp.Id=>opp},new Map<Id,Opportunity>{opp.Id=>updatedOpp},false);
		afterTrigger.syncProofOfConceptFields();
		Test.stopTest();
		
		//check that the new account reference was propagated to the related pocs
		poc1 = [SELECT Id, AccountId FROM Opportunity WHERE Id = :poc1.Id LIMIT 1];
		system.assertEquals(newAccount.Id,poc1.AccountId);
	}

	static List<Region__c> regList {
		get {
			if(regList == null) {
				Id currentUserId = UserInfo.getUserId();
				regList = new List<Region__c>{
					new Region__c(
						Country__c = 'India',
						Name = 'Test Region',
						Region__c = 'India/Pakistan',
						Super_Region__c = 'APAC',
						Sub_Region__c = null,
						OM_Task__c = true,
						OM_Task_Owner__c = currentUserId),
					new Region__c(
						Country__c = 'United States',
						Name = 'Test Region',
						Region__c = 'US',
						Super_Region__c = 'NA',
						Sub_Region__c = null,
						OM_Task__c = true,
						OM_Task_Owner__c = currentUserId),
					new Region__c(
						Country__c = 'United Kingdom',
						Name = 'Test Region',
						Region__c = 'NEE',
						Super_Region__c = 'EMEA',
						Sub_Region__c = 'UK',
						OM_Task__c = true,
						OM_Task_Owner__c = currentUserId),
					new Region__c(
						Country__c = 'Argentina',
						Name = 'Test Region',
						Region__c = 'SOLA',
						Super_Region__c = 'LATAM',
						Sub_Region__c = null,
						OM_Task__c = true,
						OM_Task_Owner__c = currentUserId) };
			}
			return regList;
		}
	}


	@IsTest
	static void syncContractsTest() {
		User runAsUser = [
			select Id
			from User
			where ProfileId = :UserInfo.getProfileId()
				and IsActive = true
				and Id != :UserInfo.getUserId()
			limit 1 ];
		insert contract;
		insert regList;
		Opportunity updatedOpp = opportunity.clone(true);
		updatedOpp.Country_of_Order__c = regList[1].Country__c;
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opportunity.Id=>opportunity},new Map<Id,Opportunity>{updatedOpp.Id=>updatedOpp},false);
		Test.startTest();
		System.runAs(runAsUser) {
			afterTrigger.syncContracts();
		}
		Test.stopTest();
		Contract c = [
			select LastModifiedById
			from Contract
			where Id = :contract.Id ];
		System.assertEquals(c.LastModifiedById,runAsUser.Id);
	}

	@IsTest
	static void submitForBUApprovalTest() {
		RecordType pocRecordType = [SELECT Id from RecordType where Name='Proof of Concept' and sObjectType='Opportunity' LIMIT 1];
		insert new RecordTypeLookup__c(Name='Proof of Concept',IdForOpportunity__c=pocRecordType.Id);
		Opportunity poc = opportunity;
		poc.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		poc.POC_Approved_by_SA_Management__c = true;
		insert poc;
		Opportunity poc2 = poc.Clone(true);
		poc2.POC_Submit_for_BU_Approval__c = true;
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(new Map<Id,Opportunity>{poc.Id=>poc},new Map<Id,Opportunity>{poc.Id=>poc2},false);
		afterTrigger.submitForBUApproval();
	}

	@IsTest
	static void linkSolutionsTest() {
		insert new BooleanSetting__c(Name=OpportunityTriggerAfter2.LINK_SOLUTIONS_SETTING,Value__c=false);
		insert opportunity;
		opportunity.CreatedFromSolution__c = solutionId;
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
			null,
			new Map<Id,Opportunity>{opportunity.Id=>opportunity},
			false );
		afterTrigger.linkSolutions();
		StrategicPlan_SolutionOpportunity__c solutionOpportunity = [
			select
				StrategicPlan_Solution__c,
				Opportunity__c
			from StrategicPlan_SolutionOpportunity__c
			where Opportunity__c = :opportunity.Id];
		System.assertEquals(solutionId,solutionOpportunity.StrategicPlan_Solution__c);
		System.assert(! afterTrigger.hasErrors);
		delete solution;
		afterTrigger.linkSolutions();
		System.assert(afterTrigger.hasErrors);
	}

	static void updateServicesAllocationsTest(Opportunity opp1) {
		Opportunity opp2 = opp1.clone(true);
		opp2.Services_Product_Line_1__c = 'line 1';
		opp2.Services_Effort_Allocation_1__c = 0;
		opp2.Services_Product_Line_2__c = 'line 2';
		opp2.Services_Product_Line_3__c = 'line 3';
		opp2.Services_Effort_Allocation_3__c = 0;
		opp2.Services_Product_Line_4__c = 'line 4';
		opp2.Services_Product_Line_5__c = 'line 5';
		opp2.Services_Effort_Allocation_5__c = 0;
		opp2.Services_Product_Line_6__c = 'line 6';
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opp1.Id=>opp1},
			new Map<Id,Opportunity>{opp1.Id=>opp2},
			false );
		afterTrigger.updateServicesAllocations();
		List<ServicesAllocation__c> servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		// we should have no allocations, because we didn't provide a non-zero effort allocation
		System.assert(servicesAllocations.isEmpty(),'Unexpected services allocations: '+servicesAllocations);
		opp2.Services_Effort_Allocation_1__c = 5.0;
		opp2.Services_Effort_Allocation_2__c = 10.0;
		opp2.Services_Effort_Allocation_3__c = 15.0;
		opp2.Services_Effort_Allocation_4__c = 18.0;
		opp2.Services_Effort_Allocation_5__c = 20.0;
		opp2.Services_Effort_Allocation_6__c = 22.0;
		afterTrigger.updateServicesAllocations();
		servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		System.assertEquals(6,servicesAllocations.size());
		System.assertEquals('line 1',servicesAllocations[0].ServicesProductLine__c);
		System.assertEquals(5.0,servicesAllocations[0].ServicesEffortAllocation__c);
		System.assertEquals('line 2',servicesAllocations[1].ServicesProductLine__c);
		System.assertEquals(10.0,servicesAllocations[1].ServicesEffortAllocation__c);
		System.assertEquals('line 3',servicesAllocations[2].ServicesProductLine__c);
		System.assertEquals(15.0,servicesAllocations[2].ServicesEffortAllocation__c);
		System.assertEquals('line 4',servicesAllocations[3].ServicesProductLine__c);
		System.assertEquals(18.0,servicesAllocations[3].ServicesEffortAllocation__c);
		System.assertEquals('line 5',servicesAllocations[4].ServicesProductLine__c);
		System.assertEquals(20.0,servicesAllocations[4].ServicesEffortAllocation__c);
		System.assertEquals('line 6',servicesAllocations[5].ServicesProductLine__c);
		System.assertEquals(22.0,servicesAllocations[5].ServicesEffortAllocation__c);
		afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opp1.Id=>opp2.clone(true)},
			new Map<Id,Opportunity>{opp1.Id=>opp2},
			false );
		afterTrigger.updateServicesAllocations();
		servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		System.assertEquals(6,servicesAllocations.size());
		System.assertEquals('line 1',servicesAllocations[0].ServicesProductLine__c);
		System.assertEquals(5.0,servicesAllocations[0].ServicesEffortAllocation__c);
		System.assertEquals('line 2',servicesAllocations[1].ServicesProductLine__c);
		System.assertEquals(10.0,servicesAllocations[1].ServicesEffortAllocation__c);
		System.assertEquals('line 3',servicesAllocations[2].ServicesProductLine__c);
		System.assertEquals(15.0,servicesAllocations[2].ServicesEffortAllocation__c);
		System.assertEquals('line 4',servicesAllocations[3].ServicesProductLine__c);
		System.assertEquals(18.0,servicesAllocations[3].ServicesEffortAllocation__c);
		System.assertEquals('line 5',servicesAllocations[4].ServicesProductLine__c);
		System.assertEquals(20.0,servicesAllocations[4].ServicesEffortAllocation__c);
		System.assertEquals('line 6',servicesAllocations[5].ServicesProductLine__c);
		System.assertEquals(22.0,servicesAllocations[5].ServicesEffortAllocation__c);
		afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opp1.Id=>opp2},
			new Map<Id,Opportunity>{opp1.Id=>opp1},
			false );
		afterTrigger.updateServicesAllocations();
		servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		// we should have no allocations, because we didn't provide a non-zero effort allocation
		System.assert(servicesAllocations.isEmpty(),'Unexpected services allocations: '+servicesAllocations);
	}

	static void updateServicesAllocations2Test(Opportunity opp1) {
		Opportunity opp2 = opp1.clone(true);
		opp2.Services_Product_Line_1__c = 'line 1';
		opp2.Services_Product_Line_2__c = 'line 2';
		opp2.Services_Product_Line_3__c = 'line 3';
		opp2.Services_Product_Line_4__c = 'line 4';
		opp2.Services_Product_Line_5__c = 'line 5';
		opp2.Services_Product_Line_6__c = 'line 6';
		opp2.Services_Effort_Allocation_1__c = 5.0;
		opp2.Services_Effort_Allocation_2__c = 10.0;
		opp2.Services_Effort_Allocation_3__c = 15.0;
		opp2.Services_Effort_Allocation_4__c = 18.0;
		opp2.Services_Effort_Allocation_5__c = 20.0;
		opp2.Services_Effort_Allocation_6__c = 22.0;
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opp1.Id=>opp1},
			new Map<Id,Opportunity>{opp1.Id=>opp2},
			false );
		afterTrigger.updateServicesAllocations();
		List<ServicesAllocation__c> servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		System.assertEquals(6,servicesAllocations.size());
		System.assertEquals('line 1',servicesAllocations[0].ServicesProductLine__c);
		System.assertEquals(5.0,servicesAllocations[0].ServicesEffortAllocation__c);
		System.assertEquals('line 2',servicesAllocations[1].ServicesProductLine__c);
		System.assertEquals(10.0,servicesAllocations[1].ServicesEffortAllocation__c);
		System.assertEquals('line 3',servicesAllocations[2].ServicesProductLine__c);
		System.assertEquals(15.0,servicesAllocations[2].ServicesEffortAllocation__c);
		System.assertEquals('line 4',servicesAllocations[3].ServicesProductLine__c);
		System.assertEquals(18.0,servicesAllocations[3].ServicesEffortAllocation__c);
		System.assertEquals('line 5',servicesAllocations[4].ServicesProductLine__c);
		System.assertEquals(20.0,servicesAllocations[4].ServicesEffortAllocation__c);
		System.assertEquals('line 6',servicesAllocations[5].ServicesProductLine__c);
		System.assertEquals(22.0,servicesAllocations[5].ServicesEffortAllocation__c);

		// now we are ready to try the future call
		OpportunityTriggerAfter2.updateServicesAllocationsNow = false;
		afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{opp1.Id=>opp2},
			new Map<Id,Opportunity>{opp1.Id=>opp1},
			false );
		Test.startTest();
		afterTrigger.updateServicesAllocations();
		Test.stopTest();
		servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		System.assert(servicesAllocations.isEmpty(),'Unexpected services allocations: '+servicesAllocations);

		// now check if the future version of the static call can create services allocations
		OpportunityTriggerAfter2.updateServicesAllocationsStatic(false,new List<Opportunity>{opp2});
		servicesAllocations = [
			select ServicesProductLine__c,ServicesEffortAllocation__c
			from ServicesAllocation__c where Opportunity__c = :opp1.Id
			order by ServicesProductLine__c, ServicesEffortAllocation__c ];
		System.assertEquals(6,servicesAllocations.size());
		System.assertEquals('line 1',servicesAllocations[0].ServicesProductLine__c);
		System.assertEquals(5.0,servicesAllocations[0].ServicesEffortAllocation__c);
		System.assertEquals('line 2',servicesAllocations[1].ServicesProductLine__c);
		System.assertEquals(10.0,servicesAllocations[1].ServicesEffortAllocation__c);
		System.assertEquals('line 3',servicesAllocations[2].ServicesProductLine__c);
		System.assertEquals(15.0,servicesAllocations[2].ServicesEffortAllocation__c);
		System.assertEquals('line 4',servicesAllocations[3].ServicesProductLine__c);
		System.assertEquals(18.0,servicesAllocations[3].ServicesEffortAllocation__c);
		System.assertEquals('line 5',servicesAllocations[4].ServicesProductLine__c);
		System.assertEquals(20.0,servicesAllocations[4].ServicesEffortAllocation__c);
		System.assertEquals('line 6',servicesAllocations[5].ServicesProductLine__c);
		System.assertEquals(22.0,servicesAllocations[5].ServicesEffortAllocation__c);
	}

	@IsTest
	static void updateServicesAllocationsTest() {
		BooleanSetting__c servicesSetting = new BooleanSetting__c(Name=OpportunityTriggerAfter2.SERVICES_ALLOCATIONS_MIGRATE_DATA_SETTING,Value__c=true);
		upsert servicesSetting;
		insert opportunity;
		Test.startTest();
		updateServicesAllocationsTest(opportunity.clone(true));
		servicesSetting.Value__c = false;
		update servicesSetting;
		updateServicesAllocationsTest(opportunity.clone(true));
		Test.stopTest();
	}

	@IsTest
	static void updateServicesAllocations2Test() {
		BooleanSetting__c servicesSetting = new BooleanSetting__c(Name=OpportunityTriggerAfter2.SERVICES_ALLOCATIONS_MIGRATE_DATA_SETTING,Value__c=false);
		upsert servicesSetting;
		insert opportunity;
		updateServicesAllocations2Test(opportunity.clone(true));
	}

	@IsTest(SeeAllData=true) // need to access Email Templates
	static void templateTest() {
		// coverage only
		EmailTemplate et = OpportunityTriggerAfter2.POC_OWNER_CHANGE_EMAIL_TEMPLATE;
	}

	@IsTest
	static void notifyOwnerChange() {
		List<User> users = [
			select Email
			from User
			where Id != :UserInfo.getUserId()
				and ProfileId = :UserInfo.getProfileId()
				and IsActive = true
			limit 3];
		opportunity.RecordTypeId = OpportunityTriggerAfter2.pocRecordTypeId;
		opportunity.Owner__c = opportunity.OwnerId = users[0].Id;
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		insert opportunity;
		AbstractTrigger.setBooleanSettings('Opp_After.',true);
		Opportunity oppNew = opportunity.clone(true);
		oppNew.Owner__c = oppNew.OwnerId = users[1].Id;
		insert new OpportunityTeamMember(
			OpportunityId=opportunity.Id,
			TeamMemberRole='Engagement SA',
			UserId = users[2].Id);
		final OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
			new Map<Id,Opportunity>{ opportunity.Id => opportunity },
			new Map<Id,Opportunity>{ oppNew.Id => oppNew },
			false );
		OpportunityTriggerAfter2.POC_OWNER_CHANGE_EMAIL_TEMPLATE = new EmailTemplate(
			Name='POC_Owner_Change',
			DeveloperName = 'POC_Owner_Change',
			Body='OPP_LIST',
			HtmlValue='OPP_LIST',
			Subject='Anything',
			Description='Anything');
		Test.startTest();
		Messaging.SingleEmailMessage mail = afterTrigger.notifyOwnerChange();
		Set<String> toAddresses = new Set<String>(mail.getToAddresses());
		System.assert(toAddresses.contains(users[0].Email),'Missing user[0]\'s email address');
		System.assert(! toAddresses.contains(users[1].Email),'Contains user[1]\'s email address');
		System.assert(toAddresses.contains(users[2].Email),'Missing user[2]\'s email address');
		Test.stopTest();
	}

	@IsTest
	static void syncShippingContactsTest() {
		opportunity.RecordTypeId = OpportunityTriggerBefore2.zeroValueOpportunityRecordTypeId;
		if(opportunity.RecordTypeId != null) {
			insert contact;
			getOpportunityLastModifiedDate();
			Opportunity newOpp = opportunity.clone(true,true,true,true);
			// testing insert
			newOpp.ShippingContact__c = contact.Id;
			Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{opportunity.Id=>opportunity};
			Map<Id,Opportunity> newMap = new Map<Id,Opportunity>{opportunity.Id=>newOpp};
			OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(oldMap,newMap,false);
			Test.startTest();
			afterTrigger.syncShippingContacts();
			Integer ocrCount = [
				select count()
				from OpportunityContactRole
				where OpportunityId = :opportunity.Id
					and ContactId = :contact.Id
					and Role = 'Shipping Contact' ];
			System.assertEquals(1,ocrCount);
			// testing delete
			afterTrigger = new OpportunityTriggerAfter2(newMap,oldMap,false);
			afterTrigger.syncShippingContacts();
			Test.stopTest();
			ocrCount = [
				select count()
				from OpportunityContactRole
				where OpportunityId = :opportunity.Id
					and ContactId = :contact.Id
					and Role = 'Shipping Contact' ];
			System.assertEquals(0,ocrCount);
		}
	}

	@IsTest
	static void removeFinancialPartnerTest() {
		opportunity.FulfillmentChannel__c = 'Distributor';
		insert opportunity;
		OpportunityPartner__c financialPartner = getOpportunityPartner(opportunity);

		Opportunity updatedOpportunity = opportunity.clone(true,true,true,true);
		updatedOpportunity.FulfillmentChannel__c = 'Direct End Customer';

		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{opportunity.Id=>opportunity};
		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>{opportunity.Id=>updatedOpportunity};
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(oldMap,newMap,false);

		Test.startTest();
		afterTrigger.removeFinancialPartner();
		Test.stopTest();

		List<OpportunityPartner__c> financialPartners = [
			SELECT Id
			FROM OpportunityPartner__c
			WHERE Opportunity__c = :opportunity.Id
			AND RelationshipType__c = 'Financial'];

		System.assert(financialPartners.isEmpty());
	}

	@IsTest
	static void orderManagementTest() {
		insert regList;
		insert opportunity;
		Order_Tracking__c ot = new Order_Tracking__c(
			Opportunity__c=opportunity.Id,
			Order_Status__c = OpportunityTriggerAfter2.SUBMITTED_FOR_OM_REVIEW_PLV);
		insert ot;
		Opportunity opp2 = opportunity.clone(true,true,true,true);
		opp2.Order_Status__c = OpportunityTriggerAfter2.SUBMITTED_FOR_OM_REVIEW_PLV;
		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{opportunity.Id=>opportunity};
		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>{opportunity.Id=>opp2};
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(oldMap,newMap,false);
		Test.startTest();
		System.assertEquals(0,afterTrigger.oppIdsBackOut.size());
		System.assertEquals(1,afterTrigger.oppIdsSubmittedForReview.size());
		System.assert(afterTrigger.oppIdsSubmittedForReview.contains(opportunity.Id));
		afterTrigger.submitToOrderManagement();
		Task t = [select Status,Subject,IsClosed from Task where WhatId = :opportunity.Id]; 
		System.assertEquals(OpportunityTriggerAfter2.NOT_STARTED_PLV,t.Status);
		System.assertEquals(false,t.IsClosed);
		System.assert(t.Subject.startsWith('Order Submitted for Processing '),'Unexpected Subject: '+t.Subject);
		afterTrigger.tasks = null;
		afterTrigger.submitToOrderManagement();
		t = [select Status from Task where WhatId = :opportunity.Id]; 
		System.assertEquals(OpportunityTriggerAfter2.NOT_STARTED_PLV,t.Status);
		afterTrigger.tasks = null;
		afterTrigger.oppIdsBackOut = null;
		afterTrigger.oppIdsSubmittedForReview = null;
		opportunity.StageName = OpportunityTriggerBefore2.CLOSED_WON_PLV;
		System.assertEquals(1,afterTrigger.oppIdsBackOut.size());
		System.assert(afterTrigger.oppIdsBackOut.contains(opportunity.Id));
		System.assertEquals(0,afterTrigger.oppIdsSubmittedForReview.size());
		System.assertEquals(1,afterTrigger.queriedOpportunities.size());
		System.assertEquals(opportunity.Id,afterTrigger.queriedOpportunities[0].Id);
		System.assertEquals(1,afterTrigger.queriedOpportunities[0].Order_Tracking__r.size());
		afterTrigger.backoutOrder();
		t = [select Status from Task where WhatId = :opportunity.Id]; 
		System.assertEquals(OpportunityTriggerAfter2.SYSTEM_DEFERRED_PLV,t.Status);
		afterTrigger.queriedOpportunities = null;
		System.assertEquals(0,afterTrigger.queriedOpportunities[0].Order_Tracking__r.size());
		Test.stopTest();
	}

	@isTest
	static void createEventRecordsTest() {
		insert opportunity;
		Opportunity opp2 = opportunity.clone(true,true,true,true);
		opp2.CloseDate = opp2.CloseDate.addYears(1);
		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{opportunity.Id=>opportunity};
		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>{opportunity.Id=>opp2};
		OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(oldMap,newMap,false);
		Test.startTest();
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2.scheduledApex = null;
		afterTrigger.createEventRecords();
		List<Event__c> events = [select Id,Processed__c from Event__c where Opportunity__c = :opp2.Id and Processed__c = false];
		System.assertEquals(1,events.size());
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2.scheduledApex = new ScheduledApex__c(Name=Opportunity_Split_Batchable2.JOB_NAME);
//US80608(rollback DE7583) 		afterTrigger.createEventRecords();
//US80608(rollback DE7583) 		System.assertEquals(1,[select count() from Event__c where Opportunity__c = :opp2.Id and Processed__c = false]);
		for(Event__c e : events) {
			e.Processed__c = true;
		}
		update events;
		afterTrigger.createEventRecords();
		System.assertEquals(1,[select count() from Event__c where Opportunity__c = :opp2.Id and Processed__c = false]);
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2.scheduledApex = null;
//US80608(rollback DE7583) 		afterTrigger.createEventRecords();
//US80608(rollback DE7583) 		System.assertEquals(1,[select count() from Event__c where Opportunity__c = :opp2.Id and Processed__c = false]);
		Test.stopTest();
	}

	@isTest
	static void countryOppSplitAUTest() {
		Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
		Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];
		User standardUser = new User(
			Alias = 'standt',
			Email='stcTestStandardUser@testorg.com', 
			EmailEncodingKey='UTF-8', 
			LastName='Testing', 
			LanguageLocaleKey='en_US', 
			LocaleSidKey='en_US',
			ProfileId = standard.Id, 
			TimeZoneSidKey='America/Los_Angeles',
			UserName='stcTestStandardUser@testorg.com');
		insert standardUser;

		List<OpportunitySplit> oppSplits;
		system.runAs(new User(Id=UserInfo.getUserId())) {
			//create opportunity
			insert opportunity;
			//create opportunity team member
			insert new List<OpportunityTeamMember>{
				new OpportunityTeamMember(
					TeamMemberRole = 'Sales Manager',
					OpportunityId = opportunity.Id,
					UserId        = opportunity.OwnerId),
				new OpportunityTeamMember(
					TeamMemberRole = 'Sales Manager',
					OpportunityId = opportunity.Id,
				UserId        = standardUser.Id) };
			OpportunitySplitType ost =  [
				SELECT Id
				FROM OpportunitySplitType
				WHERE MasterLabel = 'Overlay Credit'
				Limit 1];
			oppSplits = new List<OpportunitySplit>{
				new OpportunitySplit(
					OpportunityId=opportunity.Id,
					SplitOwnerId=opportunity.OwnerId,
					SplitPercentage=20,
					SplitTypeId=ost.Id),
				new OpportunitySplit(
					OpportunityId=opportunity.Id,
					SplitOwnerId=standardUser.Id,
					SplitPercentage=20,
					SplitTypeId=ost.Id) };
			insert oppSplits;
			//update country of order
			Opportunity opp2 = opportunity.clone(true);
			opp2.Country_of_Order__c = 'testCountry';
			OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(
				new Map<Id,Opportunity>{opportunity.Id=>opportunity},
				new Map<Id,Opportunity>{opportunity.Id=>opp2},
				false );

			Test.startTest();
			afterTrigger.countryOppSplitAU();
			Test.stopTest();
		}
		oppSplits = [
			SELECT Country__c 
			FROM OpportunitySplit
			WHERE OpportunityId =: opportunity.Id
				AND Id in :(new Map<Id,OpportunitySplit>(oppSplits).keySet()) ];
		System.assertEquals(2,oppSplits.size());
		for(OpportunitySplit oppSplit : oppSplits) {
			system.assertEquals( 'testCountry', oppSplit.Country__c );
		}
	}

	@IsTest(SeeAllData=true) // need all data to access price books?
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityTriggerAfter2.processTrigger(null,new Map<Id,Opportunity>{null=>opportunity},false);
		// insert the opportunity, again with the triggers off
		insert opportunity;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Opp_After.',true);
		Opportunity opp2 = opportunity.clone(true);
		Test.startTest();
		// insert test
		OpportunityTriggerAfter2.processTrigger(null,new Map<Id,Opportunity>{opp2.Id=>opp2},false);
		// update test
		OpportunityTriggerAfter2.processTrigger(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new Map<Id,Opportunity>{opp2.Id=>opp2},false);
		// delete test
		OpportunityTriggerAfter2.processTrigger(new Map<Id,Opportunity>{opportunity.Id=>opportunity},null,false);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('Opp_After.');
	}

	@IsTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Opp_After.',new List<Opportunity>{opportunity});
	}

}