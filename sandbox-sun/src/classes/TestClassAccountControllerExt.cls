/**
* Class Name:TestClassAccountControllerExt
* Description: Test Class created for AccountControllerExt business Class
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :9/28/2011
* Reason for Modification:Test coverage enhanced and assert statements are also added.
*/

@IsTest
private class TestClassAccountControllerExt 
{
    static testmethod void AccountControllerExt() 
    {
        List<Classification__c> cList = new List<Classification__c>();
        Classification__c pType = null;
        Classification__c pTier = null;
        
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
       
        pType=new Classification__c(Name='Partner Type');
        insert pType;   

        pTier = new Classification__c(Name='Partner Tier');
        insert pTier;   

        Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
        //Classification__c cType = new Classification__c(Name='Reseller',Parent__c=pType.Id);
        cList.add(cTier);
        //cList.add(cType);
        insert cList;
        
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
        partnerStatus.PartnerType__c = [Select c.Name, c.Id From Classification__c c where c.Name ='Reseller'].Id;
        partnerStatus.PartnerTier__c =  cList[0].Id;
        partnerStatus.ApprovalStatus__c = 'Approved';
        insert partnerStatus;
        
        test.startTest();
        
        AccountControllerExt controller = new AccountControllerExt(new ApexPages.StandardController(a));
        
        System.assertEquals(null,controller.changePartnerStatus());
        controller.back();
        
        test.stopTest();
    }
}