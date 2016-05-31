@IsTest
private class AgreementControllerExtTest {

     public static testMethod void test() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        List<Country__c> countryList = [Select Name, Id From Country__c  limit 2];
        //List<Classification__c> partnerTypeClassifications = [Select Id, name from Classification__c where Parent__r.ReferenceKey__c = 'PARTNER_TYPE' and Parent__r.HierarchyRootName__c ='Partner Type' limit 1];
        //Select c.ReferenceKey__c, c.OwnerId, c.Name, c.Id From Classification__c c where  c.ReferenceKey__c = 'PARTNER_TYPE'
        Classification__c classification = new Classification__c();
        classification.Name = 'Partner Type';
        insert classification;
        
        Classification__c childClassification = new Classification__c();
        childClassification.Name = 'Test';
        childClassification.Parent__c = classification.Id;
        insert childClassification;
        Agreement__c agreement = new Agreement__c();
        //agreement.PartnerType__c=partnerTypeClassifications.get(0).Id;
        agreement.PartnerType__c=childClassification.Id;
        agreement.Name ='Test';
        agreement.Type__c = 'Partner';
        agreement.Version__c =1.2;
        agreement.IsSignatureRequired__c = true;
        agreement.ApprovalStatus__c = 'Draft';
        agreement.ActivationDate__c = System.today();
        agreement.ExpirationDate__c = System.today() + 365;
        agreement.OwnerId = user.Id;
        insert agreement;
        AgreementControllerExt agreementController = new AgreementControllerExt(new ApexPages.StandardController(agreement));
        List<Agreement_Country__c> createCountryIdList = new List<Agreement_Country__c>();
        createCountryIdList.add(new Agreement_Country__c(Country__c =countryList.get(0).Id));
        List<Agreement_Country__c> deleteCountryIdList = new List<Agreement_Country__c>();
        deleteCountryIdList.add(new Agreement_Country__c(Country__c =countryList.get(1).Id));
        List<Id> countryIdList = new List<Id>();
        countryIdList.add(countryList.get(0).Id);
        countryIdList.add(countryList.get(1).Id);
        agreementController.createList = createCountryIdList;
        agreementController.deleteList = deleteCountryIdList;
        agreementController.saveAgreement();
        agreementController.cancelAgreement();
        agreementController.getCountries();
        agreementController.getAgreementCountries();
        agreementController.setAgreementCountries(countryIdList);
        Agreement__c agreement1 = new Agreement__c();
//        AgreementControllerExt agreementController1 = new AgreementControllerExt(new ApexPages.StandardController(agreement1));
//        agreementController1.saveAgreement();
//        agreementController1.cancelAgreement(); 
     }      
}