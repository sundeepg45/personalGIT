@IsTest(SeeAllData = true)
private class TestClassNFRUtil {

  static testmethod void NFRUtilTestMethod() {
        User owner  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
      Account account = new Account();
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = owner.Id;
        account.PartnerStatuses__c ='ISV';
        insert account;

        Product2 prd = new Product2();
        prd.Name ='Test';
        prd.LATAM_Product__c = true;
        prd.Family ='RHX';
        prd.CurrencyIsoCode ='USD';
        prd.IsActive = true;
        prd.for_NFR__c = true;
        
        insert prd;

        NFRUtil.hasChanges('Name',null,account);

        NFRUtil.hasChanges('Name',account,account);
        NFRUtil.compare('Test', null);
        NFRUtil.compare(null, null);
        NFRUtil.compare(null, 'estT');
        NFRUtil.compare('Test', 'Test');
        System.assert(NFRUtil.getNfrRT() != null, 'Nfr opportunity record type is missing');

        System.assert(NFRUtil.getDefaultPriceBook() != null, 'Price book is missing');

        Set<Id> allProducts = new Set<Id>();
        allProducts.add(prd.Id);
        Set<String> allCurrencies = new Set<String>();
        allCurrencies.add('USD');
        PricebookEntry pBookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
        	Product2Id = prd.Id, 
            IsActive = true, 
            CurrencyIsoCode ='USD', 
            UnitPrice = 75.60
        );

//      	pBookEntry.Pricebook2Id = NFRUtil.getDefaultPriceBook();
      
      	insert pBookEntry;

        NFRUtil.getPricebookEntries(allProducts,NFRUtil.getDefaultPriceBook(),allCurrencies);
  }
}