/**
 * This class unit tests the Lead_RoutingAssignment class.
 *
 * @version 2015-12-18
 * @author	Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - Depreciated - Merged into Lead_BatchableTest
 * 2012-08-21 - created
 */
@isTest
private class Lead_RoutingAssignmentTest {
//depreciated	static List<Lead_SuperRegion_Mapping__c> superRegionMappings {
//depreciated		get {
//depreciated			if(superRegionMappings == null) {
//depreciated				superRegionMappings = new List<Lead_SuperRegion_Mapping__c>{
//depreciated					new Lead_SuperRegion_Mapping__c(
//depreciated						Country__c = 'Narnia-',
//depreciated						Country_Iso_Code__c = 'N-',
//depreciated						SuperRegion__c = 'APAC'),
//depreciated					new Lead_SuperRegion_Mapping__c(
//depreciated						Country__c = 'Narnia@',
//depreciated						Country_Iso_Code__c = 'N@',
//depreciated						SuperRegion__c = 'EMEA'),
//depreciated					new Lead_SuperRegion_Mapping__c(
//depreciated						Country__c = 'Narnia_',
//depreciated						Country_Iso_Code__c = 'N_',
//depreciated						SuperRegion__c = 'LATAM'),
//depreciated					new Lead_SuperRegion_Mapping__c(
//depreciated						Country__c = 'Narnia#',
//depreciated						Country_Iso_Code__c = 'N#',
//depreciated						SuperRegion__c = 'NA')
//depreciated				};
//depreciated				insert superRegionMappings;
//depreciated			}
//depreciated			return superRegionMappings;
//depreciated		}
//depreciated	}
//depreciated
//depreciated	static List<LeadCronRoutingRule__c> leadCronRoutingRules {
//depreciated		get {
//depreciated			if(leadCronRoutingRules == null) {
//depreciated				leadCronRoutingRules = new List<LeadCronRoutingRule__c>{
//depreciated					new LeadCronRoutingRule__c(
//depreciated						OwnerId = UserInfo.getUserId(),
//depreciated						Super_Region__c = 'APAC;EMEA',
//depreciated						Lead_Ranking__c = 'A1;A2'),
//depreciated					new LeadCronRoutingRule__c(
//depreciated						OwnerId = UserInfo.getUserId(),
//depreciated						Super_Region__c = 'LATAM',
//depreciated						Lead_Ranking__c = 'B1')
//depreciated				};
//depreciated				insert leadCronRoutingRules;
//depreciated			}
//depreciated			return leadCronRoutingRules;
//depreciated		}
//depreciated	}
//depreciated
//depreciated	static Lead createLead(Id ownerId,Lead_SuperRegion_Mapping__c superRegionMapping,String leadRanking) {
//depreciated		return new Lead(
//depreciated			OwnerId = ownerId,
//depreciated			LastName ='TestLead',
//depreciated			Email='lead@email.com',
//depreciated			Title='None',
//depreciated			Lead_Ranking__c = leadRanking,
//depreciated			LeadSourceDetail__c='Test Source',
//depreciated			Route_Around__c = true,
//depreciated			Status='New',
//depreciated			Stage__c='Test Stage',
//depreciated			Super_Region__c=superRegionMapping.SuperRegion__c,
//depreciated			Company='Company',
//depreciated			Country=superRegionMapping.Country__c,
//depreciated			State='NC1',
//depreciated			Iso_Country_Code__c=superRegionMapping.Country_Iso_Code__c,
//depreciated			Products_of_Interest__c='Test Product',
//depreciated			Partner_Opt_In__c=true);
//depreciated	}
//depreciated
//depreciated	static List<Lead> leads {
//depreciated		get {
//depreciated			if(leads == null) {
//depreciated				leads = new List<Lead>();
//depreciated				for(Id ownerId : new List<Id>{UserInfo.getUserId(),Util.globalLeadRoutingQueue}) {
//depreciated					for(Lead_SuperRegion_Mapping__c superRegionMapping : superRegionMappings) {
//depreciated						for(String ranking : new List<String>{'A1','A2','B1','D1'}) {
//depreciated							leads.add(createLead(ownerId,superRegionMapping,ranking));
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated				insert leads;
//depreciated			}
//depreciated			return leads;
//depreciated		}
//depreciated	}
//depreciated
//depreciated	@isTest
//depreciated	static void startTest() {
//depreciated		System.assert(!leadCronRoutingRules.isEmpty(),'Failed to insert routing rules');
//depreciated		System.assert(!leads.isEmpty(),'Failed to insert leads');
//depreciated		Map<Id,Lead> leadsMap = new Map<Id,Lead>(leads);
//depreciated		for(Lead ld : [select OwnerId,Lead_Ranking__c,Super_Region__c from Lead where Id in :leadsMap.keySet()]) {
//depreciated			if(ld.OwnerId == UserInfo.getUserId()) {
//depreciated				System.assertEquals(leadsMap.get(ld.Id).OwnerId,ld.OwnerId);
//depreciated			}
//depreciated			System.assertEquals(leadsMap.get(ld.Id).Lead_Ranking__c,ld.Lead_Ranking__c);
//depreciated			System.assertEquals(leadsMap.get(ld.Id).Super_Region__c,ld.Super_Region__c);
//depreciated		}
//depreciated		Lead_RoutingAssignment lra = new Lead_RoutingAssignment();
//depreciated		Test.startTest();
//depreciated//		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lra.start(null));
//depreciated//		ssc.setPageSize(100);
//depreciated//		List<Lead> lds = ssc.getRecords();
//depreciated		List<Lead> lds = lra.start(null);
//depreciated		Test.stopTest();
//depreciated		System.assert(lra.errorList.isEmpty(),'Errors occured in the start method:\n'+lra.errorList);
//depreciated		leadsMap = new Map<Id,Lead>(lds);
//depreciated		System.assertNotEquals(null,leadsMap.remove(leads.get(0).Id),'Does not have '+leads.get(0)+leadsMap); // currentUser, APAC, A1
//depreciated		System.assertNotEquals(null,leadsMap.remove(leads.get(1).Id),'Does not have '+leads.get(1)); // currentUser, APAC, A2
//depreciated		System.assertNotEquals(null,leadsMap.remove(leads.get(4).Id),'Does not have '+leads.get(4)); // currentUser, EMEA, A1
//depreciated		System.assertNotEquals(null,leadsMap.remove(leads.get(5).Id),'Does not have '+leads.get(5)); // currentUser, EMEA, A2
//depreciated		System.assertNotEquals(null,leadsMap.remove(leads.get(10).Id),'Does not have '+leads.get(10)); // currentUser, LATAM, A2
//depreciated		System.assert(leadsMap.isEmpty(),'Contains extra leads: '+leadsMap);
//depreciated	}
//depreciated
//depreciated	@isTest
//depreciated	static void executeTest() {
//depreciated		System.assert(!leads.isEmpty(),'Failed to insert leads');
//depreciated		for(Lead ld : leads) {
//depreciated			ld.Company = 'Updated';
//depreciated		}
//depreciated		Map<Id,Lead> leadMap = new Map<Id,Lead>(leads);
//depreciated		Lead_RoutingAssignment lra = new Lead_RoutingAssignment();
//depreciated		Test.startTest();
//depreciated		lra.execute(null,leads);
//depreciated		Test.stopTest();
//depreciated		System.assert(lra.errorList.isEmpty(),'Errors occured in the start method:\n'+lra.errorList);
//depreciated		for(Lead ld : [
//depreciated			select Company
//depreciated			from Lead
//depreciated			where Id in :leadMap.keySet()])
//depreciated		{
//depreciated			System.assertEquals(leadMap.get(ld.Id).Company,ld.Company,'Failed to update lead: '+ld);
//depreciated		}
//depreciated	}
//depreciated
//depreciated	@isTest
//depreciated	static void executeTest2() {
//depreciated		User u = [
//depreciated			select Id
//depreciated			from User
//depreciated			where ProfileId = :UserInfo.getProfileId()
//depreciated				and Id != :UserInfo.getUserId()
//depreciated				and IsActive = true 
//depreciated			limit 1 ];
//depreciated		upsert new StringSetting__c(Name=Lead_RoutingAssignment.GLR_ERROR_QUEUE_SETTING,Value__c=u.Id);
//depreciated		Lead_RoutingAssignment.routeToGLRErrorQUeue = true;
//depreciated		System.assert(!leads.isEmpty(),'Failed to insert leads');
//depreciated		Map<Id,Lead> leadMap = new Map<Id,Lead>(leads);
//depreciated		Lead_RoutingAssignment lra = new Lead_RoutingAssignment();
//depreciated		AbstractTrigger.setBooleanSettings('Lead_Before.',false);
//depreciated		AbstractTrigger.setBooleanSettings('Lead_After.',false);
//depreciated		Test.startTest();
//depreciated		lra.execute(null,leads);
//depreciated		Test.stopTest();
//depreciated		for(Lead ld : [
//depreciated			select OwnerId, Assignment_Error__c
//depreciated			from Lead
//depreciated			where Id in :leadMap.keySet()])
//depreciated		{
//			System.assertEquals(u.Id,ld.OwnerId);
//depreciated			System.assertNotEquals(null,ld.Assignment_Error__c);
//depreciated		}
//depreciated	}
//depreciated
//depreciated	@isTest
//depreciated	static void sendErrorsTest() {
//depreciated		Lead_RoutingAssignment lra = new Lead_RoutingAssignment();
//depreciated		lra.errorList.add('anything');
//depreciated		Test.startTest();
//depreciated		System.assertNotEquals(null,lra.sendErrors(null));
//depreciated		Test.stopTest();
//depreciated	}
//depreciated
//depreciated	@isTest
//depreciated	static void finishTest() {
//depreciated		Lead_RoutingAssignment lra = new Lead_RoutingAssignment();
//depreciated		lra.finish(null);
//depreciated	}
}