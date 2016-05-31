trigger CampaignPlan_UpdateAccount on Campaign_Plan__c (before insert) {
    for(Campaign_Plan__c campaignPlan : Trigger.new) {
        // @todo Refactor later when resource limits are hit.
        campaignPlan.Account__c = [
            select Partner_Name__c
              from SFDC_Channel_Account_Plan__c 
             where Id = :campaignPlan.Business_Plan__c
        ].Partner_Name__c;
    }
}