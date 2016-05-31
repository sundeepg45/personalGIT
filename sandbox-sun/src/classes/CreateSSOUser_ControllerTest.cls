@isTest
private class CreateSSOUser_ControllerTest {

    static testMethod void myUnitTest() {
        
        //User pcmu = [select Id from user where id = '00560000001VAuW'];
        User pcmu = [SELECT Id FROM User WHERE Profile.Name = 'NA Partner Portal – Strategic License' AND IsActive = true AND IsPartnerAdmin__c = true LIMIT 1];
        System.RunAs(pcmu){
            CreateSSOUser_Controller controller = new CreateSSOUser_Controller();
            List<Country__c> countries = controller.SelectableCountryList;
            User me = controller.me;
            controller.inviteIsAdmin = TRUE;
            List<Schema.PicklistEntry> locales = controller.LocaleOptions;
            List<Schema.PicklistEntry> langs = controller.LanguageOptions;
            List<Schema.PicklistEntry> timezones = controller.TimezoneOptions;
            List<SelectOption> selectCountries = controller.SelectableCountryOptions;
            List<SelectOption> selectStates = controller.SelectableStateOptions;
            List<Schema.PicklistEntry> emailOptions = controller.EmailEncodingOptions;
            
            controller.createInvite();
        }
        
    }
}