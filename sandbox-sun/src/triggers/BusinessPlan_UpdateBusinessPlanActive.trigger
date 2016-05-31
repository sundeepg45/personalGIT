trigger BusinessPlan_UpdateBusinessPlanActive on SFDC_Channel_Account_Plan__c(before insert,before update) {
    new BusinessPlanActive().setUniqueObjectiveRule(Trigger.new);
}