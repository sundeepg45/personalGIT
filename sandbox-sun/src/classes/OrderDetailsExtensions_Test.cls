@IsTest(SeeAllData=true) // this is required to access Custom settings.
private class OrderDetailsExtensions_Test{ 
     /**
     * This unit test Tests for Creating/Editing Order Details for Opportunity and submit Orders.
     * 
     *
     *  
     */
    public static testmethod void createOrderDetails() {
        // Variable to store Recordtype id
        string recordtypeid;
        
        // insert CDH Party record.
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('251020', 'Account Testing Scenario 1', 'ORGANIZATION');
        insert cdhParty;
        System.assertNotEquals(cdhParty.Id, null);
        
        //Create Sales Account
        Account salesAccountOne = new Account();
        Account salesAccountTwo = new Account();
        List<Account> salesAccountList = new List<Account>();
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccountOne.Name = 'Test Sales Account101';
        salesAccountOne.CurrencyIsoCode = 'USD';
        salesAccountOne.RecordTypeId = recordTypeId;
        salesAccountOne.CDH_Party_Name__c = cdhParty.id;
        salesAccountList.add(salesAccountOne);
        
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccountTwo.Name = 'Test Sales Account102';
        salesAccountTwo.CurrencyIsoCode = 'USD';
        salesAccountTwo.CDH_Party_Name__c = cdhParty.id;
        salesAccountTwo.RecordTypeId = recordTypeId;
        salesAccountList.add(salesAccountTwo);
        
        // insert Sales Accounts
        insert salesAccountList;
        
        //Create Contact
        Contact contactAccount = new Contact(LastName = 'title',AccountId = salesAccountList[0].Id,Email = 'xyz@123.com');
        contactAccount.CDH_Party__c = cdhParty.id;
        insert contactAccount;
        system.assertNotEquals(null,[select AccountId from Contact where Id =:contactAccount.Id].AccountId);
        
        //Generate sample EBS Account 
        EBS_Account__c ebsAccount = new EBS_Account__c(Name='1234',Sales_Account__c = salesAccountList[0].Id,CDH_Party_Number__c='77777',Credit_Hold__c=false,EBS_Account_Description__c='test account',EBS_Party_Name__c='test ebs party',EBS_Party_Number__c='1233',Last_Credit_Review_Date__c=System.Today(),Next_Credit_Review_Date__c=System.Today(),Primary_EBS_Account__c=false,Status__c='Active');        
        //ebsAccount.CDH_Party_Number__c = '13233';
        //Inserting EBS Account
        Insert ebsAccount;
        system.assertNotEquals(null,[select CDH_Party_Number__c from EBS_Account__c where Id =:ebsAccount.Id].CDH_Party_Number__c);
        
        //Create Address
        Address__c addressRecord = new Address__c(Sales_Account__c = salesAccountList[0].Id,Address_Line1__c = '150, 14th main',Bill_To_Address__c = true,Entitle_To_Address__c = false,Sold_To_Address__c =false,Ship_To_Address__c =false ,Province__c = '' ,Zip_Postal_Code__c ='560050', Country__c = 'US', County__c = '' , State__c ='Karnataka', City__c = 'Bangalore',CDH_Party_Site_Number__c = '1234',status__c = 'Active');
        addressRecord.CDH_Party__c = cdhParty.id;
        Insert addressRecord;
        
        system.assertNotEquals(null,[select Id from Address__c where Id =:addressRecord.Id].Id);
        
        Order_Management_Profile__c ordermanagementRecord=new Order_Management_Profile__c();
        ordermanagementRecord.Account__c=salesAccountList[0].Id;
        ordermanagementRecord.Default__c=true;
        ordermanagementRecord.Name='Test data';
        insert ordermanagementRecord;
        ordermanagementRecord=new Order_Management_Profile__c();
        ordermanagementRecord.Account__c=salesAccountList[0].Id;
        ordermanagementRecord.Default__c=true;
        ordermanagementRecord.Name='Test data1';
        insert ordermanagementRecord;
        
        //Create Opportunity
        Opportunity opportunityRecord = new Opportunity();
        recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        
        // Opportunity No 1
        opportunityRecord.Name = '1234';
        opportunityRecord.StageName = 'Prepare';
        opportunityRecord.Amount = 12345;
        opportunityRecord.RecordTypeID = recordtypeid;
        opportunityRecord.Type = 'Standard';
        opportunityRecord.CloseDate = System.Today();
        opportunityRecord.PaymentType__c = 'Credit Card';
        opportunityRecord.FulfillmentChannel__c = 'Direct - End Customer';
        opportunityRecord.Country_of_Order__c = 'Australia';
        opportunityRecord.AccountId = salesAccountList[0].Id;
        opportunityRecord.CurrencyIsoCode = 'USD';
        opportunityRecord.Pay_Now__c = 'Yes';
        opportunityRecord.ForecastCategoryName = 'Pipeline';
        opportunityRecord.Bill_To_Sales_Account__c =salesAccountList[0].Id;
        opportunityRecord.Ship_To_Sales_Account__c =salesAccountList[0].Id;
        opportunityRecord.Sold_To_Sales_Account__c =salesAccountList[0].Id;
        opportunityRecord.Entitle_To_Sales_Account__c =salesAccountList[0].Id;
        opportunityRecord.Bill_To_Contact__c =contactAccount.Id;
        opportunityRecord.Ship_To_Contact__c =contactAccount.Id;
        opportunityRecord.Sold_To_Contact__c =contactAccount.Id;
        opportunityRecord.Entitle_To_Contact__c =contactAccount.Id;
        opportunityRecord.Bill_To_Address__c =addressRecord.Id;
        opportunityRecord.Sold_To_Address__c =addressRecord.Id;
        opportunityRecord.Ship_To_Address__c =addressRecord.Id;
        opportunityRecord.Entitle_To_Address__c =addressRecord.Id;
        opportunityRecord.Bill_To_Account__c =ebsAccount.Id;
        opportunityRecord.Sold_To_Account__c =ebsAccount.Id;
        opportunityRecord.Ship_To_Account__c =ebsAccount.Id;
        opportunityRecord.Entitle_To_Account__c =ebsAccount.Id;
        opportunityRecord.Order_Management_Profile__c='Test data';
        insert opportunityRecord;
        
        
         
        String pb2Standard = [select Id from Pricebook2 where isStandard=true].id;
        
        
        // set up product2 and Verify that the results are as expected.
        Product2 productRecord = new Product2(Name='Test Product',isActive=true);
        insert productRecord;
        System.assertEquals('Test Product',[SELECT Name FROM Product2 WHERE Id = :productRecord.Id].Name);
        
        // set up PricebookEntry.
        PricebookEntry priceBookEntryRecord = new PricebookEntry(Pricebook2Id = pb2Standard, Product2Id=productRecord.Id, UnitPrice=99, isActive=true);
        insert priceBookEntryRecord;
        
        // set up OpportunityLineItem.
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(PriceBookEntryId=priceBookEntryRecord.Id, OpportunityId=opportunityRecord.Id, Quantity=1, TotalPrice=99  );//,Entitle_To_Account__c = ebsAccount.id
        opportunityLineItem.Entitle_To_Account__c = ebsAccount.Id;
        opportunityLineItem.Entitle_To_Address__c = addressRecord.Id;
        opportunityLineItem.Entitle_To_Sales_Account__c = salesAccountList[0].id;
        insert opportunityLineItem;
        OpportunityLineItem opportunityLineItemQuery = [SELECT PriceBookEntryId FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id];
        
        //creating a partner type for an opportunity.
        OpportunityPartner__c opportunityPartnerRecord = IntegrationObjectsTestUtil.getSFOpportunityPartner(opportunityRecord,'Primary','Test Name' , 'Primary', 'Tier 1');
        
        //Set your current Page Reference
        Test.setCurrentPage(Page.CreateOrderDetails); //Use the name of your VF page
        ApexPages.currentPage().getParameters().put('Id', opportunityRecord.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(opportunityRecord);
        ApexPages.currentPage().getParameters().put('countryName','united states');
        
        ApexPages.currentPage().getParameters().put('adminType','County');
        
        
            
        Test.startTest();
            orderDetailsExtensions controller = new orderDetailsExtensions(stdController);
            orderDetailsExtensions.getDefaultOrderType('RH Argentina Operating Unit,REBOOK');
            orderDetailsExtensions.salesAccountSearch('Test Sales Account');
            orderDetailsExtensions.EBSAccountSearch(string.valueOf(salesAccountList[0].Id));
            orderDetailsExtensions.AddressSearch(string.valueOf(salesAccountList[0].Id),'bill');
            orderDetailsExtensions.AddressSearch(string.valueOf(salesAccountList[0].Id),'sold');
            orderDetailsExtensions.AddressSearch(string.valueOf(salesAccountList[0].Id),'ship');
            orderDetailsExtensions.AddressSearch(string.valueOf(salesAccountList[0].Id),'entitle');
            orderDetailsExtensions.ContactSearch(string.valueOf(salesAccountList[0].Id));
            String opportunityUpdateToString = '\'true\',\'No value defined here\',\'No value defined here\','+string.valueOf(salesAccountList[0].id)+','+string.valueOf(ebsAccount.id)+','+string.valueOf(addressRecord.id)+','+string.valueOf(contactAccount.id)+','+string.valueOf(salesAccountList[0].id)+','+string.valueOf(ebsAccount.id)+','+string.valueOf(addressRecord.id)+','+string.valueOf(contactAccount.id)+','+string.valueOf(salesAccountList[0].id)+','+string.valueOf(ebsAccount.id)+','+string.valueOf(addressRecord.id)+','+string.valueOf(contactAccount.id)+','+string.valueOf(salesAccountList[0].id)+','+string.valueOf(ebsAccount.id)+','+string.valueOf(addressRecord.id)+','+string.valueOf(contactAccount.id)+'';      //,string.valueOf(salesAccountList[0].id),string.valueOf(ebsAccount.id),string.valueOf(addressRecord.id),string.valueOf(contactAccount.id),string.valueOf(salesAccountList[0].id),string.valueOf(ebsAccount.id),string.valueOf(addressRecord.id),string.valueOf(contactAccount.id),string.valueOf(salesAccountList[0].id),string.valueOf(ebsAccount.id),string.valueOf(addressRecord.id),string.valueOf(contactAccount.id)';
            system.debug('-----------------------'+opportunityUpdateToString);
            ApexPages.currentPage().getParameters().put('opportunityDetailToUpdate', 'RH Canada Operating Unit'+',STANDARD-CA'+','+opportunityRecord.Bill_To_Sales_Account__c+','+opportunityRecord.Bill_To_Account__c+','+opportunityRecord.Bill_To_Address__c+','+opportunityRecord.Bill_To_Contact__c+','+opportunityRecord.Ship_To_Sales_Account__c+','+opportunityRecord.Ship_To_Account__c+','+opportunityRecord.Ship_To_Address__c+','+opportunityRecord.Ship_To_Contact__c+','+opportunityRecord.Sold_To_Sales_Account__c+','+opportunityRecord.Sold_To_Account__c+','+opportunityRecord.Sold_To_Address__c+','+opportunityRecord.Sold_To_Contact__c+','+opportunityRecord.Entitle_To_Sales_Account__c+','+opportunityRecord.Entitle_To_Account__c+','+opportunityRecord.Entitle_To_Address__c +','+opportunityRecord.Entitle_To_Contact__c);
            
            //coverage for track changes for the Opportunity
            controller.existingInstance.Entitle_To_Sales_Account__c=controller.existingInstance.Entitle_To_Account__c=controller.existingInstance.Entitle_To_Address__c=controller.existingInstance.Entitle_To_Contact__c=null;
            OpportunityLineItem opptyLineItem=new OpportunityLineItem(PriceBookEntryId=priceBookEntryRecord.Id, OpportunityId=opportunityRecord.Id, Quantity=1, TotalPrice=99 );
            insert opptyLineItem;
            
            
            controller.opportunityUpdate();
            controller.onSubmitOrderBtnClick();
            ApexPages.currentPage().getParameters().put('addrIdentifier', 'bill');
            ApexPages.currentPage().getParameters().put('salesaccountId', string.valueOf(salesAccountList[0].Id));                  // salesaccountId
            controller.initializeAddressCreation();

            System.assert(controller.AddressRecord.Bill_To_Address__c);
            System.assert(!controller.AddressRecord.Entitle_To_Address__c);
            System.assert(!controller.AddressRecord.Ship_To_Address__c);
            System.assert(!controller.AddressRecord.Sold_To_Address__c);

            controller.setSelectListFieldsToText();
       
            //RH_CountryCode_CountryName__c country = new RH_CountryCode_CountryName__c();
            //country.RH_TERRITORY_CODE__c = 'US';
            //country.Name = 'united states';
            //country.RH_TERRITORY_SHORT_NAME__c = 'US';
            //insert country;
            //Map<string,RH_CountryCode_CountryName__c > countryCodeWrapper = new Map<string,RH_CountryCode_CountryName__c >();
            //countryCodeWrapper.put('US',country);
            
            list<State__c> listState = new list<State__c>();
            
            Country__c country1 =new Country__c(Name = 'united states', Global_Region__c = 'APAC',Iso3166Alpha2__c = 'XY');
            insert country1;
            
            State__c stateObject1 =  new State__c(Name = 'Atlanta',Country__c = country1.id , Abbreviation__c = '123');
            listState.add(stateObject1);
            State__c stateObject2 =  new State__c(Name = 'New York',Country__c = country1.id ,Abbreviation__c = '134');
            listState.add(stateObject2);
            insert listState;
            
            Map<String,List<State__c>> countryStateMap = new Map<String,List<State__c>>();
            countryStateMap.put('united states' ,listState);
           
            controller.AddressRecord.Address_Line1__c = '150/5-1';
            controller.AddressRecord.Address_Line2__c = 'Raghavendra Block';
            controller.AddressRecord.City__c = 'Bangalore';
            controller.CountryName = 'INDIA';
            controller.AddressRecord.State__c = 'Karnataka';
            controller.AddressRecord.Zip_Postal_Code__c = '560050';
            controller.provinceTextValue = 'No province';
            controller.countyTextValue = 'No county';
            controller.addressRecord.Sales_Account__c = salesAccountList[0].Id;
            controller.stateTextValue = 'Karnatka';
            controller.saveAddressDetails();
            
            //create map for Address wrapper
            //controller.mapAddressCountryget.put('united states','Address Style 9');
            //controller.mapAddressWrapper=new Map<string,RH_AddressCountryMapping__c>();
            //controller.mapAddressWrapper= RH_AddressCountryMapping__c.getAll();
            //controller.getAllStates();
            //ApexPages.currentPage().getParameters().put('countryName','canada');
            //controller.mapAddressCountryget.put('canada','Address Style 8');
            //controller.mapAddressWrapper=new Map<string,RH_AddressCountryMapping__c>();
            //controller.mapAddressWrapper= RH_AddressCountryMapping__c.getAll();
            //controller.getAllStates();     
            //controller.selectedProfile = ordermanagementRecord.id;
            //controller.refreshData();
            //OrderDetailsExtensions.orderWrapperDetailsJSON='variable not used';
        Test.stopTest();
    }
    
    
}