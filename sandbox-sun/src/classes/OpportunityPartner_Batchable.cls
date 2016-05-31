/**
* This class helps to migrate records from old Opportunity Partner(OpportunityPartner__c) object 
* to new Opportunity Partner (Opportunity_Partners__c) object. 
* MOJO DOC: DOC-994439, DOC-996556
* User Story: US57740 [PRL Redesign] - Data Migration--procedure validation (subset) 
* @author Sagar Mehta <smehta@redhat.com>
* @version 2014-10-17
* 2014-10-17 - created
* Bill C Riemers <briemers@redhat.com>
* 2014-10-21 - corrected Opportunity_Partner__c to be Opportunity_Partners__c
* Vipul Jain <vipjain@redhat.com>
* 2014-10-24 -Update the query filter criteria (removed Isclosed = true or iswon = true)
* 
*/
global class OpportunityPartner_Batchable extends AbstractBatchable{                  
   
   /**
    * Constructor of the Controller class - Initializes all the variables.     
    */    
   public OpportunityPartner_Batchable(){        
        super('OpportunityPartner_Batchable');
   }
   
   /**
    * Query the records from old Opportunity Partner object (OpportunityPartner__c)
    * start method
    * @param Database.BatchableContext bc
    */
   public Database.QueryLocator start(Database.BatchableContext bc){
       errorList.clear();
       //get Limit value
       LongSetting__c longSetting = LongSetting__c.getInstance('Opportunity_Batch_Limit');
       //get Closedate value
       Date_Setting__c dateSetting = Date_Setting__c.getInstance('Opportunity_Batch_Close_Date');
       //get Last Mofified Date value
       StringSetting__c stringSetting = StringSetting__c.getInstance('Opportunity_Batch_LastModified_Date');
       String query = 'SELECT Id,';
       query = query + ' Name,';
       query = query + ' Opportunity_Partners__c,';
       query = query + ' (SELECT Id,';
       query = query + ' Opportunity__c,';
       query = query + ' Opportunity__r.Name,';
       query = query + ' Partner__c,';
       query = query + ' PartnerTier__r.Name,';
       query = query + ' PartnerType__r.Name,';
       query = query + ' RelationshipType__c';
       query = query + ' FROM OpportunityPartners2__r)';
       query = query + ' FROM Opportunity';
       query = query + ' WHERE';
       query = query + ' Opportunity_Partners__c = null';
       /* comment below critieria as per the discussion with on 25-Oct-2014
       //query = query + ' WHERE (IsClosed = true OR IsWon = true)';
       //query = query + ' AND CloseDate > ' + setting.ClosedDate__c;
       //query = query + ' AND LastModifiedDate = ' + setting.LastModifiedDate__c;
       */
       if(dateSetting.Value__c != null){
         Date closedDate = dateSetting.Value__c;         
         date cDate = date.newInstance(closedDate.year(), closedDate.month(), closedDate.day());
         query = query + ' AND CloseDate >: cDate';
         query = query + ' AND LastModifiedDate = ' + stringSetting.Value__c;
       }
       if(longSetting.Value__c != null)
          query = query + ' LIMIT ' + Integer.valueOf(longSetting.Value__c);
       
       return Database.getQueryLocator(query);        
   }
   
   /**
    * Executes the batch with the custom logic for fields mapping.
    * execute method
    * @param  List<Opportunity> opportunityList
    * @param  Database.BatchableContext bc
    */
   public void execute(Database.BatchableContext bc, List<Opportunity> opportunityList){     
      processOpportunities(opportunityList);
      if(!errorList.isEmpty()) {
         for(String error : errorList) {
          System.debug(error);
         }
      }
   }
  
    /**
     * Processes all the Opportunities and Opportunity Partner records.
     *
     * @param  opportunityList
     */
    private void processOpportunities(List<Opportunity> opportunityList) {         
         errorList.addAll(ProcessOpportunityPartnerClass.processOpportunityPartners(opportunityList).values());
    }
}