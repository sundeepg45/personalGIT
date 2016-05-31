/*****************************************************************************************
    Name    : OuboundService
    Desc    : The class that accepts domain objects and serializes them in preperation for ESB pickup

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Tiaan Kruger           2014-07-11      Created
    Scott Coleman          2014-07-14      Added queueErrorMessage()
    Scott Coleman          2014-09-16      Added support for updated message property naming convention
    Scott Coleman          2014-09-22      Added getPriority() and updated queue methods to accept priority
    Scott Coleman          10 Dec 2014     Updated to support large messages
    Bill C Riemers         05 May 2015     Resolving too many DML opperations for accounts
    Bill C Riemers         12 Aug 2015     Resolving too many DML opperations for contacts
    Bill C Riemers         07 Dec 2015     Updated to allow multiple accounts in the same message
    Scott Coleman          13 Aug 2015     Suppressing publishing of test records per US71693
    Scott Coleman          26 Aug 2015     US69276 Support for ID arrays (parsing layer only) for CDH Party Merge
******************************************************************************************/
public with sharing class OutboundService {
    public static boolean DoNotPublish = false;

    static String ORDER_TYPE = 'OAGI';

    public static void queueAccountMessage(IntegrationObjects.SalesAccount account, String operation){
        queueAccountMessage(account, operation, null);
    }

    public static void queueAccountMessages(List<IntegrationObjects.SalesAccount> accounts, String operation){
        queueAccountMessages(accounts, operation, null);
    }

    public static void queueAccountMessage(IntegrationObjects.SalesAccount account, String operation, String priorityEvent){
        queueAccountMessages(new List<IntegrationObjects.SalesAccount>{account},operation,priorityEvent);
    }

    public static void queueAccountMessages(List<IntegrationObjects.SalesAccount> accounts, String operation, String priorityEvent){
        queueAccountMessages(accounts,operation,priorityEvent,false);
    }

    public static void queueAccountMessages(List<IntegrationObjects.SalesAccount> accounts, String operation, String priorityEvent,Boolean allowDuplicates){
        if(accounts != null && ! accounts.isEmpty()) {
            Map<Id,List<Object>> salesAccountsMap = new Map<Id,List<Object>>();
            for(IntegrationObjects.SalesAccount account : accounts) {
                MessageIntegrationObjects.SalesAccount messageAccount = new MessageIntegrationObjects.SalesAccount();
                messageAccount.setIOSalesAccount(account);
                List<Object> objects = salesAccountsMap.get(account.IDs);
                if((!allowDuplicates)|| objects == null) {
                    objects = new List<Object>();
                    salesAccountsMap.put(account.IDs,objects);
                }
                objects.add(messageAccount);
            }
            queueEvents('SalesAccount','SalesAccount', salesAccountsMap, operation, getPriority('Account', priorityEvent));
        }
    }

    public static void queueContactMessage(IntegrationObjects.Contact contact, String operation){
        queueContactMessage(contact, operation, null);
    }

    public static void queueContactMessage(IntegrationObjects.Contact contact, String operation, String priorityEvent){
        //added this debug to test if passed contact details are populated here.
        system.debug('contact----details passed here >' +contact);
        queueContactMessages(new List<IntegrationObjects.Contact>{contact},operation,priorityEvent);
    }

    public static void queueContactMessages(List<IntegrationObjects.Contact> contacts, String operation, String priorityEvent){
        if(contacts != null && ! contacts.isEmpty()) {
            Map<Id,Object> contactsMap = new Map<Id,Object>();
            for(IntegrationObjects.Contact contact : contacts) {
                MessageIntegrationObjects.Contact messageContact = new MessageIntegrationObjects.Contact();
                messageContact.setIOContact(contact);
                contactsMap.put(contact.IDs,messageContact);
            }
            queueEvents('Contact', 'Contacts', contactsMap, operation, getPriority('Contact', priorityEvent));
        }
    }

    public static void queueAddressMessage(IntegrationObjects.Address address, String operation){
        queueAddressMessage(address, operation, null);
    }

    public static void queueAddressMessage(IntegrationObjects.Address address, String operation, String priorityEvent){
        MessageIntegrationObjects.Address messageAddress = new MessageIntegrationObjects.Address();
        messageAddress.setIOAddress(address);
        queueEvent('Address', 'Addresses', address.IDs, messageAddress, operation, getPriority('Address', priorityEvent));
    }

    public static void queueOrderMessage(IntegrationObjects.Order order, String operation){
        queueOrderMessage(order, operation, null);
    }

    public static void queueOrderMessage(IntegrationObjects.Order order, String operation, String priorityEvent){
        queueEvent(ORDER_TYPE, 'Order', order.ID, OrderJSONGenerator.generateOrderJSON(order, true), operation, getPriority('Opportunity', priorityEvent));
    }

    private static void queueEvent(String eventType, String wrapper, Id objectId, Object payload, String operation, Decimal priority){
        queueEvents(eventType,wrapper,new Map<Id,Object>{objectId=>payload},operation,priority);
    }

    private static void queueEvents(String eventType, String wrapper, Map<Id,Object> objectMap, String operation, Decimal priority){
        Map<Id,List<Object>> objectsMap = new Map<Id,List<Object>>();
        for(Id key : objectMap.keySet()) {
            objectsMap.put(key,new List<Object>{objectMap.get(key)});
        }
        queueEvents(eventType,wrapper,objectsMap,operation,priority);
    }

    private static void queueEvents(String eventType, String wrapper, Map<Id,List<Object>> objectsMap, String operation, Decimal priority){
        List<Outbound_Event__c> events = new List<Outbound_Event__c>();
        List<Blob> bodies = new List<Blob>();
        for(Id objectId : objectsMap.keySet()) {
            for(Object payload : objectsMap.get(objectId)) {
                IntegrationObjects.Header header = new IntegrationObjects.Header();
                header.Operation = operation;
                header.Type = eventType;
                header.Timestamp = System.datetime.now();
                header.EventKey = objectId;
                Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(objectId));
                // Generate a unique ID off of the ID of the inbound object
                header.EsbMessageGuid = EncodingUtil.convertToHex(hash).subString(0,32);

                Map<String,Object> payloadMap = new Map<String,Object>();
                if (eventType == ORDER_TYPE){
                    // Due to the complexity of the OAGI format, we are being passed a serialized order rather than an object
                    payloadMap.put(wrapper, 'REPLACE_WITH_OAGI_SERIALIZED_ORDER');
                } else {
                    payloadMap.put(wrapper, payload);
                }

                Map<String,Object> message = new Map<String,Object>();
                message.put('Header', header);
                message.put('Payload', payloadMap);

                // Clear out empty list references if they are present
                String messageJSON = System.JSON.serialize(message);
                if (eventType == ORDER_TYPE){
                    // Due to the complexity of the OAGI format, we are being passed a serialized order rather than an object
                    messageJSON = messageJSON.replace('"REPLACE_WITH_OAGI_SERIALIZED_ORDER"', String.valueOf(payload));
                } else if (eventType == 'SalesAccount'){
                    messageJSON = messageJSON.replace(',"Contacts":null','');
                    messageJSON = messageJSON.replace(',"Addresses":null','');
                    messageJSON = messageJSON.replace(',"PartnerClassifications":null','');
                    messageJSON = replaceIdArray(messageJSON);
                } else if (eventType == 'Contact'){
                    messageJSON = replaceIdArray(messageJSON);
                }

                Outbound_Event__c event = new Outbound_Event__c(
                    Record_Id__c = objectId,
                    Event_Type__c = eventType,
                    Operation__c = operation,
                    Status__c = 'New',
                    Type__c = 'outbound',
                    Priority__c = priority
                );

                if(messageJSON.length() > 131072) {
                    // truncate message so it will fit
                    event.Message__c = messageJSON.left(131072);
                    event.Full_Message_In_Attachment__c = true;
                    bodies.add(Blob.valueOf(messageJSON));
                }
                else {
                    event.Message__c = messageJSON;
                    bodies.add(null);
                }
                System.debug('Creating event for message: ' + event.Message__c);
                events.add(event);
            }
        }
        if(! events.isEmpty()) {
            if(DoNotPublish) {
                for(Outbound_Event__c event : events) {
                    event.Status__c = 'Pending';
                }
                EventLogService.logMessages(events);
            }
            else {
                List<Attachment> attachments = new List<Attachment>();
                // errors are thrown
                for(Database.SaveResult sr : Database.insert(events,true)) {
                    Outbound_Event__c event = events.remove(0);
                    Blob body = bodies.remove(0);
                    if(body != null) {
                        attachments.add(new Attachment(Name = 'FullMessage', Body = body, ParentId = event.Id));
                    }
                }
                if(! attachments.isEmpty()) {
                    // throws exceptions
                    Database.insert(attachments,true);
                }
            }
        }
    }

    public static void queueErrorMessage(String inboundMessage, String errorCode, String errorDescription){
        Decimal priority = getPriority(null, 'Error');
        Map<String, Object> inboundMessageMap = (Map<String, Object>)System.JSON.deserializeUntyped(inboundMessage);
        Map<String, Object> inboundHeaderMap = (Map<String, Object>)inboundMessageMap.get('Header');

        String operation = (String)inboundHeaderMap.get('Operation');
        String eventType = (String)inboundHeaderMap.get('Type');
        String objectId = (String)inboundHeaderMap.get('EventKey');
        String esbMessageGuid = (String)inboundHeaderMap.get('EsbMessageGuid');

        if(operation == null || operation == '') {
            operation = 'Unknown';
        }
        if(operation.length() > 20) {
            operation = operation.left(20);
        }

        if(eventType == null || eventType == '') {
            eventType = 'Unknown';
        }
        if(eventType.length() > 30) {
            eventType = eventType.left(30);
        }

        if(objectId == null || objectId == '') {
            objectId = 'Unknown';
        }
        if(objectId.length() > 20) {
            objectId = objectId.left(20);
        }

        IntegrationObjects.ErrorHeader errorHeader = new IntegrationObjects.ErrorHeader();
        errorHeader.ErrorCode = errorCode;
        errorHeader.ErrorDetails = errorDescription;
        errorHeader.ErrorGuid = esbMessageGuid;

        Map<String,Object> errorMessage = new Map<String,Object>();
        errorMessage.put('Error', errorHeader);
        errorMessage.put('Message', 'REPLACEME_WITH_ORIGINAL_PAYLOAD');

        String serializedMessage = System.JSON.serialize(errorMessage);

        serializedMessage = serializedMessage.replace('"REPLACEME_WITH_ORIGINAL_PAYLOAD"', inboundMessage);

        Outbound_Error__c error = new Outbound_Error__c(
            Record_Id__c = objectId,
            Event_Type__c = eventType,
            Operation__c = operation,
            Type__c = 'Error',
            Priority__c = priority
        );

        if(serializedMessage.length() > 131072) {
            // truncate message so it will fit
            error.Message__c = serializedMessage.left(131072);
            error.Full_Message_In_Attachment__c = true;
            System.debug('Creating error for message: ' + error.Message__c);
            insert error;

            // store full message as an attachment
            insert new Attachment(Name = 'FullMessage', Body = Blob.valueOf(serializedMessage), ParentId = error.Id);
        }
        else {
            error.Message__c = serializedMessage;
            System.debug('Creating error for message: ' + error.Message__c);
            insert error;
        }
    }

    private static Map<String,Decimal> priorityRulesMap = new Map<String,Decimal>();

    @TestVisible
    private static Decimal getPriority(String sfObject, String event){
    	// only lookup each combination once...
        String key = sfObject+':'+event;
        Decimal priority = priorityRulesMap.get(key);
        if(priority == null) {
            priority = 0;
            for(OutboundMessagePriority__c priorityRule : [SELECT Object__c, Event__c, Priority__c 
                                                            FROM OutboundMessagePriority__c
                                                            WHERE (Object__c = :sfObject AND Event__c = :event)
                                                                OR (Object__c = :sfObject AND Event__c = '*')
                                                                OR (Object__c = '*' AND Event__c = :event)
                                                                OR (Object__c = '*' AND Event__c = '*')
                                                            ORDER BY Order__c
                                                            LIMIT 1] ) 
            {
                priority = priorityRule.Priority__c;
            }
            priorityRulesMap.put(key,priority);
        }
        return priority;
    }

    @TestVisible
    private static String replaceIdArray(String json) {
        String regex = '\\"IDs\\"\\s*?\\:\\s*?\\[(.*?)\\]';
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(json);
        while (m.find())
        {
            json = json.replaceFirst(regex, '"IDs":' + m.group(1).split(',')[0]);
        }
        return json;   
    }
}