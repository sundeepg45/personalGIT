@IsTest
private class TestClassCreatePartnerShareForNFR {
     static testmethod void CreatePartnerShareForNFRTestMethod() {
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];

        Account account = new Account();
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = owner.Id;
        insert account;

        Contact cont = new Contact();
        cont.OwnerId = owner.Id;
        cont.AccountId = account.Id;
        cont.FirstName ='FS';
        cont.LastName = 'LS';
        cont.email = 'a@b.com';
        cont.LoginName__c = 'someone@redhat.com';
        insert cont;


        NFR_Request__c nfrRequest = new NFR_Request__c();
        nfrRequest.Partner__c = account.Id;
        nfrRequest.Contact_at_Partner__c = cont.Id;
        nfrRequest.OwnerId = owner.Id;
        nfrRequest.Partner_Status__c ='Ready - Reseller';
        nfrRequest.User_RHN_Entitlement_Login__c = 'RoyBattyReplicant';
        insert nfrRequest;

        Product2 prd = new Product2();
        prd.Name ='Test';
        prd.LATAM_Product__c = true;
        prd.Family ='RHX';
        prd.CurrencyIsoCode ='USD';
        prd.IsActive = true;
        prd.for_NFR__c = true;
        insert prd;
        NFR_LI__c nfrLine = new NFR_LI__c();
        nfrLine.Product__c = prd.Id;
        nfrLine.NFR__c = nfrRequest.Id;
        nfrLine.Quantity__c =4;
        insert nfrLine;
        nfrRequest.Status__c ='Approved';
        update   nfrRequest;

        Account account1 = new Account();
        account1.Name ='Test Acc';
        account1.Global_Region__c ='APAC';
        account1.OwnerId = owner.Id;
        insert account1;

        Contact con = new Contact();
        con.OwnerId = owner.Id;
        con.AccountId = account1.Id;
        con.FirstName = 'fname';
        con.LastName = 'lname';
        con.email = 'test@test.com';
        con.LoginName__c = 'tConRHNEntitlementLogin';
        insert con;

        nfrRequest.Partner__c = account1.Id;
        nfrRequest.Contact_at_Partner__c = con.Id;
        update nfrRequest;

     }
}