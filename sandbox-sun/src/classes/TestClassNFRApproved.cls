@IsTest
private class TestClassNFRApproved {
	static testmethod void NFRApproved() {
		User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
		Profile p = [select id,name from profile where Name = 'Partner Profile' limit 1];
        User user  = new User(username = 'test1@rh.com',LastName='lname',CommunityNickname='Test1', email = 'test1@rh.com', alias = 'test1', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = p.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US');

        insert user;
        User currentUser = [select id,FirstName,LastName from user where userType='PowerPartner' and isActive = true limit 1];

        //System.runAs(currentUser) {
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
        nfrRequest.Contact_at_Partner__c = cont.Id;
        nfrRequest.Partner__c = account.Id;
        nfrRequest.OwnerId = owner.Id;
        nfrRequest.Partner_Status__c ='Ready - Reseller';
        nfrRequest.User_RHN_Entitlement_Login__c = 'RickDeckerd';
        insert nfrRequest;
        //}

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

        NFR_Request__c nfrRequest1 = new NFR_Request__c();
        nfrRequest1.Contact_at_Partner__c = cont.Id;
        nfrRequest1.Partner__c = account.Id;
        nfrRequest1.OwnerId = owner.Id;
        nfrRequest1.Partner_Status__c ='Ready - Reseller';
        nfrRequest1.User_RHN_Entitlement_Login__c = 'RickDeckerd';
        insert nfrRequest1;

        Product2 prd1 = new Product2();
        prd1.Name ='Test';
        prd1.LATAM_Product__c = true;
        prd1.Family ='RHX';
        prd1.CurrencyIsoCode ='USD';
        prd1.IsActive = true;
        prd1.for_NFR__c = true;
        insert prd1;
        NFR_LI__c nfrLine1 = new NFR_LI__c();
        nfrLine1.Product__c = prd1.Id;
        nfrLine1.NFR__c = nfrRequest1.Id;
        nfrLine1.Quantity__c =4;
        insert nfrLine1;

        nfrRequest1.Status__c ='Processed';
        update   nfrRequest1;

        nfrRequest1.Status__c ='Rejected';
        update   nfrRequest1;

        nfrRequest1.Status__c ='Extension Requested';
        update   nfrRequest1;

        nfrRequest1.Status__c ='Extension Rejected';
        update   nfrRequest1;
	}
}