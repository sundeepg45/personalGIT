public with sharing class BusinessPlan_AccountTeamController {
    public BusinessPlan_AccountTeamController(ApexPages.StandardController controller) {
        businessPlanId = controller.getId();
    } 

    public Id businessPlanId {
    	set;
    	get;
    }

    public List<SFDC_Plan_Resource_Association__c> accountTeamList {
    	get {
    		return [
    		  select Name
    		       , Resource__r.Name
    		       , Channel_Plan__c
    		       , Role__c
    		       , Account_Name__c
    		       , Resource__c
    		       , Title__c
    		       , Email__c
    		       , Phone__c
    		       , Mobile__c 
    		    from SFDC_Plan_Resource_Association__c 
    		   where Channel_Plan__c = :businessPlanId
    	    ];
    	}
    }

}