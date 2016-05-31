public class OpportunityLineStagingController{
    
    public Opportunity_Line_Staging__c lineStaging;
    /**
     * Constructor of the Controller class - Initializes all the variables.
     * Populates partenr staging data
     * @param StandardController
     */    
    public OpportunityLineStagingController(ApexPages.StandardController controller) {
        if (!Test.isRunningTest())
           controller.addFields(new List<String>{'Opportunity_Stage_Header_ID__c'});
        
        lineStaging = (Opportunity_Line_Staging__c)controller.getRecord();           
    }
    
    public PageReference redirectToOpptyHeaderStaging(){
        return new PageReference('/apex/OpportunityStaging_Edit?id='+lineStaging.Opportunity_Stage_Header_ID__c);
    }
}