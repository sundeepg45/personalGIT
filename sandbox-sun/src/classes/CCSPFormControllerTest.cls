/****************************************************************************************
    Name    : CCSPFormControllerTest

Modification Log
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
 Jonathan Garrison      08-Apr-2015     Created
 Jonathan Garrison      09-Jun-2015     Improved code coverage.
****************************************************************************************/
@isTest(SeeAllData = true)
private class CCSPFormControllerTest {

    @isTest static void test() {
        ManualOnboardingController moController = ManualOnboardingControllerTest.setUpData();
        moController.submit();
        Id partnerOnboardingRegistrationId = moController.partnerOnboardingRegistration.Id;
        CCSPFormController controller = new CCSPFormController();
        ApexPages.currentPage().getParameters().put('onboardingId', partnerOnboardingRegistrationId);
        controller.init();
        controller.submit();
        controller.distributorDirected = 'Yes';
        controller.ccspForm.Relationships__c = '--None--;SUSE Cloud Program';
        controller.submit();
        controller = setUpData(partnerOnboardingRegistrationId);
        controller.submit();
        User guestUser = [
            select  Id
            from    User
            where   Name
            like    'Partner Center Site Guest User'
            limit   1
        ];
        System.runAs(guestUser) {
            controller = new CCSPFormController();
            ApexPages.currentPage().getParameters().put('onboardingId', partnerOnboardingRegistrationId);
            controller.init();
            controller.saveForm();
            controller.submit();
            controller.governmentPosition                      = 'No';
            controller.convicted                               = 'No';
            controller.underlyingFacts                         = '';
            controller.submit();
            controller.distributorDirected                     = 'Yes';
            controller.submit();
            controller.distributorName                         = 'Distributor';
            controller.submit();
            controller.requirementsExceptions                  = '';
            controller.submit();
        }
    }

    public static CCSPFormController setUpData(Id partnerOnboardingRegistrationId) {
        CCSPFormController controller = new CCSPFormController();
        ApexPages.currentPage().getParameters().put('onboardingId', partnerOnboardingRegistrationId);
        controller.init();
        controller.governmentPosition                      = 'No';
        controller.convicted                               = 'No';
        controller.underlyingFacts                         = '';
        controller.distributorName                         = 'Distributor';
        controller.distributorDirected                     = 'Yes';
        controller.requirementsExceptions                  = '';
        controller.managedOSServices                       = 'Yes';
        controller.dedicatedPhysicalServersBareMetal       = 'Yes';
        controller.dedicatedPhysicalServersVirtualization  = 'Yes';
        controller.multiTenantVirtualInstances             = 'Yes';
        controller.contactName                             = 'Mr. Contact';
        controller.contactEmail                            = 'contact@email.com';
        controller.contactPhone                            = '999-999-9999';
        controller.authorizationCountries                  = new String[] {'Albania'};
        controller.ccspForm.Products__c                    = 'Red Hat Enterprise Linux Family';
        controller.ccspForm.Certified_Hypervisor__c        = 'VMWare';
        controller.ccspForm.Cloud_Services__c              = 'PaaS';
        controller.ccspForm.Relationships__c               = '--None--';
        controller.revenueUnitMatching                     = true;
        controller.monthlyReportingRequirement             = true;
        controller.systemForReporting                      = true;
        controller.requirementToImplementAndUpdate         = true;
        return controller;
    }
}