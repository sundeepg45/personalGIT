/*****************************************************************************************
    Name    : OutBoundEventPullService
    Desc    : This class is implementing the logic for returning the records from outbound or error
              queue via a rest endpoint.
    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Chandan Prusty      06/20/2014          Created
    Tiaan Kruger        07/12/2014          Refactored
    Scott Coleman       10 Dec 2014         Updated to support large messages
******************************************************************************************/
@RestResource(urlMapping = '/OutboundEventPull/*')
global with sharing class OutboundEventPullService {
    /*
        [
          {
            "type": "outbound",
            "recordId": "SFDCuniquerecordId1"
          },
          {
            "type": "outbound",
            "recordId": "SFDCuniquerecordId2"
          }
        ]

        [
            {
                "id": {
                    "value": "04lK0000007JJ3eIAG"
                    },
                "sobject": {
                    "fieldsToNull":[],
                    "id":{
                        "value":"a4wK00000008iFVIAY"
                        },
                    "typeC":"outbound"
                }
            }
        ]
    */
    @HttpPost
    global static void getEvents(){
        // variable to hold the http request and response details.
        RestRequest request = RestContext.request;

        // setting the content type of response as JSON.
        RestContext.response.addheader('Content-Type', 'application/json');
        try {
            System.debug('Message: ' + request.requestBody.toString());
            if (request.requestBody != null && request.requestBody.toString().trim().length() > 0){
                List<RecordRequest> requestedRecords = (List<RecordRequest>)JSON.deserialize(request.requestBody.toString(), List<RecordRequest>.class);

                Set<ID> outboundEventIds = new Set<ID>();
                Set<ID> outboundErrorIds = new Set<ID>();

                for (RecordRequest rr : requestedRecords){
                    if (rr.type == 'outbound'){
                        outboundEventIds.add(rr.recordId);
                        System.debug('Message Record ID being fecthed: ' + rr.recordId);
                    } else if (rr.type == 'error'){
                        outboundErrorIds.add(rr.recordId);
                        System.debug('Error Record ID being fecthed: ' + rr.recordId);
                    }
                }

                // If we fail to parse or don't recieve any Ids, we blow up saying no data found
                if (outboundEventIds.size() == 0 && outboundErrorIds.size() == 0){
                    throw new NoIdsRecievedException('No IDs were retrieved from incoming message');
                }

                List<Outbound_Event__c> outboundEvents = fetchOutboundEvents(outboundEventIds);
                List<Outbound_Error__c> outboundErrors = fetchOutboundErrors(outboundErrorIds);

                if (outboundErrors.size() == 0 && outboundEvents.size() == 0){
                    throw new NoDataFoundException();
                }

                Map<Id,Blob> attachmentMap = new Map<Id,Blob>();
                for(Attachment attachment : [SELECT Body, ParentId FROM Attachment WHERE ParentId IN :outboundEventIds AND Name = 'FullMessage']) {
                    attachmentMap.put(attachment.ParentId, attachment.Body);
                }
                for(Attachment attachment : [SELECT Body, ParentId FROM Attachment WHERE ParentId IN :outboundErrorIds AND Name = 'FullMessage']) {
                    attachmentMap.put(attachment.ParentId, attachment.Body);
                }                

                List<Object> outboundMessages = new List<Object>();
                for(Outbound_Event__c oe : outboundEvents){
                    if(oe.Full_Message_In_Attachment__c && attachmentMap.containsKey(oe.Id)) {
                        outboundMessages.add(JSON.deserializeUntyped(attachmentMap.get(oe.Id).toString()));
                        attachmentMap.remove(oe.Id);
                    }
                    else {
                        outboundMessages.add(JSON.deserializeUntyped(oe.Message__c));
                    }
                }
                for(Outbound_Error__c oe : outboundErrors){
                    if(oe.Full_Message_In_Attachment__c && attachmentMap.containsKey(oe.Id)) {
                        outboundMessages.add(JSON.deserializeUntyped(attachmentMap.get(oe.Id).toString()));
                        attachmentMap.remove(oe.Id);
                    }
                    else {
                        outboundMessages.add(JSON.deserializeUntyped(oe.Message__c));
                    }
                }

                RestContext.response.statuscode = 201;
                RestContext.response.responseBody  = blob.valueof(JSON.serialize(outboundMessages));
            }

        } catch(exception e){
            System.debug(LoggingLevel.ERROR, 'Failed to get outbound Events: ' + e.getMessage());

            RestContext.response.statuscode = 500;
            Map<String, String> errorMap = new Map<String, String>();
            errorMap.put('error', e.getmessage());
            RestContext.response.responseBody  = blob.valueof(JSON.serialize(errorMap));
        }

    }

    global class RecordRequest {
        // variable to hold the request type
        public String type {get;set;}
        // variable to hold the sfdc record id (of outbound staging/error staging records)
        public String recordId {get;set;}
    }

    class NoIdsRecievedException extends Exception {}

    private static List<Outbound_Event__c> fetchOutboundEvents(Set<ID> ids){
        List<Outbound_Event__c> events = [
            SELECT
                Event_Type__c,
                Record_Id__c,
                Status__c,
                Message__c,
                Full_Message_In_Attachment__c
            FROM Outbound_Event__c
            WHERE Id IN :ids
            ORDER BY CreatedDate ASC];
        return events;
    }

    private static List<Outbound_Error__c> fetchOutboundErrors(Set<ID> ids){
        List<Outbound_Error__c> errors = [
            SELECT
                Event_Type__c,
                Record_Id__c,
                Status__c,
                Message__c,
                Full_Message_In_Attachment__c
            FROM Outbound_Error__c
            WHERE Id IN :ids
            ORDER BY CreatedDate ASC];
        return errors;
    }
}