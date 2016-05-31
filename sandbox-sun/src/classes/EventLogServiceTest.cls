/*****************************************************************************************
    Name    : EventLogServiceTest
    Desc    : Test class for EventLogService

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman          7/17/2014       Created
    Scott Coleman          7/28/2014       Added tests for bulk log methods
******************************************************************************************/
@isTest
private class EventLogServiceTest {

    static Inbound_Event__c inboundEvent {
        get {
            if(inboundEvent == null) {
                inboundEvent = new Inbound_Event__c(
                    Event_Type__c = 'TestMessage',
                    Message__c = 'TestMessagePayload',
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
                    Record_Id__c = '0000000FAKETEST',
                    Event_Type__c = 'TestMessage',
                    Message__c = 'TestMessagePayload',
                    Operation__c = 'Sync',
                    Status__c = 'New');
            }
            return outboundEvent;
        }
        set;
    }

    static Outbound_Error__c outboundError {
        get {
            if(outboundError == null) {
                outboundError = new Outbound_Error__c(
                    Record_Id__c = '0000000FAKETEST',
                    Event_Type__c = 'TestMessage',
                    Message__c = 'TestMessagePayload',
                    Operation__c = 'Sync',
                    Status__c = 'New');
            }
            return outboundError;
        }
        set;
    }

    @isTest 
    static void logEventTest() {
        insert inboundEvent;

        Test.startTest();
        EventLogService.logMessage('Inbound', inboundEvent.Id, inboundEvent.Event_Type__c, inboundEvent.Message__c, inboundEvent.Operation__c, inboundEvent.Retries__c, inboundEvent.Status__c, 'Testing', null);
        Test.stopTest();
        
        List<Event_Log__c> loggedEvents = [SELECT Id, Direction__c, Event_Type__c, Message__c, Error_Message__c FROM Event_Log__c where Original_Event_Id__c = :inboundEvent.Id];
        system.assertEquals(1, loggedEvents.size());
        system.assertEquals(inboundEvent.Event_Type__c, loggedEvents[0].Event_Type__c);
        system.assertEquals(inboundEvent.Message__c, loggedEvents[0].Message__c);
        system.assertEquals('Testing', loggedEvents[0].Error_Message__c);
    }

    @isTest
    static void logOutboundEventsTest() {
        List<Outbound_Event__c> outboundEvents = new List<Outbound_Event__c>{outboundEvent.clone(), outboundEvent.clone(), outboundEvent.clone()};
        insert outboundEvents;

        Test.startTest();
        EventLogService.logMessages(outboundEvents);
        Test.stopTest();
        
        List<Event_Log__c> loggedEvents = [SELECT Id, Direction__c, Event_Type__c, Message__c FROM Event_Log__c];
        system.assertEquals(3, loggedEvents.size());
        system.assertEquals('Outbound', loggedEvents[0].Direction__c);
        system.assertEquals(outboundEvent.Event_Type__c, loggedEvents[0].Event_Type__c);
        system.assertEquals(outboundEvent.Message__c, loggedEvents[0].Message__c);       
    }

    @isTest
    static void logOutboundErrorsTest() {
        List<Outbound_Error__c> outboundErrors = new List<Outbound_Error__c>{outboundError.clone(), outboundError.clone(), outboundError.clone()};
        insert outboundErrors;

        Test.startTest();
        EventLogService.logMessages(outboundErrors);
        Test.stopTest();
        
        List<Event_Log__c> loggedEvents = [SELECT Id, Direction__c, Event_Type__c, Message__c FROM Event_Log__c];
        system.assertEquals(3, loggedEvents.size());
        system.assertEquals('Outbound', loggedEvents[0].Direction__c);
        system.assertEquals('Error', loggedEvents[0].Event_Type__c);
        system.assertEquals(outboundError.Message__c, loggedEvents[0].Message__c);       
    }
}