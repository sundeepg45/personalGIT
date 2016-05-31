/*****************************************************************************************
    Name    : PartnerProgram_Trigger
    Desc    : 1. This trigger will get fired when a partner program will be created/ updated for an partner account.
                 It will also pass the details from program definition object and will call the handler class.

Modification Log :
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Neha Jaiswal         10/07/2014           Created
 Tiaan Kruger         2/23/2015            Make trigger execute if the boolean setting is missing

******************************************************************************************/

trigger PartnerProgram_Trigger on Partner_Program__c(before insert , after insert , before update ,after update, before delete) {
    /* This trigger holds the logic when any partner program is created or updated for a partner account.
        It holds the methods for created or updated program partners.
    */
    PartnerProgram_Trigger_Handler triggerhandler = new PartnerProgram_Trigger_Handler();
    if(BooleanSetting__c.getInstance('PartnerProgram_Trigger') == null || (BooleanSetting__c.getInstance('PartnerProgram_Trigger') != null && BooleanSetting__c.getInstance('PartnerProgram_Trigger').Value__c == true)){

        if(trigger.isafter ){
        	//if user is not integration admin, then this trigger should get fired.
        	if(userInfo.getName() != 'Integration Admin'){
	            //if a partner program is inserted for an account.
	            if(trigger.isInsert){
	                triggerhandler.AfterInsert(trigger.newmap);
	            }

	            //if a partner program is updated for an account.
	            if(trigger.isUpdate){
	                triggerhandler.AfterUpdate(trigger.newmap, trigger.oldmap);
	            }
        	}
        }

        if(trigger.isBefore){

            //if a partner program is deleted from an account.
            if(trigger.isDelete){
                triggerhandler.AfterDelete(trigger.oldmap);
            }

            if(trigger.isInsert || trigger.isUpdate){
                triggerhandler.AssignPartnerDetailsToIntegrationObject(trigger.old , trigger.new);
                system.debug('dfdfdfsdfdftyyutu');
            }
        }

    }
}