trigger Objective_SetAccountToPlanPartner on SFDC_Objective__c (before insert) {
    
    SFDC_Channel_Account_Plan__c bizPlan = [select Partner_Name__c from SFDC_Channel_Account_Plan__c where id =: Trigger.new[0].Channel_Plan__c ];
    Trigger.new[0].Account_Name__c = bizPlan.Partner_Name__c;
    

}