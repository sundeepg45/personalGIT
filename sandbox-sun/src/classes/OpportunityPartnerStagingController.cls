public class OpportunityPartnerStagingController{
    
    public Opportunity_Partner_Staging__c partnerStaging;
    /**
     * Constructor of the Controller class - Initializes all the variables.
     * Populates partenr staging data
     * @param StandardController
     */    
    public OpportunityPartnerStagingController(ApexPages.StandardController controller) {
        if (!Test.isRunningTest())
           controller.addFields(new List<String>{'Opportunity_Stage_Header_ID__c'});
        
        partnerStaging = (Opportunity_Partner_Staging__c)controller.getRecord();           
    }
    
    public PageReference redirectToOpptyHeaderStaging(){
        return new PageReference('/apex/OpportunityStaging_Edit?id='+partnerStaging.Opportunity_Stage_Header_ID__c);
    }
}