/** 
  * This trigger is used to prevent sales users to delete Event
  * if its corresponding Opportunity is in Closed Booked or Closed Won Stage 
  * 
  * @version 2014-12-10 
  * @author Niti Bansal <nibansal@redhat.com> 
  * 2014-12-10 - Created 
  */
trigger Event_Trigger on Event (before delete) {

    if(Trigger.isBefore && Trigger.isDelete)
    {
        if(BooleanSetting__c.getInstance('Event_Before.processRestrictDeletion') != null && BooleanSetting__c.getInstance('Event_Before.processRestrictDeletion').Value__c == true)
        {
            Event_TriggerHandler.processRestrictDeletion(Trigger.oldMap);
        }
    }

}