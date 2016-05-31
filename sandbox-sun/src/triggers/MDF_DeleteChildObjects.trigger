trigger MDF_DeleteChildObjects on SFDC_Budget__c (before delete) {

    List <SFDC_MDF__c> fundRequestList = new List<SFDC_MDF__c>(); 
    List<SFDC_MDF_Claim__c> fundClaimList = new List<SFDC_MDF_Claim__c>();
    
    
    for(Integer i=0;i<Trigger.old.size();i++){
        
        fundRequestList = [select id from SFDC_MDF__c where Budget__c =: Trigger.old[i].id];
        fundClaimList = [select id from SFDC_MDF_Claim__c where SFDC_MDF_Claim__c.Budget__c =: Trigger.old[i].id];
        
        
        delete fundRequestList; 
        delete fundClaimList; 
        
        
        
    }   


}