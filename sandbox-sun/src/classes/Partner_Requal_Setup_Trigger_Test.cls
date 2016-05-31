@isTest
private class Partner_Requal_Setup_Trigger_Test {

    static testMethod void myUnitTest() {
    	
    	Id reseller = [select id from classification__c where hierarchykey__c = 'PARTNER_TYPE.RESELLER'].id;

    	PartnerStatus__c ps = [select id, partner__c from partnerstatus__c where activationstatus__c = 'Active' and partnertype__c = :reseller limit 1];
		Account account = [select id, enrollment_date__c from account where id = :ps.partner__c];
		account.enrollment_date__c = Date.newInstance(2011, 2, 25);
		update account;
		Partner_Requal_Setup__c prs = new Partner_Requal_Setup__c();
		prs.accountid__c = account.id;
		insert prs;
		
		// test with enrollment date
		account = [select id, requalificationdate__c from account where id = :account.id];
		Date expected = Date.newInstance(2012, 2, 1);
		System.assert(account.requalificationdate__c == expected);
		
		// test with partner status date
		account.enrollment_date__c = null;
		update account;
		ps.activationdate__c = Date.newInstance(2011, 2, 25);
		update ps;

		prs = new Partner_Requal_Setup__c();
		prs.accountid__c = account.id;
		insert prs;

		account = [select id, requalificationdate__c from account where id = :account.id];
		expected = Date.newInstance(2012, 2, 1);
		System.assert(account.requalificationdate__c == expected);
    }
}