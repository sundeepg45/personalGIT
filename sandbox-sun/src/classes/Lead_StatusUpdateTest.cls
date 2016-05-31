/**
 * This class contains unit tests for validating the Lead_StatusUpdate class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2015-12-18
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - Depreciated - Merged into Lead_BatchableTest
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-04 - Added test for penalty box scenarios
 */
@isTest
private class Lead_StatusUpdateTest {
//depreciated	static Lead createLead() {
//depreciated		return new Lead(
//depreciated			OwnerId = UserInfo.getUserId(),
//depreciated			LastName='Accenture',
//depreciated			RecordTypeId = Lead_GlobalManagement.NA_SALES_LEAD_RECORDTYPE_ID,
//depreciated			Company='Accenture',
//depreciated			Status='New',
//depreciated			Lead_Ranking__c = 'P1',
//depreciated			Products_of_Interest__c='JBoss',
//depreciated			LeadSourceDetail__c='SD_RONA',
//depreciated			Country = 'Narnia',
//depreciated			Partner_Opt_In__c=true,
//depreciated			PenaltyBoxExpiration__c=null);
//depreciated	}
//depreciated
//depreciated	static testMethod void statusUpdateTest() {
//depreciated		Lead lead1 = createLead();
//depreciated		lead1.Next_Status_Update__c = DateTime.now().addDays(-1);
//depreciated		Lead lead2 = createLead();
//depreciated		lead2.Next_Status_Update__c = DateTime.now().addDays(1);
//depreciated		List<Lead> leads = new List<Lead>{lead1,lead2};
//depreciated		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,false);
//depreciated		insert leads;
//depreciated		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,true);
//depreciated		Map<Id,Lead> leadMap = new Map<Id,Lead>([
//depreciated			select Next_Status_Update__c
//depreciated			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
//depreciated		System.assertNotEquals(null,leadMap.get(lead1.Id).Next_Status_Update__c);
//depreciated		System.assertNotEquals(null,leadMap.get(lead2.Id).Next_Status_Update__c);
//depreciated		Lead_StatusUpdate.query = Lead_StatusUpdate.query.replace('where ','where Id in (\''+lead1.Id+'\',\''+lead2.Id+'\') and ');
//depreciated		Test.StartTest();
//depreciated		Lead_StatusUpdate lsu = new Lead_StatusUpdate();
//depreciated		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lsu.start(null));
//depreciated		ssc.setPageSize(100);
//depreciated		lsu.execute(null,ssc.getRecords());
//depreciated		System.assert(lsu.errorMessages.isEmpty());
//depreciated		lsu.finish(null);
//depreciated		Test.StopTest();
//depreciated		System.assertEquals(ssc.getRecords().size(),lsu.recordCount);
//depreciated		System.assertEquals(0,lsu.failureCount);
//depreciated		leadMap = new Map<Id,Lead>([
//depreciated			select Next_Status_Update__c
//depreciated			from Lead where Id in (:lead1.Id,:lead2.Id) ]);
//depreciated		System.assertEquals(null,leadMap.get(lead1.Id).Next_Status_Update__c);
//depreciated		System.assertNotEquals(null,leadMap.get(lead2.Id).Next_Status_Update__c);
//depreciated	}
//depreciated	
//depreciated	static testMethod void penaltyBoxTest() {
//depreciated		Lead lead1 = createLead();
//depreciated		lead1.Next_Status_Update__c = DateTime.now().addDays(-1);
//depreciated		lead1.PenaltyBoxExpiration__c = DateTime.now().addDays(-1);
//depreciated		Lead lead2 = createLead();
//depreciated		lead2.Next_Status_Update__c = DateTime.now().addDays(-1);
//depreciated		lead2.PenaltyBoxExpiration__c = DateTime.now().addDays(1);
//depreciated		Lead lead3 = createLead();
//depreciated		lead3.Next_Status_Update__c = DateTime.now().addDays(-1);
//depreciated		lead3.PenaltyBoxExpiration__c = null;
//depreciated		Lead lead4 = createLead();
//depreciated		lead4.Next_Status_Update__c = null;
//depreciated		lead4.PenaltyBoxExpiration__c = DateTime.now().addDays(-1);		
//depreciated		List<Lead> leads = new List<Lead>{lead1,lead2,lead3,lead4};
//depreciated		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,false);
//depreciated		insert leads;
//depreciated		LeadTriggerBefore.booleanSettingMap.put(LeadTriggerBeforeGLM.UPDATE_STATUS_SETTING,true);
//depreciated		Map<Id,Lead> leadMap = new Map<Id,Lead>([
//depreciated			select Next_Status_Update__c, PenaltyBoxExpiration__c
//depreciated			from Lead where Id in (:lead1.Id,:lead2.Id,:lead3.Id,:lead4.Id) ]);
//depreciated		System.assertNotEquals(null,leadMap.get(lead1.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertNotEquals(null,leadMap.get(lead2.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertEquals(null,leadMap.get(lead3.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertNotEquals(null,leadMap.get(lead4.Id).PenaltyBoxExpiration__c);
//depreciated		Lead_StatusUpdate.query = Lead_StatusUpdate.query.replace('where ','where Id in (\''+lead1.Id+'\',\''+lead2.Id+'\',\''+lead3.Id+'\',\''+lead4.Id+'\') and ');
//depreciated		Test.StartTest();
//depreciated		Lead_StatusUpdate lsu = new Lead_StatusUpdate();
//depreciated		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lsu.start(null));
//depreciated		ssc.setPageSize(100);
//depreciated		lsu.execute(null,ssc.getRecords());
//depreciated		System.assert(lsu.errorMessages.isEmpty());
//depreciated		lsu.finish(null);
//depreciated		Test.StopTest();
//depreciated		System.assertEquals(ssc.getRecords().size(),lsu.recordCount);
//depreciated		System.assertEquals(0,lsu.failureCount);
//depreciated		leadMap = new Map<Id,Lead>([
//depreciated			select Next_Status_Update__c, PenaltyBoxExpiration__c
//depreciated			from Lead where Id in (:lead1.Id,:lead2.Id,:lead3.Id,:lead4.Id) ]);
//depreciated		System.assertEquals(null,leadMap.get(lead1.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertNotEquals(null,leadMap.get(lead2.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertEquals(null,leadMap.get(lead3.Id).PenaltyBoxExpiration__c);
//depreciated		System.assertEquals(null,leadMap.get(lead4.Id).PenaltyBoxExpiration__c);
//depreciated	}
//depreciated
//depreciated	static testMethod void statusUpdateFailureTest() {
//depreciated		Lead_StatusUpdate.query = 'select Id from Lead where IsConverted = true limit 10';
//depreciated		Test.StartTest();
//depreciated		Lead_StatusUpdate lsu = new Lead_StatusUpdate();
//depreciated		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lsu.start(null));
//depreciated		ssc.setPageSize(100);
//depreciated		lsu.execute(null,ssc.getRecords());
//depreciated		System.assert(! lsu.errorMessages.isEmpty());
//depreciated		lsu.finish(null);
//depreciated		Test.StopTest();
//depreciated		System.assertEquals(ssc.getRecords().size(),lsu.recordCount);
//depreciated		System.assertEquals(lsu.recordCount,lsu.failureCount);
//depreciated	}
}