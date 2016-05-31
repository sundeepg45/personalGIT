/*****************************************************************************************
    Name    : InboundEventPushServiceTest
    Desc    : Test class for InboundEventPushService
                                     
    Modification Log :  
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Deloitte            07/08/2014          Created
    Scott Coleman       07/15/2014          Updating to reflect changes to service
******************************************************************************************/
@isTest
private class InboundEventPushServiceTest {

    static testMethod void doPushInboundRecord_Single_Positive_Check() {
        //Positive test of the rest webservice
        String transactional_jsonInput = '{"Payload":{"TransactionalAccount":{"Status":"Active","Credit_Hold":false,"Account_Description":"Web","Account_Number":999776,"EBS_Party_Name":"Ricoh IT Solutions Co.,Ltd.","Sales_Channel":"WEBSTORE","EBS_Party_Number":2242303,"Sales_Account":381759,"Account_Type":"External"}},"Header":{"Operation":"Sync","Type":"TransactionalAccount","InstanceId":3900025,"EsbMessageGuid":"ej4-n6zy45xh-1-ygim24xh-b4vuw2-w6p7a","Timestamp":"2014-07-02T17:08:02"},"xmlns":"http://esb.redhat.com/Salesforce/1"}';
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(transactional_jsonInput);
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.debug('\n\n testPushInboundSrvc = ' + testPushInboundSrvc + '\n\n');
        
        //Test to see if we get an ID back from the service
        System.assertNotEquals(testPushInboundSrvc,NULL); //test a null response, we should not get NULL
        System.assertEquals(res.statuscode, 201); 
        
        //Ensure the ID prefix is the same as found for the Inbound Event object, if so, the record was inserted
        Schema.Describesobjectresult dsr = Inbound_Event__c.sObjectType.getDescribe();
        
        System.assertEquals(testPushInboundSrvc.substring(0, 3),dsr.getKeyPrefix()); 
                        
    }//end test method
    
    static testMethod void doPushInboundRecord_Single_Negative_Check_A() {
        //Negative test to ensure the callout fails without a request body
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.assertEquals(testPushInboundSrvc,'The request body is empty'); //test a null response, we should not get NULL
        System.assertEquals(res.statuscode, 500);
        
    }//end test method
    
    static testMethod void doPushInboundRecord_Single_Negative_Check_B() {
        //Negative test to ensure the callout fails without a Header
        String transactional_jsonInput = '{"Payload":{"TransactionalAccount":{"Status":"Active","Credit_Hold":false,"Account_Description":"Web","Account_Number":999776,"EBS_Party_Name":"Ricoh IT Solutions Co.,Ltd.","Sales_Channel":"WEBSTORE","EBS_Party_Number":2242303,"Sales_Account":381759,"Account_Type":"External"}}}';
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(transactional_jsonInput);
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.debug('\n\n testPushInboundSrvc B = ' + testPushInboundSrvc + '\n\n');
        
        //Test to see if we get an ID back from the service, we shouldn't
        System.assert(testPushInboundSrvc.contains('Header/Payload is missing in request'));
        System.assertEquals(res.statuscode, 500);
    }//end test method 
    
    static testMethod void doPushInboundRecord_Single_Negative_Check_C() {
        //Negative test to ensure the callout fails without a Payload
        String transactional_jsonInput = '{"Header":{"Operation":"Sync","Type":"TransactionalAccount","InstanceId":3900025,"EsbMessageGuid":"ej4-n6zy45xh-1-ygim24xh-b4vuw2-w6p7a","Timestamp":"2014-07-02T17:08:02"},"xmlns":"http://esb.redhat.com/Salesforce/1"}';
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(transactional_jsonInput);
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.debug('\n\n testPushInboundSrvc C = ' + testPushInboundSrvc + '\n\n');
        
        //We should get an error
        System.assert(testPushInboundSrvc.contains('Header/Payload is missing in request'));
        System.assertEquals(res.statuscode, 500); 
                        
    }//end test method
    
    static testMethod void doPushInboundRecord_Single_Negative_Check_D() {
        //Negative test, this time with an exceptionally long string; which should generate a dml error
        String exceptionallyLargeStr = 'jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj';
        String newExceptionallyLargeStr;
        
        for(Integer i = 0; i < 10; i++){
            newExceptionallyLargeStr += newExceptionallyLargeStr + exceptionallyLargeStr;
        }//end for
        
        String transactional_jsonInput = '{"Payload":{' + newExceptionallyLargeStr +'},"Header":{},"xmlns":"http://esb.redhat.com/Salesforce/1"}';
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(transactional_jsonInput);
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.debug('\n\n testPushInboundSrvc D = ' + testPushInboundSrvc + '\n\n');
        
        //This should be a field or invalid character error
        System.assertEquals(res.statuscode, 500); 
                        
    }//end test method
    
    static testMethod void doPushInboundRecord_Mulitple_Positive_Check_A() {
        //Positive test of the rest webservice with multiple records
        String transactional_jsonInput = '{"Payload":{"SalesAccount":{"Name":"Test org1022","Status":"Active","Phone":"","CDH_Party_type":"ORGANIZATION","All_NAICS_Codes":"","Website":"","Do_Not_Do_Business_with":false,"Fax":"","SEA_Concern":"","CDH_Party_Number":6264758,"Linkedin_URL":""}},"Header":{"Operation":"Party_Only_create","Type":"SalesAccount","InstanceId":7974778,"EsbMessageGuid":"em4-v0k8bdxh-1-pj0vc6xh-vn7mju-w6p7a","System":"CDH","Timestamp":"2014-07-08T10:25:27"},"xmlns":"http://esb.redhat.com/Salesforce/1"}';
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(transactional_jsonInput);
        RestContext.request = req;
        RestContext.response = res;
        
        List<String> insertedRecordlst = new List<String>();
        List<String> errorRecordlst = new List<String>();
        
        for(Integer i = 0; i<150; i++){
            String testPushInboundSrvc;
            testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
            if(res.statuscode == 201)
                insertedRecordlst.add(testPushInboundSrvc);
            else
                errorRecordlst.add(testPushInboundSrvc);
        }//end for loop
        
        test.stopTest();
        
        Map<Id,Inbound_Event__c> ieMap = new Map<Id,Inbound_Event__c>([SELECT Id, Name FROM Inbound_Event__c WHERE Id IN: insertedRecordlst]);
        
        System.assertEquals(ieMap.size(), insertedRecordlst.size());
                                
    }//end test method

    static testMethod void doPushInboundRecord_500_Line_Order() {
        //Positive test of the rest webservice with a large order message
        StaticResource jsonMessage = [SELECT Name, Body FROM StaticResource WHERE Name = 'JSONOrderLarge1' LIMIT 1];
        Blob order_jsonInput = jsonMessage.Body;
        test.startTest();   
        
        Restrequest req = new Restrequest();
        Restresponse res = new Restresponse();
        
        req.requestURI = '/services/apexrest/InboundPush';  
        req.httpMethod = 'POST';
        req.requestBody = order_jsonInput;
        RestContext.request = req;
        RestContext.response = res;
        
        String testPushInboundSrvc;
        testPushInboundSrvc = InboundEventPushService.doPushInboundRecord(); //make the callout
        test.stopTest();
        
        System.debug('\n\n testPushInboundSrvc = ' + testPushInboundSrvc + '\n\n');
        
        //Test to see if we get an ID back from the service
        System.assertNotEquals(testPushInboundSrvc,NULL); //test a null response, we should not get NULL
        System.assertEquals(res.statuscode, 201); 
        
        //Ensure the ID prefix is the same as found for the Inbound Event object, if so, the record was inserted
        Schema.Describesobjectresult dsr = Inbound_Event__c.sObjectType.getDescribe();
        
        System.assertEquals(testPushInboundSrvc.substring(0, 3),dsr.getKeyPrefix());        
    }//end test method
}//end test class