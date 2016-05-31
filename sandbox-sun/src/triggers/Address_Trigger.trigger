/*****************************************************************************************
    Name    : Address_Trigger 
    Desc    : This trigger will handle the logic to process different business logic on address records.
             
                       
                            
Modification Log : 
---------------------------------------------------------------------------
    Developer       Date                Description
---------------------------------------------------------------------------
    Vipul Jain      06 June 2014        Created
    Bill C Riemers  12 November 2015    Depreciated - Refactored into the Address_After class
******************************************************************************************/

trigger Address_Trigger on Address__c (after insert, after update) {   
//depreciated    
//depreciated    // Logic to handle newly created address record.
//depreciated    if(trigger.isInsert) {
//depreciated    
//depreciated        // Invoke method to send outbound message to the outbound service class
//depreciated        Address_Trigger_Handler.Address_Outbound_Message(Trigger.newmap, trigger.oldmap);
//depreciated        
//depreciated        /* Invoke method to set the identfying address i.e. 
//depreciated        If a identifying address record created/update under one sales account which has already one identifying address , 
//depreciated        then set this identifying address as false on previous identifying address record.*/
//depreciated        
//depreciated        Address_Trigger_Handler.SetIdentifyingAddress(trigger.newmap);   
//depreciated    }
//depreciated     
//depreciated    // logic to handle updated address records. 
//depreciated    if(trigger.isUpdate) {
//depreciated        
//depreciated        /* Invoke method to set the identfying address i.e. 
//depreciated        If a identifying address record created/update under one sales account which has already one identifying address , 
//depreciated        then set this identifying address as false on previous identifying address record.*/
//depreciated        
//depreciated        Address_Trigger_Handler.SetIdentifyingAddress(trigger.newmap); 
//depreciated    }
}