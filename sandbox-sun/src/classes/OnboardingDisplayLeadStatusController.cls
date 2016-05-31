public without sharing class OnboardingDisplayLeadStatusController {

	public Partner_Onboarding_Registration__c lead {get; set;}

    public OnboardingDisplayLeadStatusController() { //ApexPages.StandardController stdController) {
        String leadid = (String) ApexPages.currentPage().getParameters().get('id');
        this.lead = [select Id, Partner_Onboarding_Status__c, CreatedDate, Company__c, Partner_Type__r.Name, City__c, State_Province__r.Abbreviation__c, Country__r.Name from Partner_Onboarding_Registration__c where Id = :leadid];
    }


}