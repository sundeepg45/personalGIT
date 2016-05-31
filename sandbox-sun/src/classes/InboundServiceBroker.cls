/**
 * This class will call the JSON parser for a given event type and the pass the deserialized message
 * to the appropriate inbound service.
 * 
 * @version 2015-02-03
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-07-11 - created
 * 2014-07-14 - refactored
 * 2014-07-16 - added retry
 * 2014-07-23 - commenting out Address message type
 * 2014-07-29 - eliminated unecessary retries
 * 2014-09-11 - added support for sync messages
 * 2014-10-18 - added support for product messages
 * 2015-02-03 - failed sync requests are no longer retried, retry count moved to custom setting
 * 2015-03-22 - added support for account sync by cdh party number
 */
public with sharing class InboundServiceBroker {

    public static void processMessage(Id eventId, String messageType, String message, String operation, Decimal retries, String status) {
        String errorMessage;

        // setting this static variable will prevent generation of outbound messages for
        //  updates made as a result of the inobound message
        StaticVariableUtilityClass.firstRun = false;

        String newStatus = status;   

        try {
            // create an instance of the InboundService object
            InboundService service = new InboundService();

            // for sync messages queue an outbound message for the requested record
            if(operation == 'SYNC' && message.contains('"SyncRequest"')) {
                //throw new ServiceBrokerException('SYNC operation temporarily disabled.');
                //parse message to extract id
                String keyValue;
                String keyName;
                try {
                    Map<String, Object> messageMap = (Map<String, Object>) JSON.deserializeUntyped(message);
                    Map<String, Object> payloadMap = (Map<String, Object>) messageMap.get('Payload');
                    Map<String, Object> syncRequestMap = (Map<String, Object>) payloadMap.get('SyncRequest');
                    keyName = String.valueOf(syncRequestMap.get('KeyName'));
                    keyValue = String.valueOf(syncRequestMap.get('KeyValue'));
                    System.debug('*** KeyValue: ' + keyValue);
                    System.debug('*** KeyName: ' + keyName);

                    if(messageType == 'SalesAccount') {
                        Account account;
                        if(keyName == 'CDH_PARTY_NUMBER') {
                            account = OutboundSyncSelector.getAccountData(keyValue);
                        }
                        else {
                            account = OutboundSyncSelector.getAccountData((Id)keyValue);
                        }
                        if(account != null) {
                            OutboundService.queueAccountMessage(IntegrationObjectConverter.convertSalesAccount(account, OutboundSyncSelector.getPartnerProgramData(account.CDHPartyNumber__c)), 'SYNC', 'Sync');
                        }
                        else {
                            throw new ServiceBrokerException('Account record not found for KeyValue ' + keyValue);
                        }
                    }
                    else if(messageType == 'Contact') {
                        Contact contact = OutboundSyncSelector.getContactData((Id)keyValue);
                        if(contact != null) {
                            OutboundService.queueContactMessage(IntegrationObjectConverter.convertContact(contact), 'SYNC', 'Sync');
                        }
                        else {
                            throw new ServiceBrokerException('Contact record not found for KeyValue ' + keyValue);
                        }
                    }
                    else if(messageType == 'OAGI') {
                        Opportunity opportunity;
                        if(keyName == 'OPPORTUNITY_NUMBER') {
                            opportunity = OutboundSyncSelector.getOpportunityData(keyValue);
                        }
                        else {
                            opportunity = OutboundSyncSelector.getOpportunityData((Id)keyValue);
                        }
                        if(opportunity != null) {
                            OutboundService.queueOrderMessage(IntegrationObjectConverter.convertOpportunityToOrder(opportunity), 'SYNC', 'Sync');
                        }
                        else {
                            throw new ServiceBrokerException('Opportunity record not found for KeyValue ' + keyValue);
                        }
                    }
                    else {
                        throw new ServiceBrokerException('Unsupported message type "' + messageType + '"');
                    }
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('SYNC operation failed: ' + ex.getMessage(), ex);
                }
            }
            // for each known message type, pass the message to the correct deserializer and then pass
            //  the deserialized objects to the correct inbound service
            else if(messageType == 'TransactionalAccount') {
                IntegrationObjects.TransactionalAccount account = null;
                try {
                    account = IntegrationObjectsDeserializer.parseTransactionalAccount(message);
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('Unable to deserialize transactional account message.', ex);
                }

                if(account == null) {
                    throw new ServiceBrokerException('Unable to deserialize transactional account message.');
                }

                if(!Test.isRunningTest()) {
                    service.EBS_Account_Service(account);
                }
            }
            else if(messageType == 'SalesAccount') {
                IntegrationObjects.SalesAccount account = null;
                try {
                    account = IntegrationObjectsDeserializer.parseSalesAccount(message);
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('Unable to deserialize sales account message.', ex);
                }

                if(account == null) {
                    throw new ServiceBrokerException('Unable to deserialize sales account message.');
                }

                if(!Test.isRunningTest()) {
                    service.SalesAccount_Service(account);
                }
            }
            else if(messageType == 'Contact') {
                IntegrationObjects.Contact contact = null;
                try {
                    contact = IntegrationObjectsDeserializer.parseContact(message);
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('Unable to deserialize contact message.', ex);
                }

                if(contact == null) {
                    throw new ServiceBrokerException('Unable to deserialize contact message.');
                }

                if(!Test.isRunningTest()) {
                    service.Contact_Service(new List<IntegrationObjects.Contact>{contact});
                }
            }
            else if(messageType == 'Order') {
                IntegrationObjects.Order order = null;
                try {
                    order = IntegrationObjectsDeserializer.parseOrder(message);
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('Unable to deserialize order message.', ex);
                }

                if(order == null) {
                    throw new ServiceBrokerException('Unable to deserialize order message.');
                }

                if(!Test.isRunningTest()) {
                    service.Opportunity_Service(order);
                }
            }
            else if(messageType == 'Product') {
                IntegrationObjects.Product product = null;
                try {
                    product = IntegrationObjectsDeserializer.parseProduct(message);
                }
                catch(Exception ex) {
                    throw new ServiceBrokerException('Unable to deserialize order message.', ex);
                }

                if(product == null) {
                    throw new ServiceBrokerException('Unable to deserialize order message.');
                }

                if(!Test.isRunningTest()) {
                    Product_CreateUpdate productService = new Product_CreateUpdate();
                    List<String> errors = productService.createUpdateProducts(new List<IntegrationObjects.Product>{product});

                    if(!errors.isEmpty()) {
                        String errorString = '';
                        for(String error : errors) {
                            errorString = '[' + error + ']';
                        }

                        throw new ServiceBrokerException('Error(s) processing inbound product(s): ' + errorString);
                    }
                }                
            }
            // this message type is to facilitate testing
            else if(messageType == 'ForceRetry') {
                throw new IntegrationException('Force retry');
            }
            // raise an error if the message type is unknown
            else {
                throw new ServiceBrokerException('Unknown message type "' + messageType + '"');
            }

            newStatus = 'Processed';
        }
        catch(ServiceBrokerException ex) {
            errorMessage = ex.getMessage();
            System.debug('An error occurred while processing an inbound event: ' + errorMessage);

            newStatus = 'Error';

            if(!Test.isRunningTest()) {
                try {
                    OutboundService.queueErrorMessage(message, ex.getTypeName(), errorMessage);
                }
                catch(Exception ex2) {
                    System.debug('An error occurred while attempting to generate an outbound error message: ' + ex2.getMessage());
                }
            }            
        }
        catch(Exception ex) {
            errorMessage = ex.getMessage();
            System.debug('An error occurred while processing an inbound event: ' + errorMessage);

            if(errorMessage.length() > 32768) {
                errorMessage = errorMessage.left(32768);
            }

            if(retries < getLongSetting('Integration.numRetries', 5)) {
                newStatus = 'Retried';
                retryMessage(eventId, messageType, message, operation, retries);
            }
            else {
                newStatus = 'Error';
                if(!Test.isRunningTest()) {
                    try {
                        OutboundService.queueErrorMessage(message, ex.getTypeName(), errorMessage);
                    }
                    catch(Exception ex2) {
                        System.debug('An error occurred while attempting to generate an outbound error message: ' + ex2.getMessage());
                    }
                }
            }
        }
        finally {
            EventLogService.logMessage('Inbound', eventId, messageType, message, operation, retries, newStatus, errorMessage, null);
        }
    }

    private static void retryMessage(Id eventId, String messageType, String message, String operation, Decimal retries) {
        Inbound_Event__c retriedEvent = new Inbound_Event__c(
            Event_Type__c = messageType,
            Operation__c = operation,
            Retries__c = retries + 1,
            Status__c = 'Retried');

        if(message.length() > 131072) {
            // truncate message so it will fit
            retriedEvent.Message__c = message.left(131072);
            retriedEvent.Full_Message_In_Attachment__c = true;
            insert retriedEvent;

            // store full message as an attachment
            insert new Attachment(Name = 'FullMessage', Body = Blob.valueOf(message), ParentId = retriedEvent.Id);
        }
        else {
            retriedEvent.Message__c = message;
            insert retriedEvent;
        }
    }

    private static Decimal getLongSetting(String key,Decimal defaultValue) {
        LongSetting__c l = LongSetting__c.getInstance(key);
        if(l != null) {
            defaultValue = l.Value__c;
        }
        return defaultValue;
    }

    private class ServiceBrokerException extends IntegrationException {}
}