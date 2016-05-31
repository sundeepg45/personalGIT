trigger BusinessPlan_DeleteChildObjects on SFDC_Channel_Account_Plan__c (before delete) {
    for (SFDC_Channel_Account_Plan__c plan : Trigger.old) {
        delete [
            select Id 
              from SFDC_Objective__c 
             where Channel_Plan__c = :plan.Id
        ];
        
        delete [
            select Id
              from Campaign_Plan__c 
             where Business_Plan__c = :plan.Id
        ];
        
        delete [
            select Id
              from Key_Joint_Sales_Engagement__c 
             where Channel_Plan__c = :plan.Id
        ];
        
        delete [
            select Id
              from SFDC_Plan_Resource_Association__c 
             where Channel_Plan__c = :plan.Id
        ];
    }
}