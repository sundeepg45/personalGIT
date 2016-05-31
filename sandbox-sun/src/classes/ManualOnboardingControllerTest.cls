@isTest(SeeAllData = true)
public class ManualOnboardingControllerTest {

    @isTest static void nonFedSled() {
        ManualOnboardingController controller = setUpData();
        controller.submit();
    }

    @isTest static void nonFedSledInvalidEmail() {
        ManualOnboardingController controller = setUpData();
        controller.companyEmail = 'invalid';
        controller.submit();
    }

    @isTest static void nonFedSledNonUS() {
        ManualOnboardingController controller = setUpDataNonUS();
        controller.submit();
    }

    @isTest static void fedSled() {
        ManualOnboardingController controller = setUpData();
        controller.isPublicSector = true;
        controller.updateRegionAndSubregion();
        controller.submit();
    }

    @isTest static void blankState() {
        ManualOnboardingController controller = setUpData();
        controller.state = '';
        controller.submit();
    }

    @isTest static void cancel() {
        ManualOnboardingController controller = setUpData();
        controller.cancel();
    }

    @isTest static void incpompleteData() {
        ManualOnboardingController controller = setUpData();
        controller.city = null;
        controller.submit();
    }

    public static ManualOnboardingController setUpData() {
        ManualOnboardingController controller = new ManualOnboardingController();
        controller.onLoad();
        controller.partnerType = 'Reseller';
        controller.companyName = 'Test Company Name';
        controller.address = '100 Test Address Street';
        controller.city = 'Testville';
        controller.country = 'United States';
        controller.updateStatesList();
        controller.state = 'Florida';
        controller.updateRegionAndSubregion();
        controller.postalCode = '99999';
        controller.companyEmail = 'test@test.com';
        controller.phone = '(999) 999-9999';
        controller.website = 'www.test.com';

        return controller;
    }

    public static ManualOnboardingController setUpDataNonUS() {
        ManualOnboardingController controller = setUpData();
        controller.partnerType = 'OEM';
        controller.country = 'India';
        controller.updateStatesList();
        controller.state = 'Goa';
        controller.updateRegionAndSubregion();

        return controller;
    }
}