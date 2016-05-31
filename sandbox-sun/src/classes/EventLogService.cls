/*****************************************************************************************
    Name    : EventLogService
    Desc    : The class that writes messages to the integration event log.

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman          7/17/2014       Created
    Scott Coleman          7/28/2014       Added logMessages()
    Scott Coleman          9/23/2014       Updated to support priority
    Scott Coleman          10 Dec 2014     Updated to support large messages
    Scott Coleman          13 Aug 2015     Suppressing publishing of test records per US71693
******************************************************************************************/
public with sharing class EventLogService {
    public static void logMessage(String direction, Id eventId, String messageType, String message, String operation, Decimal retries, String status, String errorMessage, Decimal priority) {
        try {
            // log the event message
            Event_Log__c loggedEvent = new Event_Log__c(
                Direction__c = direction,
                Error_Message__c = errorMessage,
                Original_Event_Id__c = eventId,
                Event_Type__c = messageType,
                Operation__c = operation,
                Retries__c = retries,
                Status__c = status,
                Priority__c = priority,
                Not_Published_To_Bus__c = OutboundService.DoNotPublish);

            if(message.length() > 131072) {
                // truncate message so it will fit
                loggedEvent.Message__c = message.left(131072);
                loggedEvent.Full_Message_In_Attachment__c = true;
                insert loggedEvent;

                // store full message as an attachment
                insert new Attachment(Name = 'FullMessage', Body = Blob.valueOf(message), ParentId = loggedEvent.Id);
            }
            else {
                loggedEvent.Message__c = message;
                insert loggedEvent;
            }
        }
        catch(Exception ex) {
            //don't fail the transaction due to logging issues
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
        }      
    }

    public static void logMessages(List<Outbound_Event__c> outboundEvents) {
        try {
            List<Event_Log__c> loggedEvents = new List<Event_Log__c>();
            Set<Id> eventIds = new Set<Id>();

            for(Outbound_Event__c outboundEvent : outboundEvents) {
                loggedEvents.add(new Event_Log__c(
                    Direction__c = 'Outbound',
                    Original_Event_Id__c = outboundEvent.Id,
                    Event_Type__c = outboundEvent.Event_Type__c,
                    Message__c = outboundEvent.Message__c,
                    Operation__c = outboundEvent.Operation__c,
                    Status__c = outboundEvent.Status__c,
                    Priority__c = outboundEvent.Priority__c,
                    Full_Message_In_Attachment__c = outboundEvent.Full_Message_In_Attachment__c,
                    Not_Published_To_Bus__c = OutboundService.DoNotPublish));

                if(outboundEvent.Full_Message_In_Attachment__c) {
                    eventIds.add(outboundEvent.Id);
                }
            }

            if(!loggedEvents.isEmpty()) {
                insert loggedEvents;

                if(!eventIds.isEmpty()) {
                    List<Attachment> loggedAttachments = new List<Attachment>();
                    Map<Id,Blob> attachmentBodyMap = new Map<Id,Blob>();
                    for(Attachment attachment : [SELECT Body, ParentId FROM Attachment WHERE ParentId IN :eventIds AND Name = 'FullMessage']) {
                        attachmentBodyMap.put(attachment.ParentId, attachment.Body);
                    }

                    for(Event_Log__c loggedEvent : loggedEvents) {
                        if(loggedEvent.Full_Message_In_Attachment__c && attachmentBodyMap.containsKey(loggedEvent.Original_Event_Id__c)) {
                            loggedAttachments.add(new Attachment(
                                                    Body = attachmentBodyMap.get(loggedEvent.Original_Event_Id__c),
                                                    Name = 'FullMessage',
                                                    ParentId = loggedEvent.Id));
                            attachmentBodyMap.remove(loggedEvent.Original_Event_Id__c);
                        }
                    }

                    if(!loggedAttachments.isEmpty()) {
                        insert loggedAttachments;
                    }
                }
            }
        }
        catch(Exception ex) {
            //don't fail the transaction due to logging issues
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }

    public static void logMessages(List<Outbound_Error__c> outboundErrors) {
        try {
            List<Event_Log__c> loggedEvents = new List<Event_Log__c>();
            Set<Id> errorIds = new Set<Id>();

            for(Outbound_Error__c outboundError : outboundErrors) {
                loggedEvents.add(new Event_Log__c(
                    Direction__c = 'Outbound',
                    Error_Message__c = 'See message header for error message',
                    Original_Event_Id__c = outboundError.Id,
                    Event_Type__c = 'Error',
                    Message__c = outboundError.Message__c,
                    Operation__c = outboundError.Operation__c,
                    Status__c = outboundError.Status__c,
                    Priority__c = outboundError.Priority__c,
                    Full_Message_In_Attachment__c = outboundError.Full_Message_In_Attachment__c));


                if(outboundError.Full_Message_In_Attachment__c) {
                    errorIds.add(outboundError.Id);
                }
            }

            if(!loggedEvents.isEmpty()) {
                insert loggedEvents;

                if(!errorIds.isEmpty()) {
                    List<Attachment> loggedAttachments = new List<Attachment>();
                    Map<Id,Blob> attachmentBodyMap = new Map<Id,Blob>();
                    for(Attachment attachment : [SELECT Body, ParentId FROM Attachment WHERE ParentId IN :errorIds AND Name = 'FullMessage']) {
                        attachmentBodyMap.put(attachment.ParentId, attachment.Body);
                    }

                    for(Event_Log__c loggedEvent : loggedEvents) {
                        if(loggedEvent.Full_Message_In_Attachment__c && attachmentBodyMap.containsKey(loggedEvent.Original_Event_Id__c)) {
                            loggedAttachments.add(new Attachment(
                                                    Body = attachmentBodyMap.get(loggedEvent.Original_Event_Id__c),
                                                    Name = 'FullMessage',
                                                    ParentId = loggedEvent.Id));
                            attachmentBodyMap.remove(loggedEvent.Original_Event_Id__c);
                        }
                    }

                    if(!loggedAttachments.isEmpty()) {
                        insert loggedAttachments;
                    }
                }                
            }
        }
        catch(Exception ex) {
            //don't fail the transaction due to logging issues
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }     
}