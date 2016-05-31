/*****************************************************************************************
    Name    : Opportunity_Trigger_Handler
    Desc    : This class will act as helper class for Opportunity trigger to process different business logic related to Opportunity
              1.) Invoke the method to populate the look up fields on cloned opportunity record.
                       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer                 Date            Description
---------------------------------------------------------------------------
    Vipul Jain               03 SEP 2014      Created  (Momentum Ticket Number : RH-00343836)
    Scott Coleman            01 JAN 2015      Added closed opp backout trigger handler
    Anshul Kumar             29 APR 2015      US67021
    Bill C Riemers           07 AUG 2015      Moved to the the OpportunityTriggerBefore2 and OpportunityTriggerAfter2 classes
******************************************************************************************/
@IsTest
private /* depreciated public with sharing */ class Opportunity_Trigger_Handler {

//depreciated	    /* Method to copy the lookup fields on the cloned opportunity record , 
//depreciated	    because some fields are read only for user and those would not be copied by default. */
//depreciated	    
//depreciated	    public Static void copyReadOnlyFieldsOnClonedOpportunity(List<Opportunity> opportunityList){
//depreciated	        
//depreciated	        // set to hold all the parent opportunity from which opportunity records are being cloned.
//depreciated	        Set<Id> setofClonedFromOpportunityId = new Set<Id>();
//depreciated	        
//depreciated	        // iteration on all the opportunities records being created.
//depreciated	        for(Opportunity opportunity : opportunityList){
//depreciated	            
//depreciated	            // prepare the set of all parent opportunity ids.
//depreciated	            setofClonedFromOpportunityId.add(opportunity.Cloned_From_Opportunity__c);
//depreciated	        }
//depreciated	        
//depreciated	        // query all the parent opportunity records while creating new opportunity records after cloning.
//depreciated	        Map<Id,Opportunity> mapOfIdAndOpportunity = new Map<Id,Opportunity>([Select Bill_To_Sales_Account__c,
//depreciated	                                                                                Bill_To_Account__c,
//depreciated	                                                                                Bill_To_Address__c,
//depreciated	                                                                                Bill_To_Contact__c,
//depreciated	                                                                                Entitle_To_Sales_Account__c,
//depreciated	                                                                                Entitle_To_Account__c,
//depreciated	                                                                                Entitle_To_Address__c,
//depreciated	                                                                                Entitle_To_Contact__c,
//depreciated	                                                                                Ship_To_Sales_Account__c,
//depreciated	                                                                                Ship_To_Account__c,
//depreciated	                                                                                Ship_To_Address__c,
//depreciated	                                                                                Ship_To_Contact__c,
//depreciated	                                                                                Sold_To_Sales_Account__c,
//depreciated	                                                                                Sold_To_Account__c,
//depreciated	                                                                                Sold_To_Address__c,
//depreciated	                                                                                Sold_To_Contact__c
//depreciated	                                                                                 from Opportunity 
//depreciated	                                                                                where Id in :setofClonedFromOpportunityId]);
//depreciated	        // iteration on the opportunity being created after cloning.
//depreciated	        for(Opportunity opportunity:opportunityList){
//depreciated	            
//depreciated	            // set the lookup fields after getting lookup fields from the parent opportunity record.
//depreciated	            opportunity.Bill_To_Sales_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Bill_To_Sales_Account__c;
//depreciated	            opportunity.Bill_To_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Bill_To_Account__c;
//depreciated	            opportunity.Bill_To_Address__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Bill_To_Address__c;
//depreciated	            opportunity.Bill_To_Contact__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Bill_To_Contact__c;
//depreciated	            opportunity.Entitle_To_Sales_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Entitle_To_Sales_Account__c;
//depreciated	            opportunity.Entitle_To_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Entitle_To_Account__c;
//depreciated	            opportunity.Entitle_To_Address__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Entitle_To_Address__c;
//depreciated	            opportunity.Entitle_To_Contact__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Entitle_To_Contact__c;
//depreciated	            opportunity.Ship_To_Sales_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Ship_To_Sales_Account__c;
//depreciated	            opportunity.Ship_To_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Ship_To_Account__c;
//depreciated	            opportunity.Ship_To_Address__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Ship_To_Address__c;
//depreciated	            opportunity.Ship_To_Contact__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Ship_To_Contact__c;
//depreciated	            opportunity.Sold_To_Sales_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Sold_To_Sales_Account__c;
//depreciated	            opportunity.Sold_To_Account__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Sold_To_Account__c;
//depreciated	            opportunity.Sold_To_Address__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Sold_To_Address__c;
//depreciated	            opportunity.Sold_To_Contact__c = mapOfIdAndOpportunity.get(opportunity.Cloned_From_Opportunity__c).Sold_To_Contact__c;
//depreciated	       }
//depreciated	    }

//depreciated	    // static set of Ids of opps that have already been backed out to prevent multiple updates
//depreciated	    public static Set<Id> backedOutOpps = new Set<ID>();

//depreciated	    public static void backOutOpportunity(List<Opportunity> opportunityList){
//depreciated	        Map<Id,RecordType> recordTypeMap = new Map<Id,RecordType>();
//depreciated	        for (RecordType recordType : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Opportunity']) {
//depreciated	            recordTypeMap.put(recordType.Id, RecordType);
//depreciated	        }
//depreciated	        Boolean needRecordTypeId = true;
//depreciated	        Id bookedOppProcessRecordTypeId = null;
//depreciated	        List<Order_Tracking__c> orderTrackingRecords = new List<Order_Tracking__c>();

//depreciated	        for(Opportunity opportunity:opportunityList){
//depreciated	            if(!backedOutOpps.contains(opportunity.Id)) {

//depreciated	                //Reset opportunity fields
//depreciated	                opportunity.Order_Status__c = 'Reverted';
//depreciated	                opportunity.Pending_OM_Review__c = false;
//depreciated	                opportunity.OM_review_complete__c = false;
//depreciated	                opportunity.DateOrderSubmitted__c = null;

//depreciated	                //Reset opportunity record type (if found)
//depreciated	                if(opportunity.Previous_Record_Type__c != null) {
//depreciated	                    if(needRecordTypeId) {
//depreciated	                        needRecordTypeId = false;
//depreciated	                        bookedOppProcessRecordTypeId = RecordTypeLookup.getRecordTypeId('Booked Opp Process','Opportunity');
//depreciated	                    }
//depreciated	                    if(bookedOppProcessRecordTypeId != null && opportunity.RecordTypeId == bookedOppProcessRecordTypeId).Name == 'Booked Opp Process') {
//depreciated	                    
//depreciated	                    try {
//depreciated	                        opportunity.RecordTypeId = Id.valueOf(opportunity.Previous_Record_Type__c);
//depreciated	                    }
//depreciated	                    catch(Exception ex) {}
//depreciated	                    }
//depreciated	                }

//depreciated	                //Create Order Tracking Record
//depreciated	                Order_Tracking__c orderTrackingRecord = new Order_Tracking__c();
//depreciated	                orderTrackingRecord.Opportunity__c = opportunity.Id;
//depreciated	                orderTrackingRecord.Opportunity_Owner__c = opportunity.OwnerId;
//depreciated	                orderTrackingRecord.Opportunity_Stage__c = opportunity.StageName;
//depreciated	                orderTrackingRecord.Oracle_Order_Number__c = opportunity.OracleOrderNumber__c ;
//depreciated	                orderTrackingRecord.Order_Status__c = opportunity.Order_Status__c ;
//depreciated	                orderTrackingRecord.Submitted_By__c = userInfo.getUserId();
//depreciated	                orderTrackingRecord.Submitted_Date__c = System.Now();
//depreciated	                orderTrackingRecords.add(orderTrackingRecord);

//depreciated	                backedOutOpps.add(opportunity.Id);
//depreciated	            }
//depreciated	        }

//depreciated	        if(!orderTrackingRecords.isEmpty()) {
//depreciated	            Database.insert(orderTrackingRecords, false);
//depreciated	        }
//depreciated	    }
//depreciated	    
//depreciated	    /**
//depreciated	    *This is the method invoked to enter new event records on change of ownership on Opportunity (US67021).
//depreciated	    *@param :
//depreciated	    *@return :    
//depreciated	    */
//depreciated	    public static void createEventRecords(){
//depreciated	       //collect all the Opportunity records with changed owner
//depreciated	        set<Id> setOppIds = new set<Id>();
//depreciated	        Opportunity oppInst;
//depreciated	        for(SObject opp : trigger.new){
//depreciated	            
//depreciated	            oppInst = (Opportunity) opp; 
//depreciated	            if(oppInst.OwnerId != ((Opportunity) trigger.oldMap.get(oppInst.Id)).OwnerId)
//depreciated	                setOppIds.add(opp.Id);
//depreciated	        }
//depreciated	        
//depreciated	       //create map opportunity id and corresponding event record 
//depreciated	        map<Id, Event__c> mapOppId_Event = new map<Id, Event__c>();
//depreciated	        for(Event__c eventInst : [SELECT Opportunity__c FROM Event__c WHERE Opportunity__c IN: setOppIds AND Processed__c = FALSE]){
//depreciated	            
//depreciated	            mapOppId_Event.put(eventInst.Opportunity__c, eventInst);
//depreciated	        } 
//depreciated	        
//depreciated	       //create new records in Event 
//depreciated	        list<Event__c> lstEvent = new list<Event__c>();
//depreciated	        Event__c eventInst;
//depreciated	        for(Id oppId : setOppIds){
//depreciated	            
//depreciated	            if(mapOppId_Event.get(oppId) == NULL){
//depreciated	                
//depreciated	                eventInst = new Event__c();
//depreciated	                eventInst.Opportunity__c = oppId;
//depreciated	                lstEvent.add(eventInst);
//depreciated	            }
//depreciated	        }
//depreciated	        
//depreciated	        Database.insert(lstEvent, FALSE); 
//depreciated	    }
}