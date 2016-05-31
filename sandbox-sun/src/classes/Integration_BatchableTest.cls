/**
 * Test class for Integration_Batchable
 * 
 * @version 2014-09-25
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-09-25 - created
 */
@isTest
private class Integration_BatchableTest {

    static final String inboundMessageType = 'TransactionalAccount';

    static String inboundMessage {
        get {
            if(inboundMessage == null) {
                StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONTransactionalAccount1A' LIMIT 1];
                inboundMessage = jsonMessage.Body.toString();                
            }
            return inboundMessage;
        }
        set;
    }

    static Inbound_Event__c inboundEvent {
        get {
            if(inboundEvent == null) {
                inboundEvent = new Inbound_Event__c(
                    Event_Type__c = inboundMessageType,
                    Message__c = inboundMessage,
                    Operation__c = 'Sync',
                    Retries__c = 0,
                    Status__c = 'New');
            }
            return inboundEvent;
        }
        set;
    }

    static Outbound_Event__c outboundEvent {
        get {
            if(outboundEvent == null) {
                outboundEvent = new Outbound_Event__c(
                    Event_Type__c = 'Contact',
                    Message__c = '{Test:"Dummy"}',
                    Operation__c = 'Sync',
                    Status__c = 'New',
                    Priority__c = 100,
                    Record_Id__c = 'Test');
            }
            return outboundEvent;
        }
        set;
    }

    static Outbound_Error__c outboundError {
        get {
            if(outboundError == null) {
                outboundError = new Outbound_Error__c(
                    Event_Type__c = 'Contact',
                    Message__c = '{Error:"Dummy"}',
                    Operation__c = 'Sync',
                    Status__c = 'New',
                    Priority__c = 100,
                    Record_Id__c = 'Test');
            }
            return outboundError;
        }
        set;
    }

    //@isTest
    //static void hasWorkTest() {
    //    List<Inbound_Event__c> testEvents = new List<Inbound_Event__c>{inboundEvent, inboundEvent.clone(), inboundEvent.clone()};
    //    insert testEvents;
    //    Integration_Batchable batchable = new Integration_Batchable();

    //    Test.startTest();
    //    Boolean hasWork = batchable.hasWork();
    //    Test.stopTest();

    //    System.assert(hasWork);
    //}

    //@isTest
    //static void hasNoWorkTest() {
    //    Integration_Batchable batchable = new Integration_Batchable();

    //    Test.startTest();
    //    Boolean hasWork = batchable.hasWork();
    //    Test.stopTest();

    //    System.assert(!hasWork);
    //}

    @isTest
    static void processInboundEventsTest() {
        List<Inbound_Event__c> testEvents = new List<Inbound_Event__c>{inboundEvent, inboundEvent.clone(), inboundEvent.clone()};
        insert testEvents;
        Integration_Batchable batchable = new Integration_Batchable();

        Test.startTest();
        batchable.processInboundEvents(testEvents);
        Test.stopTest();

        // check that the events have been dequeued
        testEvents = [SELECT Id FROM Inbound_Event__c];
        System.assert(testEvents.isEmpty());

    }

    @isTest
    static void checkOutboundEventLoadTest() {
        List<Outbound_Event__c> testEvents = new List<Outbound_Event__c>{outboundEvent, outboundEvent.clone(), outboundEvent.clone()};
        insert testEvents;

        Integer eventCount = [SELECT count() FROM Outbound_Event__c];

        LongSetting__c alertThresholdSetting = new LongSetting__c(Name = 'Integration.alertThresholdOutbound', Value__c = 2);
        insert alertThresholdSetting;

        Integration_Batchable batchable = new Integration_Batchable();

        Test.startTest();
        batchable.checkOutboundEventLoad();
        Test.stopTest();

        testEvents = [SELECT Id, Send_Load_Alert__c FROM Outbound_Event__c WHERE Send_Load_Alert__c = True];
        System.assertEquals(1, testEvents.size());
    }

    @isTest
    static void processOutboundEventsTest() {
        List<Outbound_Event__c> testEvents = new List<Outbound_Event__c>{outboundEvent, outboundEvent.clone(), outboundEvent.clone()};
        insert testEvents;

        List<Outbound_Error__c> testErrors = new List<Outbound_Error__c>{outboundError, outboundError.clone(), outboundError.clone()};
        insert testErrors;

        Integration_Batchable batchable = new Integration_Batchable();

        Test.startTest();
        batchable.processOutboundEvents(testEvents, testErrors, batchable.getOutboundLimit());
        Test.stopTest();

        // check that the status of events has been updated
        testEvents = [SELECT Id, Status__c FROM Outbound_Event__c];
        for(Outbound_Event__c testEvent : testEvents) {
            System.assertEquals('Pending', testEvent.Status__c);
        }

        // check that the status of errors has been updated
        testErrors = [SELECT Id, Status__c FROM Outbound_Error__c];
        for(Outbound_Error__c testError : testErrors) {
            System.assertEquals('Pending', testError.Status__c);
        }
    }

    @isTest
    static void processOutboundEventsPriortizationTest() {
        //using Test.loadData() because we can control the CreatedDate of the test records
        List<Outbound_Event__c> testEvents = Test.loadData(Outbound_Event__c.sObjectType, 'testOutboundEvents');
        testEvents[0].Priority__c = 45;
        testEvents[1].Priority__c = 100;
        testEvents[2].Priority__c = -999;

        //using Test.loadData() because we can control the CreatedDate of the test records
        List<Outbound_Error__c> testErrors = Test.loadData(Outbound_Error__c.sObjectType, 'testOutboundErrors');
        testErrors[0].Priority__c = 0;
        testErrors[1].Priority__c = 45;
        testErrors[2].Priority__c = 99;

        LongSetting__c pendingLimitSetting = new LongSetting__c(Name = 'Integration.maxPendingOutbound', Value__c = 3);
        insert pendingLimitSetting;

        Integration_Batchable batchable = new Integration_Batchable();

        Test.startTest();
        batchable.processOutboundEvents(testEvents, testErrors, batchable.getOutboundLimit());
        Test.stopTest();

        // check that the status of events has been updated
        System.assertEquals('Pending', testEvents[0].Status__c);
        System.assertEquals('Pending', testEvents[1].Status__c);
        System.assertEquals('New', testEvents[2].Status__c);

        // check that the status of errors has been updated
        System.assertEquals('New', testErrors[0].Status__c);
        System.assertEquals('New', testErrors[1].Status__c);
        System.assertEquals('Pending', testErrors[2].Status__c);
    }

    @isTest
    static void startTest() {
        List<Inbound_Event__c> testEvents = new List<Inbound_Event__c>{inboundEvent, inboundEvent.clone(), inboundEvent.clone()};
        insert testEvents;

        Test.startTest();
        Integration_Batchable batchable = new Integration_Batchable();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
        ssc.setPageSize(100);
        List<Inbound_Event__c> events = ssc.getRecords();
        Test.stopTest();

        System.assertEquals(3,events.size());
    }

    @isTest
    static void executeTest() {
        Inbound_Event__c testEvent = inboundEvent;
        insert testEvent;

        Test.startTest();
        Integration_Batchable batchable = new Integration_Batchable();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
        ssc.setPageSize(100);
        List<Inbound_Event__c> events = ssc.getRecords();
        batchable.execute(null,events);
        batchable.finish((AsyncApexJob)null);
        Test.stopTest();
    }
}