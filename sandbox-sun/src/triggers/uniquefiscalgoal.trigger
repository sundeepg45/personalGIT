trigger uniquefiscalgoal on FiscalGoals__c(before insert,before update) {

new FiscalGoals().setUniqueObjectiveRule(Trigger.new);

}