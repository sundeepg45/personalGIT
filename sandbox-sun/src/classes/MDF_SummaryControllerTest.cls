@IsTest
private class MDF_SummaryControllerTest {
	public static MDF_SummaryController instance {
		set;
		get;
	}
	
    public static testmethod void testActionDone() {
    	instance = new MDF_SummaryController();
    	instance.actionDone();
    }

    public static testmethod void testActionDownloadAsPDF() {
        instance = new MDF_SummaryController();
        instance.actionDownloadAsPDF();
    }

    public static testmethod void testActionPrintableView() {
        instance = new MDF_SummaryController();
        instance.actionPrintableView();
    }

    public static testmethod void testGetBudget() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'Unknown';
        account1.Subregion__c = 'Unknown';
        insert account1;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account1.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;
        
        ApexPages.currentPage().getParameters().put('id', mdf.Id);
        instance = new MDF_SummaryController();
        instance.getBudget();
    }

    public static testmethod void testGetBudgetId() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'Unknown';
        account1.Subregion__c = 'Unknown';
        insert account1;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account1.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;
        
        ApexPages.currentPage().getParameters().put('id', mdf.Id);
        instance = new MDF_SummaryController();
        instance.getBudgetId();
    }

    public static testmethod void testGetFundPairList() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'Unknown';
        account1.Subregion__c = 'Unknown';
        insert account1;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account1.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;
        
        ApexPages.currentPage().getParameters().put('id', mdf.Id);
        instance = new MDF_SummaryController();
        instance.getFundPairList();
    }
}