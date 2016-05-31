public with sharing class BusinessPlan_ObjectiveSectionController {
    public BusinessPlan_ObjectiveSectionController() {
        businessPlanId = ApexPages.currentPage().getParameters().get('id');
    }
    
    public BusinessPlan_ObjectiveSectionController(ApexPages.StandardController controller) {
        businessPlanId = controller.getId();
    } 

    public Id businessPlanId {
        set;
        get;
    }

    public List<SFDC_Objective__C> objectiveList {
    	get {
    		return [
    		    select Name
                     , Account_Name__c
    		         , Channel_Plan__c
    		         , Description__c
                     , Full_Year_Attainment__c 
                     , Full_Year_Goal__c
                     , Objective_Number_New__c
                     , Objective_Status__c
                     , Objective_Type__c
                     , Q1_Attainment__c
    		         , Q1_Goal__c
    		         , Q2_Attainment__c
                     , Q2_Goal__c
    		         , Q3_Attainment__c
                     , Q3_Goal__c
    		         , Q4_Attainment__c
                     , Q4_Goal__c
                     , Target_Date__c
    		      from SFDC_Objective__c 
    		     where Channel_Plan__c = :businessPlanId
    		 ];
    	}
    }
}