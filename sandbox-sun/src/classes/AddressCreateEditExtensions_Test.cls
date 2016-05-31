@IsTest(SeeAllData=false) // this is required to access Custom settings.
private class AddressCreateEditExtensions_Test{
     /**
     * This unit test Tests for Creating/Editing  valid address for Sales Account.
     * 
     *
     * The test addresses, however, is created. 
     */
    private static Map<String, Country__c> createCountries() {

        Map<String, Country__c> countryMap = new Map<String, Country__c>();

        Country__c country_CA = new Country__c();
        country_CA.Name = 'CANADA';
        country_CA.Address_Style__c = 'Address Style 8';
        country_CA.IsAgreementSignatureRequired__c = false;
        country_CA.Country_of_Order__c = 'Canada'; 
        country_CA.Global_Region__c = 'NA'; 
        country_CA.Iso3166Alpha2__c = 'CA'; 
        country_CA.Iso3166Alpha3__c = 'CAN'; 
        country_CA.Iso3166Numeric3__c = 124; 
        insert country_CA;
        countryMap.put('CA', country_CA);

        Country__c country_US = new Country__c();
        country_US.Name = 'UNITED STATES';
        country_US.Address_Style__c = 'Address Style 9';
        country_US.IsAgreementSignatureRequired__c = false;
        country_US.Country_of_Order__c = 'United States'; 
        country_US.Global_Region__c = 'NA'; 
        country_US.Iso3166Alpha2__c = 'US'; 
        country_US.Iso3166Alpha3__c = 'USA';
        insert country_US;
        countryMap.put('US', country_US);

        Country__c country_IN = new Country__c();
        country_IN.Name = 'INDIA';
        country_IN.Address_Style__c = 'Address Style 10';
        country_IN.IsAgreementSignatureRequired__c = false;
        country_IN.Country_of_Order__c = 'India'; 
        country_IN.Global_Region__c = 'APAC'; 
        country_IN.Iso3166Alpha2__c = 'IN'; 
        country_IN.Iso3166Alpha3__c = 'IND'; 
        country_IN.Iso3166Numeric3__c = 356; 
        insert country_IN;
        countryMap.put('IN', country_IN);

        Country__c country_CN = new Country__c();
        country_CN.Name = 'CHINA';
        country_CN.Address_Style__c = 'Address Style 8';
        country_CN.IsAgreementSignatureRequired__c = false;
        country_CN.Country_of_Order__c = 'China'; 
        country_CN.Global_Region__c = 'APAC'; 
        country_CN.Iso3166Alpha2__c = 'CN'; 
        country_CN.Iso3166Alpha3__c = 'CHN'; 
        country_CN.Iso3166Numeric3__c = 156; 
        insert country_CN;
        countryMap.put('CN', country_CN);

        Country__c country_AU = new Country__c();
        country_AU.Name = 'AUSTRALIA';
        country_AU.Address_Style__c = 'Address Style 10';
        country_AU.IsAgreementSignatureRequired__c = false;
        country_AU.Country_of_Order__c = 'Australia'; 
        country_AU.Global_Region__c = 'APAC'; 
        country_AU.Iso3166Alpha2__c = 'AU'; 
        country_AU.Iso3166Alpha3__c = 'AUS'; 
        country_AU.Iso3166Numeric3__c = 36; 
        insert country_AU;
        countryMap.put('AU', country_AU);

        return countryMap;
    }
    public static id accountRecordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('NA Partner').RecordTypeId;
    public static testmethod void EditAddressTest() {
        
        // Create Test Accounts
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = accountRecordTypeId;
        account.BillingCountry = 'US';
        insert account;
        
        //Create your sample Address
        Address__c address = new Address__c();
        address.Sales_Account__c = account.id;
        address.Country__c = 'IN';
        address.State__c = 'Karnataka';
        address.City__c = 'Bangalore';
        address.Zip_Postal_Code__c = '560050';
        address.Address_Line1__c = '150';
        address.Status__c = 'Active';
        insert address;
        
        //RH_CountryCode_CountryName__c cc = new RH_CountryCode_CountryName__c();
        //cc.Name = 'CANADA';
        //cc.RH_DESCRIPTION__c= 'Canada';
        //cc.RH_TERRITORY_CODE__c = 'CA';
        //cc.RH_TERRITORY_SHORT_NAME__c = 'Canada';
        //insert cc;
        createCountries();

        //Set your current Page Reference
        Test.setCurrentPage(Page.AddressCreateEditPage); //Use the name of your VF page
        
        ApexPages.currentPage().getParameters().put('id', address.id);
        ApexPages.currentPage().getParameters().put('countryName', 'CANADA');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(address);
        Test.startTest();
        AddressCreateEditExtensions controller = new AddressCreateEditExtensions(stdController);
        ApexPages.currentPage().getParameters().put('adminType','State');
        //controller.setSelectListValues();
        //System.assertEquals(controller.stateList.size(),1);
        ApexPages.currentPage().getParameters().put('adminType','County');
        //controller.setSelectListValues();
        //System.assertEquals(controller.countyList.size(),1);
        ApexPages.currentPage().getParameters().put('adminType','province');
        //System.assertEquals(controller.provinceList.size(),0);
        //controller.setSelectListValues();
        controller.saveAddressDetails();
        System.assertEquals('CA',controller.addressRecord.Country__c);
        controller.Cancel();
        Test.stoptest();
    } 
    
    public static testmethod void NewAddressTest() {
        
        // Create Test Accounts
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = accountRecordTypeId;
        account.BillingCountry = 'US';
        insert account;
        
        //RH_CountryCode_CountryName__c cc = new RH_CountryCode_CountryName__c();
        //cc.Name = 'CANADA';
        //cc.RH_DESCRIPTION__c= 'Canada';
        //cc.RH_TERRITORY_CODE__c = 'CA';
        //cc.RH_TERRITORY_SHORT_NAME__c = 'Canada';
        //insert cc;
        createCountries();
        
        Address__c address = new Address__c();
        
        //Set your current Page Reference
        Test.setCurrentPage(Page.AddressCreateEditPage); //Use the name of your VF page
        
        //ApexPages.currentPage().getParameters().put('id', address.id);
        ApexPages.currentPage().getParameters().put('countryName', 'CANADA');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(address);
        Test.startTest();
        AddressCreateEditExtensions controller = new AddressCreateEditExtensions(stdController);
        ApexPages.currentPage().getParameters().put('noOfIdentifyingAddress','0');
        ApexPages.currentPage().getParameters().put('accountId',account.id);
        controller.Cancel();
        ApexPages.currentPage().getParameters().put('accountId',null);
        ApexPages.currentPage().getParameters().put('retURL','/'+account.id);
        controller.Cancel();
        ApexPages.currentPage().getParameters().put('accountId',null);
        ApexPages.currentPage().getParameters().put('retURL',null);
        controller.Cancel();
        controller.countryName = 'INDIA';
        controller.stateTextValue = 'Karnataka';
        controller.provinceTextValue = '';
        controller.countyTextValue = '';
        
        // Negative Test Case
        controller.noOfIdentifyingAddress = '0';
        controller.saveAddressDetails();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Error occured')) b = true;
        }
        system.assert(!b);
        System.assertEquals(null, controller.saveAddressDetails());
        // Positive Test Case
        controller.addressRecord.Sales_Account__c = account.id;
        controller.addressRecord.Address_Line1__c = 'Raghavendra Block, Srinagar';
        controller.addressRecord.City__c = 'Sao Paulo';
        controller.saveAddressDetails();
        //System.assertEquals(string.valueOf(new pageReference('/'+controller.addressRecord.id)).substring(0,3),string.valueOf(controller.saveAddressDetails()));
        Test.stoptest();
    }
    
    public static testmethod void CountryWithProvinceTest() {
        
        // Create Test Accounts
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('NA Partner').RecordTypeId;
        account.BillingCountry = 'US';
        insert account;
        
        //Create your sample Address
        Address__c address = new Address__c();
        address.Sales_Account__c = account.id;
        address.Country__c = 'CA';
        address.Province__c = 'Quebec City';
        address.City__c = 'MONTREAL';
        address.Zip_Postal_Code__c = 'H3Z 2Y7';
        address.Address_Line1__c = '10-123 1/2 MAIN STREET';
        address.Status__c = 'Active';
        insert address;
        
        //Country__c country = new Country__c();
        //country.Name = 'CANADA';
        //country.Address_Style__c = 'Address Style 8';
        //country.IsAgreementSignatureRequired__c = false;
        //country.Country_of_Order__c = 'Canada'; 
        //country.Global_Region__c = 'NA'; 
        //country.Iso3166Alpha2__c = 'CA'; 
        //country.Iso3166Alpha3__c = 'CAN'; 
        //country.Iso3166Numeric3__c = 124; 
        //insert country;
        //Insert country;
        Map<String, Country__c> countryMap = createCountries();
        Country__c country = countryMap.get('CA');
        
        List<State__c> stateList = new List<State__c>();
        State__c s1 = new State__c(Name='Toronto',Abbreviation__c = 'ON',Country__c = country.id);
        stateList.add(s1);
        State__c s2 = new State__c(Name='Halifax',Abbreviation__c = 'NS',Country__c = country.id);
        stateList.add(s2);
        State__c s3 = new State__c(Name='Winnipeg',Abbreviation__c = 'MB',Country__c = country.id);
        stateList.add(s3);
        State__c s4 = new State__c(Name='Victoria',Abbreviation__c = 'BC',Country__c = country.id);
        stateList.add(s4);
        State__c s5 = new State__c(Name='Regina',Abbreviation__c = 'SK',Country__c = country.id);
        stateList.add(s5);
        
        insert stateList;
        
        //Set your current Page Reference
        Test.setCurrentPage(Page.AddressCreateEditPage); //Use the name of your VF page
        
        ApexPages.currentPage().getParameters().put('id', address.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(address);
        ApexPages.currentPage().getParameters().put('retURL','/'+account.id);
        Test.startTest();
            AddressCreateEditExtensions controller = new AddressCreateEditExtensions(stdController);    
            controller.Cancel();
        Test.stoptest();
    }
    
    public static testmethod void CountryWithNoProvinceTest() {
        
        // Create Test Accounts
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = accountRecordTypeId;
        account.BillingCountry = 'US';
        insert account;
        
        //Create your sample Address
        Address__c address = new Address__c();
        address.Sales_Account__c = account.id;
        address.Country__c = 'CN';
        address.Province__c = 'SHANDONG';
        address.City__c = 'QINGDAO SHI';
        address.Zip_Postal_Code__c = '266033';
        address.Address_Line1__c = 'RENMIN LU';
        address.Status__c = 'Active';
        insert address;
        
        createCountries();

        //Set your current Page Reference
        Test.setCurrentPage(Page.AddressCreateEditPage); //Use the name of your VF page
        
        ApexPages.currentPage().getParameters().put('id', address.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(address);
        ApexPages.currentPage().getParameters().put('accountId',account.id);
        Test.startTest();
        AddressCreateEditExtensions controller = new AddressCreateEditExtensions(stdController);
        Test.stoptest();
    }
    
    public static testmethod void CountryWithNoStateTest() {
        
        // Create Test Accounts
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = accountRecordTypeId;
        account.BillingCountry = 'US';
        insert account;
        
        //Create your sample Address
        Address__c address = new Address__c();
        address.Sales_Account__c = account.id;
        address.Country__c = 'AU';
        address.State__c = 'South Australia';
        address.City__c = 'WEST BEACH';
        address.Zip_Postal_Code__c = '5024';
        address.Address_Line1__c = '200 Broadway Av';
        address.Status__c = 'Active';
        insert address;

        createCountries();
        
        //Set your current Page Reference
        Test.setCurrentPage(Page.AddressCreateEditPage); //Use the name of your VF page
        
        ApexPages.currentPage().getParameters().put('id', address.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(address);
        ApexPages.currentPage().getParameters().put('accountId',account.id);
        Test.startTest();
        AddressCreateEditExtensions controller = new AddressCreateEditExtensions(stdController);
        Test.stoptest();
    }
}