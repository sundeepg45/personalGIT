/*****************************************************************************************
    Name    : Order_Inbound_Service 
    Desc    : This class defines the logic for  inserts operation into Opportunity, partner and line Items staging objects           
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik         26 JULY 2014          Created

Vipul Jain           06 OCT 2014           Updated : Removed error logging process from this class as the logic is in the Order_Opportunity_Matching logic
Scott Coleman        10 DEC 2014           Updated to move Product2 SOQL query out of line item loop to allow processing of large orders within governor limits
                     14 JUL 2015           US70316 Now setting origin value on staging record
******************************************************************************************/

public with sharing class Order_Inbound_Service {
    static final String PENDING_BOOKED_ORDER_PROCESS = 'Pending Booked Order Process';
    
    public  void OpportunityStagingSync (IntegrationObjects.Order ioOrder){
        try{
        
            
            Opportunity_Header_Staging__c opportunityStaging = new Opportunity_Header_Staging__c();
            
            //Changes made for creating booked order when directly invoice order comes for the first time.
            List<Opportunity_Header_Staging__c> relatedOHSRecord = new List<Opportunity_Header_Staging__c>();
            Opportunity_Header_Staging__c opportunityStagingBookedOrder = new Opportunity_Header_Staging__c();
            List<Opportunity_Header_Staging__c> listInvoiceBookedOrders = new List<Opportunity_Header_Staging__c>();
            //Set<Id> oppIds = new Set<Id>();
                        
            // Retrieve Opportunity Staging data
            opportunityStaging = SystemObjectConverter.ConvertioOrder(ioOrder);
            opportunityStaging.Origin__c = 'Order Integration';
            opportunityStaging.Status__c = 'Not Processed' ;
            //Added for US60577
            boolean oppProcessFlag=true;
            boolean oppProcessDiscardFlag=False;
            if(opportunityStaging.Order_Status__c == 'Invoiced' || opportunityStaging.Order_Status__c == 'Closed'){
                List<Opportunity_Header_Staging__c> relatedOHSRecordAll=[select id,name,Oracle_Order_Number__c,Order_Status__c,Status__c from Opportunity_Header_Staging__c where Oracle_Order_Number__c=:opportunityStaging.Oracle_Order_Number__c AND (Order_Status__c =: 'Booked' OR Order_Status__c =: 'Invoiced')];
                for(Opportunity_Header_Staging__c oHS:relatedOHSRecordAll){
                    if(oHS.Order_Status__c == 'Invoiced'){
                        oppProcessDiscardFlag=true;
                    }
                    if(oHS.Order_Status__c == 'Booked'){
                        relatedOHSRecord.add(OHS);
                    }
                }
                if(relatedOHSRecord.size()==0){ 
                    oppProcessFlag=false;
                    opportunityStaging.Status__c =PENDING_BOOKED_ORDER_PROCESS;                    
                }else{
                    for(Opportunity_Header_Staging__c relatedOHSRec:relatedOHSRecord){
                        if(relatedOHSRec.Status__c == 'Error' || relatedOHSRec.Status__c == 'Not Processed'){
                            oppProcessFlag=false;
                            opportunityStaging.Status__c =PENDING_BOOKED_ORDER_PROCESS;
                        }
                    }
                }
            }else if(opportunityStaging.Order_Status__c == 'BOOKED'){
                List<Opportunity_Header_Staging__c> relatedOHSRecordAll=[select id,name,Oracle_Order_Number__c,Order_Status__c,Status__c from Opportunity_Header_Staging__c where Oracle_Order_Number__c=:opportunityStaging.Oracle_Order_Number__c AND Order_Status__c =: 'Booked'];
                if(!relatedOHSRecordAll.isEmpty()){
                    oppProcessDiscardFlag=true;
                }
            }
             if(!oppProcessDiscardFlag){         
                /*Querying for User details for Opportunity Owner 
                List <User> users = [Select id from User where EmployeeNumber =:opportunityStaging.Employee_Number__c and EmployeeNumber != Null and EmployeeNumber !='' and isactive=true];
               
               
                if (users.size()>0){
                    opportunityStaging.Opportunity_Owner__c = users[0].id;
                }*/
                //Querying for Opportunity record for the Order information sent
                List <Opportunity> opportunities = new List <Opportunity> () ; 
               if(opportunityStaging.Opportunity_Number__c !=null){
                    opportunities = [Select id , AccountId,OwnerId from Opportunity where id =:opportunityStaging.Opportunity_ID__c or OpportunityNumber__c =: opportunityStaging.Opportunity_Number__c];          
               
               }
                
                if (opportunities.size() >0 ){
                    //Assigning the Opportunity record to the Opportunity Staging record
                    opportunityStaging.Opportunity_Name__c = opportunities[0].id ;
                    //Assigning the Sales Account record to the Opportunity Staging record
                    opportunityStaging.Sales_Account__c = opportunities[0].AccountId ;
                    opportunityStaging.Opportunity_Owner__c = opportunities[0].OwnerId;
                }
                
                //Insert the Opportunity Staging record
                //Added for case when we get only Invoiced message from EBS, not Booked Message.
                listInvoiceBookedOrders.add(opportunityStaging);
                if(relatedOHSRecord.size()==0 && opportunityStaging.Order_Status__c == 'Invoiced'){
                    opportunityStagingBookedOrder = opportunityStaging.clone();
                    opportunityStagingBookedOrder.Status__c = 'Not Processed' ;
                    opportunityStagingBookedOrder.Order_Status__c ='BOOKED' ;
                    listInvoiceBookedOrders.add(opportunityStagingBookedOrder);
                    
                }
                insert listInvoiceBookedOrders;
                
                List <Opportunity_Partner_Staging__c> partnerStagingList = new List <Opportunity_Partner_Staging__c> ();
                Set<String> productCodes = new Set<String>();
                List <Opportunity_Line_Staging__c> lineStagingList = new List <Opportunity_Line_Staging__c> ();
                for(Opportunity_Header_Staging__c stagingObj :  listInvoiceBookedOrders)
                {
                    //Check if partner staging data is null or not
                    if (!ioOrder.OrderPartners.isempty()){
                        // Retrieve Partner line items record
                        
                        for (IntegrationObjects.OrderPartner orderPartner : ioOrder.OrderPartners){
        
                            Opportunity_Partner_Staging__c partnerStaging = new Opportunity_Partner_Staging__c ();
                            partnerStaging = SystemObjectConverter.ConvertioOrderPartner(orderPartner);
                            partnerStaging.Opportunity_Stage_Header_ID__c = stagingObj.Id ;
                            partnerStaging.Oracle_Order_Header_Id__c = stagingObj.Oracle_Order_ID__c;
                            partnerStagingList.add(partnerStaging);
                        }
                    }
                   
                    if (!ioOrder.OrderLines.isempty()){
        
                        // Retrieve Line Items record
                        for (IntegrationObjects.OrderLine orderLine : ioOrder.OrderLines){
                            Opportunity_Line_Staging__c lineStaging = new Opportunity_Line_Staging__c ();
                            lineStaging = SystemObjectConverter.ConvertioOrderLine(orderLine);
                            lineStaging.Opportunity_Stage_Header_ID__c = stagingObj.Id ;
                            lineStaging.Opportunity_ID__c = stagingObj.Opportunity_ID__c ;
                            lineStaging.CurrencyIsoCode = stagingObj.CurrencyIsoCode ;
                            if (lineStaging.Opportunity_Number__c == null ){                        
                                lineStaging.Opportunity_Number__c = stagingObj.Opportunity_Number__c ; 
                            }
                            lineStaging.Oracle_Order_Header_Id__c = stagingObj.Oracle_Order_ID__c;
                            lineStaging.Total_Price__c = lineStaging.UnitPrice__c * lineStaging.Quantity__c ; 
                            
                            // Adding oracle product code to list
                            productCodes.add(lineStaging.Product_Code_Oracle__c);
                            lineStagingList.add(lineStaging);
                        }
                   }
    
                }
                //Inserting partner staging data
                if(!partnerStagingList.isempty()){
                    system.debug('==========================================================>'+partnerStagingList.size());
                    database.Insert(partnerStagingList);
                }         
                

                // Retrive map of SFDC product Ids
                Map<String, Id> productMap = new Map<String, Id>();
                for (Product2 product : [Select id, ProductCode from Product2 where ProductCode in :productCodes and Product2.isActive = true]) {
                    productMap.put(product.ProductCode, product.Id);
                }
        
                // Add SFDC product Id to each staging line item
                for (Opportunity_Line_Staging__c lineStaging : lineStagingList) {
                    lineStaging.Product_Code__c = productMap.get(lineStaging.Product_Code_Oracle__c);
                }
                //Inserting line items staging data
                if(!lineStagingList.isempty()){
                    system.debug('==========================================================>'+lineStagingList.size());
                    database.Insert(lineStagingList);
                }
                system.debug('========================================================================>'+oppProcessFlag);
                system.debug('========================================================================>'+listInvoiceBookedOrders[0].Order_Status__c);
                List <Opportunity_Header_Staging__c> stagingList = new List<Opportunity_Header_Staging__c>();
                if(relatedOHSRecord.size()==0 && listInvoiceBookedOrders[0].Order_Status__c == 'Invoiced'){
                    if(listInvoiceBookedOrders.size() >1){
                            system.debug('==========================================================>'+listInvoiceBookedOrders.size());
                            system.debug('Dummy Booked Order ID==========================================================>'+listInvoiceBookedOrders[1].Id);
                            stagingList = Order_Opportunity_Matching.queryOrders(new Set<Id>{listInvoiceBookedOrders[1].Id});
                            System.debug('================================================> record being processed for booked');
                            // Call Opportunity Service
                            Order_Opportunity_Matching opportunityMatchingHeader = new Order_Opportunity_Matching () ;
                            opportunityMatchingHeader.processOrders(stagingList) ;  
                     }
                }else{    
                    stagingList = Order_Opportunity_Matching.queryOrders(new Set<Id>{opportunityStaging.Id});
                    if(oppProcessFlag){  
                        // Call Opportunity Service
                        Order_Opportunity_Matching opportunityMatching = new Order_Opportunity_Matching () ;
                        opportunityMatching.processOrders(stagingList) ;   
                    }
                }
           }
                            
        }
        catch (Exception e) {
            //database.rollback(savepoint);
            System.debug(e.getmessage());
        }
    }
}