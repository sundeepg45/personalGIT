/**
 * This class helps to migrate records from old Opportunity Partner(OpportunityPartner__c) object 
 * to new Opportunity Partner (Opportunity_Partners__c) object. 
 * MOJO DOC: DOC-994439, DOC-996556
 * User Story: US57740 [PRL Redesign] - Data Migration--procedure validation (subset) 
 * User Story: US56675 [Serv and Int][SFDC] Copy over PRL data to the new PRL object and fields for use in reporting (and future GUI)
 * @version 2014-11-03
 * @author Sagar Mehta <smehta@redhat.com>
 * 2014-11-03 - created
 * Bill Riemers <briemers@redhat.com>
 * 2014-12-18 - Revised to be a little more bulk friendly (errors are still not appropriately handled)
 * 
 */
public class ProcessOpportunityPartnerClass{

    //constants to compare with the picklist values.
    private static final String FINANCIAL = 'Financial';
    private static final String INFLUENCING = 'Influencing';
    private static final String RESELLER_2 = 'Reseller 2';
    private static final String RESELLER_3 = 'Reseller 3';
    private static final String RESELLER_4 = 'Reseller 4';
    private static final String RESELLER_5 = 'Reseller 5';
    private static final String RESELLER_6 = 'Reseller 6';
    private static final String RESELLER_7 = 'Reseller 7';
    //private static final String NON_ENTITLED_ENDCO = 'Non Entitled Endco';

    /**
     * Processes all the Opportunities and Opportunity Partner records.
     *
     * @param  opportunityList
     * @return map of errors based on opportunity id
     */
    public static Map<Id,String> processOpportunityPartners(List<Opportunity> opportunityList){
       Map<Id,String> errorMap = new Map<Id,String>();
//       try{
           Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
           List<Opportunity_Partners__c> opportunityPartnersList = new List<Opportunity_Partners__c>();
           for(Opportunity opportunity : opportunityList){
              opportunityMap.put(opportunity.Id, opportunity);
              Integer counter = 1;
              //create instance of new Opportunity Partner object.
              Opportunity_Partners__c newPartner = new Opportunity_Partners__c(
                  Id=opportunity.Opportunity_Partners__c,
                  Opportunity__c = opportunity.Id,
                  OpportunityId__c = opportunity.Id,
                  Financial_Partner__c = null,
                  Financial_Partner_Tier__c = null,
                  Financial_Partner_Type__c = null,
                  Influencer_1__c = null,
                  Influencer_1_Tier__c = null,
                  Influencer_1_Type__c = null,
                  Influencer_2__c = null,
                  Influencer_2_Tier__c = null,
                  Influencer_2_Type__c = null,
                  Influencer_3__c = null,
                  Influencer_3_Tier__c = null,
                  Influencer_3_Type__c = null,
                  Influencer_4__c = null,
                  Influencer_4_Tier__c = null,
                  Influencer_4_Type__c = null,
                  Reseller1__c = null,
                  Reseller1_Tier__c = null,
                  Reseller1_Type__c = null,
                  Reseller_2__c = null,
                  Reseller_2_Tier__c = null,
                  Reseller_2_Type__c = null,
                  Reseller_3__c = null,
                  Reseller_3_Tier__c = null,
                  Reseller_3_Type__c = null,
                  Reseller_4__c = null,
                  Reseller_4_Tier__c = null,
                  Reseller_4_Type__c = null,
                  Reseller_5__c = null,
                  Reseller_5_Tier__c = null,
                  Reseller_5_Type__c = null,
                  Reseller_6__c = null,
                  Reseller_6_Tier__c = null,
                  Reseller_6_Type__c = null
                  //Non_entitled_End_Customer__c = null,
                  //Non_entitled_End_Customer_Tier__c = null,
                  //Non_entitled_End_Customer_Type__c = null 
                  );
              for(OpportunityPartner__c partner : opportunity.OpportunityPartners2__r) {
                  //Picklist value of Transaction Role is compared -- Financial
                  if(partner.RelationshipType__c == FINANCIAL){
                       newPartner.Financial_Partner__c = partner.Partner__c;
                       newPartner.Financial_Partner_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Financial_Partner_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Influencing
                  }else if(partner.RelationshipType__c == INFLUENCING && counter == 1){
                       newPartner.Influencer_1__c = partner.Partner__c;
                       newPartner.Influencer_1_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Influencer_1_Type__c = partner.PartnerType__r.Name;
                       counter = counter + 1;
                  //Picklist value of Transaction Role is compared -- Influencing
                  }else if(partner.RelationshipType__c == INFLUENCING && counter == 2){
                       newPartner.Influencer_2__c = partner.Partner__c;
                       newPartner.Influencer_2_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Influencer_2_Type__c = partner.PartnerType__r.Name;
                       counter = counter + 1;
                  //Picklist value of Transaction Role is compared -- Influencing
                  }else if(partner.RelationshipType__c == INFLUENCING && counter == 3){
                       newPartner.Influencer_3__c = partner.Partner__c;
                       newPartner.Influencer_3_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Influencer_3_Type__c = partner.PartnerType__r.Name;
                       counter = counter + 1;
                  //Picklist value of Transaction Role is compared -- Influencing
                  }else if(partner.RelationshipType__c == INFLUENCING && counter == 4){
                       newPartner.Influencer_4__c = partner.Partner__c;
                       newPartner.Influencer_4_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Influencer_4_Type__c = partner.PartnerType__r.Name;
                       counter = counter + 1;
                  //Picklist value of Transaction Role is compared -- Reseller 2
                  }else if(partner.RelationshipType__c == RESELLER_2){
                       newPartner.Reseller1__c = partner.Partner__c;
                       newPartner.Reseller1_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller1_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Reseller 3
                  }else if(partner.RelationshipType__c == RESELLER_3){
                       newPartner.Reseller_2__c = partner.Partner__c;
                       newPartner.Reseller_2_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller_2_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Reseller 4
                  }else if(partner.RelationshipType__c == RESELLER_4){
                       newPartner.Reseller_3__c = partner.Partner__c;
                       newPartner.Reseller_3_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller_3_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Reseller 5
                  }else if(partner.RelationshipType__c == RESELLER_5){
                       newPartner.Reseller_4__c = partner.Partner__c;
                       newPartner.Reseller_4_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller_4_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Reseller 6
                  }else if(partner.RelationshipType__c == RESELLER_6){
                       newPartner.Reseller_5__c = partner.Partner__c;
                       newPartner.Reseller_5_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller_5_Type__c = partner.PartnerType__r.Name;
                  //Picklist value of Transaction Role is compared -- Reseller 7
                  }else if(partner.RelationshipType__c == RESELLER_7){
                       newPartner.Reseller_6__c = partner.Partner__c;
                       newPartner.Reseller_6_Tier__c = partner.PartnerTier__r.Name;
                       newPartner.Reseller_6_Type__c = partner.PartnerType__r.Name;                 
                  }
              }
              opportunityPartnersList.add(newPartner);
           }
           if(! opportunityPartnersList.isEmpty()){
               List<Opportunity> updatedOpportunityList = new List<Opportunity>();
               // Iterate through each returned result
               for (Database.UpsertResult sr : Database.upsert(opportunityPartnersList, Schema.Opportunity_Partners__c.OpportunityId__c, false)){
                   Opportunity_Partners__c oppPartners = opportunityPartnersList.remove(0);
                   Opportunity opportunity = opportunityMap.get(oppPartners.Opportunity__c);
                   System.debug('+++ opportunity.Id: ' + opportunity.Id);
                   System.debug('+++ opportunity.Opportunity_Partners__c: ' + opportunity.Opportunity_Partners__c);
                   if(!sr.isSuccess()){
                       // Operation failed, so get all errors
                       for(Database.Error err : sr.getErrors()){
                           errorMap.put(oppPartners.OpportunityId__c, 'The following error has occurred: '+err.getStatusCode() + ': ' + err.getMessage() + '. Fields that affected this error: ' + err.getFields());
                       }
                   }else if(opportunity.Opportunity_Partners__c == null) {
                       updatedOpportunityList.add(new Opportunity(
                           Id = oppPartners.Opportunity__c,
                           Opportunity_Partners__c = oppPartners.Id,
                           FinancialPartner__c = oppPartners.Financial_Partner__c,
                           ResellerPartner__c = oppPartners.Reseller1__c ));
                   }
               }
               if(!updatedOpportunityList.isEmpty()) {
                   Boolean beforeLock = ThreadLock.lock(OpportunityTriggerBefore2.LOCK_STRING);
                   Boolean afterLock = ThreadLock.lock(OpportunityTriggerAfter2.LOCK_STRING);
                   try {
                       for(Database.SaveResult sr : Database.update(updatedOpportunityList,false)) {
                           Opportunity opp = updatedOpportunityList.remove(0);
                           if(! sr.isSuccess()) {
                               for(Database.Error err : sr.getErrors()){
                                   errorMap.put(opp.Id, 'The following error has occurred: '+err.getStatusCode() + ': ' + err.getMessage() + '. Fields that affected this error: ' + err.getFields());
                               }
                           }
                       }
                   }
                   finally {
                       if(beforeLock) {
                           ThreadLock.unlock(OpportunityTriggerBefore2.LOCK_STRING);
                       }
                       if(afterLock) {
                           ThreadLock.unlock(OpportunityTriggerAfter2.LOCK_STRING);
                       }
                   }
               }
           }
//       }catch(Exception e){
//           errorList.add('Caught Exception: '+e);
//       }
       return errorMap;
    }
}