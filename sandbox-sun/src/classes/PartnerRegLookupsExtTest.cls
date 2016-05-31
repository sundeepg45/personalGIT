@isTest
private class PartnerRegLookupsExtTest {

    static testMethod void myUnitTest() {

        Account testPartner = new Account(Name = 'Test Partner', Global_Region__c = 'NA', CurrencyIsoCode = 'USD');
        insert(testPartner);
        
        Partner_Registration__c reg = new Partner_Registration__c(
            Company_Country__c = 'US',
            Company_Name__c = 'test company',
            Estimated_Close_Date__c = System.today(),
            Company_Street_1__c = '100 E Davie St',
            Company_City__c = 'Raleigh',
            Partner__c = testPartner.Id,
            Status__c = 'Pending Channel Operations Approval'
        );
        insert(reg);
		ApexPages.StandardController ctrl = new ApexPages.StandardController(reg);
		PartnerRegLookupsExtension lookup = new PartnerRegLookupsExtension(ctrl);
		
		lookup.accountName = 'IBM';
		PageReference ref = lookup.searchAccounts();
		
    }
}