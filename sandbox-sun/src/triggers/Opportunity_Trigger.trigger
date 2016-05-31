/*****************************************************************************************
    Name    : Opportunity_Trigger
    Desc    : This trigger is used to perform different complex business logic for different events.
              1.) Invoke the method to populate the look up fields on cloned opportunity record.(Momentum Ticket Number : RH-00343836)
                       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer                 Date            Description
---------------------------------------------------------------------------
    Vipul Jain               03 SEP 2014      Created (Momentum Ticket Number : RH-00343836)
    Scott Coleman            01 JAN 2015      Added closed opp backout trigger
    Anshul Kumar             29 APR 2015      US67021
    Bill Riemers             07 AUG 2015      Moved to the OpportunityTriggerBefore2 and OpportunityTriggerAfter2 classes
******************************************************************************************/
trigger Opportunity_Trigger on Opportunity (before insert, before update, after update) {
//depreciated	    
//depreciated	    if(trigger.isbefore && trigger.isinsert){ // apply this extra safeguard as extra events might be added in future
//depreciated	        if(BooleanSetting__c.getInstance('Opportunity_Trigger') != null && BooleanSetting__c.getInstance('Opportunity_Trigger').Value__c == true){
//depreciated	            // List of the opportunity which created after being cloned from existing opportunity.
//depreciated	            List<Opportunity> listOfClonedOpportunity = new List<Opportunity>();
//depreciated	            
//depreciated	            // iterating on the newly created opportunity records and prepare list of opportunities which are being created from 
//depreciated	            for(Opportunity opportunity : trigger.new){
//depreciated	                if(opportunity.Cloned_From_Opportunity__c != Null){
//depreciated	                    listOfClonedOpportunity.add(opportunity);
//depreciated	                }
//depreciated	            }
//depreciated	            // call the method to copy the ready only look up fields on cloned opportunity records.
//depreciated	            if(listOfClonedOpportunity.size()>0){
//depreciated	               Opportunity_Trigger_Handler.copyReadOnlyFieldsOnClonedOpportunity(listOfClonedOpportunity);
//depreciated	            }
//depreciated	        }
//depreciated	    }

//depreciated	    if(trigger.isbefore && trigger.isupdate){
//depreciated	        if(BooleanSetting__c.getInstance('Opportunity_Trigger') != null && BooleanSetting__c.getInstance('Opportunity_Trigger').Value__c == true){
//depreciated	            List<Opportunity> listOfBackedOutOpportunity = new List<Opportunity>();

//depreciated	            for(Opportunity opportunity : trigger.new){
//depreciated	                Opportunity oldOpportunity = trigger.oldMap.get(opportunity.Id);

//depreciated	                if(opportunity.RecordTypeId != oldOpportunity.RecordTypeId) {
//depreciated	                    opportunity.Previous_Record_Type__c = oldOpportunity.RecordTypeId;
//depreciated	                }

//depreciated	                if(opportunity.StageName == 'Negotiate' 
//depreciated	                    && (oldOpportunity.StageName == 'Closed Won' || oldOpportunity.StageName == 'Closed Booked')) {

//depreciated	                    listOfBackedOutOpportunity.add(opportunity);
//depreciated	                }
//depreciated	            }

//depreciated	            if(!listOfBackedOutOpportunity.isEmpty()){
//depreciated	                Opportunity_Trigger_Handler.backOutOpportunity(listOfBackedOutOpportunity);
//depreciated	            }
//depreciated	        }
//depreciated	    }
//depreciated	    
//depreciated	    if(trigger.isAfter && trigger.isUpdate){
//depreciated	        if(BooleanSetting__c.getInstance('Opportunity_Trigger') != null && BooleanSetting__c.getInstance('Opportunity_Trigger').Value__c == true)
//depreciated	            Opportunity_Trigger_Handler.createEventRecords();
//depreciated	    }
}