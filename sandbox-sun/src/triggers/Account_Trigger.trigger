/*****************************************************************************************
    Name    : Account_Trigger
    Desc    : 1. This trigger will fire after insertion or after updation of a record on Sales Account object.
              All field values will get parsed using it's handler class Account_Create_Update_JSON_triggHelper and 
              will be saved in outBound_Staging_Tabel object, after this creation/updation a notification 
              link will be send to data team.
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Neha Jaiswal          06/10/2014          Created
 Vipul Jain            08 AUG 2014         By pass the duplicate check validation for Integration admin(Momentum defect Number : RH-00343524 )
 Anshul Kumar          28 APR 2015         US67021
******************************************************************************************/

trigger Account_Trigger on Account (after insert, after update) {
    
    /*invoke handler class method whenever a new Sales Account is created
    Invoking this method will call checkDuplicateAccount method of Class DuplicateCheckOnSalesAccount which prevents duplicate sales Accounts from being inserted*/
    if(((trigger.isafter && trigger.isinsert)) ||(trigger.isafter && trigger.isUpdate)){  
        
        //Account_Trigger_Handler.CheckDuplicateAcount(trigger.Newmap);
    }        
    
    /*invoke helper class method whenever a address record is updated , then roll up summary field on account will be updated and the account information along with address record
    would be passed as message into outbound service class.
    When user will update any account record in SFDC Itself , then this method will send account message to outbound service.*/  
    if(trigger.isafter && trigger.isUpdate){
        
        Account_Trigger_Handler.SalesAccount_Outbound_Message(Trigger.newMap,Trigger.oldMap);      
    }
    
    if(trigger.isAfter && trigger.isUpdate){
        
        Account_Trigger_Handler.createEventRecords();      
    }
}