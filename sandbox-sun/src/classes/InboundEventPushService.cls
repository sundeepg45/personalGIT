/*****************************************************************************************
    Name    : InboundEventPushService
    Desc    : This class is implemnting the logic for creating records into Inbound Event Object from Middleware.
              Middleware will push the record using this service into inbound event table. 
                                     
    Modification Log :  
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Chandan Prusty      05/26/2014          Created
    Scott Coleman       07/11/2014          Updating to write to Inbound Event table
******************************************************************************************/
@RestResource(urlMapping='/Inbound/*')
global with sharing class InboundEventPushService{ 
    @HttpPost
    global static string doPushInboundRecord(){
    
        // Variable to hold the RestRequest.
        RestRequest restRequest = RestContext.request;       
        
        try{
            // invoke method to process request body , if request body is not empty/null.
            if(restRequest !=null && restRequest.requestBody != null && restRequest.requestBody.tostring().trim().length()>0){
                return insertInboundRecord(restRequest.requestBody.tostring().trim());
            } 
            else{
            
                 // set response code
                 RestContext.response.statuscode = 500;
                 
                // return proper message to middleware when request  body is empty.
                return ('The request body is empty');
            }
        }
        catch(Exception e) {
        
             // set response code
             RestContext.response.statuscode = 500;
        
            // return the exception message to middleware
            return (e.getMessage());
        }           
    }
    
    // Method used to process request body and insert inbound staging record.
    private static String insertInboundRecord(String requestBody){ 
        try{     
            // deserialize JSON into <string,object> format            
            Map<String, Object> requestDetails;
            requestDetails = (Map<String, Object>)JSON.deserializeUntyped(requestBody); 
            
            // get the header details from the deserialized request body.
            Map<String, Object> requestHeader;
            requestHeader = (Map<String, Object>)requestDetails.get('Header');
            
            // check of request header or payload is not null
            if(requestHeader == null || requestDetails.get('Payload') == null ){
            
                // set the response code 
                RestContext.response.statuscode = 500;
                
                // return proper message to when header/payload is missing in request body.
                return ('Header/Payload is missing in request');
            }
            else{
                // creating the instance of inbound event
                Inbound_Event__c inboundEvent = new Inbound_Event__c(); 
                
                // set the service name from the header information of request body
                inboundEvent.Event_Type__c = String.valueOf(requestHeader.get('Type'));

                // set the operation from the header information
                inboundEvent.Operation__c = String.valueOf(requestHeader.get('Operation'));
                
                // set the trial attempts as 0
                inboundEvent.Retries__c = 0;

                // default status to New
                inboundEvent.Status__c = 'New';
                
                // setting the payload field of inbound event
                if(requestBody.length() > 131072) {
                    // truncate message so it will fit
                    inboundEvent.Message__c = requestBody.left(131072);
                    inboundEvent.Full_Message_In_Attachment__c = true;
                    insert inboundEvent;

                    // store full message as an attachment
                    insert new Attachment(Name = 'FullMessage', Body = Blob.valueOf(requestBody), ParentId = inboundEvent.Id);
                }
                else {
                    inboundEvent.Message__c = requestBody;
                    insert inboundEvent;
                }              
                
                // set the response code as 201
                RestContext.response.statuscode = 201;
                
                // return the id of inbound staging record to middleware system.
                return(inboundEvent.Id);
            }
        }
        catch(exception e){
            system.debug('exception occured-->'+e.getmessage());
            
            // set response code as 500
            RestContext.response.statuscode = 500;
            
            // return exception message to middleware system.
            return (e.getmessage());
        }                                       
    }       
}