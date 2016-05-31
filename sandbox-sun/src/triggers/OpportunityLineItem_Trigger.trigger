/** 
  * This trigger is used to prevent sales users to delete OpportunityProducts
  * if its corresponding Opportunity is in Closed Booked or Closed Won Stage 
  * Deactivate Quotes when a record is inserted, updated or deleted
  * 
  * @version 2015-10-28 
  * @author Sagar Mehta <samehta@redhat.com> 
  * 2014-12-09 - Created 
  * Pankaj Banik    <pbanik@redhat.com>
  * 2014-12-12
  * Bill Riemers <briemers@redhat.com>
  * 2015-10-28 - Move methods into before and after trigger classes
  */
trigger OpportunityLineItem_Trigger on OpportunityLineItem (after insert,after update,before delete, before insert, before update) {
//depreciated    if(BooleanSetting__c.getInstance('OpportunityLineItem_Trigger') != null && BooleanSetting__c.getInstance('OpportunityLineItem_Trigger').Value__c == true){
//depreciated        if(Trigger.isBefore && Trigger.isDelete){
//depreciated            ProcessBookedOpportunityProducts.processOpportunityProducts(Trigger.oldMap);
//depreciated        }
//depreciated        
//depreciated        //Deactivating Quotes
//depreciated        if (trigger.isUpdate && trigger.isAfter){
//depreciated           OpportunityLineItem_Trigger_Handler.deactivateQuotesOnUpdate(Trigger.oldMap,Trigger.newMap);
//depreciated        }
//depreciated    }
}