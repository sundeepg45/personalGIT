/*****************************************************************************************
    Name    : IntegrationObjectsTestUtil
    Desc    : Generates objects for use in unit testing

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Tiaan Kruger           7/11/2014       Created
    Scott Coleman          7/18/2014       Updated native opp methods
    Scott Coleman          7/06/2015       US66997 - added Active__c = true to test parties
******************************************************************************************/
public with sharing class IntegrationObjectsTestUtil {

    public static CDH_Party__c getCDHParty(String cdhPartyNumber, String cdhPartyName, String cdhPartyType){
        CDH_Party__c cdhParty = new CDH_Party__c();
        cdhParty.CDH_Party_Name__c = cdhPartyName;
        cdhParty.CDH_Party_Number_Ext__c = cdhPartyNumber;
        cdhParty.Name = cdhPartyNumber;
        cdhParty.CDH_Party_Type__c = cdhPartyType;
        //US66997
        cdhParty.Active__c = true;
        return cdhParty;
    }
    
    public static CDH_Party__c getCDHParty(String name){
        CDH_Party__c cdhParty = new CDH_Party__c();

        cdhParty.CDH_Party_Name__c = name;
        cdhParty.CDH_Party_Number_Ext__c = '1234567890' + generateRandomSeed(10);
        cdhParty.CDH_Party_Type__c = 'ORGANIZATION';
        //US66997
        cdhParty.Active__c = true;        

        return cdhParty;
    }

    public static EBS_Account__c getEBSAccount(String name, Account acct){
        EBS_Account__c ebsAccount = new EBS_Account__c();

        ebsAccount.Name = '1234567';
        ebsAccount.CDH_Party_Number__c = '1234567890' + generateRandomSeed(10);
        ebsAccount.Credit_Hold__c = True;
        ebsAccount.Credit_Review_Cycle__c = 'ANNUALLY';
        ebsAccount.Classification__c = 'Federal';
        ebsAccount.EBS_Account_Description__c = 'One Amazing EBS Account';
        ebsAccount.Sales_channel__c = 'Reseller';
        ebsAccount.Status__c = 'Active';
        ebsAccount.Account_Type__c = 'External';
        ebsAccount.EBS_Party_Name__c = name;
        ebsAccount.EBS_Party_Number__c = '8' + generateRandomSeed(6);
        ebsAccount.Last_Credit_Review_Date__c = Date.valueOf(System.now().addMonths(-3));
        ebsAccount.Next_Credit_Review_Date__c = Date.valueOf(System.now().addMonths(3));
        ebsAccount.Primary_EBS_Account__c = True;
        ebsAccount.Sales_Account__c = acct.Id;
        ebsAccount.Sales_Account__r = acct;

        return ebsAccount;
    }

    public static Account getSFAccount(CDH_Party__c party, String name){
        Account a = new Account();

        a.AccountNumber = '1234567';
        a.CDH_Party_Name__c = party.Id;
        a.Name = name;
        a.VATNumber__c = 'VAT12345';
        a.DunsNumber = 'DUNS12345';
        a.Status__c = 'Active';
        a.Sic = '1234';
        a.SicDesc = 'Software';
        a.All_NAICS_Codes__c = '098765';
        a.Do_Not_Do_Business_With__c = False;
        a.SEA_Concern__c = 'No Concerns';
        a.Trade_Style__c = 'Taco Bell';
        a.YearStarted = '2087';
        a.NumberOfEmployees = 2;
        a.AnnualRevenue = generateRandomNumber(5);
        a.Website = 'http://www.' + name.deleteWhitespace().toLowercase() + '.com';
        a.Phone = '(555) 555-1234';
        a.Fax = '(777) 777-1234';
        a.Headquarters__c = party.Id;
        a.Linkedin_URL__c = 'https://www.linkedin.com/company/' + name.deleteWhitespace().toLowercase();

        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccount(){
        return getSalesAccount('Tesla Motors');
    }

    public static List<IntegrationObjects.SalesAccount> getSalesAccountList(String name){
        List<IntegrationObjects.SalesAccount> accounts = new List<IntegrationObjects.SalesAccount>();

        accounts.add(getSalesAccount(name + ' One'));
        accounts.add(getSalesAccount(name + ' Two'));
        accounts.add(getSalesAccount(name + ' Three'));
        accounts.add(getSalesAccount(name + ' Four'));
        accounts.add(getSalesAccount(name + ' Five'));

        return accounts;
    }

    public static IntegrationObjects.SalesAccount getSalesAccount(String name){
        IntegrationObjects.SalesAccount a = new IntegrationObjects.SalesAccount();

        a.IDs = '0AcC00' + generateRandomSeed(5) + 'FaKe';
        a.CDH_Party_Number = '12345678901234567890';
        a.Name = name;
        a.CDH_Party_Type = 'ORGANIZATION';
        a.VATNumber = 'VAT12345';
        a.D_U_N_S = 'DUNS12345';
        a.Status = 'Active';
        a.Sic = '1234';
        a.SicDesc = 'Software';
        a.All_NAICS_Codes = '098765';
        a.Do_Not_Do_Business_with = False;
        a.SEA_Concern = 'No Concerns';
        a.Trade_Style = 'Taco Bell';
        a.YearStarted = '2087';
        a.NumberOfEmployees = 2;
        a.AnnualRevenue = generateRandomNumber(5);
        a.Website = 'http://www.' + name.deleteWhitespace().toLowercase() + '.com';
        a.Phone = '(555) 555-1234';
        a.Fax = '(777) 777-1234';
        a.Head_Quarters = 'Mars';
        a.Domestic_Ultimate = 'Extreme';
        a.Global_Ultimate = 'More Extreme';
        a.Linkedin_URL = 'https://www.linkedin.com/company/' + name.deleteWhitespace().toLowercase();

        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithAddress(){
        IntegrationObjects.SalesAccount a = getSalesAccount();
        a.addresses = new List<IntegrationObjects.Address>();
        a.addresses.add(getAddress());
        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithAddresses(){
        IntegrationObjects.SalesAccount a = getSalesAccount();
        a.addresses = getAddressList();
        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithContact(){
        IntegrationObjects.SalesAccount a = getSalesAccount();
        a.contacts = new List<IntegrationObjects.Contact>();
        a.contacts.add(getContact(a));
        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithContacts(){
        IntegrationObjects.SalesAccount a = getSalesAccount();
        a.contacts = getContactList(a);
        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithContactsAndAddresses(){
        IntegrationObjects.SalesAccount a = getSalesAccount();
        a.contacts = getContactList(a);
        a.addresses = getAddressList();
        return a;
    }

    public static IntegrationObjects.SalesAccount getSalesAccountWithContactAndAddress(){
        IntegrationObjects.SalesAccount a = getSalesAccountWithContact();
        a.addresses = new List<IntegrationObjects.Address>();
        a.addresses.add(getAddress());
        return a;
    }

    public static IntegrationObjects.TransactionalAccount getTransactionalAccount(){
        return getTransactionalAccount('Amazing EBS Account');
    }

    public static List<IntegrationObjects.TransactionalAccount> getTransactionalAccountList(String name){
        List<IntegrationObjects.TransactionalAccount> tAccounts = new List<IntegrationObjects.TransactionalAccount>();

        tAccounts.add(getTransactionalAccount(name + ' One'));
        tAccounts.add(getTransactionalAccount(name + ' Two'));
        tAccounts.add(getTransactionalAccount(name + ' Three'));
        tAccounts.add(getTransactionalAccount(name + ' Four'));
        tAccounts.add(getTransactionalAccount(name + ' Five'));

        return tAccounts;
    }

    public static IntegrationObjects.TransactionalAccount getTransactionalAccount(String name){
        IntegrationObjects.TransactionalAccount tAccount = new IntegrationObjects.TransactionalAccount();

        tAccount.Account_Number = '7654321';
        tAccount.Primary_EBS_Account = True;
        tAccount.Status = 'Active';
        tAccount.Account_Type = 'ORGANIZATION';
        tAccount.Account_Description = 'An Amazing Account';
        tAccount.CDH_Party_Number = '12345678901234567890';
        tAccount.Name = name;
        tAccount.EBS_Party_Number = '123456789';
        tAccount.EBS_Party_Name = 'Quite the Party';
        tAccount.Sales_Account = '12345678901234567890';
        tAccount.Sales_Channel = 'Direct';
        tAccount.Credit_hold = True;
        tAccount.Last_Credit_Review_Date = Date.valueOf(System.now().addMonths(-3));
        tAccount.Next_Credit_Review_Date = Date.valueOf(System.now().addMonths(3));
        tAccount.Credit_Review_Cycle = 'Monthly';

        return tAccount;
    }

    public static Contact getSFContact(CDH_Party__c party, String firstName, String lastName){
        Contact c = new Contact();

        c.CDH_Party__c = party.Id;
        c.LoginName__c = firstName + '.' + lastName + '+login@teslamotors.com';
        c.FirstName = firstName;
        c.LastName = lastName;
        c.Salutation = 'Sir';
        c.Status__c = 'Active';
        c.Email = firstName + '.' + lastName + '@teslamotors.fa.ke.com';
        c.Phone = '(555) 555-1234';
        c.MobilePhone = '(666) 666-1234';
        c.Fax = '(777) 777-1234';

        return c;
    }

    public static IntegrationObjects.Contact getContact(IntegrationObjects.SalesAccount salesAccount){
        return getContact('Nicolas', 'Tesla', salesAccount);
    }

    public static List<IntegrationObjects.Contact> getContactList(IntegrationObjects.SalesAccount salesAccount){
        List<IntegrationObjects.Contact> contacts = new List<IntegrationObjects.Contact>();
        contacts.add(getContact('Nicolas', 'Tesla', salesAccount));
        contacts.add(getContact('James', 'Watson', salesAccount));
        contacts.add(getContact('Captain', 'Reynolds', salesAccount));
        contacts.add(getContact('Bob', 'Munsterlander', salesAccount));
        contacts.add(getContact('Jim', 'Whitehurst', salesAccount));
        return contacts;
    }

    public static IntegrationObjects.Contact getContact(String firstName, String lastName, IntegrationObjects.SalesAccount salesAccount){
        IntegrationObjects.Contact c = new IntegrationObjects.Contact();

        c.IDs = '0CoN00' + generateRandomSeed(5) + 'FaKe';
        c.CDH_Party_Number = '12345678901234567890';
        c.SalesAccount_Id = salesAccount.IDs;
        c.SalesAccount_CDH_Party_Number = salesAccount.CDH_Party_Number;
        c.LoginName = firstName + '.' + lastName + '+login@teslamotors.com';
        c.FirstName = firstName;
        c.LastName = lastName;
        c.Salutation = 'Sir';
        c.Status = 'Active';
        c.Email = firstName + '.' + lastName + '@teslamotors.fa.ke.com';
        c.Phone = '(555) 555-1234';
        c.MobilePhone = '(666) 666-1234';
        c.Fax = '(777) 777-1234';

        return c;
    }

    public static Address__c getSFAddress(Account acct, String street, String city, String state){
        Address__c a = new Address__c();

        a.Sales_Account__c = acct.Id;
        a.Sales_Account__r = acct;
        a.CDH_Party_Site_Number__c = '01234567890123456789' + generateRandomSeed(10);
        a.Address_Line1__c = generateRandomSeed(3) + ' ' + street;
        a.Address_Line2__c = '';
        a.Address_Line3__c = '';
        a.Address_Line4__c = '';
        a.City__c = city;
        a.State__c = state;
        a.Province__c = '';
        a.Zip_Postal_Code__c = generateRandomSeed(5);
        a.County__c = 'Wake';
        a.Country__c = 'US';
        a.Bill_To_Address__c = True;
        a.Sold_To_Address__c = False;
        a.Ship_To_Address__c = False;
        a.Entitle_To_Address__c = True;
        a.Identifying_Address__c = True;
        a.Status__c = 'Active';

        return a;
    }

    public static IntegrationObjects.Address getAddress(){
        return getAddress('East Davie Street', 'Raleigh', 'NC');
    }

    public static List<IntegrationObjects.Address> getAddressList(){
        List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
        addresses.add(getAddress('East Davie Street', 'Raleigh', 'NC'));
        addresses.add(getAddress('West George Street', 'Angier', 'NC'));
        addresses.add(getAddress('Savana Street', 'Savana', 'GA'));
        addresses.add(getAddress('Pensylvania Avenue', 'Washington', 'DC'));
        addresses.add(getAddress('Varsity Drive', 'Raleigh', 'NC'));
        return addresses;
    }

    public static IntegrationObjects.Address getAddress(String street, String city, String state){
        IntegrationObjects.Address a = new IntegrationObjects.Address();

        a.IDs = '0AdR00' + generateRandomSeed(5) + 'FaKe';
        a.CDH_Party_Site_Number = '12345678901234567890';
        a.Address_Line1 = generateRandomSeed(3) + ' ' + street;
        a.Address_Line2 = '';
        a.Address_Line3 = '';
        a.Address_Line4 = '';
        a.City = city;
        a.State = state;
        a.Province = '';
        a.Zip_Postal_Code = generateRandomSeed(5);
        a.County = 'Wake';
        a.Country = 'US';
        a.Bill_To_Address = True;
        a.Sold_To_Address = False;
        a.Ship_To_Address = True;
        a.Entitle_To_Address = False;
        a.Identifying_Address = True;
        a.Status = 'Active';

        return a;
    }

    public static Opportunity getSFOpportunity(){
        CDH_Party__c cdhParty = getCDHParty('Party in the USA');
        insert cdhParty;        

        Account account = getSFAccount(cdhParty, 'Sales Account');
        insert account;

        EBS_Account__c transAccount = getEBSAccount('Entitle To Acccount', account);
        insert transAccount;

        Address__c address = getSFAddress(account, '123 Entitle St', 'Raleigh', 'NC');
        insert address;

        Contact contact = getSFContact(cdhParty, 'Paul', 'Entitled');
        insert contact;

        Opportunity opp = new Opportunity(
            AccountId = account.Id,
            Account = account,
            CloseDate = Date.valueOf(system.now().addMonths(3)),
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            Country_of_Order__c = 'United States',
            Entitle_To_Account__c = transAccount.Id,
            Entitle_To_Account__r = transAccount,
            Entitle_To_Address__c = address.Id,
            Entitle_To_Address__r = address,
            Entitle_To_Contact__c = contact.Id,
            Entitle_To_Contact__r = contact,
            Sold_To_Account__c = transAccount.Id,
            Sold_To_Account__r = transAccount,
            Sold_To_Address__c = address.Id,
            Sold_To_Address__r = address,
            Sold_To_Contact__c = contact.Id,
            Sold_To_Contact__r = contact,
            Bill_To_Account__c = transAccount.Id,
            Bill_To_Account__r = transAccount,
            Bill_To_Address__c = address.Id,
            Bill_To_Address__r = address,
            Bill_To_Contact__c = contact.Id,
            Bill_To_Contact__r = contact,                      
            Ship_To_Account__c = transAccount.Id,
            Ship_To_Account__r = transAccount,
            Ship_To_Address__c = address.Id,
            Ship_To_Address__r = address,
            Ship_To_Contact__c = contact.Id,
            Ship_To_Contact__r = contact,             
            OracleOrderId__c = '9876543210',
            OracleOrderNumber__c = '1234567890',
            Owner = new User(Id = UserInfo.getUserId(), EmployeeNumber = '54321'),
            PONumber__c = '2349',
            Order_Type__c = 'STANDARD - AR - FC E',
            Operating_Unit__c = '?',
            PaymentType__c = 'Credit Card',
            FulfillmentChannel__c = 'Direct',
            Deal_Source__c = 'A special place',
            CurrencyIsoCode = 'USD',
            Reseller_PO__c = '46374',
            Credit_Card_Number__c = '928392757483745',
            ExpirationDate__c = Date.valueOf(system.now().addMonths(9)),
            CreditCardType__c = 'Visa',
            NameOnCard__c = 'Bob Dobalina',
            PaymentTerms__c = null,
            Shipping_Instructions__c = 'Ship it please',
            VAT_Code__c = '7575',
            Rush_Order__c = false);   

        List<OpportunityLineItem> lineItems = getSFOpportunityLineItemList(opp);
        //insert lineItems;
        opp.OpportunityLineItems.addAll(lineItems);

        List<OpportunityPartner__c> partners = getSFOpportunityPartnerList(opp);
        //insert partners;
        opp.OpportunityPartners2__r.addAll(partners);

        return opp;
    }

    public static List<OpportunityLineItem> getSFOpportunityLineItemList(Opportunity opp){
        List<OpportunityLineItem> lineitems = new List<OpportunityLineItem>();

        lineitems.add(getSFOpportunityLineItem(opp, 'SKU1230'));
        lineitems.add(getSFOpportunityLineItem(opp, 'SKU1231'));
        lineitems.add(getSFOpportunityLineItem(opp, 'SKU1232'));
        lineitems.add(getSFOpportunityLineItem(opp, 'SKU1233'));

        return lineitems;
    }

    // for now if you call this from a test class you'll need to use SeeAllData=True. see note below.
    public static OpportunityLineItem getSFOpportunityLineItem(Opportunity opp, String sku){
        ///* TODO (in progress - Scott) */
        Product2 product = new Product2(
            Description = 'An amazing product',
            IsActive = true,
            Name = 'Amazing Product',
            ProductCode = sku);
        insert product;

        Id pricebookId;
        if(Test.isRunningTest()) {
            pricebookId = Test.getStandardPricebookId();
        }
        else {
            Pricebook2 pricebook = [SELECT Id FROM PriceBook2 WHERE isStandard = true LIMIT 1];
            pricebookId = pricebook.Id;
        }

        Decimal salesPrice = generateRandomNumber(4);

        PricebookEntry priceBookEntry = new PricebookEntry(
            CurrencyIsoCode = 'USD',
            isActive = true,
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 0);
        insert priceBookEntry;

        Date startDate = Date.valueOf(system.now().addMonths(1));
        Date endDate = startDate.addYears(3);
        Integer actualTerm = startDate.daysBetween(endDate);

        OpportunityLineItem oppLine = new OpportunityLineItem(
            ActualStartDate__c = startDate,
            ActualEndDate__c = endDate,
            ActualTerm__c = actualTerm,
            Base_Price__c = salesPrice,
            Contract_Numbers__c = generateRandomSeed(8),
            Description = product.Description,
            Entitle_To_Account__c = opp.Entitle_To_Account__c,
            Entitle_To_Account__r = opp.Entitle_To_Account__r,
            Entitle_To_Address__c = opp.Entitle_To_Address__c,
            Entitle_To_Address__r = opp.Entitle_To_Address__r,
            Entitle_To_Contact__c = opp.Entitle_To_Contact__c,
            Entitle_To_Contact__r = opp.Entitle_To_Contact__r,
            Install_Base_Number__c = '12345',
            One_Time_Discount__c = salesPrice * 0.75,
            OpportunityId = opp.Id,
            PricebookEntryId = priceBookEntry.Id,
            PriceOverrideReason__c = 'Price overridden',
            Quantity = Integer.valueOf(generateRandomNumber(1)),
            ScheduleLocked__c = true,
            UnitPrice = salesPrice);

        return oppLine;
    }

    public static List<OpportunityPartner__c> getSFOpportunityPartnerList(Opportunity opp){
        List<OpportunityPartner__c> partners = new List<OpportunityPartner__c>();

        partners.add(getSFOpportunityPartner(opp, 'Resller1', 'Amazing Reseller 1', 'Reseller', 'Advanced'));
        partners.add(getSFOpportunityPartner(opp, 'Resller2', 'Amazing Reseller 2', 'Reseller', 'Premier'));
        partners.add(getSFOpportunityPartner(opp, 'Financial', 'Amazing Distributor', 'Distributor', 'Affiliated'));

        return partners;
    }

    public static OpportunityPartner__c getSFOpportunityPartner(Opportunity opp, String relationShipType, String name, String type, String tier){
        Classification__c pType = null;
        Classification__c pTier = null;
        for(Classification__c c : [select Name from Classification__c where Name in ('Partner Type','Partner Tier') and Parent__c = null])
        {
            if(c.Name == 'Partner Type')
            {
                pType = c;
            }
            else if(c.Name == 'Partner Tier')
            {
                pTier = c;
            }
        }
        if(pType == null)
        {
            pType=new Classification__c(Name='Partner Type');
            insert pType;
        }
        if(pTier == null)
        {
            pTier = new Classification__c(Name='Partner Tier');
            insert pTier;
        }
        Classification__c cTier = new Classification__c(Name=tier,Parent__c=pTier.Id);
        Classification__c cType = new Classification__c(Name=type,Parent__c=pType.Id);
        insert new List<Classification__c>{cTier,cType};
        OpportunityPartner__c oppPartner = new OpportunityPartner__c(
            Opportunity__c = opp.Id,
            PartnerTier__c = cTier.Id,
            PartnerType__c = cType.Id,
            Partner__c = opp.AccountId,
            RelationshipType__c = relationShipType
            );
        return oppPartner;
    }

    public static Opportunity_Header_Staging__c getSFOpportunityHeaderStaging(
            Account soldToAccount,
            User opportunityOwner,
            Opportunity opportunity
        ){
        Opportunity_Header_Staging__c oppHS = new Opportunity_Header_Staging__c();

        oppHS.Sales_Account__c = soldToAccount.Id;
        oppHS.Sales_Account__r = soldToAccount;

        oppHS.Opportunity_Name__c = opportunity.Id;
        oppHS.Opportunity_Name__r = opportunity;
        oppHS.Opportunity_Owner__c = opportunityOwner.Id;
        oppHS.Opportunity_Owner__r = opportunityOwner;

        List<IntegrationObjects.TransactionalAccount> tAccounts = getTransactionalAccountList('Transactional Account');
        List<IntegrationObjects.Address> addresses = getAddressList();
        List<IntegrationObjects.Contact> contacts = getContactList(getSalesAccount());

        oppHS.Bill_To_Account_Number__c = tAccounts[0].Account_Number;
        oppHS.Bill_To_CDH_Party_Number__c = tAccounts[0].CDH_Party_Number;
        oppHS.Bill_To_Party_Name__c = tAccounts[0].EBS_Party_Name;
        oppHS.Bill_To_Party_Number__c = tAccounts[0].EBS_Party_Number;
        oppHS.Bill_To_Party_Type__c = tAccounts[0].Account_Type;

        oppHS.Bill_To_Address_CDH_Party_Site_Number__c = addresses[0].CDH_Party_Site_Number;
        oppHS.Bill_To_Address_Line_1__c = addresses[0].Address_Line1;
        oppHS.Bill_To_Address_Line_2__c = addresses[0].Address_Line2;
        oppHS.Bill_To_Address_Line_3__c = addresses[0].Address_Line3;
        oppHS.Bill_To_Address_Line_4__c = addresses[0].Address_Line4;
        oppHS.Bill_To_City__c = addresses[0].City;
        oppHS.Bill_To_Country__c = addresses[0].Country;
        oppHS.Bill_To_County__c = addresses[0].County;
        oppHS.Bill_To_Province__c = addresses[0].Province;
        oppHS.Bill_To_State__c = addresses[0].State;
        oppHS.Bill_To_Zip_Postal_Code__c = addresses[0].Zip_Postal_Code;

        oppHS.Bill_To_Contact_Email__c = contacts[0].Email;
        oppHS.Bill_To_Contact_First_Name__c = contacts[0].FirstName;
        oppHS.Bill_To_Contact_Last_Name__c = contacts[0].LastName;
        oppHS.Bill_To_Contact_Phone__c = contacts[0].Phone;

        oppHS.Ship_To_Account_Number__c = tAccounts[1].Account_Number;
        oppHS.Ship_To_CDH_Party_Number__c = tAccounts[1].CDH_Party_Number;
        oppHS.Ship_To_Party_Name__c = tAccounts[1].EBS_Party_Name;
        oppHS.Ship_To_Party_Number__c = tAccounts[1].EBS_Party_Number;
        oppHS.Ship_To_Party_Type__c = tAccounts[1].Account_Type;

        oppHS.Ship_To_Address_CDH_Party_Site_Number__c = addresses[1].CDH_Party_Site_Number;
        oppHS.Ship_To_Address_Line_1__c = addresses[1].Address_Line1;
        oppHS.Ship_To_Address_Line_2__c = addresses[1].Address_Line2;
        oppHS.Ship_To_Address_Line_3__c = addresses[1].Address_Line3;
        oppHS.Ship_To_Address_Line_4__c = addresses[1].Address_Line4;
        oppHS.Ship_To_City__c = addresses[1].City;
        oppHS.Ship_To_Country__c = addresses[1].Country;
        oppHS.Ship_To_County__c = addresses[1].County;
        oppHS.Ship_To_Province__c = addresses[1].Province;
        oppHS.Ship_To_State__c = addresses[1].State;
        oppHS.Ship_To_Zip_Postal_Code__c = addresses[1].Zip_Postal_Code;

        oppHS.Ship_To_Contact_Email__c = contacts[1].Email;
        oppHS.Ship_To_Contact_First_Name__c = contacts[1].FirstName;
        oppHS.Ship_To_Contact_Last_Name__c = contacts[1].LastName;
        oppHS.Ship_To_Contact_Phone__c = contacts[1].Phone;

        oppHS.Entitle_to_Account_Number__c = tAccounts[2].Account_Number;
        oppHS.Entitle_to_CDH_Party_Number__c = tAccounts[2].CDH_Party_Number;
        oppHS.Entitle_to_Party_Name__c = tAccounts[2].EBS_Party_Name;
        oppHS.Entitle_to_Party_Number__c = tAccounts[2].EBS_Party_Number;
        oppHS.Entitle_to_Party_Type__c = tAccounts[2].Account_Type;

        oppHS.Entitle_To_Address_CDH_Party_Site_Number__c = addresses[2].CDH_Party_Site_Number;
        oppHS.Entitle_To_Address_Line_1__c = addresses[2].Address_Line1;
        oppHS.Entitle_To_Address_Line_2__c = addresses[2].Address_Line2;
        oppHS.Entitle_To_Address_Line_3__c = addresses[2].Address_Line3;
        oppHS.Entitle_To_Address_Line_4__c = addresses[2].Address_Line4;
        oppHS.Entitle_To_City__c = addresses[2].City;
        oppHS.Entitle_To_Country__c = addresses[2].Country;
        oppHS.Entitle_To_County__c = addresses[2].County;
        oppHS.Entitle_To_Province__c = addresses[2].Province;
        oppHS.Entitle_To_State__c = addresses[2].State;
        oppHS.Entitle_To_Zip_Postal_Code__c = addresses[2].Zip_Postal_Code;

        oppHS.Entitle_To_Contact_Email__c = contacts[2].Email;
        oppHS.Entitle_To_Contact_First_Name__c = contacts[2].FirstName;
        oppHS.Entitle_To_Contact_Last_Name__c = contacts[2].LastName;
        oppHS.Entitle_To_Contact_Phone__c = contacts[2].Phone;

        oppHS.Sold_To_Account_Number__c = tAccounts[3].Account_Number;
        oppHS.Sold_To_CDH_Party_Number__c = tAccounts[3].CDH_Party_Number;
        oppHS.Sold_To_Party_Name__c = tAccounts[3].EBS_Party_Name;
        oppHS.Sold_To_Party_Number__c = tAccounts[3].EBS_Party_Number;
        oppHS.Sold_To_Party_Type__c = tAccounts[3].Account_Type;

        oppHS.Sold_To_Address_CDH_Party_Site_Number__c = addresses[3].CDH_Party_Site_Number;
        oppHS.Sold_To_Address_Line_1__c = addresses[3].Address_Line1;
        oppHS.Sold_To_Address_Line_2__c = addresses[3].Address_Line2;
        oppHS.Sold_To_Address_Line_3__c = addresses[3].Address_Line3;
        oppHS.Sold_To_Address_Line_4__c = addresses[3].Address_Line4;
        oppHS.Sold_To_City__c = addresses[3].City;
        oppHS.Sold_To_Country__c = addresses[3].Country;
        oppHS.Sold_To_County__c = addresses[3].County;
        oppHS.Sold_To_Province__c = addresses[3].Province;
        oppHS.Sold_To_State__c = addresses[3].State;
        oppHS.Sold_To_Zip_Postal_Code__c = addresses[3].Zip_Postal_Code;

        oppHS.Sold_To_Contact_Email__c = contacts[3].Email;
        oppHS.Sold_To_Contact_First_Name__c = contacts[3].FirstName;
        oppHS.Sold_To_Contact_Last_Name__c = contacts[3].LastName;
        oppHS.Sold_To_Contact_Phone__c = contacts[3].Phone;

        oppHS.Channel__c = 'Direct';
        oppHS.Date_Ordered__c = Date.valueOf(System.now().addMonths(-1));
        oppHS.Employee_Number__c = '45';
        oppHS.Operating_Unit__c = '5';
        oppHS.Opportunity_ID__c = '0OpP0000001FaKe';
        oppHS.Opportunity_Number__c = '12345678901234567890';
        oppHS.Oracle_Order_ID__c = '12345678901234567890';
        oppHS.Oracle_Order_Number__c = '12345678901234567890';
        oppHS.Order_Last_Update_Date__c = Date.valueOf(System.now().addDays(-5));
        oppHS.Order_Source__c = 'Somewhere';
        oppHS.Order_Status__c = 'CLOSED';
        oppHS.Order_Type__c = 'STANDARD - AR - FC E';
        oppHS.Payment_Type__c = 'Credit Card';
        oppHS.PO_Number__c = '2134';
        oppHS.Resller_PO__c = '21346';

        return oppHS;
    }

        public static Opportunity_Header_Staging__c getSFOpportunityHeaderStaging(
            EBS_Account__c billToEbsAccount,
            EBS_Account__c shipToEbsAccount,
            EBS_Account__c soldToEbsAccount,
            EBS_Account__c entitleToEbsAccount,
            Address__c billToAddress,
            Address__c shipToAddress,
            Address__c soldToAddress,
            Address__c entitleToAddress,
            Contact billToContact,
            Contact shipToContact,
            Contact soldToContact,
            Contact entitleToContact,
            Account billToAccount,
            Account shipToAccount,
            Account soldToAccount,
            Account entitleToAccount,
            User opportunityOwner,
            Opportunity opportunity
        ){
        Opportunity_Header_Staging__c oppHS = new Opportunity_Header_Staging__c();

        oppHS.Sales_Account__c = soldToAccount.Id;
        oppHS.Sales_Account__r = soldToAccount;

        oppHS.Bill_To_Account__c = billToEbsAccount.Id;
        oppHS.Bill_To_Account__r = billToEbsAccount;
        oppHS.Entitle_To_Account__c = entitleToEbsAccount.Id;
        oppHS.Entitle_To_Account__r = entitleToEbsAccount;
        oppHS.Ship_To_Account__c = shipToEbsAccount.Id;
        oppHS.Ship_To_Account__r = shipToEbsAccount;
        oppHS.Sold_To_Account__c = soldToEbsAccount.Id;
        oppHS.Sold_To_Account__r = soldToEbsAccount;

        oppHS.Bill_To_Sales_Account__c = billToAccount.Id;
        oppHS.Bill_To_Sales_Account__r = billToAccount;
        oppHS.Entitle_To_Sales_Account__c = entitleToAccount.Id;
        oppHS.Entitle_To_Sales_Account__r = entitleToAccount;
        oppHS.Ship_To_Sales_Account__c = shipToAccount.Id;
        oppHS.Ship_To_Sales_Account__r = shipToAccount;
        oppHS.Sold_To_Sales_Account__c = soldToAccount.Id;
        oppHS.Sold_To_Sales_Account__r = soldToAccount;

        oppHS.Bill_To_Contact__c = billToContact.Id;
        oppHS.Bill_To_Contact__r = billToContact;
        oppHS.Entitle_To_Contact__c = entitleToContact.Id;
        oppHS.Entitle_To_Contact__r = entitleToContact;
        oppHS.Ship_To_Contact__c = shipToContact.Id;
        oppHS.Ship_To_Contact__r = shipToContact;
        oppHS.Sold_To_Contact__c = soldToContact.Id;
        oppHS.Sold_To_Contact__r = soldToContact;

        oppHS.Bill_To_Address__c = billToAddress.Id;
        oppHS.Bill_To_Address__r = billToAddress;
        oppHS.Entitle_To_Address__c = entitleToAddress.Id;
        oppHS.Entitle_To_Address__r = entitleToAddress;
        oppHS.Ship_To_Address__c = shipToAddress.Id;
        oppHS.Ship_To_Address__r = shipToAddress;
        oppHS.Sold_To_Address__c = soldToAddress.Id;
        oppHS.Sold_To_Address__r = soldToAddress;

        oppHS.Opportunity_Name__c = opportunity.Id;
        oppHS.Opportunity_Name__r = opportunity;
        oppHS.Opportunity_Owner__c = opportunityOwner.Id;
        oppHS.Opportunity_Owner__r = opportunityOwner;

        oppHS.Channel__c = 'Direct';
        oppHS.Date_Ordered__c = Date.valueOf(System.now().addMonths(-1));
        oppHS.Employee_Number__c = '45';
        oppHS.Operating_Unit__c = '5';
        oppHS.Opportunity_ID__c = '0OpP0000001FaKe';
        oppHS.Opportunity_Number__c = '12345678901234567890';
        oppHS.Oracle_Order_ID__c = '12345678901234567890';
        oppHS.Oracle_Order_Number__c = '12345678901234567890';
        oppHS.Order_Last_Update_Date__c = Date.valueOf(System.now().addDays(-5));
        oppHS.Order_Source__c = 'Somewhere';
        oppHS.Order_Status__c = 'CLOSED';
        oppHS.Order_Type__c = 'STANDARD - AR - FC E';
        oppHS.Payment_Type__c = 'Credit Card';
        oppHS.PO_Number__c = '2134';
        oppHS.Resller_PO__c = '21346';

        return oppHS;
    }

    public static Opportunity_Line_Staging__c getSFOpportunityLineStaging(Opportunity_Header_Staging__c oppHeader, Product2 aProduct){
        Opportunity_Line_Staging__c oppLine = new Opportunity_Line_Staging__c();

        oppLine.Opportunity_Stage_Header_ID__c = oppHeader.Id;
        oppLine.Opportunity_Stage_Header_ID__r = oppHeader;

        oppLine.ActualEndDate__c = Date.valueOf(System.now().addMonths(37));
        oppLine.ActualStartDate__c = Date.valueOf(System.now().addMonths(1));
        oppLine.Quantity__c = Integer.valueOf(generateRandomNumber(1));
        oppLine.UnitPrice__c = generateRandomNumber(3);
        oppLine.Base_Price__c = oppLine.Quantity__c * oppLine.UnitPrice__c;
        oppLine.Adjusted_Price__c = oppLine.Base_Price__c * 0.7;
        oppLine.Unit_of_Measure__c = 'EA';
        oppLine.Contract_Numbers__c = '123456790';
        oppLine.Entitle_To_Account_Number__c = '12345678901234567890';
        oppLine.Install_Base_Number__c = '1234567890';
        oppLine.Opportunity_ID__c = '0OpP0000001FaKe';
        oppLine.Opportunity_Number__c = '12345678901234567890';
        oppLine.Opportunity_Product_ID__c = 'SKU1230';
        oppLine.Product_Code__c = aProduct.Id;
        oppLine.Product_Code__r = aProduct;

        return oppLine;
    }

    public static Opportunity_Partner_Staging__c getSFOpportunityPartnerStaging(Opportunity_Header_Staging__c oppHeader, Contact partnerContact, Account partnerSalesAccount){
        Opportunity_Partner_Staging__c oppPartner = new Opportunity_Partner_Staging__c();

        oppPartner.Opportunity_Stage_Header_ID__c = oppHeader.Id;
        oppPartner.Opportunity_Stage_Header_ID__r = oppHeader;

        oppPartner.Partner_Contact__c = partnerContact.Id;
        oppPartner.Partner_Contact__r = partnerContact;

        oppPartner.Partner_Sales_Account__c = partnerSalesAccount.Id;
        oppPartner.Partner_Sales_Account__r = partnerSalesAccount;

        oppPartner.CDH_Party_Number__c = '12345678901234567890';
        oppPartner.EBS_Account_Number__c = '12345678901234567890';
        oppPartner.Oracle_Order_Header_Id__c = '123456';

        oppPartner.Partner_Contact_CDH_Party_Number__c = '12345678901234567890';
        oppPartner.Partner_Contact_Email__c = partnerContact.email;
        oppPartner.Partner_Contact_First_Name__c = partnerContact.FirstName;
        oppPartner.Partner_Contact_Last_Name__c = partnerContact.LastName;
        oppPartner.Partner_Contact_Phone__c = partnerContact.Phone;

        oppPartner.PartnerTier__c = 'Advanced';
        oppPartner.Partner_Type__c = 'Reseller';
        oppPartner.RelationshipType__c = 'Reseller1';

        return oppPartner;
    }

    public static Product2 getSFProduct(String name, String sku){
        Product2 product = new Product2(name = name, ProductCode = sku);
        return product;
    }

    public static IntegrationObjects.Order getOrder(){
        IntegrationObjects.Order o = new IntegrationObjects.Order();

        o.ID = '0Ord00' + generateRandomSeed(5) + 'FaKe';
        o.orderID = '12345678901234567890v';
        o.orderNumber = '12345678901234567890';
        o.employeeNumber = '12345678901234567890v';
        o.opportunityNumber = '12345678901234567890v';
        o.purchaseOrderNumber = '12345678901234567890';
        o.orderType = '????';
        o.operatingUnit = '????';
        o.paymentType = '????';
        o.creditCardNumber = '4111111111111111';
        o.expirationDate = Date.valueOf(System.now().addMonths(3));
        o.creditCardType = 'VISA';
        o.nameOnCard = 'Bob. E. Amazing';
        o.fulfillmentChannel = '???';
        o.paymentTerms = '???';
        o.currencyIsoCode = '???';
        o.orderSource = '???';
        o.opportunityID = '0OpP00' + generateRandomSeed(5) + 'FaKe';
        o.amount = Math.random() * 1000;
        o.shippingInstructions = 'Please pack it in the smallest packing peanuts possible!';
        o.vatCode = '???';
        o.rushOrder = False;

        List<IntegrationObjects.TransactionalAccount> accounts = getTransactionalAccountList('Order Customer');
        o.billToAccount = accounts[0];
        o.shipToAccount = accounts[1];
        o.soldToAccount = accounts[2];
        o.entitleToAccount = accounts[3];


        List<IntegrationObjects.Address> addresses = getAddressList();
        o.billToAddress = addresses[0];
        o.shipToAddress = addresses[1];
        o.soldToAddress = addresses[2];
        o.entitleToAddress = addresses[3];

        List<IntegrationObjects.Contact> contacts = getContactList(getSalesAccount());
        o.billToContact = contacts[0];
        o.shipToContact = contacts[1];
        o.soldToContact = contacts[2];
        o.entitleToContact = contacts[3];

        o.orderLines = new List<IntegrationObjects.OrderLine>();
        o.orderLines.add(getOrderLine('SKU0001'));
        o.orderLines.add(getOrderLine('SKU0012'));
        o.orderLines.add(getOrderLine('SKU0099'));
        o.orderLines.add(getOrderLine('SKU1233'));

        o.orderPartners = new List<IntegrationObjects.OrderPartner>();
        o.orderPartners.add(getOrderPartner('Reseller1???', 'An Amazing Reseller Partner'));
        o.orderPartners.add(getOrderPartner('Reseller2???', 'A Second Reseller Partner'));
        o.orderPartners.add(getOrderPartner('OEM???', 'An OEM Partner'));
        o.orderPartners.add(getOrderPartner('Distributor???', 'An Disty Partner'));

        return o;
    }

    public static IntegrationObjects.OrderLine getOrderLine(String productCode){
        IntegrationObjects.OrderLine ol = new IntegrationObjects.OrderLine();

        ol.ID = '0OlN00' + generateRandomSeed(5) + 'FaKe';
        ol.productCode = productCode;
        ol.actualStartDate = Date.valueOf(system.now().addMonths(1));
        ol.actualEndDate = ol.actualStartDate.addYears(3);
        ol.quantity = Integer.valueOf(generateRandomNumber(1));
        ol.unitOfMeasure = 'EA';
        ol.salesPrice = generateRandomNumber(4);
        ol.contractNumbers = generateRandomSeed(8);
        ol.opportunityID = '0OpP00' + generateRandomSeed(5) + 'FaKe';

        ol.entitleToAccount = getTransactionalAccount('Transactional Account');
        ol.entitleToAddress = getAddress();
        ol.entitleToContact = getContact(getSalesAccount());

        ol.discretionaryDiscountedPrice = ol.salesPrice * 0.75;
        ol.oneTimeDiscountedPrice = ol.discretionaryDiscountedPrice * 0.90;
        ol.priceOverrideReason = 'Because they are awesome.';
        ol.installBaseNumber = '12345';

        return ol;
    }

    public static IntegrationObjects.OrderPartner getOrderPartner(String transactionRole, String partnerName){
        IntegrationObjects.OrderPartner partner = new IntegrationObjects.OrderPartner();

        partner.ID = '0OpA00' + generateRandomSeed(5) + 'FaKe';
        partner.partnerType = 'Reseller';
        partner.partnerTier = 'Premier';
        partner.transactionRole = transactionRole;
        partner.account = getSalesAccount(partnerName);
        partner.contact = getContact(partner.account);

        return partner;

    }

    /**
     * Generates a numeric string with a guarenteed length
    **/
    public static String generateRandomSeed(Integer length){
        String seed = '';
        // Sometimes random numbers start with 0, this catches that and generates another one.
        while (seed.length() != length) {
            seed = String.valueOf(Integer.valueOf(generateRandomNumber(length)));
            System.debug('Seed = ' + seed);
            System.debug('SeedLength = ' + seed.length() + ' has to be ' + length);
        }
        return seed;
    }

    /**
     * Generates a random number multipled by 10 to the power passed in,
     * It does NOT guarentee that it will have a specific magnitude, as sometimes
     * random numbers start with 0s
    **/
    public static Double generateRandomNumber(Integer power){
        return Math.floor(Math.random() * (Math.pow(10,power)));
    }
    
    /**
     * Method name  : loadRecordTypeMap
     * Description  : This method returns the record type of the SObject passed in the argument.
     * Return Type  : Map<String, Id>
     * Parameter    : Schema.SObjectType
     **/
    public static Map<String, Id> loadRecordTypeMap(Schema.SObjectType token){
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        // Get the Describe Result
        Schema.DescribeSObjectResult obj = token.getDescribe();
    
        // Obtain ALL Active Record Types for the given SObjectType token
        String soql = 
            'SELECT Id, DeveloperName '
            + 'FROM RecordType '
            + 'WHERE SObjectType = \'' + String.escapeSingleQuotes(obj.getName()) + '\' '
            + 'AND IsActive = TRUE';
        List<RecordType> results;
        try {
            results = Database.query(soql);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            results = new List<SObject>();
        } 
        for (RecordType recordType : results) {
            recordTypeMap.put(recordType.DeveloperName, recordType.Id);
        }
        return recordTypeMap;  
    }

}