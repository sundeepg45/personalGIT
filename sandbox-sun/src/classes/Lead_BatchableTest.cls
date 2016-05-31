/**
 * This class unit tests the Lead_Batchable class.
 *
 * @version 2015-12-18
 * @author	Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - Created - Merged from lead status update tests and lead routing assignment tests
 */
@isTest
private class Lead_BatchableTest {
	static List<Lead_SuperRegion_Mapping__c> superRegionMappings {
		get {
			if(superRegionMappings == null) {
				superRegionMappings = new List<Lead_SuperRegion_Mapping__c>{
					new Lead_SuperRegion_Mapping__c(
						Country__c = 'Narnia-',
						Country_Iso_Code__c = 'N-',
						SuperRegion__c = 'APAC'),
					new Lead_SuperRegion_Mapping__c(
						Country__c = 'Narnia@',
						Country_Iso_Code__c = 'N@',
						SuperRegion__c = 'EMEA'),
					new Lead_SuperRegion_Mapping__c(
						Country__c = 'Narnia_',
						Country_Iso_Code__c = 'N_',
						SuperRegion__c = 'LATAM'),
					new Lead_SuperRegion_Mapping__c(
						Country__c = 'Narnia#',
						Country_Iso_Code__c = 'N#',
						SuperRegion__c = 'NA')
				};
				insert superRegionMappings;
			}
			return superRegionMappings;
		}
	}

	static List<LeadCronRoutingRule2__c> leadCronRoutingRules {
		get {
			if(leadCronRoutingRules == null) {
				leadCronRoutingRules = new List<LeadCronRoutingRule2__c>{
					new LeadCronRoutingRule2__c(
						Name='Test Rule 1',
						OwnerId__c = UserInfo.getUserId(),
						Super_Region__c = 'APAC;EMEA',
						Lead_Ranking__c = 'A1;A2'),
					new LeadCronRoutingRule2__c(
						Name='Test Rule 2',
						OwnerId__c = UserInfo.getUserId(),
						Super_Region__c = 'LATAM',
						Lead_Ranking__c = 'B1')
				};
				insert leadCronRoutingRules;
			}
			return leadCronRoutingRules;
		}
	}

	static Lead createLead() {
		return new Lead(
			OwnerId = UserInfo.getUserId(),
			LastName='Accenture',
			RecordTypeId = Lead_GlobalManagement.NA_SALES_LEAD_RECORDTYPE_ID,
			Company='Accenture',
			Status='New',
			Lead_Ranking__c = 'P1',
			Products_of_Interest__c='JBoss',
			LeadSourceDetail__c='SD_RONA',
			Country = 'Narnia',
			Partner_Opt_In__c=true,
			PenaltyBoxExpiration__c=null);
	}

	static Lead createLead(Id ownerId,Lead_SuperRegion_Mapping__c superRegionMapping,String leadRanking) {
		return new Lead(
			OwnerId = ownerId,
			LastName ='TestLead',
			Email='lead@email.com',
			Title='None',
			Lead_Ranking__c = leadRanking,
			LeadSourceDetail__c='Test Source',
			Route_Around__c = true,
			Status='New',
			Stage__c='Test Stage',
			Super_Region__c=superRegionMapping.SuperRegion__c,
			Company='Company',
			Country=superRegionMapping.Country__c,
			State='NC1',
			Iso_Country_Code__c=superRegionMapping.Country_Iso_Code__c,
			Products_of_Interest__c='Test Product',
			Partner_Opt_In__c=true);
	}

	static List<Lead> leads {
		get {
			if(leads == null) {
				leads = new List<Lead>();
				for(Id ownerId : new List<Id>{UserInfo.getUserId(),Util.globalLeadRoutingQueue}) {
					for(Lead_SuperRegion_Mapping__c superRegionMapping : superRegionMappings) {
						for(String ranking : new List<String>{'A1','A2','B1','D1'}) {
							leads.add(createLead(ownerId,superRegionMapping,ranking));
						}
					}
				}
				insert leads;
			}
			return leads;
		}
	}

	@isTest
	static void startTest() {
		System.assert(!leadCronRoutingRules.isEmpty(),'Failed to insert routing rules');
		System.assert(!leads.isEmpty(),'Failed to insert leads');
		Map<Id,Lead> leadsMap = new Map<Id,Lead>(leads);
		for(Lead ld : [select OwnerId,Lead_Ranking__c,Super_Region__c from Lead where Id in :leadsMap.keySet()]) {
			if(ld.OwnerId == UserInfo.getUserId()) {
				System.assertEquals(leadsMap.get(ld.Id).OwnerId,ld.OwnerId);
			}
			System.assertEquals(leadsMap.get(ld.Id).Lead_Ranking__c,ld.Lead_Ranking__c);
			System.assertEquals(leadsMap.get(ld.Id).Super_Region__c,ld.Super_Region__c);
		}
		Lead_Batchable batchable = new Lead_Batchable();
		batchable.lastProcessed.Value__c = DateTime.now();
		Test.startTest();
		System.assert(batchable.hasWork(),'Expected to have work');
//		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
//		ssc.setPageSize(100);
//		List<Lead> lds = ssc.getRecords();
		List<Lead> lds = batchable.start(null);
		Test.stopTest();
		System.assert(batchable.errorList.isEmpty(),'Errors occured in the start method:\n'+batchable.errorList);
		leadsMap = new Map<Id,Lead>(lds);
		System.assertNotEquals(null,leadsMap.remove(leads.get(0).Id),'Does not have '+leads.get(0)+leadsMap); // currentUser, APAC, A1
		System.assertNotEquals(null,leadsMap.remove(leads.get(1).Id),'Does not have '+leads.get(1)); // currentUser, APAC, A2
		System.assertNotEquals(null,leadsMap.remove(leads.get(4).Id),'Does not have '+leads.get(4)); // currentUser, EMEA, A1
		System.assertNotEquals(null,leadsMap.remove(leads.get(5).Id),'Does not have '+leads.get(5)); // currentUser, EMEA, A2
		System.assertNotEquals(null,leadsMap.remove(leads.get(10).Id),'Does not have '+leads.get(10)); // currentUser, LATAM, A2
		System.assert(leadsMap.isEmpty(),'Contains extra leads: '+leadsMap);
	}

	@isTest
	static void executeTest() {
		System.assert(!leads.isEmpty(),'Failed to insert leads');
		for(Lead ld : leads) {
			ld.Company = 'Updated';
		}
		Map<Id,Lead> leadMap = new Map<Id,Lead>(leads);
		Lead_Batchable batchable = new Lead_Batchable();
		Test.startTest();
		batchable.execute(null,leads);
		Test.stopTest();
		System.assert(batchable.errorList.isEmpty(),'Errors occured in the start method:\n'+batchable.errorList);
		for(Lead ld : [
			select Company
			from Lead
			where Id in :leadMap.keySet()])
		{
			System.assertEquals(leadMap.get(ld.Id).Company,ld.Company,'Failed to update lead: '+ld);
		}
	}

	@isTest
	static void executeTest2() {
		User u = [
			select Id
			from User
			where ProfileId = :UserInfo.getProfileId()
				and Id != :UserInfo.getUserId()
				and IsActive = true 
			limit 1 ];
		upsert new StringSetting__c(Name=Lead_Batchable.GLR_ERROR_QUEUE_SETTING,Value__c=u.Id);
		Lead_Batchable.routeToGLRErrorQUeue = true;
		System.assert(!leads.isEmpty(),'Failed to insert leads');
		Map<Id,Lead> leadMap = new Map<Id,Lead>(leads);
		Lead_Batchable batchable = new Lead_Batchable();
		AbstractTrigger.setBooleanSettings('Lead_Before.',false);
		AbstractTrigger.setBooleanSettings('Lead_After.',false);
		Test.startTest();
		batchable.execute(null,leads);
		Test.stopTest();
		for(Lead ld : [
			select OwnerId, Assignment_Error__c
			from Lead
			where Id in :leadMap.keySet()])
		{
//			System.assertEquals(u.Id,ld.OwnerId);
			System.assertNotEquals(null,ld.Assignment_Error__c);
		}
	}

	@IsTest
	static void statusUpdateTest() {
		Lead lead1 = createLead();
		lead1.Next_Status_Update__c = DateTime.now().addDays(-1);
		Lead lead2 = createLead();
		lead2.Next_Status_Update__c = DateTime.now().addDays(1);
		List<Lead> leads1 = new List<Lead>{lead1,lead2};
		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,false);
		insert leads1;
		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,true);
		Map<Id,Lead> leadMap = new Map<Id,Lead>([
			select Next_Status_Update__c
			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
		System.assertNotEquals(null,leadMap.get(lead1.Id).Next_Status_Update__c);
		System.assertNotEquals(null,leadMap.get(lead2.Id).Next_Status_Update__c);
		Test.StartTest();
		Lead_Batchable batchable = new Lead_Batchable();
		List<Lead> leads2 = batchable.start(null);
		System.assertEquals(1,leads2.size());
		batchable.execute(null,leads2);
		System.assert(batchable.errorList.isEmpty());
		batchable.finish((Database.BatchableContext)null);
		Test.StopTest();
		leadMap = new Map<Id,Lead>([
			select Next_Status_Update__c
			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
		System.assertEquals(null,leadMap.get(lead1.Id).Next_Status_Update__c);
		System.assertNotEquals(null,leadMap.get(lead2.Id).Next_Status_Update__c);
	}

	@isTest
	static void penaltyBoxTest() {
		Lead lead1 = createLead();
		lead1.Next_Status_Update__c = DateTime.now().addDays(-1);
		lead1.PenaltyBoxExpiration__c = DateTime.now().addDays(-1);
		Lead lead2 = createLead();
		lead2.Next_Status_Update__c = DateTime.now().addDays(-1);
		lead2.PenaltyBoxExpiration__c = DateTime.now().addDays(1);
		Lead lead3 = createLead();
		lead3.Next_Status_Update__c = DateTime.now().addDays(-1);
		lead3.PenaltyBoxExpiration__c = null;
		Lead lead4 = createLead();
		lead4.Next_Status_Update__c = null;
		lead4.PenaltyBoxExpiration__c = DateTime.now().addDays(-1);
		List<Lead> leads1 = new List<Lead>{lead1,lead2,lead3,lead4};
		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,false);
		insert leads1;
		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,true);
		Map<Id,Lead> leadMap = new Map<Id,Lead>([
			select Next_Status_Update__c, PenaltyBoxExpiration__c
			from Lead where Id in (:lead1.Id,:lead2.Id,:lead3.Id,:lead4.Id) ]);
		System.assertNotEquals(null,leadMap.get(lead1.Id).PenaltyBoxExpiration__c);
		System.assertNotEquals(null,leadMap.get(lead2.Id).PenaltyBoxExpiration__c);
		System.assertEquals(null,leadMap.get(lead3.Id).PenaltyBoxExpiration__c);
		System.assertNotEquals(null,leadMap.get(lead4.Id).PenaltyBoxExpiration__c);

		Lead_Batchable batchable = new Lead_Batchable();
		batchable.lastProcessed.Value__c = DateTime.now();

		Test.StartTest();
		System.assert(batchable.hasWork(),'Expected to have work');
		List<Lead> leads2 = batchable.start(null);
		//System.assertEquals(leads1.size(),leads2.size());
		batchable.execute(null,leads2);
		//System.assert(batchable.errorList.isEmpty());
		batchable.finish((Database.BatchableContext)null);
		Test.StopTest();

		//leadMap = new Map<Id,Lead>([
		//	select Next_Status_Update__c, PenaltyBoxExpiration__c
		//	from Lead where Id in (:lead1.Id,:lead2.Id,:lead3.Id,:lead4.Id) ]);
		//System.assertEquals(null,leadMap.get(lead1.Id).PenaltyBoxExpiration__c);
		//System.assertNotEquals(null,leadMap.get(lead2.Id).PenaltyBoxExpiration__c);
		//System.assertEquals(null,leadMap.get(lead3.Id).PenaltyBoxExpiration__c);
		//System.assertEquals(null,leadMap.get(lead4.Id).PenaltyBoxExpiration__c);
	}

	@isTest(SeeAllData=true)
	static void statusUpdateFailureTest() {
		List<Lead> leads1 = [select Id from Lead where IsConverted = true limit 10];
		Test.StartTest();
		Lead_Batchable batchable = new Lead_Batchable();
		batchable.start(null);
		batchable.execute(null,leads1);
		System.assert(! batchable.errorList.isEmpty());
		batchable.finish((Database.BatchableContext)null);
		Test.StopTest();
	}

	@IsTest
	static void desiredOpportunityCloseDateTest() {
		Lead lead1 = createLead();
		lead1.Desired_Opportunity_CloseDate__c = Date.today().addDays(1);
		Lead lead2 = createLead();
		lead2.Desired_Opportunity_CloseDate__c = Date.today().addDays(2);
		List<Lead> leads1 = new List<Lead>{lead1,lead2};
		insert leads1;
		Map<Id,Lead> leadMap = new Map<Id,Lead>([
			select Desired_Opportunity_CloseDate__c
			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
		System.assertNotEquals(null,leadMap.get(lead1.Id).Desired_Opportunity_CloseDate__c);
		System.assertNotEquals(null,leadMap.get(lead2.Id).Desired_Opportunity_CloseDate__c);

		Lead_Batchable.DESIRED_CLOSE_DATE_TIMEOUT = -1;
		Lead_Batchable batchable = new Lead_Batchable();
		batchable.lastProcessed.Value__c = DateTime.now();

		Test.StartTest();
		System.assert(batchable.hasWork(),'Expected to have work');
		List<Lead> leads2 = batchable.start(null);
		System.assertEquals(leads1.size(),leads2.size());
		batchable.execute(null,leads2);
		System.assert(batchable.errorList.isEmpty());
		batchable.finish((Database.BatchableContext)null);
		Test.StopTest();

		leadMap = new Map<Id,Lead>([
			select Desired_Opportunity_CloseDate__c
			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
		System.assertEquals(null,leadMap.get(lead1.Id).Desired_Opportunity_CloseDate__c);
		System.assertEquals(null,leadMap.get(lead2.Id).Desired_Opportunity_CloseDate__c);
	}
}