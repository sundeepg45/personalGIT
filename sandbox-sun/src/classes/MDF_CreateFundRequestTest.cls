@IsTest
private class MDF_CreateFundRequestTest {
    public static MDF_CreateFundRequest instance {
        set;
        get;
    }
    
    public static testmethod void testConfirmUpdate() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;

        instance = new MDF_CreateFundRequest(new ApexPages.StandardController(mdf));
        instance.confirmUpdate();
    }    

    public static testmethod void testCancelUpdate() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;

        instance = new MDF_CreateFundRequest(new ApexPages.StandardController(mdf));
        instance.cancelUpdate();
    }
}