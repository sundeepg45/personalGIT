@isTest(SeeAllData=true)
private class OnboardingOpsCheckAntiCorruptionTrgrTest
{
    @isTest
    static void testOnboarding_OpsCheckAntiCorruptionTrigger()
    {
        //1. insert onboarding registration form
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 2' and isActive = true limit 1];
        Partner_Onboarding_Registration__c onb = PartnerTestUtils.makeOnboardingRequest('fname', 'lname', 'cname', owner);
        insert onb;

        //2. insert a ccsp form the given registration
        CCSP_Form__c form = new CCSP_Form__c();
        form.CCSPOnboardingRegistration__c = onb.Id;
        form.Custom_Terms_Required__c = 'No';
        insert form;

        //3. simulate the first approval action to test the error condition
        onb.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
        onb.Channel_Ops_Approved__c = true;
        update onb;
    }

    @isTest
    static void test_AntiCorruptionReviewError() {
        //1. insert onboarding registration form
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 2' and isActive = true limit 1];
        Partner_Onboarding_Registration__c onb = PartnerTestUtils.makeOnboardingRequest('fname', 'lname', 'cname', owner);
        insert onb;

        //2. test the error occurs when 'Anti-Corruption Review' field is not filled-in on the onboarding record:
        try
        {
        	onb.Channel_Ops_Approved__c = true;
        	update onb;
        }
        catch(Exception e)
        {
            Boolean expectedExceptionThrown = e.getMessage().contains('Please indicate on the field named ') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
    }

    @isTest
    static void test_CustomTermsRequiredFieldOnCCSPForm() {
        //1. insert onboarding registration form
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 2' and isActive = true limit 1];
        Partner_Onboarding_Registration__c onb = PartnerTestUtils.makeOnboardingRequest('fname', 'lname', 'cname', owner);
        insert onb;

        //2. insert a ccsp form the given registration
        CCSP_Form__c form = new CCSP_Form__c();
        form.CCSPOnboardingRegistration__c = onb.Id;
        insert form;

        //3. test the error occurs when Custom 'Terms Required' field is not filled-in on the ccsp form:
        try
        {
        	onb.Channel_Ops_Approved__c = true;
        	update onb;
        }
        catch(Exception e)
        {
            Boolean expectedExceptionThrown = e.getMessage().contains('Please indicate on the field named ') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
    }
}