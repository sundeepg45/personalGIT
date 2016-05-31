/****************************************************************************************
Modification Log
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
 Jonathan Garrison      07-Jul-2015     Created
****************************************************************************************/

@isTest(SeeAllData = true)
private class PrtnrPgmThnkYouCntrlrTest {

    @isTest static void test_method_one() {
        PartnerProgramThankYouController controller = new PartnerProgramThankYouController();
        controller.init();
        ApexPages.currentPage().getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, 'ladfjs');
        controller.loginButton();
    }

}