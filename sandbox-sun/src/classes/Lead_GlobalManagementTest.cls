/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Lead_GlobalManagementTest {
	static final String STAGE1 = 'TEST 1';
	static final String OTHER_REASON = 'Other';
	static RecordType leadGenRecordType {
		get {
			if(leadGenRecordType == null) {
				leadGenRecordType = [select Name from RecordType where Name = 'Lead Gen' and SobjectType='Lead' limit 1];
			}
			return leadGenRecordType;
		}
	}
	static Lead createLead() {
		return new Lead(
			OwnerId=Util.globalLeadRoutingQueue,
			RecordTypeId = Lead_GlobalManagement.LEAD_GEN_RECORDTYPE_ID,
			LastName ='TestR4DeployLead',
			Email='noone@nowhere.test',
			Title='R4',
			LeadSourceDetail__c='APAC World Tour',
			Route_Around__c = true,
			Status='New',
			Stage__c=STAGE1,
			Company='IBM',
			Country='ABCD',
			State='AB',
			Iso_Country_Code__c ='AB',
			Products_of_Interest__c='JBoss',
			Partner_Opt_In__c=true);
	}

	static testMethod void createLeadManagementHistories() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		insert lead;
		LeadManagementHistory__c t1 = Lead_GlobalManagement.createAcceptedHistory(lead.id);
		System.assert(Lead_GlobalManagement.updateLead(lead,t1));
		LeadManagementHistory__c t2 = Lead_GlobalManagement.createRejectedHistory(lead.id,OTHER_REASON,'Anything');
		System.assert(Lead_GlobalManagement.updateLead(lead,t2));
		LeadManagementHistory__c t3 = Lead_GlobalManagement.createSentToSalesHistory(lead.id);
		System.assert(Lead_GlobalManagement.updateLead(lead,t3));
		// we cannot insert a LeadManagementHistory__c twice
		//System.assert(! Lead_GlobalManagement.updateLead(lead,t3));
		System.assertNotEquals(null,Lead_GlobalManagement.getCurrentUser());
		System.assertEquals(3,[
			select COUNT() from LeadManagementHistory__c 
			where Lead__c = :lead.id 
				and RecordType.Name in (:Lead_GlobalManagement.ACCEPTED,:Lead_GlobalManagement.REJECTED,:Lead_GlobalManagement.SENT_TO_SALES) ] );
		System.assertNotEquals(null,Lead_GlobalManagement.getLeadPageReference(null));
		System.assertNotEquals(null,Lead_GlobalManagement.getLeadPageReference(lead.id));
	}

	static testMethod void testLocks() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead_GlobalManagement.booleanSettingMap.put(Lead_GlobalManagement.USE_LOCKING_SETTING,true);
		Lead lead = createLead();
		// Turn off all the triggers after the insert, so we test from
		// our method calls, not from the actual insert.
		for(String key : LeadTriggerBefore.booleanSettingMap.keySet()) {
			LeadTriggerBefore.booleanSettingMap.put(key,false);
		}
		// Turn off all the triggers after the insert, so we test from
		// our method calls, not from the actual insert.
		for(String key : LeadTriggerAfter.booleanSettingMap.keySet()) {
			LeadTriggerAfter.booleanSettingMap.put(key,false);
		}
		insert lead;
		Lead l2 = Lead_GlobalManagement.queryLead(lead.Id,null);
		System.assert(! Lead_GlobalManagement.isUnlockedRecordType(l2));
		System.assert(! Lead_GlobalManagement.isUnlockedStage(l2));
	}

	static testMethod void testGLMRecordTypes() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		System.assertEquals(Lead_GlobalManagement.GLM_RECORDTYPE_IDS.size(),[select Count() from RecordType where Id in :Lead_GlobalManagement.GLM_RECORDTYPE_IDS and SobjectType='Lead' and IsActive = true]);
	}
}