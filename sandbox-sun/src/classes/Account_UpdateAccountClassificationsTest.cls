@isTest
private class Account_UpdateAccountClassificationsTest {

    static testMethod void myUnitTest() {
		Account acct = PartnerTestUtils.quickGenericAccountSetup('Account_UpdateAccountClassificationsTest');
		update acct;
		acct.Application_Types__c = 'Application Life-Cycle Management';
		
		List<Classification__c> clfnList = [select id from Classification__c where HierarchyKey__c like 'PARTNER_CLASSIFICATION.%' and Descendents__c = 0];
		List<PartnerClassification__c> work = new List<PartnerClassification__c>();
		for (Classification__c clfn : clfnList) {
			PartnerClassification__c pc = new PartnerClassification__c();
			pc.Partner__c = acct.Id;
			pc.Classification__c = clfn.Id;
			pc.ActivationDate__c = System.today();
			work.add(pc);
		}
		insert work;

		update acct;
		
    }
}