/**
 * This is a test class for LeadConvertWizardControllerExtension.
 * 
 * @version 2015-03-02
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-06 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2015-03-02 - Updated
 */
@isTest
private class LeadConvertWizardControllerExtensionTest {
	static Lead lead {
		get {
			if(lead == null) {
				lead = LeadTriggerAfterTest.createLead(UserInfo.getUserId());
			}
			return lead;
		}
	}

	@isTest
	static void wizardConversionTest() {
		User currentUser = Lead_GlobalManagement.getCurrentUser();
		currentUser.Is_Marketing_User__c = true;
		insert lead;
		ApexPages.StandardController stdController = new ApexPages.StandardController(lead);
		LeadConvertWizardControllerExtension extension = new LeadConvertWizardControllerExtension(stdController);
		extension.currentLead.Stage__c = Lead_GlobalManagement.MARKETING_ACCEPTED;
		Test.startTest();
		PageReference ref;
		ref = extension.leadConvert();
		Test.stopTest();
		System.assertNotEquals(null,extension.leadConvert());
		for(Lead ld : [select StandardConversion__c from Lead where Id = :lead.Id]) {
			System.assertEquals(false,ld.StandardConversion__c);
		}
		extension.currentLead.Desired_Opportunity_Owner__c = UserInfo.getUserId();
		extension.reset();
		System.assertEquals(null,extension.currentLead.Desired_Opportunity_Owner__c);
	}

}