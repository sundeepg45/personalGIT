@isTest
private class PartnerStatus_ObserveRequalWindowTest {

    static testMethod void myUnitTest() {

        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];

        Account account = new Account();
        account.Name ='RequalWindowTestAccount';
        account.Global_Region__c ='NA';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner' 
        ].Id;
        account.OwnerId = user.Id;
        account.BillingCountry ='US';
        account.RequalificationDate__c = Date.today().addYears(-1);
        insert account;
        
        Classification__c isvType = [select Id from Classification__c where hierarchykey__c = 'PARTNER_TYPE.ISV'];
        Classification__c readyTier = [select Id from Classification__c where hierarchykey__c = 'PARTNER_TIER.READY'];

		//
		// should be able to add the first one
		//        
        PartnerStatus__c partnerStatus = new PartnerStatus__c();
        partnerStatus.ActivationDate__c = Date.today();
        partnerStatus.ExpirationDate__c = Date.today().addYears(1);
        partnerStatus.ApprovalStatus__c = 'Approved';
        partnerStatus.Partner__c = account.Id;
        partnerStatus.PartnerTier__c = readyTier.Id;
        partnerStatus.PartnerType__c = isvType.Id;
        insert partnerStatus;

		//
		// should not be able to add another with the window open
		//
		System.debug('################## inserting test status ####################');
        partnerStatus = new PartnerStatus__c();
        partnerStatus.ActivationDate__c = Date.today();
        partnerStatus.ExpirationDate__c = Date.today().addYears(1);
        partnerStatus.ApprovalStatus__c = 'Pending';
        partnerStatus.Partner__c = account.Id;
        partnerStatus.PartnerTier__c = readyTier.Id;
        partnerStatus.PartnerType__c = isvType.Id;
        insert partnerStatus;

    }
}