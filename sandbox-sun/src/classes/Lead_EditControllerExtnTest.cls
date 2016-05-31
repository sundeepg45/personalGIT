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
private class Lead_EditControllerExtnTest {
	static List<RecordType> nonLeadGenRecordTypes {
		get {
			if(nonLeadGenRecordTypes == null) {
				nonLeadGenRecordTypes = [select Id from RecordType where (not Id in :Lead_GlobalManagement.GLM_RECORDTYPE_IDS) and SobjectType='Lead' and IsActive = true];
			}
			return nonLeadGenRecordTypes;
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
			Stage__c=Lead_GlobalManagement.MARKETING_ACCEPTED,
			Company='IBM',
			Country='AB',
			State='AB',
			Iso_Country_Code__c ='AB',
			Products_of_Interest__c='JBoss',
			Partner_Opt_In__c=true,
			Red_Hat_Subscription_Revenue__c = 1.0);
	}

	static testMethod void testLocking() {
		Lead_GlobalManagement.booleanSettingMap.put(Lead_GlobalManagement.USE_LOCKING_SETTING,true);
		Lead lead = createLead();
		insert lead;
		ApexPages.StandardController sc = new ApexPages.StandardController(lead);
		Lead_EditControllerExtension controller = new Lead_EditControllerExtension(sc);
		System.assertNotEquals(null,controller.leadEdit());
		for(RecordType rt : nonLeadGenRecordTypes) {
			lead.RecordTypeId = rt.Id;
			try {
				update lead;
				break;
			}
			catch(Exception e) {}
		}
		sc = new ApexPages.StandardController(lead);
		controller = new Lead_EditControllerExtension(sc);
		System.assertNotEquals(null,controller.leadEdit());
	}
}