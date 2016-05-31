/**
 * Test class for InboundServiceBroker
 * 
 * @version 2014-10-18
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-07-12 - created
 * 2014-09-12 - added tests for sync messages
 * 2014-10-18 - added tests for product messages
 */
@isTest
private class InboundServiceBrokerTest {

    static void brokerTest(String messageType, String message) {
        Id eventId = '012000000000000AAA';

        Test.startTest();
        InboundServiceBroker.processMessage(eventId, messageType, message, 'Test', 0, 'New');
        Test.stopTest();

        // check that the log record was created
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Message__c 
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals(message.trim(), loggedEvents[0].Message__c.trim());        
    }

    static void brokerExceptionTest(String messageType) {
        Id eventId = '012000000000000AAA';

        Test.startTest();
        InboundServiceBroker.processMessage(eventId, messageType, '', 'Test', 0, 'New');
        Test.stopTest();

        // check that the log record was created
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Error_Message__c, Message__c 
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertNotEquals(null, loggedEvents[0].Error_Message__c);
        System.assert(loggedEvents[0].Error_Message__c.contains('Unable to deserialize'));
    }

    @isTest
    static void transactionalAccountTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONTransactionalAccount1A' LIMIT 1];
        String message = jsonMessage.Body.toString();
        brokerTest('TransactionalAccount', message);
    }

    @isTest
    static void transactionalAccountExceptionTest() {
        brokerExceptionTest('TransactionalAccount');
    }

    @isTest
    static void salesAccountTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String message = jsonMessage.Body.toString();
        brokerTest('SalesAccount', message);
    }

    @isTest
    static void salesAccountExceptionTest() {
        brokerExceptionTest('SalesAccount');
    }

    @isTest
    static void contactTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONContact1A' LIMIT 1];
        String message = jsonMessage.Body.toString();
        brokerTest('Contact', message);
    }

    @isTest
    static void contactExceptionTest() {
        brokerExceptionTest('Contact');
    }

    @isTest
    static void productTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONProduct1A' LIMIT 1];
        String message = jsonMessage.Body.toString();
        brokerTest('Product', message);
    }

    @isTest
    static void productExceptionTest() {
        brokerExceptionTest('Product');
    }

    //@isTest
    //static void addressTest() {
    //    StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONAddress1' LIMIT 1];
    //    String message = jsonMessage.Body.toString();
    //    brokerTest('Address', message);
    //}

    //@isTest
    //static void addressExceptionTest() {
    //    brokerExceptionTest('Address');
    //}

    @isTest
    static void orderTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrder1' LIMIT 1];
        String message = jsonMessage.Body.toString();
        brokerTest('Order', message);
    }

    //Order deserialization does not fail in the same way the other message types do - commented out for now
    //@isTest
    //static void orderExceptionTest() {
    //    brokerExceptionTest('Order');
    //}

    @isTest
    static void unknownMessageTypeTest() {
        Id eventId = '012000000000000AAA';

        Test.startTest();
        InboundServiceBroker.processMessage('012000000000000AAA', 'UnknownType', 'Test Message', 'Test', 0, 'New');
        Test.stopTest();

        // check the error
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Error_Message__c, Message__c, Status__c
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals('Test Message', loggedEvents[0].Message__c);
        System.assertEquals('Error', loggedEvents[0].Status__c);
        System.assertNotEquals(null, loggedEvents[0].Error_Message__c);
        System.assert(loggedEvents[0].Error_Message__c.contains('Unknown message type'));
    }

    @isTest
    static void retryTest() {
        Id eventId = '012000000000000AAA';
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String message = jsonMessage.Body.toString();        

        Test.startTest();
        InboundServiceBroker.processMessage('012000000000000AAA', 'ForceRetry', message, 'Test', 0, 'New');
        Test.stopTest();

        // check the event
        List<Inbound_Event__c> retriedEvents = [SELECT Id, Message__c, Status__c, Retries__c
                                                FROM Inbound_Event__c
                                                WHERE Status__c = 'Retried'];
        System.assertEquals(1, retriedEvents.size());
        System.assertEquals(message.trim(), retriedEvents[0].Message__c.trim());
        System.assertEquals('Retried', retriedEvents[0].Status__c);
        System.assertEquals(1, retriedEvents[0].Retries__c);
    }
    @isTest
    static void retryLimitTest() {
        Id eventId = '012000000000000AAA';
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String message = jsonMessage.Body.toString();        

        Test.startTest();
        InboundServiceBroker.processMessage('012000000000000AAA', 'ForceRetry', message, 'Test', 5, 'New');
        Test.stopTest();

        // check the error
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Error_Message__c, Message__c, Status__c, Retries__c
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals(message.trim(), loggedEvents[0].Message__c.trim());
        System.assertEquals('Error', loggedEvents[0].Status__c);
        System.assertEquals(5, loggedEvents[0].Retries__c);
    }

    @isTest
    static void syncSalesAccountTest() {
        Id eventId = '012000000000000AAA';

        Account account = new Account(Name = 'Test Account');
        insert account;
        
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONAccountSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_ID',account.Id);
        
        Test.startTest();
        InboundServiceBroker.processMessage(eventId, 'SalesAccount', message, 'SYNC', 0, 'New');
        Test.stopTest();

        // check that the log record was created for the inbound message
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Message__c 
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals(message.trim(), loggedEvents[0].Message__c.trim());

        // check that the outbound message was generated
        List<Outbound_Event__c> outboundEvents = [SELECT Id, Message__c, Event_Type__c, Operation__c
                                                    FROM Outbound_Event__c
                                                    WHERE Event_Type__c = 'SalesAccount'
                                                    AND Operation__c = 'SYNC'];
        System.assertEquals(1, outboundEvents.size());
    }

    @isTest
    static void syncSalesAccountFailureTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONAccountSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_ID','001000000000000AAA');

        Test.startTest();
        InboundServiceBroker.processMessage(null, 'SalesAccount', message, 'SYNC', 0, 'New');
        Test.stopTest();      
    }

    @isTest
    static void syncContactTest() {
        Id eventId = '012000000000000AAA';

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(
                                AccountId = account.Id,
                                Email='test@example.com',
                                FirstName='John',
                                LastName='Smith');       
        insert contact;
        
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONContactSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_ID',contact.Id);
        
        Test.startTest();
        InboundServiceBroker.processMessage(eventId, 'Contact', message, 'SYNC', 0, 'New');
        Test.stopTest();

        // check that the log record was created for the inbound message
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Message__c 
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals(message.trim(), loggedEvents[0].Message__c.trim());

        // check that the outbound message was generated
        List<Outbound_Event__c> outboundEvents = [SELECT Id, Message__c, Event_Type__c, Operation__c
                                                    FROM Outbound_Event__c
                                                    WHERE Event_Type__c = 'Contact'
                                                    AND Operation__c = 'SYNC'];
        System.assertEquals(1, outboundEvents.size());
    }

    @isTest
    static void syncContactFailureTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONContactSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_ID','001000000000000AAA');

        Test.startTest();
        InboundServiceBroker.processMessage(null, 'Contact', message, 'SYNC', 0, 'New');
        Test.stopTest();      
    }

    @isTest
    static void syncOrderTest() {
        Id eventId = '012000000000000AAA';

        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(
                                        AccountId = account.Id,
                                        Name = 'Test Opportunity',
                                        CloseDate=System.today(),
                                        StageName='Closed Booked',
                                        OwnerId=UserInfo.getUserId(),
                                        DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
                                        Country_of_Order__c='India');   
        insert opportunity;

        opportunity = [SELECT AccountId, Name, CloseDate, StageName, OwnerId, DateOrderSubmitted__c, Country_of_Order__c, OpportunityNumber__c
                        FROM Opportunity WHERE Id = :opportunity.Id LIMIT 1];
        
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrderSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_OPP_NUM',opportunity.OpportunityNumber__c);
        
        Test.startTest();
        InboundServiceBroker.processMessage(eventId, 'OAGI', message, 'SYNC', 0, 'New');
        Test.stopTest();

        // check that the log record was created for the inbound message
        List<Event_Log__c> loggedEvents = [SELECT Original_Event_Id__c, Message__c 
                                                FROM Event_Log__c
                                                WHERE Original_Event_Id__c = :eventId];
        System.assertEquals(1, loggedEvents.size());
        System.assertEquals(message.trim(), loggedEvents[0].Message__c.trim());

        // check that the outbound message was generated
        List<Outbound_Event__c> outboundEvents = [SELECT Id, Message__c, Event_Type__c, Operation__c
                                                    FROM Outbound_Event__c
                                                    WHERE Event_Type__c = 'OAGI'
                                                    AND Operation__c = 'SYNC'];
        System.assertEquals(1, outboundEvents.size());
    }

    @isTest
    static void syncOrderFailureTest() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrderSync1' LIMIT 1];
        String message = jsonMessage.Body.toString().replace('REPLACE_WITH_ID','006000000000000AAA');

        Test.startTest();
        InboundServiceBroker.processMessage(null, 'Order', message, 'SYNC', 0, 'New');
        Test.stopTest();      
    }
}