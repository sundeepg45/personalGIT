/*****************************************************************************************
    Name    : Contact_Trigger 
    Desc    : This trigger is used to perform various business process on contact
              1.) Send the outbound message when new account created or existing contact updated.
               .
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Vipul Jain          23 JULY 2014         Created
 Bill C Riemers      12 AUG 2015          Depreciated (replaced with Contact_After trigger)
******************************************************************************************/

trigger Contact_Trigger on Contact(after insert, after update){
//depreciated	    
//depreciated	    /* invoke different method for insert and update from the future prospective 
//depreciated	    (as there might be different functionality required based on insert or update in future)*/
//depreciated	    
//depreciated	    // New contact scenario
//depreciated	    if(trigger.isafter && trigger.isinsert){
//depreciated	    
//depreciated	        // Invoke the method to send outbound message of Contact_Trigger_Handler class.
//depreciated	        Contact_Trigger_Handler.Contact_Outbound_Message(trigger.newmap , trigger.oldmap);
//depreciated	    }
//depreciated	    
//depreciated	    // Contact update scenario.
//depreciated	    if(trigger.isafter && trigger.isupdate){
//depreciated	        
//depreciated	        /* Invoke the method to send outbound message of Contact_Trigger_Handler class.
//depreciated	            This method will not be invoked , when Integration Admin user have updated existing contact records.*/
//depreciated	        if((userInfo.getFirstName()+ ' '+ userInfo.getLastName()) != 'Integration Admin'){
//depreciated	            Contact_Trigger_Handler.Contact_Outbound_Message(trigger.newmap , trigger.oldmap);
//depreciated	        }
//depreciated	    }
}