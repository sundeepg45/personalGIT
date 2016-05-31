/**
 *  This trigger will fire after insertion or after updation of a record on legacy Opportunity Partner object.
 *  This will initiate the insert/update logic for copying data from legacy Opportunity Partner object to the new object.
 * As per User Story US56675
 *
 * @version 2014-10-31
 * @author Pankaj Banik   <pbanik@deloitte.com>
 * 2014-10-31 - Created
 */
trigger OpportunityPartner_Trigger on OpportunityPartner__c (after insert, after update, before delete) {
    
    /*invoke handler class method whenever a new Opportunity partner is created
    Invoking this method will call  method of Class  which initiates the data update from legacy partner object to new partner object */
    if(((trigger.isAfter && trigger.isInsert)) ||(trigger.isAfter && trigger.isUpdate)){  
        OpportunityPartner_Trigger_Handler.copyOpportunityPartnerFromLegacyPartner(trigger.newMap);
       
    }        
    /*invoke handler class method whenever a Opportunity partner is deleted
    Invoking this method will call  method of Class  which initiates the data update from legacy partner object to new partner object */
    if(((trigger.isBefore && trigger.isDelete)) ){  
        OpportunityPartner_Trigger_Handler.deleteLegacyPartnersFromNewPartners(trigger.oldMap);
       
    }
    
    
}