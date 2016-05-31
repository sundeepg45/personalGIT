trigger MDF_ValidateBudgetName on SFDC_Budget__c (before insert, before update) {
    for (SFDC_Budget__c budget : Trigger.new) {
    	try {
    		budget.Unique_Name_Constraint__c = budget.Name;
    	} catch (Exception e) {
    		budget.addError (System.Label.MDF_ErrorBudgetNameIsNotUnique);
    	}
    }
}