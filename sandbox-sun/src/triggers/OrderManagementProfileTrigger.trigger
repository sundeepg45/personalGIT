/*****************************************************************************************
    Name    : OrderManagementProfileTrigger
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer                Date                 Description
---------------------------------------------------------------------------
 Anshul Kumar             12 Jan, 2015         Created (US60986)
******************************************************************************************/
trigger OrderManagementProfileTrigger on Order_Management_Profile__c (before Insert) {
  
  //call utility method to append date to Name and check for previous primary OMP  
    OrderManagementProfileUtility.checkDefault_appendDate(Trigger.new);
}