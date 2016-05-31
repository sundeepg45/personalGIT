@IsTest
private class MDF_CalculateTest {
    public static testmethod void testGenerateCodeCoverage() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;

        SFDC_Channel_Account_Plan__c businessPlan = new SFDC_Channel_Account_Plan__c();
        businessPlan.Partner_Name__c = account.Id; 
        businessPlan.Name = 'test';
        businessPlan.Fiscal_Year__c = 'FY2010';
        insert businessPlan; 

        SFDC_Budget__c mdf1 = new SFDC_Budget__c();
        mdf1.Name = 'CheckBudget1';
        mdf1.Account_master__c = account.Id;
        mdf1.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf1.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf1.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf1.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf1.Allocated_Budget__c = 100;
        insert mdf1;

        SFDC_Budget__c mdf2 = new SFDC_Budget__c();
        mdf2.Name = 'CheckBudget2';
        mdf2.Account_master__c = account.Id;
        mdf2.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf2.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf2.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf2.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf2.Allocated_Budget__c = 100;
        insert mdf2;

        SFDC_Budget__c mdf3 = new SFDC_Budget__c();
        mdf3.Name = 'CheckBudget3';
        mdf3.Account_master__c = account.Id;
        mdf3.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf3.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf3.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf3.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf3.Allocated_Budget__c = 100;
        insert mdf3;

        SFDC_Budget__c mdf4 = new SFDC_Budget__c();
        mdf4.Name = 'CheckBudget4';
        mdf4.Account_master__c = account.Id;
        mdf4.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf4.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf4.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf4.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf4.Allocated_Budget__c = 100;
        insert mdf4;

        MDF_Calculate instance = new MDF_Calculate(new ApexPages.StandardController(businessPlan));

        instance.totalAllocatedBudget();
        instance.getAllocatedBudget1();
        instance.getAllocatedBudget2();
        instance.getAllocatedBudget3();
        instance.getAllocatedBudget4();

        instance.getExecutedBudget1();
        instance.getExecutedBudget2();
        instance.getExecutedBudget3();
        instance.getExecutedBudget4();
    }

}