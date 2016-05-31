/** 
  * This trigger is used to prevent sales users to delete Notes
  * if its corresponding Opportunity is in Closed Booked or Closed Won Stage 
  * 
  * @version 2014-12-10 
  * @author Niti Bansal <nibansal@redhat.com> 
  * 2014-12-10 - Created 
  */
trigger Note_Trigger on Note (before delete) {

    if(Trigger.isBefore && Trigger.isDelete)
    {
        if(BooleanSetting__c.getInstance('Note_Before.processRestrictDeletion') != null && BooleanSetting__c.getInstance('Note_Before.processRestrictDeletion').Value__c == true)
        {
            Note_TriggerHandler.processRestrictDeletion(Trigger.oldMap);
        }
       
    }

}