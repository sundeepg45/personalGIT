/*****************************************************************************************
    Name    : OutboundServiceTest
    Desc    : Unit testing that covers:
                - OutboundService
                - IntegrationObjectsTestUtil
                - IntegrationObjects
                - IntegrationObjectConverter
                - OutboundEventPullService
                - OutboundEventAcknowledgeService

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Tiaan Kruger           7/11/2014       Created
    Scott Coleman          7/14/2014       Added testErrorPullService()
    Scott Coleman          7/18/2014       Updated native tests due to test util updates
    Scott Coleman          9/22/2014       Added prioritization test
******************************************************************************************/
@isTest
private class OutboundServiceTest {
    @isTest static void testOutboundTestController(){
        TestOutboundServiceController ostc = new TestOutboundServiceController();
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('Party like it\'s 1999');
        insert cdhParty;
        Account acct = IntegrationObjectsTestUtil.getSFAccount(cdhParty, cdhParty.CDH_Party_Name__c);
        insert acct;
        Address__c addr = IntegrationObjectsTestUtil.getSFAddress(acct, 'East Davie Street', 'Raleigh', 'NC');
        insert addr;
        Contact cont = IntegrationObjectsTestUtil.getSFContact(cdhParty, 'Nicolas', 'Tesla');
        insert cont;

        Opportunity oppt = IntegrationObjectsTestUtil.getSFOpportunity();
        insert oppt;

        OutboundService.queueContactMessage(IntegrationObjectsTestUtil.getContact(IntegrationObjectsTestUtil.getSalesAccount()), 'INSERT');
        List<Outbound_Event__c> events = [select Id, Message__c from Outbound_Event__c];

        ostc.accountId = acct.Id;
        ostc.queueAccountMessage();

        ostc.contactId = cont.Id;
        ostc.queueContactMessage();

        ostc.addressId = addr.Id;
        ostc.queueAddressMessage();

        ostc.opportunityId = oppt.Id;
        ostc.queueOpportunityMessage();

        ostc.errorCode = 'TEST123';
        ostc.errorDescription = 'Error description';
        ostc.errorMessagePayload = events[0].Message__c;
        ostc.queueError();
    }

    @isTest static void testNativeAccount() {
        Datetime testStart = system.now();

        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('Party like it\'s 1999');
        insert cdhParty;

        Account acct = IntegrationObjectsTestUtil.getSFAccount(cdhParty, cdhParty.CDH_Party_Name__c);
        insert acct;

        // delete any events that may have been created by our inserts so we're testing this unit only
        List<Outbound_Event__c> eventsToDelete = [SELECT Id FROM Outbound_Event__c WHERE CreatedDate >= :testStart];
        delete eventsToDelete;

        Test.startTest();
        OutboundService.queueAccountMessage(IntegrationObjectConverter.convertSalesAccount(acct), 'INSERT');
        Test.stopTest();

        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testNativeAddress() {
        Datetime testStart = system.now();

        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('Party like it\'s 1999');
        insert cdhParty;

        Account acct = IntegrationObjectsTestUtil.getSFAccount(cdhParty, cdhParty.CDH_Party_Name__c);
        insert acct;

        Address__c addr = IntegrationObjectsTestUtil.getSFAddress(acct, 'East Davie Street', 'Raleigh', 'NC');
        insert addr;

        // delete any events that may have been created by our inserts so we're testing this unit only
        List<Outbound_Event__c> eventsToDelete = [SELECT Id FROM Outbound_Event__c WHERE CreatedDate >= :testStart];
        delete eventsToDelete;

        Test.startTest();
        OutboundService.queueAddressMessage(IntegrationObjectConverter.convertAddress(addr), 'INSERT');
        Test.stopTest();

        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testNativeContact() {
        Datetime testStart = system.now();

        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty('Party like it\'s 1999');
        insert cdhParty;

        Contact cont = IntegrationObjectsTestUtil.getSFContact(cdhParty, 'Nicolas', 'Tesla');
        insert cont;

        // delete any events that may have been created by our inserts so we're testing this unit only
        List<Outbound_Event__c> eventsToDelete = [SELECT Id FROM Outbound_Event__c WHERE CreatedDate >= :testStart];
        delete eventsToDelete;

        Test.startTest();
        OutboundService.queueContactMessage(IntegrationObjectConverter.convertContact(cont), 'INSERT');
        Test.stopTest();

        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testNativeOrder() {
        Datetime testStart = system.now();

        Opportunity oppt = IntegrationObjectsTestUtil.getSFOpportunity();
        insert oppt;

        // delete any events that may have been created by our inserts so we're testing this unit only
        List<Outbound_Event__c> eventsToDelete = [SELECT Id FROM Outbound_Event__c WHERE CreatedDate >= :testStart];
        delete eventsToDelete;

        Test.startTest();
        OutboundService.queueOrderMessage(IntegrationObjectConverter.convertOpportunityToOrder(oppt), 'INSERT');
        Test.stopTest();

        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testContact() {
        OutboundService.queueContactMessage(IntegrationObjectsTestUtil.getContact(IntegrationObjectsTestUtil.getSalesAccount()), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testAccount() {
        OutboundService.queueAccountMessage(IntegrationObjectsTestUtil.getSalesAccount(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testAccountWithContactsAndAddresses() {
        OutboundService.queueAccountMessage(IntegrationObjectsTestUtil.getSalesAccountWithContactsAndAddresses(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testAddress() {
        OutboundService.queueAddressMessage(IntegrationObjectsTestUtil.getAddress(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testOrder() {
        OutboundService.queueOrderMessage(IntegrationObjectsTestUtil.getOrder(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 1);
    }

    @isTest static void testError() {
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String inboundMessage = jsonMessage.Body.toString();
        OutboundService.queueErrorMessage(inboundMessage, 'ERR54321', 'Test Error');
        List<Outbound_Error__c> errors = [select Id from Outbound_Error__c];
        System.assert(errors.size() == 1);
    }

    @isTest static void testEventPullService(){
        OutboundService.queueAccountMessage(IntegrationObjectsTestUtil.getSalesAccount(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];

        OutboundEventAcknowledgeService.RecordRequest msgRR = new OutboundEventAcknowledgeService.RecordRequest();
        msgRR.type = 'outbound';
        msgRR.recordId = events[0].Id;

        List<Object> requests = new List<Object>();
        requests.add(msgRR);

        String jsonInputStr = JSON.serialize(requests);
        test.startTest();

        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();

        req.requestURI = '/services/apexrest/Pull';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInputStr);
        RestContext.request = req;
        RestContext.response = res;

        OutboundEventPullService oeps = new OutboundEventPullService();
        OutboundEventPullService.getEvents();

        if (RestContext.response.statuscode != 201){
            System.debug('StatusCode = ' + res.statuscode);
            System.debug(RestContext.response.responseBody.toString());
        }
        System.assert(RestContext.response.statuscode == 201);
    }

    @isTest static void testErrorPullService(){
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String inboundMessage = jsonMessage.Body.toString();
        OutboundService.queueErrorMessage(inboundMessage, 'ERR54321', 'Test Error');
        List<Outbound_Error__c> events = [select Id from Outbound_Error__c];

        OutboundEventAcknowledgeService.RecordRequest msgRR = new OutboundEventAcknowledgeService.RecordRequest();
        msgRR.type = 'error';
        msgRR.recordId = events[0].Id;

        List<Object> requests = new List<Object>();
        requests.add(msgRR);

        String jsonInputStr = JSON.serialize(requests);
        test.startTest();

        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();

        req.requestURI = '/services/apexrest/Pull';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInputStr);
        RestContext.request = req;
        RestContext.response = res;
        OutboundEventPullService oeps = new OutboundEventPullService();
        OutboundEventPullService.getEvents();

        if (RestContext.response.statuscode != 201){
            System.debug('StatusCode = ' + res.statuscode);
            System.debug(RestContext.response.responseBody.toString());
        }
        System.assert(RestContext.response.statuscode == 201);
    }

    @isTest static void testAdknowledgeService(){
        OutboundService.queueAccountMessage(IntegrationObjectsTestUtil.getSalesAccount(), 'INSERT');
        List<Outbound_Event__c> events = [select Id from Outbound_Event__c];

        OutboundEventAcknowledgeService.RecordRequest msgRR = new OutboundEventAcknowledgeService.RecordRequest();
        msgRR.type = 'outbound';
        msgRR.recordId = events[0].Id;

        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONSalesAccount1A' LIMIT 1];
        String inboundMessage = jsonMessage.Body.toString();
        OutboundService.queueErrorMessage(inboundMessage, 'ERR54321', 'Test Error');
        List<Outbound_Error__c> errors = [select Id from Outbound_Error__c];

        OutboundEventAcknowledgeService.RecordRequest errorRR = new OutboundEventAcknowledgeService.RecordRequest();
        errorRR.type = 'error';
        errorRR.recordId = errors[0].Id;

        List<Object> requests = new List<Object>();
        requests.add(errorRR);
        requests.add(msgRR);

        String jsonInputStr = JSON.serialize(requests);
        test.startTest();

        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();

        req.requestURI = '/services/apexrest/Pull';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInputStr);
        RestContext.request = req;
        RestContext.response = res;
        OutboundEventAcknowledgeService oeas = new OutboundEventAcknowledgeService();
        OutboundEventAcknowledgeService.acknowledgeEvents();

        if (RestContext.response.statuscode != 201){
            System.debug('StatusCode = ' + res.statuscode);
            System.debug(RestContext.response.responseBody.toString());
        }
        System.assert(RestContext.response.statuscode == 201);

        errors = [select Id from Outbound_Error__c];
        System.assert(errors.size() == 0);
        events = [select Id from Outbound_Event__c];
        System.assert(events.size() == 0);
    }

    @isTest static void testGetPriority(){
        List<OutboundMessagePriority__c> priorityRules = new List<OutboundMessagePriority__c>{
            new OutboundMessagePriority__c(Order__c=1, Name='Test1', Object__c='*', Event__c='Sync', Priority__c=100),
            new OutboundMessagePriority__c(Order__c=2, Name='Test2', Object__c='*', Event__c='Error', Priority__c=100),
            new OutboundMessagePriority__c(Order__c=3, Name='Test3', Object__c='Account', Event__c='SingleInsertUpdate', Priority__c=50),
            new OutboundMessagePriority__c(Order__c=4, Name='Test4', Object__c='Contact', Event__c='SingleInsertUpdate', Priority__c=45),
            new OutboundMessagePriority__c(Order__c=5, Name='Test5', Object__c='Opportunity', Event__c='*', Priority__c=40),
            new OutboundMessagePriority__c(Order__c=6, Name='Default', Object__c='*', Event__c='*', Priority__c=20)};
        
        insert priorityRules;

        Test.startTest();
        Decimal accountSyncPriority = OutboundService.getPriority('Account', 'Sync');
        Decimal contactInsertPriority = OutboundService.getPriority('Contact', 'SingleInsertUpdate');
        Decimal addressBulkInsertPriority = OutboundService.getPriority('Address', 'BulkInsertUpdate');
        Test.stopTest();

        System.assertEquals(100, accountSyncPriority);
        System.assertEquals(45, contactInsertPriority);
        System.assertEquals(20, addressBulkInsertPriority);
    }

    @isTest static void testGetPriorityNoRules(){
        Test.startTest();
        Decimal accountSyncPriority = OutboundService.getPriority('Account', 'Sync');
        Decimal contactInsertPriority = OutboundService.getPriority('Contact', 'SingleInsertUpdate');
        Decimal addressBulkInsertPriority = OutboundService.getPriority('Address', 'BulkInsertUpdate');
        Test.stopTest();

        System.assertEquals(0, accountSyncPriority);
        System.assertEquals(0, contactInsertPriority);
        System.assertEquals(0, addressBulkInsertPriority);
    }

    @isTest static void testLargeOrder() {
        IntegrationObjects.Order order = IntegrationObjectsTestUtil.getOrder();
        IntegrationObjects.OrderLine orderLine = order.orderLines[0];
        for(Integer i=0; i<500; i++) {
            order.orderLines.add(orderLine.clone());
        }
        OutboundService.queueOrderMessage(order, 'INSERT');
        List<Outbound_Event__c> events = [select Id, Full_Message_In_Attachment__c from Outbound_Event__c];
        System.assert(events[0].Full_Message_In_Attachment__c);
        System.assert(events.size() == 1);

        OutboundEventAcknowledgeService.RecordRequest msgRR = new OutboundEventAcknowledgeService.RecordRequest();
        msgRR.type = 'outbound';
        msgRR.recordId = events[0].Id;

        List<Object> requests = new List<Object>();
        requests.add(msgRR);

        String jsonInputStr = JSON.serialize(requests);
        test.startTest();

        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();

        req.requestURI = '/services/apexrest/Pull';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInputStr);
        RestContext.request = req;
        RestContext.response = res;

        OutboundEventPullService oeps = new OutboundEventPullService();
        OutboundEventPullService.getEvents();

        if (RestContext.response.statuscode != 201){
            System.debug('StatusCode = ' + res.statuscode);
            System.debug(RestContext.response.responseBody.toString());
        }
        System.assertEquals(201, RestContext.response.statuscode);        
    }    
}