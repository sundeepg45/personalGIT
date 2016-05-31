/** 
  * This trigger is used to prevent sales users to delete Task
  * if its corresponding Opportunity is in Closed Booked or Closed Won Stage 
  * 
  * @version 2014-12-10 
  * @author Niti Bansal <nibansal@redhat.com> 
  * 2014-12-10 - Created 
  */
trigger Task_Trigger on Task (before delete) {

    if(Trigger.isBefore && Trigger.isDelete)
    {
        if(BooleanSetting__c.getInstance('Task_Before.processRestrictDeletion') != null && BooleanSetting__c.getInstance('Task_Before.processRestrictDeletion').Value__c == true)
        {
            Task_TriggerHandler.processRestrictDeletion(Trigger.oldMap);
        }
     
    }

}