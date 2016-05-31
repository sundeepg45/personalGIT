/**
* Test class for IntegrationObjectsDeserializer
* 
* @version 2015-05-06
* @author John Herson <jherson@redhat.com>
* 2014-07-01 - Created
* Bill C Riemers <briemers@redhat.com>
* 2015-05-06 - Added parseDate tests.
* 2015-05-04 - Added tests for program names
*/
@isTest
public class IntegrationObjectsDeserializerTest {

    @isTest
    static void testTransactionalAccount() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONTransactionalAccount1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testTransactionalAccount()');
        
        Test.startTest();
        IntegrationObjects.TransactionalAccount account = IntegrationObjectsDeserializer.parseTransactionalAccount(json);
        Test.stopTest();

        System.assert(account != null);
        System.assert(account.Account_Number == '12345');
        System.assert(account.Status == 'Active');
        
        System.debug('Account_Number: ' + account.Account_Number);
    }

    @isTest
    static void testSalesAccount() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testSalesAccount()');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();

        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);
        
        List<IntegrationObjects.Address> addresses = account.Addresses;
        System.assertEquals(null, addresses);
        System.debug('Address Size: null');
    }
    
    @isTest
    static void testSalesAccountWithSingleAddress() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccountSingleAddr1A' LIMIT 1];
        String json = jsonMessage.Body.toString();

        System.debug('testSalesAccountWithSingleAddress()');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();
        
        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);
        
        List<IntegrationObjects.Address> addresses = account.Addresses;
        System.assert(addresses.size() == 1);
        System.debug('Address Size: ' + addresses.size());
        System.debug('Address Line1: ' + addresses.get(0).Address_Line1);
    }
    
    @isTest
    static void testSalesAccountWithSingleContact() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccountSingleCont1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testSalesAccountWithSingleContact()');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();
        
        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);

        List<IntegrationObjects.Contact> contacts = account.Contacts;
        System.assert(contacts.size() == 1);
        System.debug('Contacts Size: ' + contacts.size());
        System.debug('Contact First Name: ' + contacts.get(0).FirstName);
    }
    
    @isTest
    static void testSalesAccountWithMultipleContacts() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccountMultiCont1A' LIMIT 1];
        String json = jsonMessage.Body.toString();        

        System.debug('testSalesAccountWithMultipleContacts');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();
        
        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);

        List<IntegrationObjects.Contact> contacts = account.Contacts;
        System.assert(contacts.size() == 2);
        System.debug('Contacts Size: ' + contacts.size());
        System.debug('Contact First Name: ' + contacts.get(0).FirstName);
    }
    
    @isTest
    static void testSalesAccountWithMultipleAddresses() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccountMultiAddr1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testSalesAccountWithMultipleAddresses()');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();
        
        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);

        List<IntegrationObjects.Address> addresses = account.Addresses;
        System.debug('Address Size: ' + addresses.size());
        System.debug('Address Line1: ' + addresses.get(0).Address_Line1);
    }
    
    @isTest
    static void testSalesAccountWithMultipleAddressesAndContacts() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccountMultiAddrCont1A' LIMIT 1];
        String json = jsonMessage.Body.toString();  
        
        System.debug('testSalesAccountWithMultipleAddressesAndContacts()');
        
        Test.startTest();
        IntegrationObjects.SalesAccount account = IntegrationObjectsDeserializer.parseSalesAccount(json);
        Test.stopTest();
        
        System.assert(account != null);
        System.assertEquals('0016000000GZCnj', account.IDs);
        
        System.debug('ID: ' + account.IDs);

        List<IntegrationObjects.Address> addresses = account.Addresses;
        System.debug('Address Size: ' + addresses.size());
        System.debug('Address Line1: ' + addresses.get(0).Address_Line1);
        
        List<IntegrationObjects.Contact> contacts = account.Contacts;
        System.assert(contacts.size() == 2);
        System.debug('Contacts Size: ' + contacts.size());
        System.debug('Contact First Name: ' + contacts.get(0).FirstName);
    }

    @isTest
    static void testContact() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONContact1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testContact()');
        
        Test.startTest();
        IntegrationObjects.Contact contact = IntegrationObjectsDeserializer.parseContact(json);
        Test.stopTest();
        
        System.assert(contact != null);
        System.assertEquals('003m0000004Fp6LAAS', contact.IDs);
        
        System.debug('Id: ' + contact.IDs);
        System.debug('Contact First Name: ' + contact.FirstName);
    }

    @isTest
    static void testProduct() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONProduct1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testProduct()');
        
        Test.startTest();
        IntegrationObjects.Product product = IntegrationObjectsDeserializer.parseProduct(json);
        Test.stopTest();
        
        System.assert(product != null);
        System.assertEquals('Advanced Mission Critical', product.Name);
        
        System.debug('Product Code:' + product.ProductCode);
        System.debug('Product Name: ' + product.Name);
    }

    @isTest
    static void testAddress() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONAddress1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testAddress()');
        
        Test.startTest();
        IntegrationObjects.Address address = IntegrationObjectsDeserializer.parseAddress(json);
        Test.stopTest();
        
        System.assert(address != null);
        System.assertEquals('a2Nm00000000FLnEAM', address.IDs);
        
        System.debug('Id: ' + address.IDs);
        System.debug('Address Line1: ' + address.Address_Line1);
    }

    @isTest
    static void testHeader() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONTransactionalAccount1A' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testHeader()');
        
        Test.startTest();
        IntegrationObjects.Header header = IntegrationObjectsDeserializer.parseHeader(json);
        Test.stopTest();
        
        System.assert(header != null);
        System.assertEquals('Sync', header.Operation);
        System.assertEquals('TransactionalAccount', header.Type);
        System.assertEquals('12345', header.EventKey);
    }

    //@isTest
    //static void replaceIdArrayTest() {
    //    String json = '{"Payload":{"Contacts":{"Status":"Active","Phone":null,"Email":"pban@infy.com","LoginName":null,"IDs":["003K000000psV8PIAU","003K000000psV6xIAE"],"SalesAccountId":"001K00000102P3eIAE","Fax":null,"Salutation":"Mr.","FirstName":"PankajV1","MobilePhone":"(989) 107-8888","LastName":"Bainik","CDHPartyNumber":7103518,"SalesAccountCDHPartyNumber":7103504}},"Header":{"Operation":"oracle.apps.ar.hz.ContactPoint.create","Type":"Contact","InstanceId":8827185,"EsbMessageGuid":"6w6-765r54yh-1-9acge3yh-z2ml5f-w6p7a","Timestamp":"2014-07-27T05:21:55"},"xmlns":"http://esb.redhat.com/Salesforce/1"}';
    //    String newJson = IntegrationObjectsDeserializer.replaceIdArray(json);
    //    system.debug('****** ' + newJson);
    //}

    @isTest
    static void testOrder() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrder1' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testOrder()');
        
        Test.startTest();
        IntegrationObjects.Order order = IntegrationObjectsDeserializer.parseOrder(json);
        Test.stopTest();
        
        System.assert(order != null);
        
        System.assert(order.billToAccount != null);
        System.assert(order.soldToAccount != null);
        System.assert(order.shipToAccount != null);
        System.assert(order.entitleToAccount != null);
        
        System.assert(order.billToAddress.Address_Line1 != null);
        
        System.debug('Bill To: ' + order.billToAccount.Name);
        System.debug('Ship To: ' + order.shipToAccount.Name);
        System.debug('Sold To: ' + order.soldToAccount.Name);
        System.debug('Entitle To: ' + order.entitleToAccount.Name);
        
        System.debug('Bill To Address: ' + order.billToAddress.Address_Line1);
        System.debug(System.JSON.serialize(order));
    }

    @isTest
    static void testLargeOrder() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrderLarge1' LIMIT 1];
        String json = jsonMessage.Body.toString();
        
        System.debug('testLargeOrder()');
        
        Test.startTest();
        IntegrationObjects.Order order = IntegrationObjectsDeserializer.parseOrder(json);
        Test.stopTest();
        
        System.assert(order != null);
    }
    
    @isTest
    static void testCompareTransactionAccount() {
        IntegrationObjects.TransactionalAccount account1 = new IntegrationObjects.TransactionalAccount();
        account1.Name = 'A';
        account1.Account_Number = '0';
        account1.EBS_Party_Number = '1';
        account1.PartyType = '2';
        account1.CDH_Party_Number = '3';
        IntegrationObjects.TransactionalAccount account2 = new IntegrationObjects.TransactionalAccount();
        account2.Name = account1.Name;
        account2.Account_Number = account1.Account_Number;
        account2.EBS_Party_Number = account1.EBS_Party_Number;
        account2.PartyType = account1.PartyType;
        account2.CDH_Party_Number = account1.CDH_Party_Number;
        IntegrationObjectsDeserializer.compareTransactionalAccount(account1,null);
        IntegrationObjectsDeserializer.compareTransactionalAccount(null,account2);
        IntegrationObjectsDeserializer.compareTransactionalAccount(account1,account2);
        Exception ex1 = null;
        try {
            account2.Name=account1.Name+'0';
            IntegrationObjectsDeserializer.compareTransactionalAccount(account1,account2);
        }
        catch(IntegrationObjectsDeserializer.PartnerParseException ex) {
            ex1=ex;
        }
        System.assertNotEquals(null,ex1);
    }

    @isTest
    static void testCompareAddress() {
        IntegrationObjects.Address address1 = new IntegrationObjects.Address();
        address1.CDH_Party_Site_Number = '1';
        address1.Zip_Postal_Code = 'A';
        address1.Country = 'B';
        address1.County = 'C';
        address1.State = 'D';
        address1.City = 'E';
        address1.Address_Line1 = 'F';
        address1.Address_Line2 = 'G'; 
        address1.Address_Line3 = 'H'; 
        address1.Address_Line4 = 'I'; 
        IntegrationObjects.Address address2 = new IntegrationObjects.Address();
        address2.CDH_Party_Site_Number = '2';
        address2.Zip_Postal_Code = address1.Zip_Postal_Code;
        address2.Country = address1.Country;
        address2.County = address1.County;
        address2.State = address1.State;
        address2.City = address1.City;
        address2.Address_Line1 = address1.Address_Line1;
        address2.Address_Line2 = address1.Address_Line2; 
        address2.Address_Line3 = address1.Address_Line3; 
        address2.Address_Line4 = address1.Address_Line4; 
        IntegrationObjectsDeserializer.compareAddress(address1,null);
        IntegrationObjectsDeserializer.compareAddress(null,address2);
        IntegrationObjectsDeserializer.compareAddress(address1,address2);
        Exception ex1 = null;
        try {
            address2.City=address1.City+'0';
            IntegrationObjectsDeserializer.compareAddress(address1,address2);
        }
        catch(IntegrationObjectsDeserializer.PartnerParseException ex) {
            ex1=ex;
        }
        System.assertNotEquals(null,ex1);
    }

    @isTest
    static void testCompareContact() {
        IntegrationObjects.Contact contact1 = new IntegrationObjects.Contact();
        contact1.CDH_Party_Number = '1';
        contact1.FirstName = 'A';
        contact1.LastName = 'B';
        contact1.Email = 'C';
        contact1.Phone = 'D';
        IntegrationObjects.Contact contact2 = new IntegrationObjects.Contact();
        contact2.CDH_Party_Number = contact1.CDH_Party_Number;
        contact2.FirstName = contact1.FirstName;
        contact2.LastName = contact1.LastName;
        contact2.Email = contact1.Email;
        contact2.Phone = contact1.Phone;
        IntegrationObjectsDeserializer.compareContact(contact1,null);
        IntegrationObjectsDeserializer.compareContact(null,contact2);
        IntegrationObjectsDeserializer.compareContact(contact1,contact2);
        Exception ex1 = null;
        try {
            contact2.FirstName=contact1.FirstName+'0';
            IntegrationObjectsDeserializer.compareContact(contact1,contact2);
        }
        catch(IntegrationObjectsDeserializer.PartnerParseException ex) {
            ex1=ex;
        }
        System.assertNotEquals(null,ex1);
    }

    @isTest
    static void testParseDate() {
        Date d1 = Date.newInstance(2015,6,1);
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('01-Jun-2015'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('01-JUN-2015'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('01-jun-15'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('01-JUN-15'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('1-Jun-2015'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('1-JUN-2015'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('1-jun-15'));
        System.assertEquals(d1,IntegrationObjectsDeserializer.parseDate('1-JUN-15'));
        System.assertEquals(null,IntegrationObjectsDeserializer.parseDate('01-TOM-15'));
    }
}