/****************************************************************************************
Modification Log
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
 Jonathan Garrison      07-Jul-2015     Created
****************************************************************************************/

public with sharing class PartnerProgramThankYouController {

    private String federationId;

    public PartnerProgramThankYouController() {

    }

    public void init() {
        federationId = ApexPages.currentPage().getParameters().get(OnboardingApplyController.PARAM_FEDERATION_ID);
    }

    public PageReference loginButton() {
        PageReference page = new PageReference('/partner');
        page.setRedirect(true);
        page.getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, federationId);
        return page;
    }
}