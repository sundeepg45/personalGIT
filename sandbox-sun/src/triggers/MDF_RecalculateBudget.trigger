trigger MDF_RecalculateBudget on SFDC_Budget__c (before update) {
    for (SFDC_Budget__c budget : Trigger.new) {
        try {
            MDF_RecalculateBudget calculator = new MDF_RecalculateBudget();
            calculator.budget = budget;
            calculator.recalculate();
        } catch (Exception e) {
            budget.addError(e);
        }
    }
}