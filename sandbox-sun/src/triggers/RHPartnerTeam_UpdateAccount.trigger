trigger RHPartnerTeam_UpdateAccount on SFDC_Plan_Resource_Association__c (before insert) {
    for(SFDC_Plan_Resource_Association__c partnerTeam : Trigger.new) {
        partnerTeam.Account_Name__c = [
            select Partner_Name__c 
              from SFDC_Channel_Account_Plan__c 
             where Id = :partnerTeam.Channel_Plan__c
        ].Partner_Name__c;
    }
}