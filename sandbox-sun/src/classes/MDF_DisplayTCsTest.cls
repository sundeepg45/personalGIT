@IsTest
private class MDF_DisplayTCsTest {
    public static MDF_DisplayTCs instance {
        set;
        get;
    }
    
    public static testmethod void testGetEncodedTCs() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'APAC';
        account1.Subregion__c = 'Japan';
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
        
        instance = new MDF_DisplayTCs(new ApexPages.StandardController(mdf));
        system.assert(null != instance.getEncodedTCs());
    }
}