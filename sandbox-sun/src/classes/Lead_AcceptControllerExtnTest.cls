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
private class Lead_AcceptControllerExtnTest {
	static final String STAGE1 = 'TEST 1';
	static Lead createLead() {
		return new Lead(
			OwnerId=Util.globalLeadRoutingQueue,
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
			PenaltyBoxExpiration__c = DateTime.now().addDays(2),
			Products_of_Interest__c='JBoss',
			Partner_Opt_In__c=true);
	}

	static testMethod void acceptLeadTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Lead lead = createLead();
		insert lead;
		ApexPages.StandardController sc = new ApexPages.StandardController(lead);
		Lead_AcceptControllerExtension controller = new Lead_AcceptControllerExtension(sc);
		Lead_GlobalManagement.getCurrentUser().Is_Marketing_User__c = false;
		System.assertNotEquals(null,controller.acceptLead());
		System.assertEquals(null,controller.lead.PenaltyBoxExpiration__c);
		System.assertEquals(null,controller.acceptLead());
		Lead lead2 = [ select Stage__c,OwnerId,Route_Around__c from Lead where Id = :lead.Id ];
		System.assert(lead2.Route_Around__c);
		System.assertEquals(lead2.Stage__c,Lead_GlobalManagement.SALES_ACCEPTED);
		System.assertEquals(lead2.OwnerId,UserInfo.getUserId());
		Lead_GlobalManagement.getCurrentUser().Is_Marketing_User__c = true;
		System.assertNotEquals(null,controller.acceptLead());
		lead2 = [ select Stage__c,OwnerId,Route_Around__c from Lead where Id = :lead.Id ];
		System.assert(! lead2.Route_Around__c);
		System.assertEquals(lead2.Stage__c,Lead_GlobalManagement.MARKETING_ACCEPTED);
		List<LeadManagementHistory__c> histories = [
			select Id
			from LeadManagementHistory__c
			where Lead__c = : lead.Id
				and RecordType.Name = :Lead_GlobalManagement.ACCEPTED ];
		System.assertEquals(2,histories.size());
	}
}