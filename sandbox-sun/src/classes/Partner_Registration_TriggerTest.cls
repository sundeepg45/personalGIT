@isTest(SeeAllData=true)
private class Partner_Registration_TriggerTest {

    static testMethod void myUnitTest() {
    	Account acct = PartnerTestUtils.basicAccountSetup('Asgard, Inc.');
    	Account cust = PartnerTestUtils.basicAccountSetup('Midgard, Inc.');
    	Contact c = PartnerTestUtils.makeContact(acct.Id, 'MightyThor');
    	insert c;
    	User u = PartnerTestUtils.makeUser(acct, c);
    	insert u;
    	
    	Test.startTest();
		Partner_Registration__c par = new Partner_Registration__c();
		par.Partner__c = acct.Id;
		par.Status__c = 'Open';
		par.Company_Name__c = 'Midgard, Inc.';	
		par.End_Customer__c = cust.Id;
        par.Company_Country__c = 'US';
        par.Estimated_Close_Date__c = System.today();
        par.Company_Street_1__c = '100 E Davie St';
        par.Company_City__c = 'Raleigh';
		insert par;
		par.Status__c = 'Pending Channel Operations Approval';
		update par;
		par.Status__c = 'Pending Partner Account Owner Approval';
		update par;
        par.Status__c = 'Pending End Customer Owner Approval';
        update par;
        par.Status__c = 'Pending Proof of Performance Approval';
        update par;
		par.Status__c = 'Approved';
		update par;
    }
}