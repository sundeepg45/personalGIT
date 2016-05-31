@isTest(SeeAllData = true)
private class Lead_EnforceCCPCompletionTest {

	static testMethod void partnerCCPOnboardingApprovedTest() {

		User me = [select Id from User where Id = :UserInfo.getUserId()];
		Lead lead = PartnerTestUtils.makeLead('Daffy','Duck', 'Looney Tunes', me);
		lead.RecordTypeId = [select Id from RecordType where sObjectType = 'Lead' and DeveloperName = 'Partner_Onboarding'].Id;
		lead.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').objectId__c;
		lead.Partner_Tier__c = RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED').objectId__c;
		lead.Partner_Onboarding_Status__c = 'Pending';
		insert lead;
		lead.Partner_Onboarding_Status__c = 'First Approval';
		try {
			update lead;
			System.assert(false, 'Expected CCP validation to catch this update');
		}
		catch (DmlException ex) {
			// this is what we expect, continue
		}

		Partner_CCP_Form__c form = new Partner_CCP_Form__c();
		form.Lead__c = lead.Id;
		form.Website__c = 'http://www.redhat.com';
		form.Expected_Contract_Close_Date__c = System.today();
		form.Regions__c = 'Global';
		insert form;

		// the update should pass this time		
		update lead;

	}
}