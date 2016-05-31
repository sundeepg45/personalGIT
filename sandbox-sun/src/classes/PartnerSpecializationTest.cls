@isTest
private class PartnerSpecializationTest {

    static testMethod void myUnitTest() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];

        Account account = new Account();
        account.Name ='PartnerSpecializationTestAccount';
        account.Global_Region__c ='NA';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner' 
        ].Id;
        account.OwnerId = user.Id;
        account.BillingCountry ='US';
        insert account;
        
    	PartnerSpecializationExtension controller = new PartnerSpecializationExtension(account);

        controller.setup();
        controller.cloudSelected = True;
        controller.publicSectorSelected = False;
        controller.DCISelected = False;
        controller.MWSSelected = False;
        controller.doRequestCase();
        
        List<PartnerClassification__c> pclfnList = new List<PartnerClassification__c>();
        for (Classification__c clfn : [
        	select id from classification__c where hierarchykey__c like 'PARTNER_CLASSIFICATION.SPECIALIZATION.%'
        ]) {
        	PartnerClassification__c pclfn = new PartnerClassification__c();
        	pclfn.classification__c = clfn.id;
        	pclfn.partner__c = account.id;
        	pclfn.ActivationDate__c = System.today();
        	pclfn.ExpirationDate__c = System.today().addMonths(12);
        	pclfnList.add(pclfn);
        }
        insert pclfnList;
        controller.setup();
        controller.doRequestCase();
    }
}