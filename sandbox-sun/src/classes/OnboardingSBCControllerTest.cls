@isTest(SeeAllData = true)
private class OnboardingSBCControllerTest {

    @isTest static void cancelBeforeSearch() {
        ApexPages.currentPage().getParameters().put('id', getOnboardingRegistration().Id);
        OnboardingSearchBeforeCreateController controller = new OnboardingSearchBeforeCreateController();
        controller.onLoad();
        controller.cancel();
    }

    @isTest static void searchByPIOrDUNS() {
        ApexPages.currentPage().getParameters().put('id', getOnboardingRegistration().Id);
        OnboardingSearchBeforeCreateController controller = new OnboardingSearchBeforeCreateController();
        controller.onLoad();
        // First, no search parameters provided.
        controller.partyId = '';
        controller.DUNSNumber = '';
        controller.searchPIOrDuns();
        // Now search with parameters.
        controller.partyId = '12345';
        controller.searchPIOrDUNS();
        // Try No Match Found.
        controller.noMatchFound();
        controller.cancelFinalization();
        // Select first item and Proceed.
        controller.selectedRecord = '0';
        controller.matchFound();
        controller.finalize();
    }

    @isTest static void searchByName() {
        ApexPages.currentPage().getParameters().put('id', getOnboardingRegistration().Id);
        OnboardingSearchBeforeCreateController controller = new OnboardingSearchBeforeCreateController();
        controller.onLoad();
        // First, no search parameters provided.
        controller.accountName = '';
        controller.city = '';
        controller.country = '';
        controller.searchName();
        // Now search with parameters.
        controller.accountName = 'test';
        controller.city = 'Raleigh';
        controller.country = 'US';
        controller.searchName();
        // Try No Match Found.
        controller.noMatchFound();
        controller.cancelFinalization();
        // Select first item and Proceed.
        controller.selectedRecord = '0';
        controller.matchFound();
        controller.finalize();
    }

    public static Partner_Onboarding_Registration__c getOnboardingRegistration() {
        return [
            select  Id,
                    Company__c,
                    Address1__c,
                    City__c,
                    Country__r.Name,
                    State_Province__r.Name,
                    Postal_Code__c,
                    SBC_Initiated__c,
                    CDH_Party_Number__c,
                    DUNSNumber__c,
                    Sales_Account__c,
                    Account__c,
                    Partner_Tier_Name__c,
                    Partner_Type_Formula__c,
                    Partner_Onboarding_Status__c
            from    Partner_Onboarding_Registration__c
            where   Partner_Onboarding_Status__c = 'Submitted'
            limit   1
        ];
    }
}