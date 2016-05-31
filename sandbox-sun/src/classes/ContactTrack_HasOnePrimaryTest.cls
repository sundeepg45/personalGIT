@isTest(SeeAllData=true)
private class ContactTrack_HasOnePrimaryTest {

	@isTest static void simpleTest() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('ContactTrack_HasOnePrimaryTest');
        Contact contact = PartnerTestUtils.makeContact(acct.Id, 'ContactTrack_HasOnePrimaryTestUser');
        insert contact;

        Contact_Track__c ctrack = new Contact_Track__c();
        ctrack.Partner_Track__c = [select Id from PartnerTrack__c limit 1].Id;
        ctrack.Contact__c = contact.Id;
        ctrack.Primary__c = true;
        insert ctrack;
	}


}