@isTest
private class TestClassChangePartnerStatusTrig {
    
    /*
     * Test Case for the trigger.
     */
     static testmethod void ChangePartnerStatusTestMethod() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        Classification__c resellerCalssification = [Select c.Name, c.Id From Classification__c c where c.Name ='Reseller'];
        Classification__c readyClassification = [Select c.Name, c.Id From Classification__c c where c.Name ='Ready'];
        RecordType partnerRecordType =[Select r.Name, r.Id From RecordType r where r.name='EMEA Partner'];
        Account a = new Account();
    a.ownerId = user.Id;
    a.name = 'Test';
    a.BillingStreet = 'Test';
    a.BillingCity = 'Test';
    a.BillingState = 'CA';
    a.BillingCountry = 'US';
    a.ShippingState = 'CA';
    a.ShippingCountry = 'US';
    a.RecordTypeId = partnerRecordType.Id;
    insert a;
  
      
    PartnerStatus__c partnerStatus = new PartnerStatus__c();
    partnerStatus.Partner__c= a.Id;
    partnerStatus.PartnerType__c =resellerCalssification.Id;
    partnerStatus.PartnerTier__c =  readyClassification.Id;
    insert partnerStatus;
     
      test.starttest();
      System.debug('Previous Partner Status ID----------->'+ partnerStatus.Id);
    PartnerStatus__c partnerStatus1 = new PartnerStatus__c();
    partnerStatus1.Partner__c= a.Id;
    partnerStatus1.Previous_Partner_Status__c = partnerStatus.Id;
    partnerStatus1.PartnerType__c =resellerCalssification.Id;
    partnerStatus1.PartnerTier__c =  readyClassification.Id;
    insert partnerStatus1;
    
      
      partnerStatus1.ApprovalStatus__c='Approved';
      System.debug('Previous Partner Status ID----------->Before Update'+ partnerStatus1.Id);
      update partnerStatus1;

        test.stoptest();
        
     }

}