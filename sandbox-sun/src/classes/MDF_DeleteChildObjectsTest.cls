@IsTest
private class MDF_DeleteChildObjectsTest {
    public static testmethod void testDeleteFundRequests() {
        Account account = new Account();
        account.Name = 'Account';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner'
        ].Id;
        insert account;

        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;

        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = 'USD';
        fundRequest.Total_Expenditure_of_Activity__c = 100 * 1.50;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100;
        fundRequest.Approval_Status__c = 'Pending First Approval';
        insert fundRequest;

        delete mdf;
    }
}