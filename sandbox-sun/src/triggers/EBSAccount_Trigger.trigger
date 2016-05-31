/**
 *  
 *
 * @version 2015-02-23
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2015-02-23 - Created
 */
trigger EBSAccount_Trigger on EBS_Account__c (after Insert, after Update) {
//depreciated    
//depreciated    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate) && 
//depreciated       BooleanSetting__c.getInstance('EBSAccountTrigger.updtEBSaccNmbrOnAcc') != NULL &&
//depreciated       BooleanSetting__c.getInstance('EBSAccountTrigger.updtEBSaccNmbrOnAcc').Value__c){
//depreciated        
//depreciated      //call the handler method to update the parent account with EBS Account numbers
//depreciated        EBSAccount_TriggerHandler.updateEBSaccNumberOnAccount();
//depreciated    }
}