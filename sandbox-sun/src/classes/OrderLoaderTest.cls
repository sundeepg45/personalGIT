/**
 * This test class covers OrderLoaderTrigger.trigger and OrderLoaderBatchable.cls
 *
 * @version 2015-07-10
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-07-10 - Added test for new contructor that supports querying staging records by a unique batch id
 * 2015-02-25 - Created
 */
@isTest
private class OrderLoaderTest {

    public static CDH_Party__c testAccountCDHParty1 {
         get {
            if(testAccountCDHParty1 == null) {
                testAccountCDHParty1 = new CDH_Party__c(
                    Name = '123456'
                );
                insert testAccountCDHParty1;
            }
            return testAccountCDHParty1;
        }
    }

    public static Account testAccount1 {
        get {
            if(testAccount1 == null) {
                testAccount1 = new Account(
                    CDH_Party_Name__c = testAccountCDHParty1.Id,
                    CDH_Party_Name__r = testAccountCDHParty1,
                    Name = 'Test Account 1'
                );
                insert testAccount1;
            }
            return testAccount1;
        }
    }

    public static Account testPartnerAccount1 {
        get {
            if(testPartnerAccount1 == null) {
                RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' and Name LIKE '%Partner%' LIMIT 1];

                testPartnerAccount1 = new Account(
                    CDH_Party_Name__c = testAccountCDHParty1.Id,
                    CDH_Party_Name__r = testAccountCDHParty1,
                    Name = 'Test Partner Account 1',
                    RecordTypeId = partnerRecordType.Id
                );
                insert testPartnerAccount1;
            }
            return testPartnerAccount1;
        }
    }

    public static Account testAccount2 {
        get {
            if(testAccount2 == null) {
                testAccount2 = new Account(
                    CDH_Party_Name__c = testAccountCDHParty1.Id,
                    CDH_Party_Name__r = testAccountCDHParty1,
                    Name = 'Test Account 2'
                );
                insert testAccount2;
            }
            return testAccount2;
        }
    }

    public static Address__c testAddress1 {
        get {
            if(testAddress1 == null) {
                testAddress1 = new Address__c(
                    CDH_Party_Site_Number__c = '234567',
                    Sales_Account__c = testAccount1.Id,
                    Sales_Account__r = testAccount1
                );
                insert testAddress1;
            }
            return testAddress1;
        }
    }

    public static CDH_Party__c testContactCDHParty1 {
         get {
            if(testContactCDHParty1 == null) {
                testContactCDHParty1 = new CDH_Party__c(
                    Name = '345678'
                );
                insert testContactCDHParty1;
            }
            return testContactCDHParty1;
        }       
    }

    public static Contact testContact1 {
        get {
            if(testContact1 == null) {
                testContact1 = new Contact(
                    AccountId = testAccount1.Id,
                    CDH_Party__c = testContactCDHParty1.Id,
                    CDH_Party__r = testContactCDHParty1,         
                    LastName = 'Test 1'
                );
                insert testContact1;
            }
            return testContact1;
        }
    }

    public static Contact testPartnerContact1 {
        get {
            if(testPartnerContact1 == null) {
                testPartnerContact1 = new Contact(
                    AccountId = testPartnerAccount1.Id,
                    CDH_Party__c = testContactCDHParty1.Id,
                    CDH_Party__r = testContactCDHParty1,         
                    LastName = 'Test 1'
                );
                insert testPartnerContact1;
            }
            return testPartnerContact1;
        }
    }

    public static EBS_Account__c testEBSAccount1 {
        get {
            if(testEBSAccount1 == null) {
                testEBSAccount1 = new EBS_Account__c(
                    EBS_Party_Number__c = '98765',
                    Name = '98765',
                    Sales_Account__c = testAccount1.Id,
                    Sales_Account__r = testAccount1
                );
                insert testEBSAccount1;
            }
            return testEBSAccount1;
        }
    }

    public static Opportunity_Header_Staging__c oppHeaderStaging {
        get {
            if(oppHeaderStaging == null) {
                oppHeaderStaging = new Opportunity_Header_Staging__c(
                    Bill_To_Account_Number__c = testEBSAccount1.EBS_Party_Number__c,
                    Bill_To_Address_CDH_Party_Site_Number__c = testAddress1.CDH_Party_Site_Number__c,
                    Bill_To_CDH_Party_Number_Account__c = testAccount1.CDH_Party_Name__r.Name,
                    Bill_To_CDH_Party_Number__c = testContact1.CDH_Party__r.Name,
                    Entitle_To_Account_Number__c = testEBSAccount1.EBS_Party_Number__c,
                    Entitle_To_Address_CDH_Party_Site_Number__c = testAddress1.CDH_Party_Site_Number__c,
                    Entitle_To_CDH_Party_Number_Account__c = testAccount1.CDH_Party_Name__r.Name,
                    Entitle_To_CDH_Party_Number__c = testContact1.CDH_Party__r.Name,
                    Ship_To_Account_Number__c = testEBSAccount1.EBS_Party_Number__c,
                    Ship_To_Address_CDH_Party_Site_Number__c = testAddress1.CDH_Party_Site_Number__c,
                    Ship_To_CDH_Party_Number_Account__c = testAccount1.CDH_Party_Name__r.Name,
                    Ship_To_CDH_Party_Number__c = testContact1.CDH_Party__r.Name,
                    Sold_To_Account_Number__c = testEBSAccount1.EBS_Party_Number__c,
                    Sold_To_Address_CDH_Party_Site_Number__c = testAddress1.CDH_Party_Site_Number__c,
                    Sold_To_CDH_Party_Number_Account__c = testAccount1.CDH_Party_Name__r.Name,
                    Sold_To_CDH_Party_Number__c = testContact1.CDH_Party__r.Name,
                    Order_Source__c = 'Saba',
                    Status__c = null,
                    Origin__c = 'Order Loader',
                    Batch_ID__c = '12345abcde'
                );
            }
            return oppHeaderStaging;
        }
    }

    public static Id getOppHeaderStagingId() {
        if(oppHeaderStaging.Id == null) {
            insert oppHeaderStaging;
        }
        return oppHeaderStaging.Id;
    }

    public static Opportunity_Line_Staging__c oppLineStaging {
        get {
            if(oppLineStaging == null) {
                oppLineStaging = new Opportunity_Line_Staging__c(
                    Entitle_To_CDH_Party_Number_Account__c = testAccount1.CDH_Party_Name__r.Name,
                    Entitle_To_CDH_Party_Number__c = testContact1.CDH_Party__r.Name,
                    Entitle_To_CDH_Party_Site_Number__c = testAddress1.CDH_Party_Site_Number__c,
                    Entitle_To_Account_Number__c = testEBSAccount1.EBS_Party_Number__c,
                    Opportunity_Stage_Header_ID__c = getOppHeaderStagingId()
                );
                insert oppLineStaging;
            }
            return oppLineStaging;
        }
    }

    public static Opportunity_Partner_Staging__c oppPartnerStaging {
        get {
            if(oppPartnerStaging == null) {
                oppPartnerStaging = new Opportunity_Partner_Staging__c(
                    CDH_Party_Number__c = testPartnerAccount1.CDH_Party_Name__r.Name,
                    Partner_Contact_CDH_Party_Number__c = testPartnerContact1.CDH_Party__r.Name,
                    Opportunity_Stage_Header_ID__c = getOppHeaderStagingId()
                );
                insert oppPartnerStaging;
            }
            return oppPartnerStaging;
        }
    }

    public static Opportunity_Header_Staging__c oppHeaderStagingNoKeys {
        get {
            if(oppHeaderStagingNoKeys == null) {
                oppHeaderStagingNoKeys = new Opportunity_Header_Staging__c(
                    Bill_To_Account_Number__c = null,
                    Bill_To_Address_CDH_Party_Site_Number__c = null,
                    Bill_To_CDH_Party_Number_Account__c = null,
                    Bill_To_CDH_Party_Number__c = null,
                    Entitle_To_Account_Number__c = null,
                    Entitle_To_Address_CDH_Party_Site_Number__c = null,
                    Entitle_To_CDH_Party_Number_Account__c = null,
                    Entitle_To_CDH_Party_Number__c = null,
                    Ship_To_Account_Number__c = null,
                    Ship_To_Address_CDH_Party_Site_Number__c = null,
                    Ship_To_CDH_Party_Number_Account__c = null,
                    Ship_To_CDH_Party_Number__c = null,
                    Sold_To_Account_Number__c = null,
                    Sold_To_Address_CDH_Party_Site_Number__c = null,
                    Sold_To_CDH_Party_Number_Account__c = null,
                    Sold_To_CDH_Party_Number__c = null,
                    Order_Source__c = 'Saba',
                    Status__c = null
                );
                insert oppHeaderStagingNoKeys;
            }
            return oppHeaderStagingNoKeys;
        }
    }

    public static Opportunity_Line_Staging__c oppLineStagingNoKeys {
        get {
            if(oppLineStagingNoKeys == null) {
                oppLineStagingNoKeys = new Opportunity_Line_Staging__c(
                    Entitle_To_CDH_Party_Number_Account__c = null,
                    Entitle_To_CDH_Party_Number__c = null,
                    Entitle_To_CDH_Party_Site_Number__c = null,
                    Entitle_To_Account_Number__c = null,
                    Opportunity_Stage_Header_ID__c = oppHeaderStagingNoKeys.Id
                );
                insert oppLineStagingNoKeys;
            }
            return oppLineStagingNoKeys;
        }
    }

    public static Opportunity_Partner_Staging__c oppPartnerStagingNoKeys {
        get {
            if(oppPartnerStagingNoKeys == null) {
                oppPartnerStagingNoKeys = new Opportunity_Partner_Staging__c(
                    CDH_Party_Number__c = null,
                    Partner_Contact_CDH_Party_Number__c = null,
                    Opportunity_Stage_Header_ID__c = oppHeaderStagingNoKeys.Id
                );
                insert oppPartnerStagingNoKeys;
            }
            return oppPartnerStagingNoKeys;
        }
    }

    @isTest static void insertBatchTest() {
        Test.startTest();
        Order_Loader_Batch__c batch = new Order_Loader_Batch__c(Batch_Start_Date__c = DateTime.now().addDays(1), Batch_Id__c = '12345abcde');
        Database.insert(batch, false);
        List<Order_Loader_Batch__c> batches = new List<Order_Loader_Batch__c>{batch.clone(false), batch.clone(false)};
        Database.insert(batches, false);
        Test.stopTest();

        batches = [SELECT Id from Order_Loader_Batch__c];
        System.assertEquals(2, batches.size());
    }

    @isTest static void batchStartTest() {
        Id testOppStagingId = getOppHeaderStagingId();
        OrderLoaderBatchable batchable = new OrderLoaderBatchable(UserInfo.getUserId(), DateTime.now().addDays(-1));
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
        ssc.setPageSize(100);

        Test.startTest();
        List<Opportunity_Header_Staging__c> orders = ssc.getRecords();
        batchable.execute(null,orders);
        Test.stopTest();

        System.assertEquals(1,orders.size());
        System.assertEquals(testOppStagingId,orders[0].Id);        
    }

     @isTest static void batchStartBatchIdTest() {
        Id testOppStagingId = getOppHeaderStagingId();
        OrderLoaderBatchable batchable = new OrderLoaderBatchable('12345abcde');
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
        ssc.setPageSize(100);

        Test.startTest();
        List<Opportunity_Header_Staging__c> orders = ssc.getRecords();
        batchable.execute(null,orders);
        Test.stopTest();

        System.assertEquals(1,orders.size());
        System.assertEquals(testOppStagingId,orders[0].Id);        
    }   

    @isTest static void matchingTest() {
        Id testOppStagingId = getOppHeaderStagingId();
        Opportunity_Line_Staging__c testOppLineStaging = oppLineStaging;
        Opportunity_Partner_Staging__c testOppPartnerStaging = oppPartnerStaging;

        Test.startTest();
        OrderLoaderMatching.processOrders(new Set<Id>{testOppStagingId});
        Test.stopTest();

        Opportunity_Header_Staging__c testOppStaging = [
            SELECT
                Bill_To_Sales_Account__c,
                Bill_To_Address__c,
                Bill_To_Contact__c,
                Bill_To_Account__c,
                Entitle_To_Sales_Account__c,
                Entitle_To_Address__c,
                Entitle_To_Contact__c,
                Entitle_To_Account__c,
                Ship_To_Sales_Account__c,
                Ship_To_Address__c,
                Ship_To_Contact__c,
                Ship_To_Account__c,
                Sold_To_Sales_Account__c,
                Sold_To_Address__c,
                Sold_To_Contact__c,
                Sold_To_Account__c,
                (SELECT
                    Entitle_To_Sales_Account__c,
                    Entitle_To_Address__c,
                    Entitle_To_Contact__c,
                    Entitle_To_Account__c
                FROM Opportunities_Line_Staging__r),
                (SELECT
                    Partner_Sales_Account__c,
                    Partner_Contact__c
                FROM Opportunities_Partner_Staging__r)
            FROM Opportunity_Header_Staging__c
            WHERE Id = :testOppStagingId
        ];

        System.assertEquals(testAccount1.Id, testOppStaging.Bill_To_Sales_Account__c);
        System.assertEquals(testAddress1.Id, testOppStaging.Bill_To_Address__c);
        System.assertEquals(testContact1.Id, testOppStaging.Bill_To_Contact__c);
        System.assertEquals(testEBSAccount1.Id, testOppStaging.Bill_To_Account__c);
        System.assertEquals(testAccount1.Id, testOppStaging.Entitle_To_Sales_Account__c);
        System.assertEquals(testAddress1.Id, testOppStaging.Entitle_To_Address__c);
        System.assertEquals(testContact1.Id, testOppStaging.Entitle_To_Contact__c);
        System.assertEquals(testEBSAccount1.Id, testOppStaging.Entitle_To_Account__c);
        System.assertEquals(testAccount1.Id, testOppStaging.Ship_To_Sales_Account__c);
        System.assertEquals(testAddress1.Id, testOppStaging.Ship_To_Address__c);
        System.assertEquals(testContact1.Id, testOppStaging.Ship_To_Contact__c);
        System.assertEquals(testEBSAccount1.Id, testOppStaging.Ship_To_Account__c);
        System.assertEquals(testAccount1.Id, testOppStaging.Sold_To_Sales_Account__c);
        System.assertEquals(testAddress1.Id, testOppStaging.Sold_To_Address__c);
        System.assertEquals(testContact1.Id, testOppStaging.Sold_To_Contact__c);
        System.assertEquals(testEBSAccount1.Id, testOppStaging.Sold_To_Account__c);
        System.assertEquals(testAccount1.Id, testOppStaging.Opportunities_Line_Staging__r[0].Entitle_To_Sales_Account__c);
        System.assertEquals(testAddress1.Id, testOppStaging.Opportunities_Line_Staging__r[0].Entitle_To_Address__c);
        System.assertEquals(testContact1.Id, testOppStaging.Opportunities_Line_Staging__r[0].Entitle_To_Contact__c);
        System.assertEquals(testEBSAccount1.Id, testOppStaging.Opportunities_Line_Staging__r[0].Entitle_To_Account__c);
        System.assertEquals(testPartnerAccount1.Id, testOppStaging.Opportunities_Partner_Staging__r[0].Partner_Sales_Account__c);
        System.assertEquals(testPartnerContact1.Id, testOppStaging.Opportunities_Partner_Staging__r[0].Partner_Contact__c);
    }

    @isTest static void multipleAccountMatchingTest() {
        Id testOppStagingId = getOppHeaderStagingId();
        Opportunity_Line_Staging__c testOppLineStaging = oppLineStaging;
        Opportunity_Partner_Staging__c testOppPartnerStaging = oppPartnerStaging;
        Account testAccount = testAccount2; // insert a second sales account for the same CDH party to prevent a single match

        Test.startTest();
        OrderLoaderMatching.processOrders(new Set<Id>{testOppStagingId});
        Test.stopTest();

        Opportunity_Header_Staging__c testOppStaging = [
            SELECT
                Bill_To_Sales_Account__c,
                Entitle_To_Sales_Account__c,
                Ship_To_Sales_Account__c,
                Sold_To_Sales_Account__c,
                (SELECT
                    Entitle_To_Sales_Account__c
                FROM Opportunities_Line_Staging__r),
                (SELECT
                    Partner_Sales_Account__c
                FROM Opportunities_Partner_Staging__r)
            FROM Opportunity_Header_Staging__c
            WHERE Id = :testOppStagingId
        ];

        System.assertEquals(null, testOppStaging.Bill_To_Sales_Account__c);
        System.assertEquals(null, testOppStaging.Entitle_To_Sales_Account__c);
        System.assertEquals(null, testOppStaging.Ship_To_Sales_Account__c);
        System.assertEquals(null, testOppStaging.Sold_To_Sales_Account__c);
        System.assertEquals(null, testOppStaging.Opportunities_Line_Staging__r[0].Entitle_To_Sales_Account__c);
        System.assertEquals(testPartnerAccount1.Id, testOppStaging.Opportunities_Partner_Staging__r[0].Partner_Sales_Account__c); // the partner account should still match
    }

    @isTest static void noKeysMatchingTest() {
        Account testAccount = testAccount1;
        Address__c testAddress = testAddress1;
        Contact testContact = testContact1;
        EBS_Account__c testEBSAcccount = testEBSAccount1;
        Opportunity_Header_Staging__c testOppHeaderStaging = oppHeaderStagingNoKeys;
        Opportunity_Line_Staging__c testOppLineStaging = oppLineStagingNoKeys;
        Opportunity_Partner_Staging__c testOppPartnerStaging = oppPartnerStagingNoKeys;

        Test.startTest();
        OrderLoaderMatching.processOrders(new Set<Id>{testOppHeaderStaging.Id});
        Test.stopTest();

        //no asserts, this is a check for unhandled exceptions when there are no keys on the staging records
    }
}