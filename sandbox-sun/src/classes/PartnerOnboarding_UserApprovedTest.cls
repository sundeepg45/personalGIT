@isTest(SeeAllData = true)
private class PartnerOnboarding_UserApprovedTest {

    @isTest static void test() {
        OnboardingJoinController ctrl = new OnboardingJoinController();
        Map<String,String> pmap = ApexPages.currentPage().getParameters();
        pmap.put('federation-id', 'Elrond');
        pmap.put('rhn-company-name', 'Rivendell');
        pmap.put('rhn-email', 'halfelven@rivendell.com');
        pmap.put('customer-type', 'B');
        pmap.put('rhn-salutation', 'Mr.');
        pmap.put('rhn-first-name', 'Elrond');
        pmap.put('rhn-last-name', 'Halfelven');
        ctrl.init();

        Account acct = PartnerTestUtils.quickGenericAccountSetup('Rivendell test account');
        acct.AllowedEmailDomains__c = 'rivendell.com';
        update acct;
        Partner_Program__c ps = [select Id from Partner_Program__c where Account__c = :acct.Id];

        //
        // step 1
        //
        ctrl.partnerType = 'PARTNER_TYPE.RESELLER';
        ctrl.leadCountry = 'US';

        //
        // step 2
        //
        ctrl.selectedPartnerStatus = ps.id;

        Partner_Program__c[] pslist = ctrl.getExistingPartnerList();
        System.assert(pslist.size() == 1, 'Expected to match 1 program, found ' + pslist.size());

        PageReference page = ctrl.submitApplication();

        Partner_Onboarding_Registration__c partnerOnboardingRegistration = [
            select  Id,
                    RHNLogin__c,
                    Partner_Onboarding_Status__c
            from    Partner_Onboarding_Registration__c
            where   RHNLogin__c = :'Elrond'
            limit   1
        ];

        partnerOnboardingRegistration.Partner_Onboarding_Status__c = 'Approved';
        update partnerOnboardingRegistration;
	}
}