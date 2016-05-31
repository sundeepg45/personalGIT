trigger SolutionOpportunity_PreventDuplicates on StrategicPlan_SolutionOpportunity__c (before insert,before update) {
    for(StrategicPlan_SolutionOpportunity__c solutionOpportunity : Trigger.new) {
        solutionOpportunity.CombinedKey__c = solutionOpportunity.StrategicPlan_Solution__c+''+solutionOpportunity.Opportunity__c;
    }
}