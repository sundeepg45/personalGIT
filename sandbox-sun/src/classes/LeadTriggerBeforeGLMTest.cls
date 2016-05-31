/**
 * This class contains unit tests for validating the LeadTriggerBeforeGLM class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2014-02-20
 * 2014-02-20 - Added a test method for assignLeadForReportingId
 * 2012-10-11 - US26041 - Restored partner exclusion for setting status removed in US21120
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-03-05 - refactored into sub classes
 * 2011-09-01 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-04 - updated updateStageTest to check penalty box scenarios
 * 2012-07-20 - updated updateStageTest to check for transition back to Inquiry stage
 * 2012-07-13 - added ownerUpdatedTest()
 * 2012-05-21 - updated test to include Suspect leads
 */
@isTest
private class LeadTriggerBeforeGLMTest {
	static Lead createLead() {
		return LeadTriggerBeforeTest.createLead();
	}

	@isTest
	static void assignLeadForReportingId() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		insert Lead;
		lead = [
			select
				Id,
				LFR__c
			from Lead
			where Id = :lead.Id];
		if(lead.LFR__c == null) {
			Map<Id,Lead> oldMap = new Map<Id,Lead>{lead.Id=>lead};
			List<Lead> newList = oldMap.values().deepClone(true);
			LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(oldMap,newList);
			t.assignLeadForReportingId();
			System.assertNotEquals(null,newList[0].LFR__c);
		}
	}

	@isTest
	static void stageUpdatedTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		DateTime n = DateTime.now();
		lead.LastStageModifiedDateTime__c = n.addDays(-1);
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead2},new List<Lead>{lead});
		t.stageUpdated();
		System.assertEquals(lead2.LastStageModifiedDateTime__c,lead.LastStageModifiedDateTime__c);
		lead.LastStageModifiedDateTime__c = lead2.LastStageModifiedDateTime__c;
		lead.Stage__c = lead2.Stage__c + 'Test';
		t.stageUpdated();
		System.assert(lead.LastStageModifiedDateTime__c.getTime() >= n.getTime());
	}

	@isTest
	static void ownerUpdatedTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		DateTime n = DateTime.now();
		lead.LastOwnerModifiedDateTime__c = n.addDays(-1);
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead2},new List<Lead>{lead});
		t.ownerUpdated();
		System.assertEquals(lead2.LastOwnerModifiedDateTime__c,lead.LastOwnerModifiedDateTime__c);
		lead.LastOwnerModifiedDateTime__c = lead2.LastOwnerModifiedDateTime__c;
		lead.OwnerId = LeadTriggerBeforeGLM.NEW_LEADS_QUEUE;
		t.ownerUpdated();
		System.assert(lead.LastOwnerModifiedDateTime__c.getTime() >= n.getTime());
	}

	@isTest
	static void leadConvertedTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM.toOpportunity = false;
		LeadTriggerBeforeGLM.toContact = false;
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
		t.currentUser.Is_Marketing_User__c = true;
		t.leadConverted();
		System.assertEquals(lead.Stage__c,lead2.Stage__c);
		t.currentUser.Is_Marketing_User__c = false;
		System.assertEquals(lead.Stage__c,lead2.Stage__c);
		LeadTriggerBeforeGLM.toOpportunity = true;
		LeadTriggerBeforeGLM.toContact = false;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.SALES_QUALIFIED,lead2.Stage__c);
		t.currentUser.Is_Marketing_User__c = true;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.MARKETING_QUALIFIED,lead2.Stage__c);
		LeadTriggerBeforeGLM.toOpportunity = false;
		LeadTriggerBeforeGLM.toContact = true;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.MARKETING_QUALIFIED,lead2.Stage__c);
		t.currentUser.Is_Marketing_User__c = false;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.SALES_CONTACT,lead2.Stage__c);
		LeadTriggerBeforeGLM.toOpportunity = true;
		LeadTriggerBeforeGLM.toContact = true;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.SALES_QUALIFIED,lead2.Stage__c);
		t.currentUser.Is_Marketing_User__c = true;
		t.leadConverted();
		System.assertEquals(LeadTriggerBeforeGLM.MARKETING_QUALIFIED,lead2.Stage__c);
		t.currentUser.Is_Marketing_User__c = false;
		// testing portal user by-pass
		for(User u : [select Id from User where IsActive=true and IsPortalEnabled=true limit 1] ) {
			LeadTriggerBeforeGLM.toOpportunity = false;
			LeadTriggerBeforeGLM.toContact = false;
			lead.OwnerId = u.Id;
			lead2 = lead.clone();
			t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
			t.leadConverted();
			System.assertEquals(lead.Stage__c,lead2.Stage__c);
			LeadTriggerBeforeGLM.toOpportunity = true;
			LeadTriggerBeforeGLM.toContact = false;
			t.leadConverted();
			System.assertEquals(lead.Stage__c,lead2.Stage__c);
		}
	}

	@isTest
	static void leadLock() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Util.setTesting(true);
		Lead lead = createLead();
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
		t.leadLock();
		// allowed since no fields were changed
		System.assert(! t.hasErrors);
		for(String stage : LeadTriggerBeforeGLM.LOCKED_STAGES) {
			lead2.Stage__c = stage;
			lead2.Country = 'USA';
			t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
			t.leadLock();
			// the update was allowed because the lead stage has changed
			System.assert(! t.hasErrors);
			break;
		}
		for(String stage : LeadTriggerBeforeGLM.LOCKED_STAGES) {
			lead.Stage__c = stage;
			lead2.Stage__c = stage;
			lead2.Country = 'USA';
			t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
			t.leadLock();
			// the update was not allowed
			System.assert(t.hasErrors);
			break;
		}
		
	}

	@isTest
	static void updateStageTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		lead.OwnerId = LeadTriggerBeforeGLM.NEW_LEADS_QUEUE;
		lead.Stage__c = LeadTriggerBeforeGLM.SALES_ACCEPTED;
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		// does nothing
		t.updateStage();
		System.assertEquals(LeadTriggerBeforeGLM.SALES_ACCEPTED,lead2.Stage__c);
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead}, new List<Lead>{lead2});
		t.updateStage();
		System.assertEquals(LeadTriggerBeforeGLM.PROSPECT,lead2.Stage__c);
		lead2 = lead.clone();
		lead2.Lead_Ranking__c = 'P5';
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
		t.updateStage();
		System.assertEquals(LeadTriggerBeforeGLM.INQUIRY,lead2.Stage__c);
		// check that stage not updated to prospect when in penalty box
		lead2 = lead.clone();
		lead2.PenaltyBoxExpiration__c = DateTime.now().addDays(1);
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead}, new List<Lead>{lead2});
		t.updateStage();
		System.assertEquals(LeadTriggerBeforeGLM.SALES_ACCEPTED,lead2.Stage__c);
		// now check that stage is updated to prospect when penalty box expires
		lead2.PenaltyBoxExpiration__c = DateTime.now().addDays(-1);
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead}, new List<Lead>{lead2});
		t.updateStage();
		System.assertEquals(LeadTriggerBeforeGLM.PROSPECT,lead2.Stage__c);
	}

	@isTest
	static void insertStageTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		lead.Stage__c = LeadTriggerBeforeGLM.INQUIRY;
		Lead lead2;
		LeadTriggerBeforeGLM t;

		// test a lead owned by a marketing user
		lead2 = lead.clone();
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.userMap.get(lead2.OwnerId).Is_Marketing_User__c = true;
		t.insertStage();
		if(t.currentUser.Id != LeadTriggerBeforeGLM.INTEGRATION_ADMIN_ID) {
			system.assertEquals(LeadTriggerBeforeGLM.MARKETING_ACCEPTED,lead2.Stage__c);
		}

		// test a lead owned by a sales user
		lead2 = lead.clone();
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.userMap.get(lead2.OwnerId).Is_Marketing_User__c = false;
		t.insertStage();
		if(t.currentUser.Id != LeadTriggerBeforeGLM.INTEGRATION_ADMIN_ID) {
			system.assertEquals(LeadTriggerBeforeGLM.SALES_ACCEPTED,lead2.Stage__c);
		}

		// test an insert done by the INTEGRATION ADMIN
		lead2 = lead.clone();
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.currentUser = new User(Id=LeadTriggerBeforeGLM.INTEGRATION_ADMIN_ID);
		t.insertStage();
		system.assertEquals(lead.Stage__c, lead2.Stage__c);

		// test an insert on a queue
		lead2 = lead.clone();
		lead2.OwnerId = LeadTriggerBeforeGLM.NEW_LEADS_QUEUE;
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.insertStage();
		system.assertEquals(lead.Stage__c, lead2.Stage__c);

		// test an partner onboarding insert
		lead2 = lead.clone();
		lead2.Partner_Onboarding_Status__c = 'Approved';
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.insertStage();
		system.assertEquals(lead.Stage__c, lead2.Stage__c);
		
		// testing portal user by-pass
		for(User u : [select Id from User where IsActive=true and IsPortalEnabled=true limit 1] ) {
			lead2 = lead.clone();
			lead2.OwnerId = u.Id;
			t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
			t.insertStage();
			system.assertEquals(lead.Stage__c, lead2.Stage__c);
		}
		
		// test a Suspect lead (as from Eloqua)
		lead2 = lead.clone();
		lead2.OwnerId = LeadTriggerBeforeGLM.NEW_LEADS_QUEUE;
		lead2.Stage__c = LeadTriggerBeforeGLM.SUSPECT;
		t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.insertStage();
		system.assertEquals(LeadTriggerBeforeGLM.INQUIRY, lead2.Stage__c);
		system.assert(lead2.HistoryOnInsert__c);
		system.assertEquals(LeadTriggerBeforeGLM.SUSPECT,lead2.HistoryOnInsertStage__c);
	}

	@isTest(SeeAllData=true) // I do not know why this is required
	static void updateStatusTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		lead.Stage__c = LeadTriggerBeforeGLM.MARKETING_ACCEPTED;
		Lead lead2 = lead.clone();
		LeadTriggerBeforeGLM t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.NOT_WORKING,lead2.Status);
		lead2 = lead.clone();
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{null=>lead},new List<Lead>{lead2});
		lead2.Stage__c = LeadTriggerBeforeGLM.INQUIRY;
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.WAITING,lead2.Status);
		lead2.OwnerId = LeadTriggerBeforeGLM.INQUIRIES_QUEUE;
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.NURTURING,lead2.Status);
		// Now to test with tasks we need to actually insert the lead.
		// Before inserting a lead, we disable the triggers so the test results
		// are not effected by anything but what we are actually testing.
		LeadTriggerBefore.processTrigger(null,null);
		AbstractTrigger.setBooleanSettings('Lead_Before.',false);
		LeadTriggerAfter.processTrigger(null,null);
		AbstractTrigger.setBooleanSettings('Lead_After.',false);
		for(String key : LeadTriggerAfter.booleanSettingMap.keySet()) {
			LeadTriggerAfter.booleanSettingMap.put(key,false);
		}
		insert lead;
		lead2 = lead.clone(true);
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{lead.Id=>lead},new List<Lead>{lead2});
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.NOT_WORKING,lead2.Status);
		System.assertEquals(null,lead2.Next_Status_Update__c);
		Task t1 = new Task(
			ActivityDate = System.today().addDays(365),
			RecordTypeId = Util.tandemRecordTypeId,
			Type = 'Other',
			WhoId = lead2.Id );
		insert t1;
		lead2 = lead.clone(true);
		t = new LeadTriggerBeforeGLM(new Map<Id,Lead>{lead.Id=>lead},new List<Lead>{lead2});
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.NOT_WORKING,lead2.Status);
		System.assertNotEquals(null,lead2.Next_Status_Update__c);
		Task t2 = new Task(
			ActivityDate = System.today().addDays(1),
			RecordTypeId = Util.tandemRecordTypeId,
			Type = 'Other',
			WhoId = lead2.Id );
		insert t2;
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.DEVELOPING,lead2.Status);
		// I'm not sure why, but we need see all data for this to pass.
		System.assertNotEquals(null,lead2.Next_Status_Update__c);
		t2.Status = 'Completed';
		t2.ActivityDate = System.today();
		update t2;
		t.updateStatus();
		System.assertEquals(LeadTriggerBeforeGLM.WORKING,lead2.Status);
		System.assertNotEquals(null,lead2.Next_Status_Update__c);
		// testing portal user by-pass
		for(User u : [select Id from User where IsActive=true and IsPortalEnabled=true limit 1] ) {
			lead.Stage__c = LeadTriggerBeforeGLM.MARKETING_ACCEPTED;
			lead.OwnerId = u.Id;
			lead2 = lead.clone();
			t = new LeadTriggerBeforeGLM(null,new List<Lead>{lead2});
			t.updateStatus();
			System.assertEquals(lead.Status,lead2.Status);
		}
	}
}