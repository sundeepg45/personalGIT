/**
 * Test the Lead_RejectControllerExtension class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2012-07-10
 * 2012-07-10 - change comparison to upper case
 */
@isTest
private class Lead_RejectControllerExtnTest {
	static final String STAGE1 = 'TEST 1';
	static final String STAGE2 = 'TEST 2';
	static final String OTHER_REASON = 'Other';
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
			Products_of_Interest__c='JBoss',
			Partner_Opt_In__c=true);
	}

	static Reject_Lead_Setup__c createRejectLeadSetup() {
		return new Reject_Lead_Setup__c(
			DaysInPenaltyBox__c = 5,
			OwnerId = UserInfo.getUserId(),
			Lead_Stage__c = STAGE2,
			Source_Stage__c = STAGE1,
			Rejection_Reason__c = OTHER_REASON );
	}

	static testMethod void rejectLeadTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		insert createRejectLeadSetup();
		Lead lead = createLead();
		insert lead;
		ApexPages.StandardController sc = new ApexPages.StandardController(lead);
		Lead_RejectControllerExtension controller = new Lead_RejectControllerExtension(sc);
		controller.rejectionAllowed();
		System.assert(! controller.isRejectionReasonMissing);
		System.assert(! controller.isRejectionCommentMissing);
		System.assertEquals(null,controller.rejectLead());
		System.assert(controller.isRejectionReasonMissing);
		System.assert(! controller.isRejectionCommentMissing);
		controller.rejectionReason = 'Testing';
		System.assertEquals(null,controller.rejectLead());
		controller.rejectionReason = 'Other';
		System.assertEquals(null,controller.rejectLead());
		System.assert(! controller.isRejectionReasonMissing);
		System.assert(controller.isRejectionCommentMissing);
		controller.rejectionComment = 'Anything';
		System.assertNotEquals(null,controller.rejectLead());
		System.assert(! controller.isRejectionReasonMissing);
		System.assert(! controller.isRejectionCommentMissing);
		Lead lead2 = [ select Stage__c,OwnerId,Route_Around__c from Lead where Id = :lead.Id];
		System.assert(! lead2.Route_Around__c);
		System.assertEquals(lead2.Stage__c.toUpperCase(),STAGE2.toUpperCase());
		System.assertEquals(lead2.OwnerId,UserInfo.getUserId());
		LeadManagementHistory__c h = [ 
			select Comments__c 
			from LeadManagementHistory__c
			where Lead__c = : lead.Id 
				and RecordType.Name = :Lead_GlobalManagement.REJECTED ];
		System.assertEquals(controller.rejectionComment,h.Comments__c);
	}
}